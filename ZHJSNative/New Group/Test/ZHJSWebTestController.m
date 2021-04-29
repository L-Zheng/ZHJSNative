//
//  ZHJSWebTestController.m
//  ZHJSNative
//
//  Created by EM on 2021/4/25.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHJSWebTestController.h"
#import "ZHWebView.h"
#import "ZHJSHandler.h"

@interface ZHJSWebTestApi : NSObject<ZHJSApiProtocol>
@property (nonatomic,weak) ZHWebView *webView;
@end
@implementation ZHJSWebTestApi

- (void)js_xxx:(ZHJSApiArgItem *)arg{
}

#pragma mark - page

- (id <ZHJSPageProtocol>)jsPage{
    return self.webView;
}

#pragma mark - ZHJSApiProtocol

//js api方法名前缀  如：fund
- (NSString *)zh_jsApiPrefixName{
    return @"fund";
}
//ios api方法名前缀 如：js_
- (NSString *)zh_iosApiPrefixName{
    return @"js_";
}
@end

@interface ZHJSWebTestController ()<ZHWebViewDebugSocketDelegate, ZHWebViewExceptionDelegate, ZHWKNavigationDelegate>
@property (nonatomic, strong) ZHWebView *webView;
@property (nonatomic,strong) WKProcessPool *processPool;

@end

@implementation ZHJSWebTestController

#pragma mark - life cycle

- (void)viewDidLoad{
    [super viewDidLoad];
    
    [self configView];
    [self readyLoadWebView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self configWebViewFrame:self.webView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self configNavigaitonBar:animated];
    
    if (self.webView.didTerminate) {
        [self doLoadWebView:self.webView];
    }
}

#pragma mark - config

- (void)configView{
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)configNavigaitonBar:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    UINavigationBar *bar = self.navigationController.navigationBar;
    bar.translucent = NO;
    bar.barTintColor = [UIColor whiteColor];
}

- (void)configWebView:(ZHWebView *)webView{
    //配置view
    [self configWebViewFrame:webView];
    if (!webView.superview) [self.view addSubview:webView];
    self.webView = webView;
    //配置代理
    [self configWebViewDelegate:webView target:self];
}
- (void)configWebViewFrame:(WKWebView *)webView{
    if (@available(iOS 11.0, *)) {
        webView.frame = (CGRect){CGPointZero, {self.view.bounds.size.width, self.view.bounds.size.height - self.view.safeAreaInsets.bottom}};
    } else {
        webView.frame = self.view.bounds;
    }
}
- (void)configWebViewDelegate:(ZHWebView *)webView target:(id)target{
    webView.zh_debugSocketDelegate = target;
    webView.zh_exceptionDelegate = target;
    webView.zh_navigationDelegate = target;
    webView.zh_UIDelegate = target;
}

#pragma mark - load

- (void)readyLoadWebView{
    ZHWebView *webView = [[ZHWebView alloc] initWithGlobalConfig:[self createConfig]];
    NSArray *arr = [self apis];
    for (NSObject *apiObj in arr) {
        if ([apiObj isKindOfClass:ZHJSWebTestApi.class]) {
            ((ZHJSWebTestApi *)apiObj).webView = webView;
        }
    }
    
    [self doLoadWebView:webView];
    if (!webView.superview) [self.view addSubview:webView];
}

- (void)doLoadWebView:(ZHWebView *)webView{
    __weak __typeof__(self) __self = self;
    
    ZHWebDebugMode debugMode = webView.debugItem.debugMode;
    
    // 加载h5跟目录(此目录必须在App沙盒内)
    NSString *loadFolder = nil;
    // 加载h5文件相对路径
    NSString *loadFileName = @"/index.html";
    // 加载线上h5地址
    NSString *loadOnlineUrlStr = @"https://www.baidu.com";
    
    // 线上release模式
    if (debugMode == ZHWebDebugMode_Release) {
//        [self LoadLocalWebView:webView loadFileName:loadFileName loadFolder:loadFolder finish:^(NSDictionary *info, NSError *error) {
//            if (error) return;
//            [__self configWebView:webView];
//            [__self renderWebView:webView];
//        }];
        
        [self loadOnlineWebView:webView url:[NSURL URLWithString:loadOnlineUrlStr] finish:^(NSDictionary *info, NSError *error) {
            if (error) return;
            [__self configWebView:webView];
            [__self renderWebView:webView];
        }];
        return;
    }
    
    // 本机调试模式
    if (debugMode == ZHWebDebugMode_Local) {
        loadFolder = webView.debugItem.localUrlStr;
        [webView loadLocalDebug:loadFileName loadFolder:loadFolder finish:^(NSDictionary *info, NSError *error) {
            if (error) return;
            [__self configWebView:webView];
            [__self renderWebView:webView];
        }];
//        // 拷贝到临时目录
//        NSString *baseFolder = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.jijin.webview"];
//        NSString *tempFolder = [baseFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%p", webView]];
//        NSFileManager *fm = [NSFileManager defaultManager];
//        if (![fm fileExistsAtPath:baseFolder]) {
//            [fm createDirectoryAtPath:baseFolder withIntermediateDirectories:YES attributes:nil error:nil];
//        }
//        if ([fm fileExistsAtPath:tempFolder]) {
//            [fm removeItemAtPath:tempFolder error:nil];
//        }
//        [fm copyItemAtPath:loadFolder toPath:tempFolder error:nil];
//        // 加载
//        [self LoadLocalWebView:webView loadFileName:loadFileName loadFolder:tempFolder finish:^(NSDictionary *info, NSError *error) {
//            if (error) return;
//            [__self configWebView:webView];
//            [__self renderWebView:webView];
//        }];
        return;
    }
    // socket调试模式
    if (debugMode == ZHWebDebugMode_Online) {
        [webView loadOnlineDebug:[NSURL URLWithString:webView.debugItem.socketUrlStr] startLoadBlock:^(NSURL *runSandBoxURL) {

        } finish:^(NSDictionary *info, NSError *error) {
            if (error) return;
            [__self configWebView:webView];
            [__self renderWebView:webView];
        }];
//        [self loadOnlineWebView:webView url:[NSURL URLWithString:webView.debugItem.socketUrlStr] finish:^(NSDictionary *info, NSError *error) {
//            if (error) return;
//            [__self configWebView:webView];
//            [__self renderWebView:webView];
//        }];
        return;
    }
}

/// 加载本地h5
/// @param webView webview
/// @param loadFileName 加载的h5相对路径
/// @param loadFolder WebView运行h5资源的根目录
/// @param finish finish
- (void)LoadLocalWebView:(ZHWebView *)webView
            loadFileName:(NSString *)loadFileName
              loadFolder:(NSString *)loadFolder
                  finish:(void (^) (NSDictionary *info, NSError *error))finish{
    if (!webView ||
        !loadFolder || ![loadFolder isKindOfClass:NSString.class] || loadFolder.length == 0 ||
        !loadFileName || ![loadFileName isKindOfClass:NSString.class] || loadFileName.length == 0) {
        if (finish) finish(nil, [NSError new]);
        return;
    }
    ZHWebLoadConfig *loadConfig = webView.globalConfig.loadConfig;
    
    loadConfig.readAccessURL = loadConfig.readAccessURL?:[NSURL fileURLWithPath:loadFolder];
    
    NSString *htmlPath = [loadFolder stringByAppendingPathComponent:loadFileName];
    
    NSURL *url = [NSURL fileURLWithPath:htmlPath];
    NSURL *baseURL = [NSURL fileURLWithPath:loadFolder isDirectory:YES];
    
    [webView loadWithUrl:url
                 baseURL:baseURL
              loadConfig:loadConfig
          startLoadBlock:^(NSURL *runSandBoxURL) {
    }
                  finish:^(NSDictionary *info, NSError *error) {
        if (finish) finish(error ? nil : info, error);
    }];
}
// 加载线上h5地址
- (void)loadOnlineWebView:(ZHWebView *)webView
                      url:(NSURL *)url
                   finish:(void (^) (NSDictionary *info, NSError *error))finish{
    if (!webView || !url || url.isFileURL) {
        if (finish) finish(nil, [NSError new]);
        return;
    }
    [webView loadWithUrl:url baseURL:nil loadConfig:webView.globalConfig.loadConfig startLoadBlock:^(NSURL *runSandBoxURL) {
        
    } finish:^(NSDictionary *info, NSError *error) {
        if (!error) {
        }
        if (finish) finish(info, error);
    }];
}

- (void)renderWebView:(ZHWebView *)webView{
    self.navigationItem.title = webView.title;
    [self readyRender:nil];
}

- (void)readyRender:(NSDictionary *)info{
    if (!info) return;
        
    id (^block)(id res) = ^(id res){
        return [ZHWebView encodeObj:res];
    };
    
    NSString *jsonStr = block(info);
    NSString *js = [NSString stringWithFormat:@"render(\"%@\")",jsonStr];
    //    NSString *js = [NSString stringWithFormat:@"renderA(\"%@\")",type];
    [self.webView evaluateJs:js completionHandler:^(id res, NSError *error) {
        if (error) {
            NSLog(@"----❌--%@--", error);
        }else{
            NSLog(@"----✅---");
        }
    }];
}

#pragma mark - ZHWKNavigationDelegate

- (void)webView:(ZHWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
}

- (void)webView:(ZHWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
}

- (void)webView:(ZHWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
}

- (void)webView:(ZHWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    if (decisionHandler) decisionHandler(WKNavigationActionPolicyAllow);
}

//当WKWebView总体内存占用过大，页面即将白屏的时候，系统会调用上面的回调函数，我们在该函数里执行[webView reload]（这个时候webView.URL取值尚不为零）解决白屏问题。在一些高内存消耗的页面可能会频繁刷新当前页面
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView{
}


#pragma mark - ZHWebViewExceptionDelegate

- (void)zh_webView:(ZHWebView *)webView exception:(NSDictionary *)exception{
    
}

#pragma mark - ZHWebViewDebugSocketDelegate

- (void)zh_webViewReadyRefresh:(ZHWebView *)webView{
}
- (void)zh_webViewStartRefresh:(ZHWebView *)webView{
    [self doLoadWebView:webView];
}

#pragma mark - dealloc

- (void)dealloc{
    [self clear];
    NSLog(@"%s", __func__);
}

- (void)clear{
    //清空代理 【scrollView.delegate】 否则iOS8上会崩溃
    if (!_webView) return;
    _webView.scrollView.delegate = nil;
    _webView.UIDelegate = nil;
    _webView.navigationDelegate = nil;
    
    _webView.zh_scrollViewDelegate = nil;
    _webView.zh_UIDelegate = nil;
    _webView.zh_navigationDelegate = nil;
    
    if (_webView.superview) [_webView removeFromSuperview];
    _webView = nil;
}

#pragma mark - getter

- (NSArray <id <ZHJSApiProtocol>> *)apis{
    return @[[[ZHJSWebTestApi alloc] init]];
}

- (WKProcessPool *)processPool{
    if (!_processPool) {
        _processPool = [[WKProcessPool alloc] init];
    }
    return _processPool;
}

- (ZHWebConfig *)createConfig{
    ZHWebMpConfig *mpConfig = nil;
//    mpConfig.appId = [self currentTemplateKey];
//    mpConfig.loadFileName = [self currentTemplateLoadName];
//    mpConfig.presetFilePath = [self currentTemplatePresetFolder];
    
    ZHWebCreateConfig *createConfig = [ZHWebCreateConfig new];
    createConfig.frameValue = [NSValue valueWithCGRect:[UIScreen mainScreen].bounds];
    createConfig.processPool = [self processPool];
    createConfig.apis = [self apis];
//    createConfig.extraScriptStart = @"var testGlobalFunc = function (params) {var res = JSON.parse(decodeURIComponent(params));console.log(res);return true;}";
    
    //配置controller
    ZHWebApiOpConfig *apiOpConfig = [[ZHWebApiOpConfig alloc] init];
    apiOpConfig.belong_controller = self;
    apiOpConfig.status_controller = self;
    apiOpConfig.navigationItem = self.navigationItem;
    apiOpConfig.navigationBar = self.navigationController.navigationBar;
    apiOpConfig.router_navigationController = self.navigationController;
    
    ZHWebLoadConfig *loadConfig = [ZHWebLoadConfig new];
    loadConfig.cachePolicy = nil;
    loadConfig.timeoutInterval = nil;
    loadConfig.readAccessURL = [NSURL fileURLWithPath:NSHomeDirectory()];
    
    ZHWebConfig *config = [ZHWebConfig new];
    config.mpConfig = mpConfig;
    config.createConfig = createConfig;
    config.loadConfig = loadConfig;
    config.apiOpConfig = apiOpConfig;
    
    return config;
}

@end
