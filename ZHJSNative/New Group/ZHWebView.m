//
//  ZHWebView.m
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHWebView.h"
#import "ZHJSHandler.h"
#import "ZHFloatView.h"

//创建 error
__attribute__((unused)) static BOOL ZHCheckDelegate(id delegate, SEL sel) {
    if (!delegate || !sel) return NO;
    return [delegate respondsToSelector:sel];
}

@interface ZHWebView ()<WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic,copy) void (^loadFinish) (BOOL success);
@property (nonatomic, assign) BOOL loadSuccess;
@property (nonatomic, assign) BOOL loadFail;

@property (nonatomic, assign) BOOL didTerminate;//WebContentProcess进程被终结
@property (nonatomic,strong) UIGestureRecognizer *pressGes;
@property (nonatomic, strong) ZHJSHandler *handler;
//外部handler
//@property (nonatomic,strong) NSMutableArray <id <ZHJSApiProtocol>> *apiHandlers;

#ifdef DEBUG
@property (nonatomic,strong) ZHFloatView *floatView;
#endif

@property (nonatomic, strong) NSLock *lock;

@end

@implementation ZHWebView

- (instancetype)initWithApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers{
    return [self initWithFrame:CGRectZero apiHandlers:apiHandlers];
}
- (instancetype)initWithFrame:(CGRect)frame apiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers{
    
    ZHJSHandler *handler = [[ZHJSHandler alloc] initWithApiHandlers:apiHandlers];
    
    WKUserContentController *userContent = [[WKUserContentController alloc] init];
    
    //注入api
    NSMutableArray *apis = [NSMutableArray array];
#ifdef DEBUG
    //log
    [apis addObject:@{
        @"code": [handler fetchWebViewLogApi]?:@"",
        @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentStart),
        @"mainFrameOnly": @(YES)
    }];
    //error
    [apis addObject:@{
        @"code": [handler fetchWebViewErrorApi]?:@"",
        @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentStart),
        @"mainFrameOnly": @(YES)
    }];
    //websocket js用于监听socket链接
    [apis addObject:@{
        @"code": [handler fetchWebViewSocketApi]?:@"",
        @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentStart),
        @"mainFrameOnly": @(YES)
    }];
    //禁用webview长按弹出菜单
    [apis addObject:@{
        @"code": [handler fetchWebViewTouchCalloutApi]?:@"",
        @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentEnd),
        @"mainFrameOnly": @(YES)
    }];
#endif
    //api support js
    [apis addObject:@{
        @"code": [handler fetchWebViewSupportApi]?:@"",
        @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentStart),
        @"mainFrameOnly": @(YES)
    }];
    //api js
    [apis addObject:@{
        @"code": [handler fetchWebViewApi]?:@"",
        @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentStart),
        @"mainFrameOnly": @(YES)
    }];
    //api 注入完成
    [apis addObject:@{
        @"code": [handler fetchWebViewApiFinish]?:@"",
        @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentEnd),
        @"mainFrameOnly": @(YES)
    }];
    for (NSDictionary *map in apis) {
        NSString *code = [map valueForKey:@"code"];
        if (code.length == 0) continue;
        NSNumber *jectionTime = [map valueForKey:@"jectionTime"];
        NSNumber *mainFrameOnly = [map valueForKey:@"mainFrameOnly"];
        WKUserScript *script = [[WKUserScript alloc] initWithSource:code injectionTime:jectionTime.integerValue forMainFrameOnly:mainFrameOnly.boolValue];
        [userContent addUserScript:script];
    }
    
    //监听js
    NSArray *handlerNames = [self.class fetchHandlerNames];
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
    
    self = [self initWithFrame:frame configuration:config];
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
        
        if ([self.class isAvailableIOS11]) {
            self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        
        self.handler = handler;
        handler.webView = self;
        
        //设置代理
        self.UIDelegate = self;
        self.navigationDelegate = self;
        /**
         iOS9设备  设置了WKWebView的scrollView.delegate  要在使用WKWebView的地方
         dealloc时 清空代理scrollView.delegate = nil;   不能在WKWebView的dealloc方法里面清空代理
         否则crash
         */
        //        self.scrollView.delegate = self;
        
        //设置外部handler
//        self.apiHandlers = [apiHandlers mutableCopy];
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration{
    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
        [self configGesture];
    }
    return self;
}

- (NSArray<id<ZHJSApiProtocol>> *)apiHandlers{
    return [self.handler apiHandlers];
}

//添加移除api
- (void)addJsCode:(NSString *)jsCode completion:(void (^) (id res, NSError *error))completion{
    //WebView 没有加载
    if (!self.loadSuccess) {
        WKUserContentController *userContent = self.configuration.userContentController;
        WKUserScript *script = [[WKUserScript alloc] initWithSource:jsCode injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
        [userContent addUserScript:script];
        
        if (completion) completion(@{}, nil);
        return;
    }
    //webview已经加载
    [self evaluateJs:jsCode completionHandler:^(id res, NSError *error) {
        if (completion) completion(res, error);
    }];
}
- (void)addApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, id res, NSError *error))completion{
    __weak __typeof__(self) __self = self;
    
    [self.handler addApiHandlers:apiHandlers completion:^(NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, NSString *jsCode, NSError *error) {
        if (jsCode.length == 0 || error) {
            if (completion) completion(successApiHandlers, failApiHandlers, nil, error?:[NSError errorWithDomain:@"" code:404 userInfo:@{NSLocalizedDescriptionKey: @"api注入失败"}]);
            return;
        }

        //WebView 没有加载
        if (!__self.loadSuccess) {
            WKUserContentController *userContent = __self.configuration.userContentController;
            WKUserScript *script = [[WKUserScript alloc] initWithSource:jsCode injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
            [userContent addUserScript:script];
            
            if (completion) completion(successApiHandlers, failApiHandlers, @{}, nil);
            return;
        }
        //webview已经加载
        [__self evaluateJs:jsCode completionHandler:^(id res, NSError *error) {
            if (completion) completion(successApiHandlers, failApiHandlers, res, error);
        }];
    }];
}
- (void)removeApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, id res, NSError *error))completion{
    __weak __typeof__(self) __self = self;
    
    [self.handler removeApiHandlers:apiHandlers completion:^(NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, NSString *jsCode, NSError *error) {
        if (jsCode.length == 0 || error) {
            if (completion) completion(successApiHandlers, failApiHandlers, nil, error?:[NSError errorWithDomain:@"" code:404 userInfo:@{NSLocalizedDescriptionKey: @"api移除失败"}]);
            return;
        }

        //WebView 没有加载 【之后添加的addUserScript会覆盖之前的】
        if (!__self.loadSuccess) {
            WKUserContentController *userContent = __self.configuration.userContentController;
            WKUserScript *script = [[WKUserScript alloc] initWithSource:jsCode injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
            [userContent addUserScript:script];
            
            if (completion) completion(successApiHandlers, failApiHandlers, @{}, nil);
            return;
        }
        
        //webview已经加载
        [__self evaluateJs:jsCode completionHandler:^(id res, NSError *error) {
            if (completion) completion(successApiHandlers, failApiHandlers, res, error);
        }];
    }];
}

#pragma mark - layout

- (void)layoutSubviews{
    [super layoutSubviews];
    
    [self showFlowView];
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

#pragma mark - handler

+ (NSArray *)fetchHandlerNames{
    return @[ZHJSHandlerLogName, ZHJSHandlerName, ZHJSHandlerErrorName];
}

#pragma mark - Exception

/**白屏时
 页面 webView.titile 会被置空
 页面 URL 会被置空
 WKCompositingView控件会被销毁
 */
- (ZHWebViewExceptionOperate)checkException{
    if (self.didTerminate) return ZHWebViewExceptionOperateNewInit;
    
    BOOL isBlank = [self isBlankView:self];
    if (isBlank) return ZHWebViewExceptionOperateNewInit;
    
    BOOL isTitle = (self.title.length > 0);
    BOOL isURL = (self.URL != nil);
    if (!isTitle || !isURL) return ZHWebViewExceptionOperateReload;
    
    return ZHWebViewExceptionOperateNothing;
}
//检查WKCompositingView是否被系统回收
- (BOOL)isBlankView:(UIView *)webView {
    if ([webView isKindOfClass:NSClassFromString(@"WKCompositingView")]) return NO;
    NSArray *subViews = webView.subviews;
    for (UIView *subView in subViews) {
        if (![self isBlankView:subView]) return NO;
    }
    return YES;
}

#pragma mark - load

/** 加载资源的问题
真机上的目录   这俩目录的base路径不一样
 Documents：///var/mobile/Containers/Data/Application/32053764-FAB0-4C1A-A770-E41440D3E175/Documents
 Temp:           ///private/var/mobile/Containers/Data/Application/D2EAEA82-D1C0-42EE-9FBC-C5816CE1BDC0/tmp
 
 加载的 index.html位于沙盒内 【Documents、Temp】                       img标签的src 资源文件 可以访问  xx.app/xx.bundle中的资源图片
 加载的 index.html位于 xx.app/xx.bundle内   img标签的src 资源文件 可以访问  xx.app/xx.bundle中的资源图片
 
 加载的 index.html位于沙盒内【Documents】    img标签的src 要访问沙盒中资源文件  需设置readAccessURL = Documents目录
 加载的 index.html位于沙盒内【Temp】    img标签的src 要访问沙盒中资源文件  需设置readAccessURL = Temp目录
 加载的 index.html位于 xx.app/xx.bundle内   img标签的src 不能访问沙盒中资源文件
 
 
 结果：ios9以上 加载的 index.html位于沙盒内【Documents】设置readAccessURL = Documents目录
 ios9以下 加载的 index.html拷贝到【Temp】文件夹下  需要的资源也要拷贝
 */
- (void)loadUrl:(NSURL *)url baseURL:(NSURL *)baseURL allowingReadAccessToURL:(NSURL *)readAccessURL finish:(void (^) (BOOL success))finish{
    [self updateFloatViewTitle:@"刷新中..."];
    __weak __typeof__(self) __self = self;
    //回调
    void (^callBack)(BOOL) = ^(BOOL success){
        if (finish) finish(success);
        [__self updateFloatViewTitle:@"刷新"];
    };
    //webView加载完成回调
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
    if ([self.class isAvailableIOS9]) {
        NSURL *fileURL = [ZHWebView fileURLWithPath:path isDirectory:NO];
        if (!fileURL) {
            callBack(NO);
            return;
        }
        setWebViewFinish();
        [self loadFileURL:fileURL allowingReadAccessToURL:readAccessURL?:[NSURL fileURLWithPath:path.stringByDeletingLastPathComponent]];
        return;
    }
    
    //iOS8
    //检查路径是否在tmp目录
    BOOL isInTmpFolder = [path containsString:[self.class getTemporaryFolder]];
    NSString *newPath = path;
    //拷贝到tmp目录下
    if (!isInTmpFolder) {
        //没有传沙盒路径 默认url的上一级目录为沙盒目录
        if (!baseURL) {
            NSString *superFolder = [self.class fetchSuperiorFolder:url.path];
            if (!superFolder) {
                callBack(NO);
                return;
            }
            baseURL = [NSURL fileURLWithPath:superFolder];
            if (![fm fileExistsAtPath:baseURL.path]) {
                callBack(NO);
                return;
            }
        }
        //获取相对路径
        NSArray *baseURLComs = [baseURL pathComponents];
        NSMutableArray *URLComs = [[url pathComponents] mutableCopy];
        [URLComs removeObjectsInArray:baseURLComs];
        NSString *relativePath = [URLComs componentsJoinedByString:@"/"];
        if (relativePath.length == 0) {
            callBack(NO);
            return;
        }
        
        //拷贝
        BOOL result = NO;
        NSError *error = nil;
        
        NSString *iOS8TargetFolder = [self fetchRunSandBox];
        if ([fm fileExistsAtPath:iOS8TargetFolder]) {
            result = [fm removeItemAtPath:iOS8TargetFolder error:&error];
            if (!result || error) {
                callBack(NO);
                return;
            }
        }
        result = [fm copyItemAtPath:baseURL.path toPath:iOS8TargetFolder error:&error];
        if (!result || error) {
            callBack(NO);
            return;
        }
        
        newPath = [iOS8TargetFolder stringByAppendingPathComponent:relativePath];
    }
    
    NSURL *fileURL = [ZHWebView fileURLWithPath:newPath isDirectory:NO];
    if (!fileURL) {
        callBack(NO);
        return;
    }
    setWebViewFinish();
    NSURLRequest *request = [NSURLRequest requestWithURL:fileURL];
    [self loadRequest:request];
}

//渲染js页面
- (void)renderLoadPage:(NSURL *)jsSourceBaseURL jsSourceURL:(NSURL *)jsSourceURL completionHandler:(void (^)(id res, NSError *error))completionHandler{
    [self render:@"loadPage" jsSourceBaseURL:jsSourceBaseURL jsSourceURL:jsSourceURL completionHandler:completionHandler];
}
- (void)render:(NSString *)renderFunctionName jsSourceBaseURL:(NSURL *)jsSourceBaseURL jsSourceURL:(NSURL *)jsSourceURL completionHandler:(void (^)(id res, NSError *error))completionHandler{
    
    void (^callBlock)(id, NSError *) = ^(id res, NSError *error){
        if (completionHandler) completionHandler(res, error);
    };
    
    NSString *sandBox = [self fetchRunSandBox];
    
    if (![self.class checkString:renderFunctionName]) {
        callBlock(nil, [NSError errorWithDomain:@"ZHWebViewManager" code:900 userInfo:@{NSLocalizedDescriptionKey: @"renderFunctionName is nil >> %@"}]);
        return;
    }
    
    if (![self.fm fileExistsAtPath:sandBox] ||
        ![self.class checkURL:jsSourceBaseURL] || ![self.fm fileExistsAtPath:jsSourceBaseURL.path] ||
        ![self.class checkURL:jsSourceURL] || ![self.fm fileExistsAtPath:jsSourceURL.path]) {
        
        callBlock(nil, [NSError errorWithDomain:@"ZHWebViewManager" code:900 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"loadPath is nil >> %@", jsSourceURL.absoluteString]}]);
        return;
    }
    
    //拷贝资源、js到沙盒
    [self.lock lock];
    
    BOOL result = NO;
    NSError *error = nil;
    
    //获取子目录
    NSArray *array = [self.fm subpathsAtPath:jsSourceBaseURL.path];
    NSEnumerator *childFile = [array objectEnumerator];
    NSString *subpath;
    
    while ((subpath = [childFile nextObject]) != nil) {
        NSString *newSourcePath = [jsSourceBaseURL.path stringByAppendingPathComponent:subpath];
        NSString *newTargetPath = [sandBox stringByAppendingPathComponent:subpath];
        if ([self.fm fileExistsAtPath:newTargetPath]) {
            result = [self.fm removeItemAtPath:newTargetPath error:&error];
            if (!result || error) {
                callBlock(nil, error ? error : [NSError errorWithDomain:@"ZHWebViewManager" code:900 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"remove file is failed. >>> path [%@]", newTargetPath]}]);
                [self.lock unlock];
                return;
            }
        }
        result = [self.fm copyItemAtPath:newSourcePath toPath:newTargetPath error:&error];
        if (!result || error) {
            callBlock(nil, error ? error : [NSError errorWithDomain:@"ZHWebViewManager" code:900 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"copy is failed. >>> from path [%@] to path [%@]", newSourcePath, newTargetPath]}]);
            [self.lock unlock];
            return;
        }
    }
    
    NSArray *jsSourceBaseURLComs = [jsSourceBaseURL pathComponents];
    NSMutableArray *jsSourceURLComs = [[jsSourceURL pathComponents] mutableCopy];
    [jsSourceURLComs removeObjectsInArray:jsSourceBaseURLComs];
    NSString *relativePath = [jsSourceURLComs componentsJoinedByString:@"/"];
    
    if (![self.class checkString:relativePath]) {
        callBlock(nil, [NSError errorWithDomain:@"ZHWebViewManager" code:900 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"loadPath is nil >> path [%@]", jsSourceURL.absoluteString]}]);
        [self.lock unlock];
        return;
    }
    
    //渲染
    NSString *jsonStr = [self.class encodeObj:relativePath];
    NSString *js = [NSString stringWithFormat:@"%@(\"%@\")",renderFunctionName, jsonStr];
    __weak __typeof__(self) __self = self;
    [self evaluateJs:js completionHandler:^(id res, NSError *error) {
        [__self.lock unlock];
        if (completionHandler) completionHandler(res, error);
    }];
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

#pragma mark - run js

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
    NSString *paramsStr = [ZHWebView encodeObj:params];
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
- (void)evaluateJs:(NSString *)js completionHandler:(void (^)(id res, NSError *error))completionHandler{
    __weak __typeof__(self) __self = self;
    [self evaluateJavaScript:js completionHandler:^(id res, NSError *error) {
        if (error) {
            [__self.handler showWebViewException:error.userInfo];
        }
        if (completionHandler) completionHandler(res, error);
    }];
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

#pragma mark - WKNavigationDelegate

- (void)webView:(ZHWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    if (webView.loadFinish) webView.loadFinish(NO);
    
    id <ZHWKNavigationDelegate> de = self.zh_navigationDelegate;
    if (ZHCheckDelegate(de, @selector(webView:didFailNavigation:withError:))) {
        [de webView:webView didFailNavigation:navigation withError:error];
    }
}

- (void)webView:(ZHWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    if (webView.loadFinish) webView.loadFinish(YES);
    
    id <ZHWKNavigationDelegate> de = self.zh_navigationDelegate;
    if (ZHCheckDelegate(de, @selector(webView:didFinishNavigation:))) {
        [de webView:webView didFinishNavigation:navigation];
    }
}

- (void)webView:(ZHWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    NSLog(@"-----❌didFailProvisionalNavigation---------------");
    NSLog(@"%@",error);
    
    id <ZHWKNavigationDelegate> de = self.zh_navigationDelegate;
    if (ZHCheckDelegate(de, @selector(webView:didFailProvisionalNavigation:withError:))) {
        [de webView:webView didFailProvisionalNavigation:navigation withError:error];
    }
}

- (void)webView:(ZHWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    
    id <ZHWKNavigationDelegate> de = self.zh_navigationDelegate;
    if (ZHCheckDelegate(de, @selector(webView:decidePolicyForNavigationAction:decisionHandler:))) {
        [de webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
        return;
    }
    
    if ([navigationAction.request.URL.scheme isEqualToString:@"file"]) {
        if (decisionHandler) decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    if (decisionHandler) decisionHandler(WKNavigationActionPolicyAllow);
}

//当WKWebView总体内存占用过大，页面即将白屏的时候，系统会调用上面的回调函数，我们在该函数里执行[webView reload]（这个时候webView.URL取值尚不为零）解决白屏问题。在一些高内存消耗的页面可能会频繁刷新当前页面
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView{
    if ([self.class isAvailableIOS9]) {
        id <ZHWKNavigationDelegate> de = self.zh_navigationDelegate;
        if (ZHCheckDelegate(de, @selector(webViewWebContentProcessDidTerminate:))) {
            [de webViewWebContentProcessDidTerminate:webView];
        }
        self.didTerminate = YES;
    }
}

#pragma mark - WKUIDelegate

// 页面是弹出窗口 _blank 处理
- (WKWebView *)webView:(ZHWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    id <ZHWKUIDelegate> de = self.zh_UIDelegate;
    if (ZHCheckDelegate(de, @selector(webView:createWebViewWithConfiguration:forNavigationAction:windowFeatures:))) {
        return [de webView:webView createWebViewWithConfiguration:configuration forNavigationAction:navigationAction windowFeatures:windowFeatures];
    }
    
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

//处理js的同步消息
-(void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler{
    NSError *error;
    NSDictionary *receiveInfo = [NSJSONSerialization JSONObjectWithData:[prompt dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    
    id result = [self.handler handleScriptMessage:receiveInfo];
    if (!result) {
        if (completionHandler) completionHandler(nil);
        return;
    }
    /** 包裹一层数据：js端再解析出来
     作用：原生传数据可在js正常解析出类型
     不包裹：
         completionHandler回调@(YES)   js解析为Number类型
         completionHandler回调@(1111)   js解析为Number类型
     包裹：
         result ：@(YES)  @(NO)  js解析为Boolean类型  可直接使用
         result ：@(111)  js解析为Number类型
     */
    result = @{@"data": result};
    NSData *data = nil;
    @try {
        data = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
    } @catch (NSException *exception) {
        NSLog(@"❌-------%s---------", __func__);
        NSLog(@"%@",exception);
    } @finally {
        
    }
    if (!data) {
        if (completionHandler) completionHandler(nil);
        return;
    }
    if (completionHandler) completionHandler([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

#pragma mark - UIScrollViewDelegate

#pragma mark - socket debug
#ifdef DEBUG
- (void)socketDidOpen:(NSDictionary *)params{
    
}
- (void)socketDidReceiveMessage:(NSDictionary *)params{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![params isKindOfClass:[NSDictionary class]]) return;
        NSString *type = [params valueForKey:@"type"];
        if (![type isKindOfClass:[NSString class]]) return;
        if ([type isEqualToString:@"invalid"]) {
            [self performSelector:@selector(socketCallReadyRefresh) withObject:nil];
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(socketCallRefresh) object:nil];
            return;
        }
        if ([type isEqualToString:@"hash"]) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(socketCallRefresh) object:nil];
//            [self performSelector:@selector(socketCallRefresh) withObject:nil afterDelay:0.5];
            return;
        }
        if ([type isEqualToString:@"ok"] || [type isEqualToString:@"warnings"]) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(socketCallRefresh) object:nil];
            [self performSelector:@selector(socketCallRefresh) withObject:nil afterDelay:0.3];
            return;
        }
    });
}
- (void)socketDidError:(NSDictionary *)params{
    
}
- (void)socketDidClose:(NSDictionary *)params{
    
}
- (void)socketCallReadyRefresh{
    [self updateFloatViewTitle:@"准备中..."];
    if (ZHCheckDelegate(self.zh_socketDebugDelegate, @selector(webViewReadyRefresh:))) {
        [self.zh_socketDebugDelegate webViewReadyRefresh:self];
    }
}
- (void)socketCallRefresh{
    [self updateFloatViewTitle:@"刷新中..."];
        
        /** presented 与dismiss同时进行 会crash */
    //    if ([self.presentedViewController isKindOfClass:[UIAlertController class]]) {
    //        [self dismissViewControllerAnimated:YES completion:nil];
    //    }
    
    //获取代理
    id <ZHWebViewSocketDebugDelegate> socketDebugDelegate = self.zh_socketDebugDelegate;
    //清除代理
    self.zh_navigationDelegate = nil;
    self.zh_UIDelegate = nil;
    self.zh_socketDebugDelegate = nil;
    //清除缓存【否则ios11以上不会实时刷新最新的改动】
    [self clearWebViewSystemCache];
    //回调
    if (ZHCheckDelegate(socketDebugDelegate, @selector(webViewRefresh:))) {
        [socketDebugDelegate webViewRefresh:self];
    }
}
#endif

#pragma mark - parse URL

/// 本地路径转NSURL，支持带参数（系统的fileURLWithPath会导致参数被编码，webview加载失败）
/// @param path 本地k路径
/// @param isDirectory 是否文件夹
+ (NSURL *)fileURLWithPath:(NSString *)path isDirectory:(BOOL)isDirectory {
    NSArray *components = [path componentsSeparatedByString:@"?"];
    if (components.count < 1) {
        return nil;
    }
    NSString *subPath = components[0];
    NSURL *fileUrl = [NSURL fileURLWithPath:subPath isDirectory:isDirectory];
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:fileUrl resolvingAgainstBaseURL:NO];
    
    if (components.count > 1) {
        NSString *paramStr = components[1];
        NSArray *params = [paramStr componentsSeparatedByString:@"&"];
        NSMutableArray *queryItems = [NSMutableArray new];
        for (NSString *param in params) {
            NSArray *keyValue = [param componentsSeparatedByString:@"="];
            if (keyValue.count > 1) {
                [queryItems addObject:[NSURLQueryItem queryItemWithName:keyValue[0] value:keyValue[1]]];
            }
        }
        [urlComponents setQueryItems:queryItems];
    }
    return urlComponents.URL;
}

#pragma mark - encode

+ (NSString *)encodeObj:(id)data{
    if (!data) return nil;
    NSString *res = nil;
    if ([data isKindOfClass:[NSString class]]) {
        res = (NSString *)data;
    }else if ([data isKindOfClass:[NSNumber class]]){
        res = [NSString stringWithFormat:@"%@",data];
    }else if ([data isKindOfClass:[NSDictionary class]] ||
              [data isKindOfClass:[NSArray class]]){
        NSError *jsonError;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&jsonError];
        res = jsonError ? jsonError.userInfo[NSLocalizedDescriptionKey] : [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        if (jsonError) return nil;
        res = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }else if ([data isKindOfClass:[NSObject class]]){
        res = [data description];
    }else{
        //默认obj作为BOOL值处理
        res = [NSString stringWithFormat:@"%d",data];
    }
    return [res stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

#pragma mark - clear

- (void)clearWebViewSystemCache{
    if ([self.class isAvailableIOS9]) {
        WKWebsiteDataStore *dataSource = [WKWebsiteDataStore defaultDataStore];
        [dataSource removeDataOfTypes:[WKWebsiteDataStore allWebsiteDataTypes] modifiedSince:[NSDate dateWithTimeIntervalSince1970:0] completionHandler:^{
        }];
        return;
    }
    NSFileManager *mg = [NSFileManager defaultManager];
    void (^removeFolder)(NSString *) = ^(NSString *folder){
        if ([mg fileExistsAtPath:folder]) {
            [mg removeItemAtPath:folder error:nil];
        }
    };
    NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    NSString *libraryDir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask, YES)[0];
    NSString *tempDir = NSTemporaryDirectory();
    NSString *path1 = [NSString stringWithFormat:@"%@/WebKit/%@/WebsiteData", libraryDir, bundleId];
    NSString *path2 = [NSString stringWithFormat:@"%@/Caches/%@/WebKit", libraryDir, bundleId];
    NSString *path3 = [NSString stringWithFormat:@"%@/%@/WebKit", tempDir, bundleId];
    removeFolder(path1);
    removeFolder(path2);
    removeFolder(path3);
}

#pragma mark - debug

+ (BOOL)isAvailableIOS11{
#ifdef DEBUG
    if (@available(iOS 11.0, *)) {
        return YES;
    }
    return NO;
#endif
    if (@available(iOS 11.0, *)) {
        return YES;
    }
    return NO;
}

+ (BOOL)isAvailableIOS9{
#ifdef DEBUG
    //❌
//    return NO;
    if (@available(iOS 9.0, *)) {
        return YES;
    }
    return NO;
#endif
    if (@available(iOS 9.0, *)) {
        return YES;
    }
    return NO;
}

#pragma mark - file

- (NSFileManager *)fm{
    return [NSFileManager defaultManager];
}

#pragma mark - check

+ (BOOL)checkString:(NSString *)string{
    return !(!string || ![string isKindOfClass:[NSString class]] || string.length == 0);
}

+ (BOOL)checkURL:(NSURL *)URL{
    return !(!URL || ![URL isKindOfClass:[NSURL class]] || URL.absoluteString.length == 0);
}


#pragma mark - path

+ (NSString *)getDocumentFolder{
    NSArray *userPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [userPaths objectAtIndex:0];
}
+ (NSString *)getCacheFolder{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}
+ (NSString *)getTemporaryFolder{
    return NSTemporaryDirectory();
}

//获取webView运行沙盒
- (NSString *)fetchRunSandBox{
    NSString *boxFolder = [NSString stringWithFormat:@"%p", self];
    if ([self.class isAvailableIOS9]) {
        return [ZHWebViewFolder() stringByAppendingPathComponent:boxFolder];
    }
    return [ZHWebViewTmpFolder() stringByAppendingPathComponent:boxFolder];
}

//获取路径的上级目录
+ (NSString *)fetchSuperiorFolder:(NSString *)path{
    if (!path || ![path isKindOfClass:[NSString class]] || path.length == 0) return nil;

    NSMutableArray *pathComs = [[path pathComponents] mutableCopy];
    if (pathComs.count <= 1) {
        return nil;
    }
    [pathComs removeLastObject];
    return [pathComs componentsJoinedByString:@"/"];
}


#pragma mark - float view

- (void)showFlowView{
#ifdef DEBUG
    [self.floatView showInView:self];
#endif
}
- (void)updateFloatViewTitle:(NSString *)title{
#ifdef DEBUG
    [self.floatView updateTitle:title];
#endif
}

#pragma mark - getter

- (NSLock *)lock{
    if (!_lock) {
        _lock = [[NSLock alloc] init];
    }
    return _lock;
}


#ifdef DEBUG
- (ZHFloatView *)floatView{
    if (!_floatView) {
        _floatView = [ZHFloatView floatView];
        __weak __typeof__(self) __self = self;
        _floatView.tapClickBlock = ^{
            [__self socketCallRefresh];
        };
    }
    return _floatView;
}
#endif

@end
