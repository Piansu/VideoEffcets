//
//  GLRenderView.m
//  YUVPlayer
//
//  Created by suruochang on 2019/1/9.
//  Copyright © 2019年 Su Ruochang. All rights reserved.
//

#import "GLRenderView.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

//NSString *const kGPUImageVertexShaderString = SHADER_STRING
//(
// attribute vec4 position;
// attribute vec4 inputTextureCoordinate;
//
// varying vec2 textureCoordinate;
//
// void main()
// {
//     gl_Position = position;
//     textureCoordinate = inputTextureCoordinate.xy;
// }
// );
//
//NSString *const kGPUImagePassthroughFragmentShaderString = SHADER_STRING
//(
// varying vec2 textureCoordinate;
//
// uniform sampler2D inputImageTexture;
//
// void main()
// {
//     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
// }
// );


@interface GLRenderView ()
{
    NSOpenGLContext *_context;
    
    GLuint _textures[3];
}

@property (nonatomic, assign) GLuint       programId;

@property (nonatomic, assign) GLuint myColorRenderBuffer;
@property (nonatomic, assign) GLuint myColorFrameBuffer;
@property (nonatomic, assign) GLuint bufferAttr;

@end

@implementation GLRenderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self commonInit];
    }
    
    return self;
}

- (NSOpenGLContext *)createContext
{
    NSOpenGLPixelFormatAttribute pixelFormatAttributes[] = {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAAccelerated, 0,
        0
    };
    
    NSOpenGLPixelFormat *_pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:pixelFormatAttributes];
    if (_pixelFormat == nil)
    {
        NSLog(@"Error: No appropriate pixel format found");
    }
    // TODO: Take into account the sharegroup
    NSOpenGLContext *context = [[NSOpenGLContext alloc] initWithFormat:_pixelFormat shareContext:nil];
    
    NSAssert(context != nil, @"Unable to create an OpenGL context. The GPUImage framework requires OpenGL support to work.");
    
    _context = context;
    self.pixelFormat = _pixelFormat;
    self.openGLContext = context;
    self.wantsBestResolutionOpenGLSurface = YES;
    
    [context makeCurrentContext];
    
    return context;
}

- (void)commonInit;
{
    [self createContext];
    
    [self setupGLProgram];
    
    [self setupVertex];
}


- (void)setupVertex
{
    //前三个是顶点坐标， 后面两个是纹理坐标
    GLfloat attrArr[] =
    {
        1.0f, -1.0f, -1.0f,     1.0f, 0.0f,
        -1.0f, 1.0f, -1.0f,     0.0f, 1.0f,
        -1.0f, -1.0f, -1.0f,    0.0f, 0.0f,
        1.0f, 1.0f, -1.0f,      1.0f, 1.0f,
        -1.0f, 1.0f, -1.0f,     0.0f, 1.0f,
        1.0f, -1.0f, -1.0f,     1.0f, 0.0f,
    };
    
    GLuint attrBuffer;
    glGenBuffers(1, &attrBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    self.bufferAttr = attrBuffer;
}


- (void)draw {
    
    [_context makeCurrentContext];
    
    glUseProgram(self.programId);
    
    [self setDisplayFramebuffer];
    
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    CGFloat scale = [NSScreen mainScreen].backingScaleFactor; //获取视图放大倍数，可以把scale设置为1试试
    glViewport(self.frame.origin.x * scale,
               self.frame.origin.y * scale,
               self.frame.size.width * scale,
               self.frame.size.height * scale); //设置视口大小
    
    GLuint position = glGetAttribLocation(self.programId, "position");
    glEnableVertexAttribArray(position);
    glBindBuffer(GL_ARRAY_BUFFER, self.bufferAttr);
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    
    GLuint textCoor = glGetAttribLocation(self.programId, "coordinate");
    glEnableVertexAttribArray(textCoor);
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
    
    GLuint rotate = glGetUniformLocation(self.programId, "rotateMatrix");
    
    GLfloat zRotation[16] = {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    };
    //设置旋转矩阵
    glUniformMatrix4fv(rotate, 1, GL_FALSE, (GLfloat *)&zRotation[0]);
    
    GLchar *name[3] = {"planarY", "planarU", "planarV"};

    for (int i = 0; i < 3; i++) {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, _textures[i]);
        glUniform1i(glGetUniformLocation(self.programId, name[i]), i);
    }
    
    glDrawArrays(GL_TRIANGLES, 0, 6);

    [self presentFramebuffer];
}

- (void)setDisplayFramebuffer;
{
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    
    glViewport(0, 0, (GLint)self.frame.size.width, (GLint)self.frame.size.height);
}

- (void)presentFramebuffer;
{
    [self.openGLContext flushBuffer];
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

- (GLuint)setupTextureWithData:(u_char *)data
                   width:(int)width
                  height:(int)height
{
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    GLuint tmpTexture;
    glGenTextures(1, &tmpTexture);
    glBindTexture(GL_TEXTURE_2D, tmpTexture);
    
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_LUMINANCE,
                 (GLint)width,
                 (GLint)height,
                 0,
                 GL_LUMINANCE,
                 GL_UNSIGNED_BYTE,
                 data);
    
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    return tmpTexture;
}

- (void)uploadYUVData:(u_char *)buffer
                width:(int)width
               height:(int)height
{
    if (_textures[0] == 0)
        glGenTextures(3, _textures);
    
    UInt8 *pixels[3] = { buffer,
                         buffer + (width * height),
                         buffer + (width * height * 5 / 4) };
    int widths[3] = { width, width / 2, width / 2 };
    int heights[3] = { height, height / 2, height / 2 };
    
    for (int i=0; i<3; i++) {
        
        glBindTexture(GL_TEXTURE_2D, _textures[i]);
        
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_LUMINANCE,
                     widths[i],
                     heights[i],
                     0,
                     GL_LUMINANCE,
                     GL_UNSIGNED_BYTE,
                     pixels[i]);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    [self draw];
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
}

@end
