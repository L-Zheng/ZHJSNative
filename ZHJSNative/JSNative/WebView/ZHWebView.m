//
//  ZHWebView.m
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHWebView.h"
#import "ZHJSHandler.h"
#import "ZHJSInWebSocketApi.h"
#import "ZHJSInWebFundApi.h"
#import "NSError+ZH.h"
#import "ZHUtil.h"

@interface ZHWebView ()<WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate>

// webview异常信息
@property (nonatomic,strong) NSDictionary *exceptionInfo;

//webView运行的沙盒目录
@property (nonatomic, copy) NSURL *runSandBoxURL;

@property (nonatomic, copy) void (^loadFinish) (NSDictionary *info, NSError *error);
@property (nonatomic, assign) BOOL loadSuccess;
@property (nonatomic, assign) BOOL loadFail;

@property (nonatomic, assign) BOOL didTerminate;//WebContentProcess进程被终结
@property (nonatomic, strong) UIGestureRecognizer *pressGes;

@property (nonatomic, strong) NSLock *lock;

@end

@implementation ZHWebView

- (instancetype)initWithGlobalConfig:(ZHWebConfig *)globalConfig{
    self.globalConfig = globalConfig;
    globalConfig.webView = self;
    
    ZHWebMpConfig *mpConfig = globalConfig.mpConfig;
    mpConfig.webView = self;
    self.mpConfig = mpConfig;
    
    self.webItem = [ZHWebViewItem createByInfo:@{
        @"appId": mpConfig.appId?:@"",
        @"envVersion": mpConfig.envVersion?:@"",
        @"url": mpConfig.loadFileName?:@"",
        @"params": @{}
    }];
    
    return [self initWithCreateConfig:globalConfig.createConfig];
}
- (instancetype)initWithCreateConfig:(ZHWebCreateConfig *)createConfig{
    // 初始化配置
    self.createConfig = createConfig;
    createConfig.webView = self;
    NSArray <id <ZHJSApiProtocol>> *apis = createConfig.apis;
    WKProcessPool *processPool = createConfig.processPool;
    CGRect frame = createConfig.frameValue.CGRectValue;
    
    // webView配置
    WKWebViewConfiguration *wkConfig = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *userContent = [[WKUserContentController alloc] init];
    
    // debug配置
    ZHWebDebugItem *debugItem = [ZHWebDebugItem item:self];
    self.debugItem = debugItem;
    
    // 内置api
    NSMutableArray *inApis = [NSMutableArray array];
    if (debugItem && debugItem.debugModeEnable) {
        ZHJSInWebSocketApi *socket = [[ZHJSInWebSocketApi alloc] init];
        socket.webView = self;
        [inApis addObject:socket];
    }
    if (createConfig.injectInAPI) {
        ZHJSInWebFundApi *fund = [[ZHJSInWebFundApi alloc] init];
        fund.webView = self;
        [inApis addObject:fund];
    }
    
    // api处理配置
    ZHJSHandler *handler = [[ZHJSHandler alloc] init];
    handler.apiHandler = [[ZHJSApiHandler alloc] initWithApis:inApis apis:apis?:@[]];
    handler.jsPage = self;
    handler.webView = self;
    self.handler = handler;
    
    //注入api
    NSMutableArray *apiCodes = [NSMutableArray array];
    /*
     WKUserScriptInjectionTimeAtDocumentStart:
        document创建完成之后，其它任何内容加载之前。此时h5里面只有window、document对象，没有head、body对象
     WKUserScriptInjectionTimeAtDocumentEnd:
        document加载完成之后（html根标签代码执行到末尾），其它任何子资源可能加载完成之前
     js执行顺序：(vue项目打包后会把js插入到body的末尾)
     start脚本 -> header里面的script标签 -> body里面的script标签 ->vue插入到body末尾的script标签 (beforeCreate -> created -> mounted) -> 与body同级的后面的script标签 ->html根标签执行结束 -> end脚本
     */
    //log
    if (debugItem.logOutputXcodeEnable) {
        [apiCodes addObject:@{
            @"code": [handler fetchWebViewLogApi]?:@"",
            @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentStart),
            @"mainFrameOnly": @(YES)
        }];
    }
    //error
    if (debugItem.alertWebErrorEnable) {
        [apiCodes addObject:@{
            @"code": [handler fetchWebViewErrorApi]?:@"",
            @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentStart),
            @"mainFrameOnly": @(YES)
        }];
    }
    //websocket js用于监听socket链接
    if (debugItem.debugModeEnable) {
        [apiCodes addObject:@{
            @"code": [handler fetchWebViewSocketApi]?:@"",
            @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentStart),
            @"mainFrameOnly": @(YES)
        }];
    }
    //webview log控制台
    if (debugItem.logOutputWebEnable) {
        // 不可使用本地url地址：socket调试时，访问的是http地址，浏览器不允许访问本地地址
//        [apiCodes addObject:@{
//            @"code": @"var ZhengVconsoleLog = document.createElement('script'); ZhengVconsoleLog.type = 'text/javascript'; ZhengVconsoleLog.src = 'http://wechatfe.github.io/vconsole/lib/vconsole.min.js?v=3.3.0'; ZhengVconsoleLog.charset = 'UTF-8'; ZhengVconsoleLog.onload = function(){var vConsole = new VConsole();}; ZhengVconsoleLog.onerror = function(error){}; window.document.body.appendChild(ZhengVconsoleLog);",
//            @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentEnd),
//            @"mainFrameOnly": @(YES)
//        }];
        [apiCodes addObject:@{
            @"code": [handler fetchWebViewConsoleApi]?:@"",
            @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentEnd),
            @"mainFrameOnly": @(YES)
        }];
    }
    //禁用webview长按弹出菜单
    if (debugItem.touchCalloutEnable) {
        [apiCodes addObject:@{
            @"code": [handler fetchWebViewTouchCalloutApi]?:@"",
            @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentEnd),
            @"mainFrameOnly": @(YES)
        }];
    }
    //api support js
    [apiCodes addObject:@{
        @"code": [handler fetchWebViewSupportApi]?:@"",
        @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentStart),
        @"mainFrameOnly": @(YES)
    }];
    //api js
    [apiCodes addObject:@{
        @"code": [handler fetchWebViewApi:NO]?:@"",
        @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentStart),
        @"mainFrameOnly": @(YES)
    }];
    //api 注入完成
    [apiCodes addObject:@{
        @"code": [handler fetchWebViewApiFinish]?:@"",
        @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentEnd),
        @"mainFrameOnly": @(YES)
    }];
    //api 注入附加脚本
    if ([ZHWebView checkString:createConfig.extraScriptStart]) {
        [apiCodes addObject:@{
            @"code": createConfig.extraScriptStart?:@"",
            @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentStart),
            @"mainFrameOnly": @(YES)
        }];
    }
    if ([ZHWebView checkString:createConfig.extraScriptEnd]) {
        [apiCodes addObject:@{
            @"code": createConfig.extraScriptEnd?:@"",
            @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentEnd),
            @"mainFrameOnly": @(YES)
        }];
    }
    for (NSDictionary *map in apiCodes) {
        NSString *code = [map valueForKey:@"code"];
        if (code.length == 0) continue;
        NSNumber *jectionTime = [map valueForKey:@"jectionTime"];
        NSNumber *mainFrameOnly = [map valueForKey:@"mainFrameOnly"];
        WKUserScript *script = [[WKUserScript alloc] initWithSource:code injectionTime:jectionTime.integerValue forMainFrameOnly:mainFrameOnly.boolValue];
        [userContent addUserScript:script];
    }
    
    //监听ScriptMessageHandler
    NSArray *handlerNames = [self.class fetchHandlerNames];
    for (NSString *key in handlerNames) {
        [userContent addScriptMessageHandler:handler name:key];
    }
    
    //配置内容进程池
    if (processPool) {
        wkConfig.processPool = processPool;
    }
    // 设置偏好设置
    wkConfig.preferences = [[WKPreferences alloc] init];
    // 默认为0
    wkConfig.preferences.minimumFontSize = 10;
    // 默认认为YES
    wkConfig.preferences.javaScriptEnabled = YES;
    //允许视频
    wkConfig.allowsInlineMediaPlayback = YES;
    wkConfig.userContentController = userContent;
    
    //设置跨域
    
    // 禁用 file 协议；
//    setAllowFileAccess(false);
//    setAllowFileAccessFromFileURLs(false);
//    setAllowUniversalAccessFromFileURLs(false);
    
    // 设置是否允许通过 file url 加载的 Js代码读取其他的本地文件
    if ([ZHJSDebugMg() availableIOS9]) {
        [wkConfig.preferences setValue:@YES forKey:@"allowFileAccessFromFileURLs"];
    }
    if ([ZHJSDebugMg() availableIOS10]) {
        // 设置是否允许通过 file url 加载的 Javascript 可以访问其他的源(包括http、https等源)
        [wkConfig setValue:@YES forKey:@"allowUniversalAccessFromFileURLs"];
    }
    
    self = [self initWithFrame:frame configuration:wkConfig];
    if (self) {
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration{
    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
        [self updateUserInterfaceStyle];
        [self configGesture];
        [self configUI];
    }
    return self;
}

- (NSArray<id<ZHJSApiProtocol>> *)apis{
    return [self.handler apis];
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
- (void)addApis:(NSArray <id <ZHJSApiProtocol>> *)apis completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApis, NSArray<id<ZHJSApiProtocol>> *failApis, id res, NSError *error))completion{
    __weak __typeof__(self) __self = self;
    [self.handler addApis:apis completion:^(NSArray<id<ZHJSApiProtocol>> *successApis, NSArray<id<ZHJSApiProtocol>> *failApis, NSString *jsCode, NSError *error) {
        if (jsCode.length == 0 || error) {
            if (completion) completion(successApis, failApis, nil, error?:[NSError errorWithDomain:@"" code:404 userInfo:@{NSLocalizedDescriptionKey: @"api注入失败"}]);
            return;
        }
        //注入新的jsCode
        [__self addJsCode:jsCode completion:^(id res, NSError *error) {
            if (completion) completion(successApis, failApis, res, error);
        }];
    }];
}
- (void)removeApis:(NSArray <id <ZHJSApiProtocol>> *)apis completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApis, NSArray<id<ZHJSApiProtocol>> *failApis, id res, NSError *error))completion{
    __weak __typeof__(self) __self = self;
    [self.handler removeApis:apis completion:^(NSArray<id<ZHJSApiProtocol>> *successApis, NSArray<id<ZHJSApiProtocol>> *failApis, NSString *jsCode, NSError *error) {
        if (jsCode.length == 0 || error) {
            if (completion) completion(successApis, failApis, nil, error?:[NSError errorWithDomain:@"" code:404 userInfo:@{NSLocalizedDescriptionKey: @"api移除失败"}]);
            return;
        }
        //注入新的jsCode
        [__self addJsCode:jsCode completion:^(id res, NSError *error) {
            if (completion) completion(successApis, failApis, res, error);
        }];
    }];
}

#pragma mark - layout

- (void)layoutSubviews{
    [super layoutSubviews];
    [self updateUI];
}
//- (void)didMoveToSuperview{
//    [super didMoveToSuperview];
//    if (self.superview) {
//        [self updateUserInterfaceStyle];
//    }
//}

#pragma mark - UI

- (void)configUI{
    // UI配置
    UIColor *lightColor = [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0];
    if (@available(iOS 13.0, *)) {
        self.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor blackColor];
            }
            return lightColor;
        }];
    }else{
        self.backgroundColor = lightColor;
    }
    //    self.scrollView.bounces = NO;
    //    self.scrollView.alwaysBounceVertical = NO;
    //    self.scrollView.alwaysBounceHorizontal = NO;
    self.scrollView.showsVerticalScrollIndicator = YES;
    //设置流畅滑动【否则 滑动效果没有减速过快】
    self.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    //禁用链接预览
    //    [webView setAllowsLinkPreview:NO];
    
    if ([ZHJSDebugMg() availableIOS11]) {
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    //设置代理
    self.UIDelegate = self;
    self.navigationDelegate = self;
    /**
     iOS9设备  设置了WKWebView的scrollView.delegate  要在使用WKWebView的地方
     dealloc时 清空代理scrollView.delegate = nil;   不能在WKWebView的dealloc方法里面清空代理
     否则crash
     */
    //        self.scrollView.delegate = self;
    
    [self.debugItem showFloatView];
}

- (void)updateUI{
    [self.debugItem updateFloatViewLocation];
}

#pragma mark - theme

- (void)updateUserInterfaceStyle{
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
    }
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
    if (self.didTerminate) return ZHWebViewExceptionOperateReload;
    
    BOOL isBlank = [self isBlankView:self];
    if (isBlank) return ZHWebViewExceptionOperateReload;
    
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
- (void)loadWithUrl:(NSURL *)url
            baseURL:(NSURL *)baseURL
         loadConfig:(ZHWebLoadConfig *)loadConfig
     startLoadBlock:(void (^) (NSURL *runSandBoxURL))startLoadBlock
             finish:(void (^) (NSDictionary *info, NSError *error))finish{
    self.loadConfig = loadConfig;
    loadConfig.webView = self;
    NSNumber *cachePolicy = loadConfig.cachePolicy;
    NSNumber *timeoutInterval = loadConfig.timeoutInterval;
    NSURL *readAccessURL = loadConfig.readAccessURL;
    
    [self.debugItem updateRefreshFloatViewTitle:@"刷新中..."];
    __weak __typeof__(self) __self = self;
    void (^callBack)(NSDictionary *, NSError *) = ^(NSDictionary *info, NSError *error){
        if (finish) finish(info, error);
        [__self.debugItem updateRefreshFloatViewTitle:@"刷新"];
    };
    
    NSString *extraErrorDesc = [NSString stringWithFormat:@"file path is %@. url is %@. baseURL is %@. loadConfig is %@.", url.path, url, baseURL, [loadConfig formatInfo]];
    
    if (!url) {
        callBack(nil, ZHInlineError(404, ZHLCInlineString(@"webview load url is null. %@", extraErrorDesc)));
        return;
    }
    
    NSString *path = url.path;
    
    //远程Url
    if (!url.isFileURL) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        if (cachePolicy && timeoutInterval) {
            request = [NSURLRequest requestWithURL:url cachePolicy:cachePolicy.unsignedIntegerValue timeoutInterval:timeoutInterval.doubleValue];
        }
        [self callWebViewStartLoad:nil renderURL:url block:startLoadBlock];
        [self configWebViewFinishCallBack:callBack];
        [self loadRequest:request];
        return;
    }
    
    //本地Url
    BOOL isDirectory = YES;
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path isDirectory:&isDirectory]) {
        callBack(nil, ZHInlineError(404, ZHLCInlineString(@"file is not exists. %@", extraErrorDesc)));
        return;
    }
    if (isDirectory) {
        callBack(nil, ZHInlineError(404, ZHLCInlineString(@"file path is directory. %@", extraErrorDesc)));
        return;
    }
    if ([ZHJSDebugMg() availableIOS9]) {
        NSURL *fileURL = [ZHWebView fileURLWithPath:path isDirectory:NO];
        if (!fileURL) {
            callBack(nil, ZHInlineError(404, ZHLCInlineString(@"parse url params is failed. %@", extraErrorDesc)));
            return;
        }
        self.runSandBoxURL = [ZHUtil parseRealRunBoxFolder:baseURL fileURL:url];
        [self callWebViewStartLoad:self.runSandBoxURL renderURL:fileURL block:startLoadBlock];
        [self configWebViewFinishCallBack:callBack];
        [self loadFileURL:fileURL allowingReadAccessToURL:readAccessURL?:self.runSandBoxURL];
        return;
    }
    
    //iOS8
    //检查路径是否在tmp目录
    BOOL isInTmpFolder = [path containsString:[self.class getTemporaryFolder]];
    
    //在tmp目录下
    if (isInTmpFolder) {
        NSURL *fileURL = [ZHWebView fileURLWithPath:path isDirectory:NO];
        if (!fileURL) {
            callBack(nil, ZHInlineError(404, ZHLCInlineString(@"parse url params is failed. %@", extraErrorDesc)));
            return;
        }
        NSURLRequest *request = [NSURLRequest requestWithURL:fileURL];
        if (cachePolicy && timeoutInterval) {
            request = [NSURLRequest requestWithURL:fileURL cachePolicy:cachePolicy.unsignedIntegerValue timeoutInterval:timeoutInterval.doubleValue];
        }
        self.runSandBoxURL = [ZHUtil parseRealRunBoxFolder:baseURL fileURL:url];
        [self callWebViewStartLoad:self.runSandBoxURL renderURL:fileURL block:startLoadBlock];
        [self configWebViewFinishCallBack:callBack];
        [self loadRequest:request];
        return;
    }
    
    //拷贝到tmp目录下
    NSURL *newBaseURL = [ZHUtil parseRealRunBoxFolder:baseURL fileURL:url];
    if (!newBaseURL) {
        callBack(nil, ZHInlineError(404, ZHLCInlineString(@"parse run box is failed. %@", extraErrorDesc)));
        return;
    }
    //获取相对路径
    NSArray *newBaseURLComs = [newBaseURL pathComponents];
    NSMutableArray *URLComs = [[url pathComponents] mutableCopy];
    [URLComs removeObjectsInArray:newBaseURLComs];
    NSString *relativePath = [URLComs componentsJoinedByString:@"/"];
    if (![self.class checkString:relativePath]) {
        callBack(nil, ZHInlineError(404, ZHLCInlineString(@"fetch relativePath is failed. %@", extraErrorDesc)));
        return;
    }
    
    //拷贝
    BOOL result = NO;
    NSError *error = nil;
    
    NSString *iOS8TargetFolder = [self fetchReadyRunSandBox];
    if ([fm fileExistsAtPath:iOS8TargetFolder]) {
        result = [fm removeItemAtPath:iOS8TargetFolder error:&error];
        if (!result || error) {
            callBack(nil, ZHInlineError(-999, ZHLCInlineString(@"remove folder(%@) is failed(error: %@). %@", iOS8TargetFolder, error.zh_localizedDescription, extraErrorDesc)));
            return;
        }
    }else{
        //创建上级目录 否则拷贝失败
        NSString *superFolder = [ZHUtil fetchSuperiorFolder:iOS8TargetFolder];
        if (!superFolder) {
            callBack(nil, ZHInlineError(404, ZHLCInlineString(@"fetch superior folder by folder(%@) is failed. %@", iOS8TargetFolder, extraErrorDesc)));
            return;
        }
        if (![self.fm fileExistsAtPath:superFolder]) {
            result = [self.fm createDirectoryAtPath:superFolder withIntermediateDirectories:YES attributes:nil error:&error];
            if (!result || error) {
                callBack(nil, ZHInlineError(-999, ZHLCInlineString(@"create folder(%@) is failed(error: %@). %@", superFolder, error.zh_localizedDescription, extraErrorDesc)));
                return;
            }
        }
    }
    result = [fm copyItemAtPath:newBaseURL.path toPath:iOS8TargetFolder error:&error];
    if (!result || error) {
        callBack(nil, ZHInlineError(-999, ZHLCInlineString(@"copy sourcePath(%@) to targetPath(%@) is failed(error: %@). %@", newBaseURL.path, iOS8TargetFolder, error.zh_localizedDescription, extraErrorDesc)));
        return;
    }
    
    NSString *newPath = [iOS8TargetFolder stringByAppendingPathComponent:relativePath];
    
    NSURL *fileURL = [ZHWebView fileURLWithPath:newPath isDirectory:NO];
    if (!fileURL) {
        callBack(nil, ZHInlineError(404, ZHLCInlineString(@"parse url(%@) params is failed. %@", newPath, extraErrorDesc)));
        return;
    }
    NSURLRequest *request = [NSURLRequest requestWithURL:fileURL];
    if (cachePolicy && timeoutInterval) {
        request = [NSURLRequest requestWithURL:fileURL cachePolicy:cachePolicy.unsignedIntegerValue timeoutInterval:timeoutInterval.doubleValue];
    }
    self.runSandBoxURL = [NSURL fileURLWithPath:iOS8TargetFolder];
    [self callWebViewStartLoad:self.runSandBoxURL renderURL:fileURL block:startLoadBlock];
    [self configWebViewFinishCallBack:callBack];
    [self loadRequest:request];
}

- (void)loadLocalDebug:(NSString *)loadFileName
            loadFolder:(NSString *)loadFolder
                finish:(void (^) (NSDictionary *info, NSError *error))finish{
    if (!loadFolder || ![loadFolder isKindOfClass:NSString.class] || loadFolder.length == 0 ||
        !loadFileName || ![loadFileName isKindOfClass:NSString.class] || loadFileName.length == 0) {
        if (finish) finish(nil, ZHInlineError(404, ZHLCInlineString(@"webview loadFolder(%@) or loadFileName(%@) is null.", loadFolder, loadFileName)));
        return;
    }
    
    // 拷贝到临时目录
    NSString *baseFolder = ZHWebViewTmpFolder();
    NSString *tempFolder = [baseFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%p", self]];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:baseFolder]) {
        [fm createDirectoryAtPath:baseFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if ([fm fileExistsAtPath:tempFolder]) {
        [fm removeItemAtPath:tempFolder error:nil];
    }
    [fm copyItemAtPath:loadFolder toPath:tempFolder error:nil];
    
    ZHWebLoadConfig *loadConfig = self.globalConfig.loadConfig;
    loadConfig.readAccessURL = loadConfig.readAccessURL?:[NSURL fileURLWithPath:loadFolder];
    
    NSString *htmlPath = [loadFolder stringByAppendingPathComponent:loadFileName];
    NSURL *url = [NSURL fileURLWithPath:htmlPath];
    NSURL *baseURL = [NSURL fileURLWithPath:loadFolder isDirectory:YES];
    
    [self loadWithUrl:url
                 baseURL:baseURL
              loadConfig:loadConfig
          startLoadBlock:^(NSURL *runSandBoxURL) {
    }
                  finish:^(NSDictionary *info, NSError *error) {
        if (finish) finish(error ? nil : info, error);
    }];
}
- (void)loadOnlineDebug:(NSURL *)url
         startLoadBlock:(void (^) (NSURL *runSandBoxURL))startLoadBlock
                 finish:(void (^) (NSDictionary *info, NSError *error))finish{
    if (!url || url.isFileURL) {
        if (finish) finish(nil, [NSError new]);
        return;
    }
    [self loadWithUrl:url baseURL:nil loadConfig:self.globalConfig.loadConfig startLoadBlock:^(NSURL *runSandBoxURL) {
        if (startLoadBlock) startLoadBlock(runSandBoxURL);
    } finish:^(NSDictionary *info, NSError *error) {
        if (finish) finish(info, error);
    }];
}


//配置webview渲染回调
- (void)callWebViewStartLoad:(NSURL *)runSandBoxURL renderURL:(NSURL *)renderURL block:(void (^) (NSURL *runSandBoxURL))block{
    self.didTerminate = NO;
    self.renderURL = renderURL;
    if (!block) return;
    block(runSandBoxURL);
}
- (void)configWebViewFinishCallBack:(void (^) (NSDictionary *info, NSError *error))finish{
    __weak __typeof__(self) __self = self;
    self.loadFinish = ^(NSDictionary *info, NSError *error) {
        BOOL success = error ? NO : YES;
        __self.loadSuccess = success;
        __self.loadFail = !success;
        if (success) {
            __self.loadFinish = nil;
        }
        if (finish) finish(info, error);
    };
}

//渲染js页面
- (void)renderLoadPage:(NSURL *)jsSourceBaseURL jsSourceURL:(NSURL *)jsSourceURL completionHandler:(void (^)(id res, NSError *error))completionHandler{
    [self render:@"loadPage" jsSourceBaseURL:jsSourceBaseURL jsSourceURL:jsSourceURL completionHandler:completionHandler];
}
- (void)render:(NSString *)renderFunctionName jsSourceBaseURL:(NSURL *)jsSourceBaseURL jsSourceURL:(NSURL *)jsSourceURL completionHandler:(void (^)(id res, NSError *error))completionHandler{
    
    void (^callBlock)(id, NSError *) = ^(id res, NSError *error){
        if (completionHandler) completionHandler(res, error);
    };
    
    NSString *sandBox = self.runSandBoxURL.path;
    
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
    
    //获取相对路径
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
    
    NSString *funcJs = paramsStr.length ? [NSString stringWithFormat:@"(%@)(\"%@\");", funcName, paramsStr] : [NSString stringWithFormat:@"(%@)();", funcName];
    
    // typeof fund === 'function'
    NSString *js = [NSString stringWithFormat:@"\
          (function () {\
              try {\
                      if (Object.prototype.toString.call(window.%@) === '[object Function]') {\
                        return %@\
                      } else {\
                        return '%@ is ' + Object.prototype.toString.call(window.%@);\
                      }\
                  }\
              catch (error) {\
                  return error.toString();\
              }\
          })();", funcName, funcJs, funcName, funcName];
    
    [self evaluateJs:js completionHandler:^(id res, NSError *error) {
        if (error) {
            NSLog(@"----❌js:function:%@--error:%@--", funcName, error);
        }else{
//            NSLog(@"----✅js:function:%@--返回值:%@--", funcName, res?:@"void");
        }
        if (completionHandler) completionHandler(res, error);
    }];
}
- (void)evaluateJs:(NSString *)js completionHandler:(void (^)(id res, NSError *error))completionHandler{
    if ([[NSThread currentThread] isEqual:[NSThread mainThread]]) {
        [self evaluateJsThreadSafe:js completionHandler:completionHandler];
        return;
    }
    __weak __typeof__(self) __self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [__self evaluateJsThreadSafe:js completionHandler:completionHandler];
    });
}
- (void)evaluateJsThreadSafe:(NSString *)js completionHandler:(void (^)(id res, NSError *error))completionHandler{
    // evaluateJavaScript 只允许主线程回调
    if (@available(iOS 9.0, *)) {
        __weak __typeof__(self) __self = self;
        [self evaluateJavaScript:js completionHandler:^(id res, NSError *error) {
            if (error) {
                [__self.handler showWebViewException:error.userInfo];
            }
            if (completionHandler) completionHandler(res, error);
        }];
        return;
    }
    /** iOS8 crash问题
         调用evaluateJavaScript函数，如果此时WKWebView退出dealloc，会导致completionHandler block释放，
         此时JS代码还在执行，等待JavaScriptCore执行完毕，准备回调completionHandler，发生野指针错误。
     iOS9，苹果已修复此问题
        https://zhuanlan.zhihu.com/p/24990222
        https://trac.webkit.org/changeset/179160/webkit
        不再提前获取completionHandler，准备回调时再获取completionHandler
     修复：
        completionHandler强引用WKWebView，推迟WKWebView及completionHandler的释放，待completionHandler执行完成后，
        completionHandler会自动销毁，WKWebView释放。
     */
    __strong __typeof__(self) strongSelf = self;
    [self evaluateJavaScript:js completionHandler:^(id res, NSError *error) {
        //强引用WebView
        strongSelf;
        if (error) {
            [strongSelf.handler showWebViewException:error.userInfo];
        }
        if (completionHandler) completionHandler(res, error);
    }];
}
- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler{
    [super evaluateJavaScript:javaScriptString completionHandler:completionHandler];
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

/* 调用顺序
 网页加载成功 ： www.baidu.com
 decidePolicyForNavigationAction
 didStartProvisionalNavigation
 decidePolicyForNavigationResponse
 didCommitNavigation
 didFinishNavigation
 
 网页加载失败 ： www.xxx.com
 decidePolicyForNavigationAction
 didStartProvisionalNavigation
 didFailProvisionalNavigation
 */
// Decides whether to allow or cancel a navigation.
- (void)webView:(ZHWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    
//    NSLog(@"lbz-web-%s", __func__);
    id <ZHWKNavigationDelegate> de = self.zh_navigationDelegate;
    if (ZHCheckDelegate(de, _cmd)) {
        [de webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
        return;
    }
    
    if ([navigationAction.request.URL.scheme isEqualToString:@"file"]) {
        if (decisionHandler) decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    if (decisionHandler) decisionHandler(WKNavigationActionPolicyAllow);
}
// Decides whether to allow or cancel a navigation after its response is known.
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
//    NSLog(@"lbz-web-%s", __func__);
    id <ZHWKNavigationDelegate> de = self.zh_navigationDelegate;
    if (ZHCheckDelegate(de, _cmd)) {
        return [de webView:webView decidePolicyForNavigationResponse:navigationResponse decisionHandler:decisionHandler];
    }
    if (decisionHandler) decisionHandler(WKNavigationResponsePolicyAllow);
}
//  Invoked when a main frame navigation starts.
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation{
//    NSLog(@"lbz-web-%s", __func__);
    id <ZHWKNavigationDelegate> de = self.zh_navigationDelegate;
    if (ZHCheckDelegate(de, _cmd)) {
        return [de webView:webView didStartProvisionalNavigation:navigation];
    }
}
// nvoked when a server redirect is received for the main frame.
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation{
//    NSLog(@"lbz-web-%s", __func__);
    id <ZHWKNavigationDelegate> de = self.zh_navigationDelegate;
    if (ZHCheckDelegate(de, _cmd)) {
        return [de webView:webView didReceiveServerRedirectForProvisionalNavigation:navigation];
    }
}
// Invoked when an error occurs while starting to load data for the main frame.
- (void)webView:(ZHWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    if (webView.loadFinish) webView.loadFinish(nil, ZHInlineError(error.code, ZHLCInlineString(@"%@", error.zh_localizedDescription)));
//    NSLog(@"lbz-web-%s", __func__);
    NSLog(@"-----❌didFailProvisionalNavigation---------------");
    NSLog(@"%@",error);
    
    id <ZHWKNavigationDelegate> de = self.zh_navigationDelegate;
    if (ZHCheckDelegate(de, _cmd)) {
        return [de webView:webView didFailProvisionalNavigation:navigation withError:error];
    }
}
// Invoked when content starts arriving for the main frame.
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation{
//    NSLog(@"lbz-web-%s", __func__);
    id <ZHWKNavigationDelegate> de = self.zh_navigationDelegate;
    if (ZHCheckDelegate(de, _cmd)) {
        return [de webView:webView didCommitNavigation:navigation];
    }
}
// Invoked when a main frame navigation completes.
- (void)webView:(ZHWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
//    NSLog(@"lbz-web-%s", __func__);
    if (webView.loadFinish) webView.loadFinish(nil, nil);
    
    id <ZHWKNavigationDelegate> de = self.zh_navigationDelegate;
    if (ZHCheckDelegate(de, _cmd)) {
        return [de webView:webView didFinishNavigation:navigation];
    }
}
// Invoked when an error occurs during a committed main frame navigation.
- (void)webView:(ZHWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
//    NSLog(@"lbz-web-%s", __func__);
    if (webView.loadFinish) webView.loadFinish(nil, ZHInlineError(error.code, ZHLCInlineString(@"%@", error.zh_localizedDescription)));
    
    id <ZHWKNavigationDelegate> de = self.zh_navigationDelegate;
    if (ZHCheckDelegate(de, _cmd)) {
        return [de webView:webView didFailNavigation:navigation withError:error];
    }
}
//- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{
//    id <ZHWKNavigationDelegate> de = self.zh_navigationDelegate;
//    if (ZHCheckDelegate(de, _cmd)) {
//        return [de webView:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
//    }
//}
//当WKWebView总体内存占用过大，页面即将白屏的时候，系统会调用上面的回调函数，我们在该函数里执行[webView reload]（这个时候webView.URL取值尚不为零）解决白屏问题。在一些高内存消耗的页面可能会频繁刷新当前页面
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView{
    if ([ZHJSDebugMg() availableIOS9]) {
        // webview content进程被系统终结，抛出异常
        NSDictionary *exceptionInfo = @{
            @"reason": @"The web view whose underlying web content process was terminated.",
            @"address": [NSString stringWithFormat:@"%p", self],
            @"stack": [NSString stringWithFormat:@"%s", __func__],
        };
        self.exceptionInfo = exceptionInfo;
        self.didTerminate = YES;

        id <ZHWKNavigationDelegate> de = self.zh_navigationDelegate;
        if (ZHCheckDelegate(de, _cmd)) {
            [de webViewWebContentProcessDidTerminate:webView];
        }else{
            [self.handler showWebViewException:exceptionInfo];
        }
    }
}

#pragma mark - WKUIDelegate

// 页面是弹出窗口 _blank 处理
- (WKWebView *)webView:(ZHWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    id <ZHWKUIDelegate> de = self.zh_UIDelegate;
    if (ZHCheckDelegate(de, _cmd)) {
        return [de webView:webView createWebViewWithConfiguration:configuration forNavigationAction:navigationAction windowFeatures:windowFeatures];
    }
    
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}
- (void)webViewDidClose:(WKWebView *)webView{
    if (![ZHJSDebugMg() availableIOS9]) return;
    id <ZHWKUIDelegate> de = self.zh_UIDelegate;
    if (ZHCheckDelegate(de, _cmd)) {
        return [de webViewDidClose:webView];
    }
}
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    id <ZHWKUIDelegate> de = self.zh_UIDelegate;
    if (ZHCheckDelegate(de, _cmd)) {
        return [de webView:webView runJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    }
    
    // 默认实现
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (completionHandler) completionHandler();
    }];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:action];
    UIViewController *router_ctrl = self.globalConfig.apiOpConfig.router_navigationController?:[self.handler fetchActivityCtrl];
    [router_ctrl presentViewController:alert animated:YES completion:nil];
}
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler{
    id <ZHWKUIDelegate> de = self.zh_UIDelegate;
    if (ZHCheckDelegate(de, _cmd)) {
        return [de webView:webView runJavaScriptConfirmPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    }
    
    // 默认实现
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (completionHandler) completionHandler(YES);
    }];
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (completionHandler) completionHandler(NO);
    }];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:action1];
    [alert addAction:action2];
    
    UIViewController *router_ctrl = self.globalConfig.apiOpConfig.router_navigationController?:[self.handler fetchActivityCtrl];
    [router_ctrl presentViewController:alert animated:YES completion:nil];
}
//处理js的同步消息
-(void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler{
    __weak __typeof__(self) weakSelf = self;
    void (^block) (void) = ^(void){
        id <ZHWKUIDelegate> de = weakSelf.zh_UIDelegate;
        if (ZHCheckDelegate(de, _cmd)) {
           [de webView:webView runJavaScriptTextInputPanelWithPrompt:prompt defaultText:defaultText initiatedByFrame:frame completionHandler:completionHandler];
           return;
        }
        
        // 默认实现
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:prompt message:defaultText preferredStyle:UIAlertControllerStyleAlert];
        __weak __typeof__(alert) weakAlert = alert;
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (completionHandler) completionHandler(weakAlert.textFields[0].text);
        }];
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            if (completionHandler) completionHandler(nil);
        }];
        [alert addAction:action1];
        [alert addAction:action2];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        }];
        UIViewController *router_ctrl = weakSelf.globalConfig.apiOpConfig.router_navigationController?:[weakSelf.handler fetchActivityCtrl];
        [router_ctrl presentViewController:alert animated:YES completion:nil];
    };
    
    if (!prompt || ![prompt isKindOfClass:NSString.class] || prompt.length == 0) {
        block();
        return;
    }
    
    NSData *promptData = [prompt dataUsingEncoding:NSUTF8StringEncoding];
    if (!promptData || ![promptData isKindOfClass:NSData.class] || promptData.length == 0) {
        block();
        return;
    }
    
    NSError *error;
    NSDictionary *receiveInfo = [NSJSONSerialization JSONObjectWithData:[prompt dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
    
    if (error || !receiveInfo || ![receiveInfo isKindOfClass:NSDictionary.class] || receiveInfo.allKeys.count == 0) {
        block();
        return;
    }
    
    // 检查是否允许处理此消息
    if (![self.handler allowHandleScriptMessage:receiveInfo]) {
        block();
        return;
    }
    
    // 说明此函数是api调用过来的
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
        data = [NSJSONSerialization dataWithJSONObject:result options:kNilOptions error:nil];
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

#pragma mark - ZHJSPageProtocol

// renderUrl
- (NSURL *)zh_renderURL{
    return self.renderURL;
}
- (NSURL *)zh_runSandBoxURL{
    return self.runSandBoxURL;
}
// pageitem
- (ZHJSPageItem *)zh_pageItem{
    return self.webItem;
}
// pageId
- (NSString *)zh_pageApplicationId{
    NSString *appId = self.webItem.appId;
    if (!appId || ![appId isKindOfClass:NSString.class] || appId.length == 0) {
        return [NSString stringWithFormat:@"%p", self];
    }
    return appId;
}

// api
- (id <ZHJSPageApiOpProtocol>)zh_apiOp{
    return self.globalConfig.apiOpConfig;
}

#pragma mark - UIScrollViewDelegate

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

//获取webView的内置zip资源临时解压目录
- (NSString *)fetchPresetUnzipTmpFolder{
    NSString *boxFolder = [NSString stringWithFormat:@"%p", self];
    return [ZHWebViewPresetUnzipTmpFolder() stringByAppendingPathComponent:boxFolder];
}
//获取webView准备运行沙盒
- (NSString *)fetchReadyRunSandBox{
    NSString *boxFolder = [NSString stringWithFormat:@"%p", self];
    if ([ZHJSDebugMg() availableIOS9]) {
        return [ZHWebViewFolder() stringByAppendingPathComponent:boxFolder];
    }
    return [ZHWebViewTmpFolder() stringByAppendingPathComponent:boxFolder];
}

#pragma mark - getter

- (NSLock *)lock{
    if (!_lock) {
        _lock = [[NSLock alloc] init];
    }
    return _lock;
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
        NSData *jsonData = nil;
        @try {
            // 当原生传来的json中包含有NSObject对象，数据解析异常导致crash
            jsonData = [NSJSONSerialization dataWithJSONObject:data options:kNilOptions error:&jsonError];
        } @catch (NSException *exception) {
            jsonData = [NSJSONSerialization dataWithJSONObject:@{} options:kNilOptions error:&jsonError];
        } @finally {
        }
        if (jsonError || !jsonData) return nil;
        res = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }else if ([data isKindOfClass:[NSObject class]]){
        res = [data description];
    }else{
        //默认obj作为BOOL值处理
        res = [NSString stringWithFormat:@"%d",data];
    }
    
    NSString *(^block)(NSString *) = ^NSString *(NSString *str){
        return [str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    };
    if (@available(iOS 8.3, *)) {
        return block(res);
    }
    /** iOS8.2以下对于 较长的中文字符串 编码存在内存问题，导致crash
     https://stackoverflow.com/questions/44309415/stack-overflow-in-nsstringnsurlutilities-stringbyaddingpercentencodingwithal
     https://github.com/Alamofire/Alamofire/issues/206
     将字符串分割操作
     */
    if (res.length < 400) {
        return block(res);
    }
    NSMutableString *newRes = [NSMutableString string];
    NSInteger totalCount = res.length;
    NSInteger batchSize = 100;
    for (NSUInteger i = 0; i < totalCount; i += batchSize) {
        NSInteger rangeLength = i + batchSize > totalCount ? totalCount - i : batchSize;
        [newRes appendString:block([res substringWithRange:NSMakeRange(i, rangeLength)])];
    }
    return newRes.copy;
}

#pragma mark - clear

+ (void)clearWebViewSystemCache:(void (^) (void))complete{
    if ([ZHJSDebugMg() availableIOS9]) {
        WKWebsiteDataStore *dataSource = [WKWebsiteDataStore defaultDataStore];
//        NSMutableSet *set = [WKWebsiteDataStore allWebsiteDataTypes];
        NSMutableSet *set = [NSMutableSet set];
        [set addObjectsFromArray:@[
            WKWebsiteDataTypeDiskCache,//硬盘缓存
            WKWebsiteDataTypeMemoryCache,//内存缓存
            WKWebsiteDataTypeOfflineWebApplicationCache//离线应用缓存
//            WKWebsiteDataTypeCookies,//cookie
//            WKWebsiteDataTypeSessionStorage,//session
//            WKWebsiteDataTypeLocalStorage,//localStorage,cookie的一个兄弟
//            WKWebsiteDataTypeWebSQLDatabases,//数据库
//            WKWebsiteDataTypeIndexedDBDatabases//索引数据库
        ]];
        if (@available(iOS 11.3, *)) {
            [set addObjectsFromArray:@[
                WKWebsiteDataTypeFetchCache,//硬盘fetch缓存
                WKWebsiteDataTypeServiceWorkerRegistrations
            ]];
        }
        [dataSource removeDataOfTypes:set modifiedSince:[NSDate dateWithTimeIntervalSince1970:0] completionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (complete) complete();
            });
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
    if (complete) complete();
}

#pragma mark - dealloc

- (void)dealloc{
    @try {
        WKUserContentController *userContent = self.configuration.userContentController;
        [userContent removeAllUserScripts];

        NSArray *handlerNames = [self.class fetchHandlerNames];
        for (NSString *key in handlerNames) {
            [userContent removeScriptMessageHandlerForName:key];
        }
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
//    //不能在此清理缓存文件  可能直接用的WebView加载路径 没有创建独立沙盒路径  dealloc里面不能用self
//    NSFileManager *fm = [NSFileManager defaultManager];
//    NSString *folder1 = [self fetchReadyRunSandBox];
//    NSString *folder2 = self.runSandBoxURL.path;
//    if ([fm fileExistsAtPath:folder1]) {
//        [fm removeItemAtPath:folder1 error:nil];
//    }
//    if ([fm fileExistsAtPath:folder2]) {
//        [fm removeItemAtPath:folder2 error:nil];
//    }
    
    NSLog(@"%s", __func__);
}

@end
