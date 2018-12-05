//
//  ViewController.m
//  OpenGLDemo_GLK
//
//  Created by suruochang on 2018/10/9.
//  Copyright © 2018年 suruochang. All rights reserved.
//

#import "ViewController.h"
#import "VideoCaptureDevice.h"
#import "PNGHelper.h"
#import <OpenGLES/ES2/glext.h>
#import "NSString+image.h"

static void DataProviderReleaseDataCallback(void *info, const void *data, size_t size)
{
    free((void *)data);
}

@interface ViewController ()
{
    GLuint uvBuffer;
    GLuint vertexBuffer;
    GLuint yuvProgram;
    CVOpenGLESTextureRef _videoTexture;
    CVOpenGLESTextureCacheRef _videoTextureCache;
}

@property (nonatomic, strong) VideoCaptureDevice *videoCapture;

@property (nonatomic, strong) EAGLContext *context;

@property (nonatomic, assign) GLuint combineProgram;
@property (nonatomic, assign) GLuint bufferAttr;
@property (nonatomic, assign) GLuint textureId;

@property (nonatomic, assign) GLuint frameBufferId;
@property (nonatomic, assign) GLuint renderTextureId;
@property (nonatomic, assign) GLuint frameBufferWidth;
@property (nonatomic, assign) GLuint frameBufferHeight;
@property (nonatomic, assign) GLuint sampleBufferTexture;

@property (nonatomic, assign) GLuint textTextureId;
@property (nonatomic, assign) CGRect textShowRect;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setupEAGLContext];
    
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGFloat scale = [UIScreen mainScreen].scale;
    self.frameBufferWidth = (bounds.size.width * scale);
    self.frameBufferHeight = (bounds.size.height * scale);
    
    [self initFboObjectWithWidth:self.frameBufferWidth
                          height:self.frameBufferHeight];
    
    [self setupCameraCompoments];
    
    [self setupGLProgram];
    [self setupTextTexture];
}

- (void)setupEAGLContext {
    // 初始化EAGLContext
    GLKView *view = (GLKView *)self.view;
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    // 设置帧率为60fps
    self.preferredFramesPerSecond = 60;
    
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.drawableMultisample = GLKViewDrawableMultisample4X;
    
    [EAGLContext setCurrentContext:view.context];
    self.context = view.context;
}

- (void)setupGLProgram
{
    //读取文件路径
    NSString* vertFile = [[NSBundle mainBundle] pathForResource:@"combine" ofType:@"vsh"];
    NSString* fragFile = [[NSBundle mainBundle] pathForResource:@"combine" ofType:@"fsh"];
    
    //加载shader
    self.combineProgram = [self loadShaders:vertFile frag:fragFile];
    
    //链接
    glLinkProgram(self.combineProgram);
    GLint linkSuccess;
    glGetProgramiv(self.combineProgram, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) { //连接错误
        GLchar messages[256];
        glGetProgramInfoLog(self.combineProgram, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"error%@", messageString);
        return ;
    }
    else {
        NSLog(@"link ok");
        glUseProgram(self.combineProgram); //成功便使用，避免由于未使用导致的的bug
    }
}

- (void)setupCameraCompoments
{
    [self setupYUVProgram];
    
    GLfloat quadVertexData [] = {
        -1, -1,
        1, -1,
        -1, 1,
        1, 1,
    };
    GLuint vertexId;
    glGenBuffers(1, &vertexId);
    glBindBuffer(GL_ARRAY_BUFFER, vertexId);
    glBufferData(GL_ARRAY_BUFFER, sizeof(quadVertexData), quadVertexData, GL_STATIC_DRAW);
    
    GLfloat quadTextureData[] =  { // 正常坐标
        0, 0,
        1, 0,
        0, 1,
        1, 1
    };
    
    GLuint uvId;
    glGenBuffers(1, &uvId);
    glBindBuffer(GL_ARRAY_BUFFER, uvId);
    glBufferData(GL_ARRAY_BUFFER, sizeof(quadTextureData), quadTextureData, GL_STATIC_DRAW);
    
    uvBuffer = uvId;
    vertexBuffer = vertexId;
    
    VideoCaptureDevice *device = [[VideoCaptureDevice alloc] init];
    [device setupDevice];
    device.delegate = (id<VideoCaptureDeviceDelegate>)self;
    [device startRunning];
    
    self.videoCapture = device;
}

- (void)setupYUVProgram
{
    //读取文件路径
    NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"YUVShader" ofType:@"vsh"];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"YUVShader" ofType:@"fsh"];
    
    //加载shader
    yuvProgram = [self loadShaders:vertFile frag:fragFile];
    
    //链接
    glLinkProgram(yuvProgram);
    GLint linkSuccess;
    glGetProgramiv(yuvProgram, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) { //连接错误
        GLchar messages[256];
        glGetProgramInfoLog(yuvProgram, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"error%@", messageString);
        return ;
    }
    else {
        NSLog(@"link ok");
        glUseProgram(yuvProgram); //成功便使用，避免由于未使用导致的的bug
    }
}

- (void)setupTextTexture
{
    NSString *text = @"Hello World!";
    UIImage *image = [text imageWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18.0], NSForegroundColorAttributeName:[UIColor blackColor]}];
    NSLog(@"%@", image);
    
    CGImageRef spriteImage = image.CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", text);
        return;
    }
    
    // 2 读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte *spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte)); //rgba共4个byte
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData,
                                                       width,
                                                       height,
                                                       8,
                                                       width * 4,
                                                       CGImageGetColorSpace(spriteImage),
                                                       kCGImageAlphaPremultipliedLast);
    
    CGContextClearRect(spriteContext, CGRectMake(0, 0, width, height ));
    CGContextTranslateCTM(spriteContext, 0, height);
    CGContextScaleCTM (spriteContext, 1.0, -1.0);
    // 3在CGContextRef上绘图
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    // 4绑定纹理到默认的纹理ID（这里只有一张图片，故而相当于默认于片元着色器里面的colorMap，如果有多张图不可以这么做）
    glActiveTexture(GL_TEXTURE2);
    glGenTextures(1, &_textTextureId);
    glBindTexture(GL_TEXTURE_2D, _textTextureId);
    
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_RGBA,
                 (GLint)width,
                 (GLint)height,
                 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE,
                 spriteData);
    
    free(spriteData);
    
    //水印显示在左下角
    self.textShowRect = CGRectMake(0.05, 0.05,
                                   image.size.width / CGRectGetWidth(self.view.frame),
                                   image.size.height / CGRectGetHeight(self.view.frame));
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark VideoCaptureDeviceDelegate

- (void)device:(VideoCaptureDevice *)device didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;
{
    [self setupBufferToTexture:sampleBuffer];
}

- (void)setupBufferToTexture:(CMSampleBufferRef)sampleBuffer
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVReturn err;
    if (pixelBuffer != NULL) {
        int frameWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
        int frameHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
        
        
//        if (_sampleBufferTexture > 0) {
//            glDeleteTextures(1, &_sampleBufferTexture);
//        }
//
//        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
//
//        glActiveTexture(GL_TEXTURE0);
//        glGenTextures(1, &_sampleBufferTexture);
//        glBindTexture(GL_TEXTURE_2D, _sampleBufferTexture);
//
//        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//
//        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, frameWidth, frameHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(pixelBuffer));
//
//        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

        
        if (!_videoTextureCache) {

            GLKView *view = (GLKView *)self.view;

            CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, view.context, NULL, &_videoTextureCache);
            if (err != noErr) {
                NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
                return;
            }
        }

        [self cleanUpTextures];


        glActiveTexture(GL_TEXTURE0);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           _videoTextureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_RGBA,
                                                           frameWidth,
                                                           frameHeight,
                                                           GL_BGRA,
                                                           GL_UNSIGNED_BYTE,
                                                           0,
                                                           &_videoTexture);
        if (err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }

        glBindTexture(CVOpenGLESTextureGetTarget(_videoTexture), CVOpenGLESTextureGetName(_videoTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
    }
    
    glUseProgram(yuvProgram);
    
    glUniform1i(glGetUniformLocation(yuvProgram, "Sampler"), 0);
}

- (void)cleanUpTextures
{
    if (_videoTexture) {
        CFRelease(_videoTexture);
        _videoTexture = NULL;
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

#pragma mark callback
- (void)update {
    
}

#pragma mark render
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    CGFloat scale = [[UIScreen mainScreen] scale]; //获取视图放大倍数，可以把scale设置为1试试
    glViewport(self.view.frame.origin.x * scale, self.view.frame.origin.y * scale, self.view.frame.size.width * scale, self.view.frame.size.height * scale); //设置视口大小

    glBindFramebuffer(GL_FRAMEBUFFER, self.frameBufferId);

    [self drawSampleVideo];

    __block CGFloat red, green, blue, alpha;
    [self averageColor:^(CGFloat redComponent, CGFloat greenComponent, CGFloat blueComponent, CGFloat alphaComponent) {
        red = redComponent;
        green = greenComponent;
        blue = blueComponent;
        alpha = alphaComponent;
    }];
    
    [(GLKView *)self.view bindDrawable];

    glClear ( GL_COLOR_BUFFER_BIT );
    glViewport (self.view.frame.origin.x * scale, self.view.frame.origin.y * scale, self.view.frame.size.width * scale, self.view.frame.size.height * scale);

    glUseProgram(_combineProgram);
    
    GLuint vertexLocation = glGetAttribLocation(_combineProgram, "position");
    GLuint texLocation = glGetAttribLocation(_combineProgram, "texCoord");
    GLuint samplerLocation = glGetUniformLocation(_combineProgram, "Sampler");
    GLuint textSamplerLocation = glGetUniformLocation(_combineProgram, "textSampler");
    GLuint textRectLocation = glGetUniformLocation(_combineProgram, "textRect");
    GLuint textColorLocation = glGetUniformLocation(_combineProgram, "u_textColor");
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glVertexAttribPointer(vertexLocation, 2, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(vertexLocation);
    
    glBindBuffer(GL_ARRAY_BUFFER, uvBuffer);
    glVertexAttribPointer(texLocation, 2, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(texLocation);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, self.renderTextureId);
    glUniform1i(samplerLocation, 1);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, self.textTextureId);
    glUniform1i(textSamplerLocation, 2);
    
    CGRect textShowRect = self.textShowRect;
    glUniform4f(textRectLocation, textShowRect.origin.x, textShowRect.origin.y, textShowRect.size.width, textShowRect.size.height);
    
    CGFloat average = (red + green + blue) / 3.0;
    CGFloat result = (average + 0.5);
    float color = result - floorf(result);
    
    glUniform3f(textColorLocation, color, color, color);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

}

- (void)drawSampleVideo
{
    glClear ( GL_COLOR_BUFFER_BIT );
    
    glUseProgram(yuvProgram);
    
    GLuint vertexLocation = glGetAttribLocation(yuvProgram, "position");
    GLuint texLocation = glGetAttribLocation(yuvProgram, "texCoord");
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glVertexAttribPointer(vertexLocation, 2, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(vertexLocation);
    
    glBindBuffer(GL_ARRAY_BUFFER, uvBuffer);
    glVertexAttribPointer(texLocation, 2, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(texLocation);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void)dealloc
{
    [self cleanUpTextures];
    
    if (_videoTextureCache) {
        CFRelease(_videoTextureCache);
    }
    
    self.videoCapture.delegate = nil;
    [self.videoCapture stopRunning];
    self.videoCapture = nil;
    
    if (yuvProgram) {
        glDeleteProgram(yuvProgram);
    }
    
    if (_combineProgram) {
        glDeleteProgram(_combineProgram);
    }
    
    if (_bufferAttr) {
        glDeleteBuffers(1, &_bufferAttr);
    }
    
    if (_textureId) {
        glDeleteTextures(1, &_textureId);
    }
}

#pragma mark OpengGL Compile
/**
 *  c语言编译流程：预编译、编译、汇编、链接
 *  glsl的编译过程主要有glCompileShader、glAttachShader、glLinkProgram三步；
 *  @param vert 顶点着色器
 *  @param frag 片元着色器
 *
 *  @return 编译成功的shaders
 */
- (GLuint)loadShaders:(NSString *)vert frag:(NSString *)frag {
    GLuint verShader, fragShader;
    GLint program = glCreateProgram();
    
    //编译
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    
    //释放不需要的shader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}

- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    //读取字符串
    NSString* content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar* source = (GLchar *)[content UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
}

- (void)initFboObjectWithWidth:(GLsizei)width height:(GLsizei)height
{
    GLsizei windowWidth = width;
    GLsizei windowHeight = height;
    
    GLuint renderedTexture;
    glGenTextures(1, &renderedTexture);
    // "Bind" the newly created texture : all future texture functions will modify this texture
    glBindTexture(GL_TEXTURE_2D, renderedTexture);
    // Poor filtering
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    // Give an empty image to OpenGL ( the last "0" means "empty" )
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, windowWidth, windowHeight, 0,GL_RGB, GL_UNSIGNED_BYTE, NULL);
    
    // The framebuffer, which regroups 0, 1, or more textures, and 0 or 1 depth buffer.
    GLuint FramebufferName = 0;
    glGenFramebuffers(1, &FramebufferName);
    glBindFramebuffer(GL_FRAMEBUFFER, FramebufferName);
    // Set "renderedTexture" as our colour attachement #0
    //    glFramebufferTexture(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, renderedTexture, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, renderedTexture, 0);
    
    
//     The depth buffer
//        GLuint depthrenderbuffer;
//        glGenRenderbuffers(1, &depthrenderbuffer);
//        glBindRenderbuffer(GL_RENDERBUFFER, depthrenderbuffer);
//        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, windowWidth, windowHeight);
//        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthrenderbuffer);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    switch (status) {
        case GL_FRAMEBUFFER_COMPLETE:
            break;
        case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
            break;
        case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
            break;
        case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
            break;
        case GL_FRAMEBUFFER_UNSUPPORTED:
            break;
            
        default:
            break;
    }
    
    if (status != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"GL_FRAMEBUFFER 创建有问题");
    }
    self.frameBufferId = FramebufferName;
    self.renderTextureId = renderedTexture;
    
}

- (void)saveFrameBufferToImage
{
    int width = self.frameBufferWidth;
    int height = self.frameBufferHeight;
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.frameBufferId);
    glViewport(0, 0, width, height);
    
    NSUInteger totalBytesForImage = width * height * 4;
    
    GLubyte *rawImagePixels = (GLubyte *)malloc(totalBytesForImage);
    
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, rawImagePixels);
    
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rawImagePixels, totalBytesForImage, DataProviderReleaseDataCallback);
    CGColorSpaceRef defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGImageRef cgImageFromBytes = CGImageCreate(width,
                                                height,
                                                8,
                                                32,
                                                4 * width,
                                                defaultRGBColorSpace,
                                                kCGBitmapByteOrderDefault | kCGImageAlphaLast,
                                                dataProvider,
                                                NULL,
                                                NO,
                                                kCGRenderingIntentDefault);
    
    CGDataProviderRelease(dataProvider);
    CGColorSpaceRelease(defaultRGBColorSpace);
    
    UIImage *image = [[UIImage alloc] initWithCGImage:cgImageFromBytes scale:1.0 orientation:(UIImageOrientationUp)];
    NSLog(@"%@", image);
    CGImageRelease(cgImageFromBytes);
}

- (void)averageColor:(void (^)(CGFloat redComponent, CGFloat greenComponent, CGFloat blueComponent, CGFloat alphaComponent))complete
{
    if (CGRectEqualToRect(self.textShowRect, CGRectZero))
    {
        return;
    }
    
    int width = self.frameBufferWidth;
    int height = self.frameBufferHeight;
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.frameBufferId);
    glViewport(0, 0, width, height);
    
    CGRect regin = self.textShowRect;
    
    NSUInteger totalNumberOfPixels = (regin.size.width * width) * (regin.size.height * height);
    NSUInteger totalBytesForImage = totalNumberOfPixels * 4;
    
    GLubyte *rawImagePixels = (GLubyte *)malloc(totalBytesForImage);
    
    //截取所有像素
//    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, rawImagePixels);
    
    //截取的是部分像素
    //(0,0)为左下角
    glReadPixels(regin.origin.x * width,
                 regin.origin.y * height,
                 regin.size.width * width,
                 regin.size.height *height,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE,
                 rawImagePixels);
    
    NSUInteger redTotal = 0, greenTotal = 0, blueTotal = 0, alphaTotal = 0;
    NSUInteger byteIndex = 0;
    for (NSUInteger currentPixel = 0; currentPixel < totalNumberOfPixels; currentPixel++)
    {
        redTotal += rawImagePixels[byteIndex++];
        greenTotal += rawImagePixels[byteIndex++];
        blueTotal += rawImagePixels[byteIndex++];
        alphaTotal += rawImagePixels[byteIndex++];
    }
    
    free (rawImagePixels);
    
    CGFloat normalizedRedTotal = (CGFloat)redTotal / (CGFloat)totalNumberOfPixels / 255.0;
    CGFloat normalizedGreenTotal = (CGFloat)greenTotal / (CGFloat)totalNumberOfPixels / 255.0;
    CGFloat normalizedBlueTotal = (CGFloat)blueTotal / (CGFloat)totalNumberOfPixels / 255.0;
    CGFloat normalizedAlphaTotal = (CGFloat)alphaTotal / (CGFloat)totalNumberOfPixels / 255.0;
    
    if (complete) {
        complete(normalizedRedTotal, normalizedGreenTotal, normalizedBlueTotal, normalizedAlphaTotal);
    }
}

@end
