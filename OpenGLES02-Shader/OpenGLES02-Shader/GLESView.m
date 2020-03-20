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

@interface GLESView ()

/** <# 注释 #> */
@property (nonatomic, strong) EAGLContext *mContext;
/** <# 注释 #> */
@property (nonatomic, strong) CAEAGLLayer *mEaglLayer;
/** <# 注释 #> */
@property (nonatomic, assign) GLuint mProgram;

/** <# 注释 #> */
@property (nonatomic, assign) GLuint mColorRenderBuffer;
/** <# 注释 #> */
@property (nonatomic, assign) GLuint mColorFrameBuffer;

@end

@implementation GLESView

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
    /**
     1、为什么熊猫的反的？要如何解决？
     2、在这个样例中，顶点着色器调用次数和片元着色器调用次数哪个多？
     3、glsl里面的变量可以通过glUniform进行赋值，那么是否可以在编译成功后或者链接成功后直接进行赋值？

     1.纹理坐标在左下角
     2.片元着色器。顶点着色器调用次数与“顶点数量”有关，片元着色器调用与光栅化后“像素”多少有关系。
     作者：落影loyinglin
     链接：https://www.jianshu.com/p/ee597b2bd399
     来源：简书
     著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。
     */
    glClearColor(231 / 255.0, 230 / 255.0, 225 / 255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale,
               self.frame.origin.y * scale,
               self.frame.size.width * scale,
               self.frame.size.height * scale);

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

    //前三个是顶点坐标， 后面两个是纹理坐标
//    GLfloat vertexs[] =
//    {
//        0.5f,  -0.5f,  -1.0f,   1.0f,   0.0f,
//        -0.5f, 0.5f,   -1.0f,   0.0f,   1.0f,
//        -0.5f, -0.5f,  -1.0f,   0.0f,   0.0f,
//        0.5f,  0.5f,   -1.0f,   1.0f,   1.0f,
//        -0.5f, 0.5f,   -1.0f,   0.0f,   1.0f,
//        0.5f,  -0.5f,  -1.0f,   1.0f,   0.0f,
//    };
    
    // 为什么会翻转？ 是因为纹理的原点在左下角 与 顶点坐标有区别。 但是在GPUIMAge中，有处理
    GLfloat vertexs[] =
      {
          0.5f,  -0.5f,  -1.0f,   1.0f,  1.0 - 0.0f,
          -0.5f, 0.5f,   -1.0f,   0.0f,  1.0 - 1.0f,
          -0.5f, -0.5f,  -1.0f,   0.0f,  1.0 - 0.0f,
          0.5f,  0.5f,   -1.0f,   1.0f,  1.0 - 1.0f,
          -0.5f, 0.5f,   -1.0f,   0.0f,  1.0 - 1.0f,
          0.5f,  -0.5f,  -1.0f,   1.0f,  1.0 - 0.0f,
      };

    // 上传顶点数据
    GLuint vertexBuffer; // VBO
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexs), vertexs, GL_STATIC_DRAW);

    GLuint position = glGetAttribLocation(self.mProgram, "position");
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL);
    glEnableVertexAttribArray(position);

    GLuint textureCoordinate = glGetAttribLocation(self.mProgram, "textureCoordinate");
    glVertexAttribPointer(textureCoordinate, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
    glEnableVertexAttribArray(textureCoordinate);

    [self setupTexture:@"source.jpg"];

    //获取shader里面的变量，这里记得要在glLinkProgram后面，后面，后面！
    GLuint rotate = glGetUniformLocation(self.mProgram, "rotateMatrix");

    float radians = 10 * 3.14159f / 180.0f;
    float s = sin(radians);
    float c = cos(radians);

    //z轴旋转矩阵
    GLfloat zRotation[16] = {    //
        c,   -s,   0, 0.2, //
        s,   c,    0, 0,//
        0,   0,    1.0, 0,//
        0.0, 0,    0, 1.0 //
    };

    //设置旋转矩阵
    glUniformMatrix4fv(rotate, 1, GL_FALSE, (GLfloat *)&zRotation[0]);

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
