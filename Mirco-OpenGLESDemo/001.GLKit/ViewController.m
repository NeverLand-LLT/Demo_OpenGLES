//
//  ViewController.m
//  OpenGLES_Triangle
//
//  Created by Melody on 2019/11/25.
//  Copyright © 2019 Melody. All rights reserved.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// 通过GLKit 简单实现OpenGLES 绘制
@interface ViewController ()<GLKViewDelegate>
@property (nonatomic, strong) EAGLContext *mContext;
@property (nonatomic, strong) GLKBaseEffect *mEffect;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    // 1.设置OpenGLES 配置
    [self setupConfig];
    //2. 加载顶点数据
    [self uploadVertexArray];
    // 3. 加载纹理
    [self uploadTexture];
    //  4.渲染 - (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {

    /*
     思考题
     1、代码中有6个顶点坐标，能否使用更少的顶点显示一个图像？
     2、顶点缓存数组可以不用glBufferData，要如何实现？
     3、如果把这个图变成左右两只对称的熊猫，该如何改？
     1.
     GLfloat vertexData[] = {
          -0.5, -0.5,  0.0f,    0.0f, 0.0f, //左下
          0.5,  -0.5,  0.0f,    1.0f, 0.0f, //右下
          -0.5, 0.5,   0.0f,    0.0f, 1.0f, //左上
          0.5,  0.5,   -0.0f,   1.0f, 1.0f, //右上
      };
     glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

     //===============
     glElement

     - (void)uploadVertexArray {
     //顶点数据，前三个是顶点坐标，后面两个是纹理坐标
     GLfloat squareVertexData[] =
     {
     0.5, -0.5, 0.0f, 1.0f, 0.0f, //右下
     0.5, 0.5, -0.0f, 1.0f, 1.0f, //右上
     -0.5, 0.5, 0.0f, 0.0f, 1.0f, //左上
     -0.5, -0.5, 0.0f, 0.0f, 0.0f, //左下
     };
     GLbyte indices[] =
     {
     0,1,2,
     2,3,0
     };


     //顶点数据缓存
     GLuint buffer;
     glGenBuffers(1, &buffer);
     glBindBuffer(GL_ARRAY_BUFFER, buffer);
     glBufferData(GL_ARRAY_BUFFER, sizeof(squareVertexData), squareVertexData, GL_STATIC_DRAW);

     GLuint texturebuffer;
     glGenBuffers(1, &texturebuffer);
     glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, texturebuffer);
     glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

     glEnableVertexAttribArray(GLKVertexAttribPosition); //顶点数据缓存
     glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);

     glEnableVertexAttribArray(GLKVertexAttribTexCoord0); //纹理
     glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
     }

     - (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
     glClearColor(0.3f, 0.6f, 1.0f, 1.0f);
     glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

     //启动着色器
     [self.mEffect prepareToDraw];
     glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, 0);
     }

     2.
     ===========
     static const GLfloat imageVertices[] = {
          -1.0f, -1.0f,
          1.0f,  -1.0f,
          -1.0f, 1.0f,
          1.0f,  1.0f,
      };

      static const GLfloat noRotationTextureCoordinates[] = {
          0.0f, 0.0f,
          1.0f, 0.0f,
          0.0f, 1.0f,
          1.0f, 1.0f,
      };

      glEnableVertexAttribArray(GLKVertexAttribPosition);
      glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, imageVertices);

      glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
      glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, noRotationTextureCoordinates);

     // 绘制 指定TRIANGLES 图元
     glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
     =================

     3/

     GLfloat vertexData[] = {
           0.0,  -0.5,  0.0f,    1.0f, 0.0f,  //右下
           0.0,  0.5,   -0.0f,   1.0f, 1.0f,  //右上
           -1.0, 0.5,   0.0f,    0.0f, 1.0f, //左上
           0.0,  -0.5,  0.0f,    1.0f, 0.0f, //右下
           -1.0, 0.5,   0.0f,    0.0f, 1.0f,//左上
           -1.0, -0.5,  0.0f,    0.0f, 0.0f, //左下

           1.0,  -0.5,  0.0f,    1.0 - 1.0f, 0.0f,  //右下
           1.0,  0.5,   -0.0f,   1.0 - 1.0f, 1.0f,      //右上
           0.0,  0.5,   0.0f,    1.0 - 0.0f, 1.0f,    //左上
           1.0,  -0.5,  0.0f,    1.0 - 1.0f, 0.0f,     //右下
           0.0,  0.5,   0.0f,    1.0 - 0.0f, 1.0f,   //左上
           0.0,  -0.5,  0.0f,    1.0 - 0.0f, 0.0f,    //左下

       };

        // 绘制 指定TRIANGLES 图元
        glDrawArrays(GL_TRIANGLES, 0, 12);
     */
}

- (void)setupConfig {
    _mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_mContext) {
        NSLog(@"Failed to create ES context");
    }
    GLKView *view = (GLKView *)self.view;  // StoryBoard的View也要改变Class
    view.context = self.mContext;
    view.delegate = self; // 如果不走Delegate 需要指定？ 为啥以前不用的？
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888; // 设置颜色缓冲格式
    [EAGLContext setCurrentContext:self.mContext];

//    self.view.backgroundColor = [UIColor orangeColor];
}

- (void)uploadVertexArray {
    // 数组创建的两种方式
//    GLfloat *vertexData = alloca(sizeof(GLfloat) * count);
    GLfloat vertexData[] = {
        0.5,  -0.5,  0.0f,    1.0f, 0.0f, //右下
        0.5,  0.5,   -0.0f,   1.0f, 1.0f, //右上
        -0.5, 0.5,   0.0f,    0.0f, 1.0f, //左上

        0.5,  -0.5,  0.0f,    1.0f, 0.0f, //右下
        -0.5, 0.5,   0.0f,    0.0f, 1.0f, //左上
        -0.5, -0.5,  0.0f,    0.0f, 0.0f, //左下
    };

    /* 上传顶点数据缓存  OpenGLES render 需要 顶点数据 以及 纹理数据。
     一般情况下，顶点数据包含 顶点坐标Vertexs 以及 纹理坐标TextureCoordinates(如果需要渲染纹理的话)。
     而上传顶点数据有两种方式：
     1、通过glBufferData 在GPU中开辟一个缓存存储着。
     2.通过glVertexAttribPointer最后一个参数直接指定读取位置(GPUImage常用的是这种)。
     区别:
     glBufferData里面的顶点缓存可以复用。
     glVertexAttribPointer指定读取位置，是每次都会把顶点数组从CPU发送到GPU。影响性能
     */

    // 创建一个VBO句柄
    GLuint vertexBufferObject;
    // 申请一个缓存区的标识符
    glGenBuffers(1, &vertexBufferObject);
    //把标识符绑定到GL_ARRAY_BUFFER上
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferObject);
    //把顶点数据从cpu复制到gpu内存中
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);

    // GLKVertexAttribPosition GLKVertexAttribTexCoord0 是GLKit 提供的，从glProgram 注册好的句柄
    // 开启读取顶点坐标
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    // 指定读取顶点坐标方式(glBufferData方式)
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);

    // 开启读取纹理坐标
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    // 指定读取纹理坐标方式(glBufferData方式)
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);

    // Q: 如果使用glBufferData方式，读取顶点数据都需要从vertexData读取？ 无论是顶点坐标还是纹理坐标？ VAO呢？
}

- (void)uploadTexture {
    /// 加载纹理
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"source.jpg" ofType:nil];
    // 因为图片读取的方向是 左上角为原点，x右边、y下边为正。 而OpenGLEST的纹理读取是做左下角为原点，x右、y上边边为正。 GLKTextureInfo，加载为了修改放心，需要制定Options  BottomLeft为YES
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1), GLKTextureLoaderOriginBottomLeft, nil];
    // 加载
    NSError *error;
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:&error];
    if (error) {
        NSLog(@"Error:GLKTextureLoader 加载图片纹理失败:%@", error);
        exit(1);
    }
    // 着色器
    _mEffect = [[GLKBaseEffect alloc] init];
    // 开启TEXTURE2D0纹理缓存 openGLES 中一共大概有32个TEXTURE2D缓存，是固定的
    self.mEffect.texture2d0.enabled = GL_TRUE;
    // 绑定纹理句柄
    self.mEffect.texture2d0.name = textureInfo.name;
}

#pragma MARK: - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    /// 清理FBO内容 FBO在这里没有体现到，因为GLKit内部创建好了，FBO可以想象为一个画布
    // 指定清理画布填充颜色
    glClearColor(1.0f, 1.0f, 0.886f, 1.0f);
    // 执行清理
    glClear(GL_COLOR_BUFFER_BIT);

    // 启动着色器
    [self.mEffect prepareToDraw];

    // 绘制 指定TRIANGLES 图元
    glDrawArrays(GL_TRIANGLES, 0, 6.0);
}

#pragma clang diagnostic pop

@end
