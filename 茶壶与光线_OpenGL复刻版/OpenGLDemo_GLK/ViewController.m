//
//  ViewController.m
//  OpenGLDemo_GLK
//
//  Created by suruochang on 2018/10/9.
//  Copyright © 2018年 suruochang. All rights reserved.
//

#import "ViewController.h"
#import "ObjLoader.h"

@interface ViewController ()

@property (nonatomic, strong) EAGLContext *context;

@property (nonatomic, assign) GLuint programId;
@property (nonatomic, assign) GLuint bufferAttr;
@property (nonatomic, assign) GLuint textureId;
@property (nonatomic, assign) GLuint uvBufferAttr;
@property (nonatomic, assign) GLuint normalBufferAttr;

@property (nonatomic, strong) OBJModel *teapotObj;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setupEAGLContext];
    [self setupGLProgram];
//    [self setupTexture:@"test.jpg"];
    [self setupTeapotModel];
    
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
    glClearColor(0.95, 0.95, 0.95, 1);
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

- (GLuint)setupTexture:(NSString *)fileName {
    
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
    glActiveTexture(GL_TEXTURE1);
    glGenTextures(1, &_textureId);
    glBindTexture(GL_TEXTURE_2D, _textureId);
    
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
    
    glUniform1i(glGetUniformLocation(_programId, "colorMap"), 1);
    
    return 0;
}

- (void)setupTeapotModel
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"teapot" ofType:@"obj"];
    OBJModel *teapotObj = [[OBJModel alloc] initWithResourcePath:path];
    
    GLuint vertexbuffer;
    glGenBuffers(1, &vertexbuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
    glBufferData(GL_ARRAY_BUFFER, teapotObj.vertexData.length, teapotObj.vertexData.bytes, GL_STATIC_DRAW);
    
    GLuint uvbuffer;
    glGenBuffers(1, &uvbuffer);
    glBindBuffer(GL_ARRAY_BUFFER, uvbuffer);
    glBufferData(GL_ARRAY_BUFFER, teapotObj.uvCoordinateData.length, teapotObj.uvCoordinateData.bytes, GL_STATIC_DRAW);
    
    GLuint normalbuffer;
    glGenBuffers(1, &normalbuffer);
    glBindBuffer(GL_ARRAY_BUFFER, normalbuffer);
    glBufferData(GL_ARRAY_BUFFER, teapotObj.normalData.length, teapotObj.normalData.bytes, GL_STATIC_DRAW);
    
    self.bufferAttr = vertexbuffer;
    self.uvBufferAttr = uvbuffer;
    self.normalBufferAttr = normalbuffer;
    
    self.teapotObj = teapotObj;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)update {
    
}

#pragma mark render
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    CGFloat scale = [[UIScreen mainScreen] scale]; //获取视图放大倍数，可以把scale设置为1试试
    glViewport(self.view.frame.origin.x * scale, self.view.frame.origin.y * scale, self.view.frame.size.width * scale, self.view.frame.size.height * scale); //设置视口大小
    
    glUseProgram(self.programId);
    
    GLuint position = glGetAttribLocation(self.programId, "position");
    glEnableVertexAttribArray(position);
    glBindBuffer(GL_ARRAY_BUFFER, self.bufferAttr);
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(float) * 4, NULL);
    
    GLuint normal = glGetAttribLocation(self.programId, "normal");
    glEnableVertexAttribArray(normal);
    glBindBuffer(GL_ARRAY_BUFFER, self.normalBufferAttr);
    glVertexAttribPointer(normal, 3, GL_FLOAT, GL_FALSE, sizeof(float) * 4, NULL);
    
    GLuint modelLocation = glGetUniformLocation(self.programId, "modelMatrix");
    GLuint viewLocation = glGetUniformLocation(self.programId, "viewMatrix");
    GLuint projectionLocation = glGetUniformLocation(self.programId, "projectionMatrix");
    
    static CGFloat x = 0, y = 0;
    x = -self.timeSinceFirstResume * (M_PI / 2);
    y = -self.timeSinceFirstResume * (M_PI / 3);

    GLKMatrix4 modelMatrix = GLKMatrix4Rotate(GLKMatrix4Identity, x, 1, 0, 0);
    modelMatrix = GLKMatrix4Rotate(modelMatrix, y, 0, 1, 0);
    
    GLKMatrix4 viewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, -1.5);
    
    const float aspect = view.frame.size.width / view.frame.size.height;
    const float fov = (2 * M_PI) / 5;
    const float near = 0.1;
    const float far = 100;
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(fov, aspect, near, far);
    
    glUniformMatrix4fv(modelLocation, 1, GL_FALSE, (GLfloat *)&modelMatrix);
    glUniformMatrix4fv(viewLocation, 1, GL_FALSE, (GLfloat *)&viewMatrix);
    glUniformMatrix4fv(projectionLocation, 1, GL_FALSE, (GLfloat *)&projectionMatrix);
    
    glDrawArrays(GL_TRIANGLES, 0, self.teapotObj.size);
}

- (void)dealloc
{
    if (_programId) {
        glDeleteProgram(_programId);
    }
    
    if (_bufferAttr) {
        glDeleteBuffers(1, &_bufferAttr);
    }
    
    if (_textureId) {
        glDeleteTextures(1, &_textureId);
    }
    
    if (_uvBufferAttr) {
        glDeleteBuffers(1, &_uvBufferAttr);
    }
    
    if (_normalBufferAttr) {
        glDeleteBuffers(1, &_normalBufferAttr);
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
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
}



@end
