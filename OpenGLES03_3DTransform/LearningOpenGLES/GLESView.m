//
//  GLESView.m
//  OpenGLES02-Shader
//
//  Created by Melody on 2020/3/19.
//  Copyright © 2020 Melody. All rights reserved.
//
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#import "GLESView.h"
#import <OpenGLES/ES2/gl.h>
#import "GLESUtils.h"
#import "GLESMath.h"

@interface GLESView ()

/** OpenGLEST 上下文 */
@property (nonatomic, strong) EAGLContext *mContext;
/** OpenGLEST Layer */
@property (nonatomic, strong) CAEAGLLayer *mEaglLayer;
/** OpenGLEST programe */
@property (nonatomic, assign) GLuint mProgram;

/** 渲染Buffer句柄 */
@property (nonatomic, assign) GLuint mColorRenderBuffer;
/** 帧缓存Buffer句柄 */
@property (nonatomic, assign) GLuint mColorFrameBuffer;

@end

@implementation GLESView
{
    float degree;
    float yDegree;
    BOOL bX;
    BOOL bY;
    NSTimer *myTimer;
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)layoutSubviews {
    [self setupLayer];
    [self setupContext];
    [self destoryRenderAndFrameBuffer];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self render];
}

- (void)setupLayer {
    // 设置CAEAGLLayer
    _mEaglLayer = (CAEAGLLayer *)self.layer;
    // 设置放大倍数
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    // CALayer默认是透明的，必须将它设置为不透明才能可见
    self.mEaglLayer.opaque = YES;

    //设置描绘属性，在这里设置不维持渲染内容以及颜色格式为RGBA8
    self.mEaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                                          kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

- (void)setupContext {
    // 创建OpenGLES 上下文，指定2.0版本
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:api];
    if (!context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }

    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Failed to set Current OpenGLES Context");
        exit(1);
    }

    _mContext = context;
}

- (void)destoryRenderAndFrameBuffer {
    glDeleteFramebuffers(1, &_mColorFrameBuffer);
    _mColorFrameBuffer = 0;
    glDeleteFramebuffers(1, &_mColorRenderBuffer);
    _mColorRenderBuffer = 0;
}

- (void)setupRenderBuffer {
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    _mColorRenderBuffer = buffer;
    glBindRenderbuffer(GL_RENDERBUFFER, self.mColorRenderBuffer);
    // 为颜色缓冲区分配存储空间
    [self.mContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.mEaglLayer];
}

- (void)setupFrameBuffer {
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    _mColorFrameBuffer = buffer;
    // 绑定FrameBuffer
    glBindFramebuffer(GL_FRAMEBUFFER, self.mColorFrameBuffer);
    // 将colorRenderBuffer 装配到 GL_COLOR_ATTACHEMENT0 装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.mColorRenderBuffer);
}

- (void)render {
    glClearColor(231 / 255.0, 230 / 255.0, 225 / 255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale,
               self.frame.origin.y * scale,
               self.frame.size.width * scale,
               self.frame.size.height * scale);

    if (self.mProgram) {
        // FIXME:  应该不需要每次删除program 的 0 0 ?
        glDeleteProgram(self.mProgram);
        _mProgram = 0;
    }

    // 编译加载Shader
    _mProgram = [self loadShaders];

    //链接
    glLinkProgram(self.mProgram);
    GLint linkSucess;
    glGetProgramiv(self.mProgram, GL_LINK_STATUS, &linkSucess);

    if (linkSucess == GL_FALSE) {
        // 链接失败
        GLchar message[256];
        glGetProgramInfoLog(self.mProgram, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"link program error:%@", messageString);
        exit(1);
    }

    NSLog(@"link program success !");
    glUseProgram(self.mProgram); // 指定GLProgram为当前Program ，每次使用OpenGL，需要保证执行的代码在自己的program中

    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };

    GLfloat vertexs[] =
    {
        -0.5f, 0.5f,  0.0f,   0.0f, 0.0f, 0.5f,  0.0f, 1.0f,    //左上
        0.5f,  0.5f,  0.0f,   0.0f, 0.5f, 0.0f,  1.0f, 1.0f,          //右上
        -0.5f, -0.5f, 0.0f,   0.5f, 0.0f, 1.0f,  0.0f, 0.0f,          //左下
        0.5f,  -0.5f, 0.0f,   0.0f, 0.0f, 0.5f,  1.0f, 0.0f,          //右下
        0.0f,  0.0f,  1.0f,   1.0f, 1.0f, 1.0f,  0.5f, 0.5f,          //顶点
    };

    // 上传顶点数据
    GLuint vertexBufferObject;
    glGenBuffers(1, &vertexBufferObject);  // VBO
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferObject);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexs), vertexs, GL_STATIC_DRAW);

    GLuint position = glGetAttribLocation(self.mProgram, "position");
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL);
    
    glEnableVertexAttribArray(position);

    GLuint positionColor = glGetAttribLocation(self.mProgram, "positionColor");
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 3);
    glEnableVertexAttribArray(positionColor);

    GLuint textureCoordinate = glGetAttribLocation(self.mProgram, "textureCoordinate");
    glVertexAttribPointer(textureCoordinate, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 6);
    glEnableVertexAttribArray(textureCoordinate);

    [self setupTexture:@"source.jpg"];

    // Uniform
    GLuint projectionMatrixSlot = glGetUniformLocation(self.mProgram, "projectionMatrix");
    GLuint modelViewMatrixSlot = glGetUniformLocation(self.mProgram, "modelViewMatrix");

    float width = self.frame.size.width;
    float height = self.frame.size.height;

    KSMatrix4 _projectionMatrix;
    ksMatrixLoadIdentity(&_projectionMatrix);
    float aspect = width / height;    //长宽比

    ksPerspective(&_projectionMatrix, 30.0, aspect, 5.0f, 20.0f);    //透视变换，视角30°

    //设置glsl里面的投影矩阵
    glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat *)&_projectionMatrix.m[0][0]);

    glEnable(GL_CULL_FACE);

    KSMatrix4 _modelViewMatrix;
    ksMatrixLoadIdentity(&_modelViewMatrix);

    //平移
    ksTranslate(&_modelViewMatrix, 0.0, 0.0, -10.0);
    KSMatrix4 _rotationMatrix;
    ksMatrixLoadIdentity(&_rotationMatrix);

    //旋转
    ksRotate(&_rotationMatrix, degree, 1.0, 0.0, 0.0);     //绕X轴
    ksRotate(&_rotationMatrix, yDegree, 0.0, 1.0, 0.0);     //绕Y轴

    //把变换矩阵相乘，注意先后顺序
    ksMatrixMultiply(&_modelViewMatrix, &_rotationMatrix, &_modelViewMatrix);
    //    ksMatrixMultiply(&_modelViewMatrix, &_modelViewMatrix, &_rotationMatrix);

    // Load the model-view matrix
    glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, (GLfloat *)&_modelViewMatrix.m[0][0]);

    glDrawArrays(GL_TRIANGLES, 0, 6);

    [self.mContext presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - LoadrTexture

- (GLuint)setupTexture:(NSString *)fileName {
    // 1.获取图片的CGImageRef
    CGImageRef sourceImage = [UIImage imageNamed:fileName].CGImage;

    if (!sourceImage) {
        NSLog(@"Faild to load image");
        exit(1);
    }

    // 读取图片的大小
    size_t width = CGImageGetWidth(sourceImage);
    size_t height = CGImageGetHeight(sourceImage);

    GLubyte *imageData = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte)); //申请空间 RGBA一个像素4个子像素
    // 创建一个上下文(画布) 并配置大小，颜色格式等
    CGContextRef imageContext = CGBitmapContextCreate(imageData, width, height, 8, width * 4,
                                                      CGImageGetColorSpace(sourceImage), kCGImageAlphaPremultipliedLast);

    //在CGContextRef上绘图
    CGContextDrawImage(imageContext, CGRectMake(0, 0, width, height), sourceImage);

    // 绑定纹理到纹理ID上（这里只有一张图片，故而相当于默认于片元着色器里面的colorMap 0，如果有多张图不可以这么做）
//    GLuint textureID = 0;

    CGContextRelease(imageContext);

    glBindTexture(GL_TEXTURE_2D, 0);

    // 指定纹理拉伸、缩放处理
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    float floatWidth = width, floatHeight = height;
    // 上传纹理
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, floatWidth, floatHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);

    free(imageData);
    return 0;
}

#pragma mark - LoadShader

/**
*  c语言编译流程：预编译、编译、汇编、链接
*  glsl的编译过程主要有glCompileShader、glAttachShader、glLinkProgram三步；
*   vert 顶点着色器 frag 片元着色器
*
*  @return 编译成功的shaders
*/
- (GLuint)loadShaders {
    GLuint vertShader, fragShader;
    GLint program = glCreateProgram();

    NSString *shaderName = @"shader";
    // 编译
    [self compileShader:&vertShader type:GL_VERTEX_SHADER shaderName:shaderName];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER shaderName:shaderName];

    // 关联
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);

    // 释放不需要的shader句柄
    glDeleteShader(vertShader);
    glDeleteShader(fragShader);

    return program;
}

- (void)compileShader:(GLuint *)shader type:(GLenum)type shaderName:(NSString *)shaderName {
    NSError *error;
    NSString *filePath = [[NSBundle mainBundle] pathForResource:shaderName ofType:(type == GL_VERTEX_SHADER) ? @"vsh" : @"fsh"];
    NSString *shaderString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    const GLchar *source = (GLchar *)[shaderString UTF8String];

    if (error) {
        NSLog(@"compileShader Faild with path:%@ \n error: %@", filePath, error);
        exit(1);
    }
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
}

@end

#pragma clang diagnostic pop
