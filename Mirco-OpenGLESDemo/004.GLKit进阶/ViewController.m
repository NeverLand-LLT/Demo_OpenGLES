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

@interface ViewController ()<GLKViewDelegate>
@property (nonatomic, strong) EAGLContext *mContext;
@property (nonatomic, strong) GLKBaseEffect *mEffect;

@property (nonatomic, assign) int mCount;
@property (nonatomic, assign) float mDegreeX;
@property (nonatomic, assign) float mDegreeY;
@property (nonatomic, assign) float mDegreeZ;

@property (nonatomic, assign) BOOL mBoolX;
@property (nonatomic, assign) BOOL mBoolY;
@property (nonatomic, assign) BOOL mBoolZ;

@end

@implementation ViewController
{
    dispatch_source_t timer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    // 通过GLKit 简单实现OpenGLES 绘制

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
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;

    [EAGLContext setCurrentContext:self.mContext];
    glEnable(GL_DEPTH_TEST); ///!!!

//    self.view.backgroundColor = [UIColor orangeColor];
}

- (void)uploadVertexArray {
    //顶点数据，前三个是顶点坐标， 中间三个是顶点颜色，    最后两个是纹理坐标
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f,   0.0f,   0.0f,  0.0f, 0.5f,       0.0f, 1.0f, //左上
        0.5f,  0.5f,   0.0f,   0.0f,  0.5f, 0.0f,       1.0f, 1.0f, //右上
        -0.5f, -0.5f,  0.0f,   0.5f,  0.0f, 1.0f,       0.0f, 0.0f, //左下
        0.5f,  -0.5f,  0.0f,   0.0f,  0.0f, 0.5f,       1.0f, 0.0f, //右下
        0.0f,  0.0f,   1.0f,   1.0f,  1.0f, 1.0f,       0.5f, 0.5f, //顶点
    };
    //顶点索引
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };

    self.mCount = sizeof(indices) / sizeof(GLuint);

    // 创建一个VBO句柄
    GLuint vertexBufferObject;
    glGenBuffers(1, &vertexBufferObject);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferObject);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_STATIC_DRAW);

    // 创建EBO indices
    GLuint index;
    glGenBuffers(1, &index);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 0);

    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, 4 * 8, (GLfloat *)NULL + 3);

    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 4 * 8, (GLfloat *)NULL + 6);
}

- (void)uploadTexture {
    /// 加载纹理
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"source.JPG" ofType:nil];
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

    //初始的投影
    CGSize size = self.view.bounds.size;
    float aspect = fabs(size.width / size.height);
    // 透视投影变换
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0), aspect, 0.1f, 10.f);
    projectionMatrix = GLKMatrix4Scale(projectionMatrix, 1.0f, 1.0f, 1.0f);
    self.mEffect.transform.projectionMatrix = projectionMatrix;
    // 平移变换
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -2.0f);
    self.mEffect.transform.modelviewMatrix = modelViewMatrix;

    //定时器
    double delayInSeconds = 0.1;
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC, 0.0);
    dispatch_source_set_event_handler(timer, ^{
        self.mDegreeX += 0.1  * self.mBoolX;
        self.mDegreeY += 0.1 * self.mBoolY;
        self.mDegreeZ += 0.1 * self.mBoolZ;
    });
    dispatch_resume(timer);
}

#pragma mark - Event Methods

- (IBAction)changeXValue:(id)sender {
    self.mBoolX = !self.mBoolX;
}

- (IBAction)changeYValue:(id)sender {
    self.mBoolY = !self.mBoolY;
}

- (IBAction)changeZValue:(id)sender {
    self.mBoolZ = !self.mBoolZ;
}

#pragma mark - GLKViewController

/**
 *  场景数据变化
 */
- (void)update {
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -2.0f);

    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, self.mDegreeX);
    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, self.mDegreeY);
    modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, self.mDegreeZ);

    self.mEffect.transform.modelviewMatrix = modelViewMatrix;
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    /// 清理FBO内容 FBO在这里没有体现到，因为GLKit内部创建好了，FBO可以想象为一个画布
    // 指定清理画布填充颜色
    glClearColor(1.0f, 1.0f, 0.886f, 1.0f);
    // 执行清理
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // 启动着色器
    [self.mEffect prepareToDraw];

    // 绘制 指定TRIANGLES 图元
    glDrawElements(GL_TRIANGLES, self.mCount, GL_UNSIGNED_INT, 0);
}

#pragma clang diagnostic pop

@end
