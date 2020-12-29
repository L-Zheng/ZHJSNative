//
//  ZHController.m
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHController.h"
#import "ZHWebView.h"
#import "ZHWebViewConfiguration.h"
#import "ZHJSApiProtocol.h"
#import "ZHJSContext.h"
#import "ZHWebViewManager.h"
#import "ZHCustomApiHandler.h"
#import "ZHCustom1ApiHandler.h"
#import "ZHCustomExtra1ApiHandler.h"

#import "ZHCustomApiHandler.h"
#import "ZHCustom1ApiHandler.h"
#import "ZHCustom2ApiHandler.h"

@interface ZHController ()<ZHWebViewSocketDebugDelegate>
@property (nonatomic, strong) ZHWebView *webView;
@property (nonatomic, strong) ZHJSContext *context;

@property (nonatomic,strong) WKProcessPool *processPool;
@end

@implementation ZHController

- (NSArray <id <ZHJSApiProtocol>> *)apiHandlers{
    return @[[[ZHCustomApiHandler alloc] init], [[ZHCustom1ApiHandler alloc] init], [[ZHCustom2ApiHandler alloc] init]];
}

- (NSString *)currentTemplateKey{
    //appid
    return @"preReadyWebViewKey";
}

- (NSString *)currentTemplateLoadName{
    return @"index.html";
}
- (NSString *)currentTemplatePresetFolder{
    return [[[NSBundle mainBundle] pathForResource:@"TestBundle" ofType:@"bundle"] stringByAppendingPathComponent:@"release"];
}

- (WKProcessPool *)processPool{
    if (!_processPool) {
        _processPool = [[WKProcessPool alloc] init];
    }
    return _processPool;
}

- (ZHWebViewConfiguration *)createConfig{
    ZHWebViewAppletConfiguration *appletConfig = [ZHWebViewAppletConfiguration new];
    appletConfig.appId = [self currentTemplateKey];
    appletConfig.loadFileName = [self currentTemplateLoadName];
    appletConfig.presetFilePath = [self currentTemplatePresetFolder];
    
    ZHWebViewCreateConfiguration *createConfig = [ZHWebViewCreateConfiguration new];
    createConfig.frameValue = [NSValue valueWithCGRect:[UIScreen mainScreen].bounds];
    createConfig.processPool = [self processPool];
    createConfig.apiHandlers = [self apiHandlers];
    createConfig.extraScriptStart = @"var testGlobalFunc = function (params) {var res = JSON.parse(decodeURIComponent(params));console.log(res);return true;}";
    
    ZHWebViewLoadConfiguration *loadConfig = [ZHWebViewLoadConfiguration new];
    loadConfig.cachePolicy = nil;
    loadConfig.timeoutInterval = nil;
    loadConfig.readAccessURL = [NSURL fileURLWithPath:[ZHWebView getDocumentFolder]];
    
    
    ZHWebViewConfiguration *config = [ZHWebViewConfiguration new];
    config.appletConfig = appletConfig;
    config.createConfig = createConfig;
    config.loadConfig = loadConfig;
    
    return config;
}

- (ZHJSContextConfiguration *)createContextConfig{
    ZHJSContextAppletConfiguration *appletConfig = [ZHJSContextAppletConfiguration new];
    appletConfig.appId = nil;
    appletConfig.envVersion = nil;
    appletConfig.loadFileName = nil;
    appletConfig.presetFilePath = nil;
    appletConfig.presetFileInfo = nil;
    
    ZHJSContextCreateConfiguration *createConfig = [ZHJSContextCreateConfiguration new];
    createConfig.apiHandlers = [self apiHandlers];
    
    ZHJSContextLoadConfiguration *loadConfig = [ZHJSContextLoadConfiguration new];
    
    ZHJSContextConfiguration *config = [ZHJSContextConfiguration new];
    config.appletConfig = appletConfig;
    config.createConfig = createConfig;
    config.loadConfig = loadConfig;
    
    return config;
}

- (void)preLoad{
    //预加载
    [[ZHWebViewManager shareManager] preReadyWebView:[self createConfig] finish:^(NSDictionary *info, NSError *error) {
        NSLog(@"--------------------");
        
        //预加载完成不能立即使用： webView loadSuccess只是加载成功  里面的内容还没有配置完成
        //        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //            [self readyLoadWebView];
        //        });
    }];
}

- (void)btnClick{
    NSLog(@"--------------------");
}

- (void)testJSContext{
    
    //运算js
    ZHJSContextConfiguration *contextConfig = [self createContextConfig];
    self.context = [[ZHJSContext alloc] initWithGlobalConfig:contextConfig];
    NSURL *url = [NSURL fileURLWithPath:[[[NSBundle mainBundle] pathForResource:@"TestBundle" ofType:@"bundle"] stringByAppendingPathComponent:@"test.js"]];
    [self.context renderWithUrl:url baseURL:nil loadConfig:contextConfig.loadConfig loadStartBlock:^(NSURL *runSandBoxURL) {
        
    } loadFinishBlock:^(NSDictionary *info, NSError *error) {
        NSLog(@"--------------------");
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(100, 50, 100, 100)];
    bgView.backgroundColor = [UIColor redColor];
    [self.view addSubview:bgView];
    
    UIButton *bgBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 180, 100, 100)];
    bgBtn.backgroundColor = [UIColor greenColor];
    [self.view addSubview:bgBtn];
    [bgBtn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    
//    [self preLoad];
    
    [self configView];
    [self readyLoadWebView];
//
////    ZHCustomExtra1ApiHandler *extr1 = [ZHCustomExtra1ApiHandler new];
////    [self.context addApiHandlers:@[extr1] completion:^(NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, id res, NSError *error) {
////        JSValue *addApiTestValue = [self.context objectForKeyedSubscript:@"addApiTest"];
////        [addApiTestValue callWithArguments:@[]];
////
////
////        [self.context removeApiHandlers:@[extr1] completion:^(NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, id res, NSError *error) {
////            JSValue *addApiTestValue = [self.context objectForKeyedSubscript:@"addApiTest"];
////            [addApiTestValue callWithArguments:@[]];
////
////        }];
////    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self configWebViewFrame:self.webView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self configNavigaitonBar:animated];
    NSLog(@"----✅viewWillAppear----");
    
    if (self.webView.didTerminate) {
        ZHWebViewManager *mg = [ZHWebViewManager shareManager];
        __weak __typeof__(self) weakSelf = self;
        [mg loadWebView:self.webView config:weakSelf.webView.globalConfig finish:^(NSDictionary *info, NSError *error) {
            if (error) return;
            [weakSelf configWebView:weakSelf.webView];
            [weakSelf renderWebView:weakSelf.webView];
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    NSLog(@"----✅viewDidAppear----");
    [self configGesture];
}

- (void)configView{
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)configNavigaitonBar:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    UINavigationBar *bar = self.navigationController.navigationBar;
    bar.translucent = NO;
}

- (void)readyLoadWebView{
    ZHWebViewManager *mg = [ZHWebViewManager shareManager];
    //查找可用WebView
    ZHWebView *webView = [mg fetchWebView:[self currentTemplateKey]];
    if (webView) {
        //检查是否异常
        ZHWebViewExceptionOperate operate = [webView checkException];
        if (operate == ZHWebViewExceptionOperateNothing) {
            [self configWebView:webView];
            [self renderWebView:webView];
            //预加载新的webview
//            [self preLoad];
            return;
        }else if (operate == ZHWebViewExceptionOperateReload){
        }else if (operate == ZHWebViewExceptionOperateNewInit){
            webView = [[ZHWebView alloc] initWithGlobalConfig:[self createConfig]];
        }
    }else{
        webView = [[ZHWebView alloc] initWithGlobalConfig:[self createConfig]];
    }
    
    [self doLoadWebView:webView];
    if (!webView.superview) [self.view addSubview:webView];
    //预加载新的webview
//    [self preLoad];
}

- (void)doLoadWebView:(ZHWebView *)webView{
    ZHWebViewManager *mg = [ZHWebViewManager shareManager];
    __weak __typeof__(self) __self = self;
    [mg loadWebView:webView config:webView.globalConfig finish:^(NSDictionary *info, NSError *error) {
        if (error) return;
        [__self configWebView:webView];
        [__self renderWebView:webView];
    }];
}

- (void)renderWebView:(ZHWebView *)webView{
    self.navigationItem.title = webView.title;
    [self readyRender:nil];
}
- (void)configWebView:(ZHWebView *)webView{
    //配置view
    [self configWebViewFrame:webView];
    if (!webView.superview) [self.view addSubview:webView];
    self.webView = webView;
    //配置代理
    [self configWebViewDelegate:webView target:self];
    //配置handler
}
- (void)configWebViewFrame:(WKWebView *)webView{
    if (@available(iOS 11.0, *)) {
        webView.frame = (CGRect){CGPointZero, {self.view.bounds.size.width, self.view.bounds.size.height - self.view.safeAreaInsets.bottom}};
    } else {
        webView.frame = self.view.bounds;
    }
}
- (void)configWebViewDelegate:(ZHWebView *)webView target:(id)target{
    webView.zh_navigationDelegate = target;
    webView.zh_UIDelegate = target;
    webView.zh_socketDebugDelegate = target;
}

- (void)configGesture{
    @try {
        NSArray *internalTargets = [self.navigationController.interactivePopGestureRecognizer valueForKey:@"targets"];
        id internalTarget = [internalTargets.firstObject valueForKey:@"target"];
        UIScreenEdgePanGestureRecognizer *panGes = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:internalTarget action:@selector(handleNavigationTransition:)];
        panGes.edges = UIRectEdgeLeft;
        [self.view addGestureRecognizer:panGes];
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
}

- (void)readyRender11:(NSDictionary *)info{
    [self.webView renderLoadPage:[NSURL fileURLWithPath:@"/Users/em/Desktop/EMCode/other-person/h5-hybrid/dist1"] jsSourceURL:[NSURL fileURLWithPath:@"/Users/em/Desktop/EMCode/other-person/h5-hybrid/dist1/js/index.js"] completionHandler:^(id res, NSError *error) {
        NSLog(@"--------------------");
    }];
}
- (void)readyRender:(NSDictionary *)info{
    info = @{
        @"code": @"cccccc",
    };
    if (!info) return;
        
    id (^block)(id res) = ^(id res){
        return [ZHWebView encodeObj:res];
    };
    
    NSString *jsonStr = block(info);
    
    NSString *desc = @"renderFundDetail";
    
    NSLog(@"----✅start %@---", desc);
    NSLog(@"----👇jsCode %@ start--", desc);
    
    NSString *js = [NSString stringWithFormat:@"render(\"%@\")",jsonStr];
    NSLog(@"%@", js);
    NSLog(@"----☝️jsCode %@ end--", desc);
    //    NSString *js = [NSString stringWithFormat:@"renderA(\"%@\")",type];
    [self.webView evaluateJs:js completionHandler:^(id res, NSError *error) {
        if (error) {
            NSLog(@"----❌%@--%@--", desc, error);
        }else{
            NSLog(@"----✅%@---", desc);
        }
//        ZHCustomExtra1ApiHandler *extraApi = [ZHCustomExtra1ApiHandler new];
//        [self.webView addApiHandlers:@[extraApi] completion:^(NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, id res, NSError *error) {
//            NSLog(@"--------------------");
//            [self.webView evaluateJs:@"window.addApiTest();" completionHandler:^(id res, NSError *error) {
//                NSLog(@"--------------------");
//
//
//                [self.webView removeApiHandlers:@[extraApi] completion:^(NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, id res, NSError *error) {
//                    NSLog(@"--------------------");
//
//                    [self.webView evaluateJs:@"window.addApiTest();" completionHandler:^(id res, NSError *error) {
//                        NSLog(@"--------------------");
//                    }];
//
//                }];
//
//            }];
//        }];
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (object == self.webView) {
        if ([keyPath isEqualToString:@"loading"]) {
            return;
        }
        if ([keyPath isEqualToString:@"title"]){
            self.title = self.webView.title;
            return;
        }
        if ([keyPath isEqualToString:@"estimatedProgress"]){
            NSLog(@"%f",self.webView.estimatedProgress);
//            [self.progressView setProgress:self.webView.estimatedProgress animated:YES];
//            if (self.progressView.progress == 1.0) {
//                __weak __typeof__(self) __self = self;
//                [UIView animateWithDuration:0.55 animations:^{
//                    __self.progressView.alpha = 0.0;
//                }];
//            }
            return;
        }
    }
    
    if ([keyPath isEqualToString:@"contentSize"] &&
        object == self.webView.scrollView) {
        if (@available(iOS 9.0, *)) {
            __weak __typeof__(self) __self = self;
            [self.webView evaluateJavaScript:@"document.body.offsetHeight;" completionHandler:^(id _Nullable object, NSError * _Nullable error) {
                if (!error) {
                    // 网页内容高度
                    CGFloat bodyHeight = [object floatValue];
                    CGFloat webViewHeight = __self.webView.frame.size.height;
                    if (fabs(webViewHeight - bodyHeight) > 2) {
//                        NSLog(@"**************body--height = %@", @(bodyHeight));
//                        NSLog(@"**************webView--height = %@", @(webViewHeight));
                        //                    [weakSelf fireEvent:EF_WEB_PAGE_HEIGHT_CHANGE params:@{@"pageHeight": @(bodyHeight/weakSelf.weexInstance.pixelScaleFactor)}];
                    }
                }
            }];
        }else {
            CGFloat webHeight = self.webView.frame.size.height;
            CGFloat newHeight = [change[NSKeyValueChangeNewKey] CGSizeValue].height;
            if (fabs(webHeight - newHeight) > 2 && newHeight > 0) {
                //            [self fireEvent:EF_WEB_PAGE_HEIGHT_CHANGE params:@{@"pageHeight": @(newHeight/self.weexInstance.pixelScaleFactor)}];
            }
//            NSLog(@"changeNew: %@", NSStringFromCGSize(self.webView.scrollView.contentSize));
        }
    }
}

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

#pragma mark - ZHWebViewSocketDebugDelegate

- (void)webViewReadyRefresh:(ZHWebView *)webView{
}
- (void)webViewRefresh:(ZHWebView *)webView debugModel:(ZHWebViewDebugModel)debugModel info:(NSDictionary *)info{
    
    [self doLoadWebView:webView];
}
@end
