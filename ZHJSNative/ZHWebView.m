//
//  ZHWebView.m
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHWebView.h"
#import "ZHJSHandler.h"
#import "ZHUtil.h"
#import "ZHWebViewDelegate.h"

@interface ZHWebView ()<UIGestureRecognizerDelegate>

@property (nonatomic,copy) void (^loadFinish) (BOOL success);
@property (nonatomic, assign) BOOL loadSuccess;
@property (nonatomic, assign) BOOL loadFail;

@property (nonatomic,strong) UIGestureRecognizer *pressGes;

@property (nonatomic, strong) ZHJSHandler *handler;
@property (nonatomic,strong) ZHWebViewDelegate *zh_delegate;
@end

@implementation ZHWebView

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration{
    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
        [self configGesture];
    }
    return self;
}


- (instancetype)initWithApiHandler:(id <ZHJSApiProtocol>)apiHandler{
    ZHJSHandler *handler = [[ZHJSHandler alloc] initWithApiHandler:apiHandler];
    
    WKUserContentController *userContent = [[WKUserContentController alloc] init];
    
    //注入log
    {
        NSString *code = [handler fetchWebViewLogApi];
        if (code.length) {
            WKUserScript *script = [[WKUserScript alloc] initWithSource:code injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
            [userContent addUserScript:script];
        }
    }
    //注入error
    {
        NSString *code = [handler fetchWebViewErrorApi];
        if (code.length) {
            WKUserScript *script = [[WKUserScript alloc] initWithSource:code injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
            [userContent addUserScript:script];
        }
    }
#ifdef DEBUG
    //注入websocket js用于监听socket链接
    {
        NSString *code = [handler fetchWebViewSocketApi];
        if (code.length) {
            WKUserScript *script = [[WKUserScript alloc] initWithSource:code injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
            [userContent addUserScript:script];
        }
    }
    //禁用webview长按弹出菜单
    {
        NSString *code = [handler fetchWebViewTouchCalloutApi];
        if (code.length) {
            WKUserScript *script = [[WKUserScript alloc] initWithSource:code injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
            [userContent addUserScript:script];
        }
    }
#endif
    //注入api js
    {
        NSString *code = [handler fetchWebViewApi];
        if (code.length) {
            WKUserScript *script = [[WKUserScript alloc] initWithSource:code injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
            [userContent addUserScript:script];
        }
    }
    
    //监听js
    NSArray *handlerNames = [ZHWebView fetchHandlerNames];
    for (NSString *key in handlerNames) {
        [userContent addScriptMessageHandler:handler name:key];
    }
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    // 设置偏好设置
    config.preferences = [[WKPreferences alloc] init];
    // 默认为0
    config.preferences.minimumFontSize = 10;
    // 默认认为YES
    config.preferences.javaScriptEnabled = YES;
    //允许视频
    config.allowsInlineMediaPlayback = YES;
    config.userContentController = userContent;
    
    self = [self initWithFrame:CGRectZero configuration:config];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0];
        //    self.scrollView.bounces = NO;
        //    self.scrollView.alwaysBounceVertical = NO;
        //    self.scrollView.alwaysBounceHorizontal = NO;
        self.scrollView.showsVerticalScrollIndicator = YES;
        //设置流畅滑动【否则 滑动效果没有减速过快】
        self.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
        //禁用链接预览
        //    [webView setAllowsLinkPreview:NO];
        
        if (@available(iOS 11.0, *)) {
            self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        
        self.handler = handler;
        handler.webView = self;
        self.zh_delegate = [[ZHWebViewDelegate alloc] init];
        self.zh_delegate.webView = self;
        
        //设置代理
        self.UIDelegate = self.zh_delegate;
        self.navigationDelegate = self.zh_delegate;
        self.scrollView.delegate = self.zh_delegate;
    }
    return self;
}

#pragma mark - config gesture

- (void)configGesture{
    //此长按手势 可防止手势冲突  如:webview中的图表长按滑动手势与pageCtrl滑动手势冲突
    UILongPressGestureRecognizer *pressGes = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGes:)];
    pressGes.minimumPressDuration = 0.4f;
    pressGes.numberOfTouchesRequired = 1;
    pressGes.cancelsTouchesInView = YES;
    pressGes.delegate = self;
    self.pressGes = pressGes;
    [self addGestureRecognizer:self.pressGes];
}

- (void)longPressGes:(UILongPressGestureRecognizer *)gesture{
    switch (gesture.state){
        case UIGestureRecognizerStateBegan:{
        }
            break;
        case UIGestureRecognizerStateChanged:{
        }
            break;
        case UIGestureRecognizerStateEnded:{
//            UIScrollView *scroll = [self fetchSuperScrollView];
        }
            break;
        default:{
//            UIScrollView *scroll = [self fetchSuperScrollView];
        }
            break;
    }
}

#pragma mark - fetch

- (UIScrollView *)fetchInScrollView:(UIView *)view{
    if ([view isKindOfClass:[UIScrollView class]]) return (UIScrollView *)view;
    if (!view.superview) return nil;
    return [self fetchInScrollView:view.superview];
}

- (UIScrollView *)fetchSuperScrollView{
    UIView *view = self;
    return [self fetchInScrollView:view];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
//    NSLog(@"%@--%@",NSStringFromClass([gestureRecognizer class]), NSStringFromClass([otherGestureRecognizer class]));
    if ([otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        //只有当手势为长按手势时反馈，非长按手势将阻止。
        return YES;
    }else{
        return NO;
    }
}

#pragma mark - handler

+ (NSArray *)fetchHandlerNames{
    return @[ZHJSHandlerLogName, ZHJSHandlerName, ZHJSHandlerErrorName];
}

#pragma mark - load

- (void)loadUrl:(NSURL *)url finish:(void (^) (BOOL success))finish{
    //回调
    void (^callBack)(BOOL) = ^(BOOL success){
        if (finish) finish(success);
    };
    //webView加载完成回调
    __weak __typeof__(self) __self = self;
    void (^setWebViewFinish)(void) = ^(){
        __self.loadFinish = ^(BOOL success) {
            __self.loadSuccess = success;
            __self.loadFail = !success;
            if (success) {
                __self.loadFinish = nil;
            }
            callBack(success);
        };
    };
    
    if (!url) {
        callBack(NO);
        return;
    }

    NSString *path = url.path;
    
    //远程Url
    if (!url.isFileURL) {
        setWebViewFinish();
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self loadRequest:request];
        return;
    }
    
    //本地Url
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        callBack(NO);
        return;
    }
    if (@available(iOS 9.0, *)) {
        NSURL *fileURL = [ZHUtil fileURLWithPath:path isDirectory:NO];
        if (!fileURL) {
            callBack(NO);
            return;
        }
        setWebViewFinish();
        [self loadFileURL:fileURL allowingReadAccessToURL:[NSURL fileURLWithPath:path.stringByDeletingLastPathComponent]];
        return;
    }
    
    //iOS8及以下要拷贝目录到temp
    NSString *newPath = [ZHUtil copyToTempWithPath:path hierarchy:1];
    NSURL *fileURL = [ZHUtil fileURLWithPath:newPath isDirectory:NO];
    if (!fileURL) {
        callBack(NO);
        return;
    }
    setWebViewFinish();
    NSURLRequest *request = [NSURLRequest requestWithURL:fileURL];
    [self loadRequest:request];
}

#pragma mark - keyboard

// 键盘已经弹起（不能用willShow事件，iOS 8、9在willShow之后底层的webkit又在改偏移）
- (void)keyboardDidShow:(NSNotification *)notification {
    // 获取键盘的高度
//    CGRect frame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
//    CGRect begin = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
//    CGRect end = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
//    CGFloat duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
//    duration = duration > 0 ? duration : 0.25;
//
//
//    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
//    CGRect rect = [self.superview convertRect:self.frame toView:keyWindow];
//
//    // webview 距屏幕底部距离
//    CGFloat bottom = keyWindow.frame.size.height - (rect.origin.y + rect.size.height);
//
//    // 三方键盘会执行多次，最后一次是准的，所以这里做判断
//    if(begin.size.height>0 && (begin.origin.y - end.origin.y > 0)){
//        [self.scrollView setContentOffset:CGPointMake(0, frame.size.height - bottom)];
//    }
}

// 键盘已经消失
- (void)keyboardDidHide:(NSNotification *)notification {
//    [self.scrollView setContentOffset:CGPointMake(0, 0)];
}

- (void)dealloc{
    @try {
        WKUserContentController *userContent = self.configuration.userContentController;
        [userContent removeAllUserScripts];

        NSArray *handlerNames = [ZHWebView fetchHandlerNames];
        for (NSString *key in handlerNames) {
            [userContent removeScriptMessageHandlerForName:key];
        }
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
    NSLog(@"-------%s---------", __func__);
}

#pragma mark - js

/** evaluateJavaScript方法运行js函数的参数：
 尽量包裹一层数据【使用NSDictionary-->转成NSString-->utf-8编码】：js端再解析出来【utf-8解码-->JSON.parse()-->json】
 
 作用：原生传数据可在js正常解析出类型
 不包裹直接传参数：
     @(YES)   js解析为String类型
     @(1111)   js解析为String类型
 包裹：
     result ：@(YES)  @(NO)  js解析为Boolean类型  可直接使用
     result ：@(111)  js解析为Number类型
 */
/** 发送js消息 */
- (void)postMessageToJs:(NSString *)funcName params:(NSDictionary *)params completionHandler:(void (^)(id res, NSError *error))completionHandler{
    NSString *paramsStr = [ZHUtil encodeObj:params];
    NSString *js;
    if (paramsStr.length) {
        js = [NSString stringWithFormat:@"(%@)(\"%@\")", funcName, paramsStr];
    }else{
        js = [NSString stringWithFormat:@"(%@)()", funcName];
    }
    __weak __typeof__(self) __self = self;
    [self evaluateJavaScript:js completionHandler:^(id _Nullable res, NSError * _Nullable error) {
        if (error) {
            NSLog(@"----❌js:function:%@--error:%@--", funcName, error);
            [__self.handler showWebViewException:error.userInfo];
        }else{
            NSLog(@"----✅js:function:%@--返回值:%@--", funcName, res?:@"void");
        }
        if (completionHandler) {
            completionHandler(res, error);
        }
    }];
}

#pragma mark - socket debug
#ifdef DEBUG
- (void)socketDidOpen:(NSDictionary *)params{
    
}
- (void)socketDidReceiveMessage:(NSDictionary *)params{
    NSLog(@"---------js_socketDidReceiveMessage-----------");
    NSLog(@"%@",params);
    if (![params isKindOfClass:[NSDictionary class]]) return;
    NSString *type = [params valueForKey:@"type"];
    if (![type isKindOfClass:[NSString class]]) return;
    if ([type isEqualToString:@"invalid"]) {
        if ([self.socketDebugDelegate respondsToSelector:@selector(webViewReadyRefresh:)]) {
            [self.socketDebugDelegate webViewReadyRefresh:self];
        }
        return;
    }
    if ([type isEqualToString:@"hash"]) {
        if ([self.socketDebugDelegate respondsToSelector:@selector(webViewRefresh:)]) {
            [self.socketDebugDelegate webViewRefresh:self];
        }
        return;
    }
}
- (void)socketDidError:(NSDictionary *)params{
    
}
- (void)socketDidClose:(NSDictionary *)params{
    
}
#endif

@end
