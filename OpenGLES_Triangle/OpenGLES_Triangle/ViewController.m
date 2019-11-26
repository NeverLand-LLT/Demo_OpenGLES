//
//  ViewController.m
//  OpenGLES_Triangle
//
//  Created by Melody on 2019/11/25.
//  Copyright © 2019 Melody. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<GLKViewDelegate>
{
    EAGLContext *context;
    GLKBaseEffect *mEffect;
}
@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    /// 1.设置OpenGLES 配置
    [self setupConfig];

    ///2. 加载顶点数据
    [self uploadVertexArray];

    /// 3. 加载纹理
    [self uploadTexture];
}

- (void)uploadTexture {
    // 加载纹理数据
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"001.JPG" ofType:nil];
    // GLKTextureLoaderOriginBottomLeft，纹理坐标是相反的
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1), GLKTextureLoaderOriginBottomLeft, nil];

    // 加载
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:NULL];

    // 着色器
    mEffect = [[GLKBaseEffect alloc] init];
    //第一个纹理属性
    mEffect.texture2d0.enabled = GL_TRUE;
    // 纹理的名字
    mEffect.texture2d0.name = textureInfo.name;
}

- (void)uploadVertexArray {
    GLfloat vertexData[] = {
        0.5,  -0.5,  0.0f,   1.0f, 0.0f, //右下
        0.5,  0.5,   -0.0f,  1.0f, 1.0f, //右上
        -0.5, 0.5,   0.0f,   0.0f, 1.0f, //左上

        0.5,  -0.5,  0.0f,   1.0f, 0.0f, //右下
        -0.5, 0.5,   0.0f,   0.0f, 1.0f, //左上
        -0.5, -0.5,  0.0f,   0.0f, 0.0f, //左下
    };

    /// 上传顶点坐标
    // 申请一个缓存区的标识符
    GLuint vertextBuffer;
    glGenBuffers(1, &vertextBuffer);
    // 把标识符绑定到GL_ARRAY_BUFFER上
    glBindBuffer(GL_ARRAY_BUFFER, vertextBuffer);
    // 把顶点数据从cpu内存复制到gpu内存
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);

    // 开启读取顶点坐标功能
    glEnableVertexAttribArray(GLKVertexAttribPosition);

    // 指定读取顶点坐标方式
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) *  5, (GLfloat *)NULL + 0);

    // 开启纹读取纹理坐标功能
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);

    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
}

- (void)setupConfig {
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!context) {
        NSLog(@"Failed to create ES context");
    }

    GLKView *view = (GLKView *)self.view;
    view.context = context;

    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;

    [EAGLContext setCurrentContext:context];
    glEnable(GL_DEPTH_TEST);
    glClearColor(0.1, 0.2, 0.3, 1.0);
}

#pragma MARK: - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(0.3f, 0.6f,1.0f,1.0f);
    
    glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    
    // 启动着色器
    [mEffect prepareToDraw];
    
    glDrawArrays(GL_TRIANGLES, 0, 6);
}

@end
