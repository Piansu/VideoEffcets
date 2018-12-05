//
//  GLRenderView.m
//  OpenGLDemo
//
//  Created by suruochang on 2018/9/21.
//  Copyright © 2018年 suruochang. All rights reserved.
//

#import "GLRenderView.h"
#import <OpenGLES/ES2/gl.h>
#import <GLKit/GLKit.h>

static NSDate *snap = NULL;

@interface GLRenderView ()

@property (nonatomic, strong) EAGLContext *myContext;
@property (nonatomic, strong) CAEAGLLayer *myEagLayer;
@property (nonatomic, assign) GLuint       programId;

@property (nonatomic, assign) GLuint myColorRenderBuffer;
@property (nonatomic, assign) GLuint myColorFrameBuffer;

@property (nonatomic, assign) GLuint textureId0;
@property (nonatomic, assign) GLuint textureId1;

@property (nonatomic, assign) BOOL initial;


@property (nonatomic, assign) float *vertexPointer;
@property (nonatomic, assign) float *coordinatePointer;
@property (nonatomic, assign) GLuint positionId;
@property (nonatomic, assign) GLuint coordinateId;
@property (nonatomic, assign) int vertexNumber;

@end

@implementation GLRenderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
        [btn setTitle:@"再来一次" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(resetTime) forControlEvents:UIControlEventTouchUpInside];
        btn.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height - 40 - 50);
        [self addSubview:btn];
    }
    
    return self;
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)setupGL
{
    if (self.initial == NO) {
        
        [self setupLayer];
        [self setupContext];
        
        [self setupGLProgram];
        [self setupRenderBuffer];
        [self setupFrameBuffer];
        
        [self setupTexture];
        
        [self setupVertex];
        
        self.initial = YES;
        
        
        CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(render)];
        [link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
}



- (void)setupLayer
{
    self.myEagLayer = (CAEAGLLayer*) self.layer;
    //设置放大倍数
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    
    // CALayer 默认是透明的，必须将它设为不透明才能让其可见
    self.myEagLayer.opaque = YES;
    
    // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}


- (void)setupContext {
    // 指定 OpenGL 渲染 API 的版本，在这里我们使用 OpenGL ES 2.0
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    EAGLContext* context = [[EAGLContext alloc] initWithAPI:api];
    if (!context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    // 设置为当前上下文
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
    self.myContext = context;
}


- (void)setupGLProgram
{
    //读取文件路径
    NSString* vertFile = [[NSBundle mainBundle] pathForResource:@"shader" ofType:@"vsh"];
    NSString* fragFile = [[NSBundle mainBundle] pathForResource:@"shader" ofType:@"fsh"];
    
    //加载shader
    self.programId = [self loadShaders:vertFile frag:fragFile];
    
    //链接
    glLinkProgram(self.programId);
    GLint linkSuccess;
    glGetProgramiv(self.programId, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) { //连接错误
        GLchar messages[256];
        glGetProgramInfoLog(self.programId, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"error%@", messageString);
        return ;
    }
    else {
        NSLog(@"link ok");
        glUseProgram(self.programId); //成功便使用，避免由于未使用导致的的bug
    }
}

- (void)setupRenderBuffer {
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    self.myColorRenderBuffer = buffer;
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    // 为 颜色缓冲区 分配存储空间
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}

- (void)setupFrameBuffer {
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    self.myColorFrameBuffer = buffer;
    // 设置为当前 framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, self.myColorRenderBuffer);
}

- (GLuint)loadTextureToGPU:(NSString *)fileName {
    
    // 1获取图片的CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
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
    CGContextScaleCTM (spriteContext, 1.0,-1.0);
    // 3在CGContextRef上绘图
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    // 4绑定纹理到默认的纹理ID（这里只有一张图片，故而相当于默认于片元着色器里面的colorMap，如果有多张图不可以这么做）
    GLuint textureId;
    glActiveTexture(GL_TEXTURE1);
    glGenTextures(1, &textureId);
    glBindTexture(GL_TEXTURE_2D, textureId);
    
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
    
    return textureId;
}

- (void)setupTexture
{
    self.textureId0 = [self loadTextureToGPU:@"test.jpg"];
    self.textureId1 = [self loadTextureToGPU:@"mandrill.png"];
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureId0);
    glUniform1i(glGetUniformLocation(_programId, "colorMap"), 0);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, self.textureId1);
    glUniform1i(glGetUniformLocation(_programId, "replaceMap"), 1);
}

- (void)setupVertex
{
    float vertexMin = -1.0, vertexMax = 1.0;
    int count = 10;
    float lenght = vertexMax - vertexMin;
    float piece = lenght / count;
    
    float uvMin = 0, uvMax = 1;
    float uvLenght = uvMax - uvMin;
    float uvPiece = uvLenght / count;
    
    int numberOfTrangle = count * count * 2;
    
    /*
     *一个顶点包含了2个坐标+2个显示位置信息
     *一个三角形3个顶点
     */
    float *buffer = calloc(numberOfTrangle * 4 * 3, sizeof(float));
    float *uvBuffer = calloc(numberOfTrangle * 3 * 2, sizeof(float));
    
    for (int i=0; i < count; i++) {
        
        for (int j=0; j < count; j++) {
            
            //布局一个矩形的数据
            int index = i * count + j;
            
            float X = vertexMin + j * piece;
            float Y = vertexMin + i * piece;
            
            GLKVector2 downLeft = GLKVector2Make(X, Y);
            GLKVector2 downRight = GLKVector2Make(X + piece, Y);
            GLKVector2 upLeft = GLKVector2Make(X, Y + piece);
            GLKVector2 upRight = GLKVector2Make(X + piece, Y + piece);
            
            float uvX = uvMin + j * uvPiece;
            float uvY = uvMin + i * uvPiece;
            
            GLKVector2 downLeft_uv = GLKVector2Make(uvX, uvY);
            GLKVector2 downRight_uv = GLKVector2Make(uvX + uvPiece, uvY);
            GLKVector2 upLeft_uv = GLKVector2Make(uvX, uvY + uvPiece);
            GLKVector2 upRight_uv = GLKVector2Make(uvX + uvPiece, uvY + uvPiece);
            
            buffer[index * 24 + 0] = upLeft.x;
            buffer[index * 24 + 1] = upLeft.y;
            buffer[index * 24 + 2] = i;
            buffer[index * 24 + 3] = j;
            
            buffer[index * 24 + 4] = downLeft.x;
            buffer[index * 24 + 5] = downLeft.y;
            buffer[index * 24 + 6] = i;
            buffer[index * 24 + 7] = j;
            
            buffer[index * 24 + 8] = upRight.x;
            buffer[index * 24 + 9] = upRight.y;
            buffer[index * 24 + 10] = i;
            buffer[index * 24 + 11] = j;
            
            buffer[index * 24 + 12] = downRight.x;
            buffer[index * 24 + 13] = downRight.y;
            buffer[index * 24 + 14] = i;
            buffer[index * 24 + 15] = j;
            
            buffer[index * 24 + 16] = upRight.x;
            buffer[index * 24 + 17] = upRight.y;
            buffer[index * 24 + 18] = i;
            buffer[index * 24 + 19] = j;
            
            buffer[index * 24 + 20] = downLeft.x;
            buffer[index * 24 + 21] = downLeft.y;
            buffer[index * 24 + 22] = i;
            buffer[index * 24 + 23] = j;
            
            uvBuffer[index * 12 + 0] = upLeft_uv.x;
            uvBuffer[index * 12 + 1] = upLeft_uv.y;
            uvBuffer[index * 12 + 2] = downLeft_uv.x;
            uvBuffer[index * 12 + 3] = downLeft_uv.y;
            uvBuffer[index * 12 + 4] = upRight_uv.x;
            uvBuffer[index * 12 + 5] = upRight_uv.y;
            uvBuffer[index * 12 + 6] = downRight_uv.x;
            uvBuffer[index * 12 + 7] = downRight_uv.y;
            uvBuffer[index * 12 + 8] = upRight_uv.x;
            uvBuffer[index * 12 + 9] = upRight_uv.y;
            uvBuffer[index * 12 + 10] = downLeft_uv.x;
            uvBuffer[index * 12 + 11] = downLeft_uv.y;
        }
    }
    
    GLuint vertexId, uvId;
    glGenBuffers(1, &vertexId);
    glBindBuffer(GL_ARRAY_BUFFER, vertexId);
    glBufferData(GL_ARRAY_BUFFER, (numberOfTrangle * 4 * 3 * sizeof(float)), buffer, GL_STATIC_DRAW);
    
    glGenBuffers(1, &uvId);
    glBindBuffer(GL_ARRAY_BUFFER, uvId);
    glBufferData(GL_ARRAY_BUFFER, (numberOfTrangle * 3 * 2 *sizeof(float)), uvBuffer, GL_STATIC_DRAW);
    
    self.positionId = vertexId;
    self.coordinateId = uvId;
    self.vertexNumber = numberOfTrangle * 3;
    self.vertexPointer = buffer;
    self.coordinatePointer = uvBuffer;
    
}

- (void)render {
    
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    CGFloat scale = [[UIScreen mainScreen] scale]; //获取视图放大倍数，可以把scale设置为1试试
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale); //设置视口大小
    
    glUseProgram(self.programId);
    
    //顶点
    GLuint position = glGetAttribLocation(self.programId, "position");
    glEnableVertexAttribArray(position);
    glBindBuffer(GL_ARRAY_BUFFER, self.positionId);
    glVertexAttribPointer(position, 4, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 4, NULL);
    
    //纹理坐标
    GLuint textCoor = glGetAttribLocation(self.programId, "coordinate");
    glEnableVertexAttribArray(textCoor);
    glBindBuffer(GL_ARRAY_BUFFER, self.coordinateId);
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 2, (float *)NULL);
    
//    CGFloat aspect = self.frame.size.width / self.frame.size.height;
//    GLKMatrix4 m = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -1.0f);
//    GLKMatrix4 v = GLKMatrix4MakeLookAt(0, -1.0, 1.0, 0, 0, -1, 0, 1, 0);
//    GLKMatrix4 p = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90), aspect, 0.1, 10);
//    GLKMatrix4 mvp = GLKMatrix4Multiply(p, GLKMatrix4Multiply(v, m));
    GLKMatrix4 mvp = GLKMatrix4Identity;
    GLuint mvpLocation = glGetUniformLocation(self.programId, "rotateMatrix");
    glUniformMatrix4fv(mvpLocation, 1, GL_FALSE, (GLfloat *)&mvp);
    
    NSTimeInterval inter = 0;
    if (snap == nil) {
        snap = [NSDate date];
    } else {
        inter = [[NSDate date] timeIntervalSince1970] - [snap timeIntervalSince1970];
    }
    
    glUniform1f(glGetUniformLocation(self.programId, "time"), inter);
    
    glDrawArrays(GL_TRIANGLES, 0, self.vertexNumber);
    
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    
    glDisableVertexAttribArray(position);
    glDisableVertexAttribArray(textCoor);
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    [self setupGL];
    [self render];
}

- (void)destoryRenderAndFrameBuffer
{
    glDeleteFramebuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
    glDeleteRenderbuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
}

- (void)resetTime
{
    snap = [NSDate date];
}

- (void)dealloc
{
    [self destoryRenderAndFrameBuffer];
    
    if (_programId) {
        glDeleteProgram(_programId);
    }
    
    if (_positionId) {
        glDeleteBuffers(1, &_positionId);
    }
    
    if (_coordinateId) {
        glDeleteBuffers(1, &_coordinateId);
    }
    
    if (_textureId0) {
        glDeleteTextures(1, &_textureId0);
    }
    
    if (_vertexPointer) {
        free(_vertexPointer);
    }
    
    if (_coordinatePointer) {
        free(_coordinatePointer);
    }
}

#pragma mark Compile
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
    
    GLint status;
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    
    if (status != GL_TRUE)
    {
        GLint logLength;
        glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0)
        {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(*shader, logLength, &logLength, log);
            if (type == GL_VERTEX_SHADER) {
                NSLog(@"VERTEX SHADER compile error :%s", log);
            } else if (type == GL_FRAGMENT_SHADER) {
                NSLog(@"FRAGMENT SHADER compile error :%s", log);
            }
            
            free(log);
        }
    }
}


@end
