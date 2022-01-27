//
//  ZHController.m
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHController.h"
#import "ZHWebView.h"
#import "ZHWebFetchConfig.h"
#import "ZHWebDebugItem.h"
#import "ZHJSApiProtocol.h"
#import "ZHJSContext.h"
#import "ZHWebViewManager.h"
#import "ZHJSDebugManager.h"
#import "ZHCustomApi.h"
#import "ZHCustom1Api.h"
#import "ZHCustomExtra1Api.h"

#import "ZHCustomApi.h"
#import "ZHCustom1Api.h"
#import "ZHCustom2Api.h"

@interface ZHController ()<ZHWebViewDebugSocketDelegate>
@property (nonatomic, strong) ZHWebView *webView;
@property (nonatomic, strong) ZHJSContext *context;

@property (nonatomic,strong) WKProcessPool *processPool;
@end

@implementation ZHController

- (NSArray <id <ZHJSApiProtocol>> *)apis{
    return @[[[ZHCustomApi alloc] init], [[ZHCustom1Api alloc] init], [[ZHCustom2Api alloc] init]];
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

- (ZHWebConfig *)createConfig{
    ZHWebMpConfig *mpConfig = [ZHWebMpConfig new];
    mpConfig.appId = [self currentTemplateKey];
    mpConfig.loadFileName = [self currentTemplateLoadName];
    mpConfig.presetFilePath = [self currentTemplatePresetFolder];
    
    ZHWebCreateConfig *createConfig = [ZHWebCreateConfig new];
    createConfig.frameValue = [NSValue valueWithCGRect:[UIScreen mainScreen].bounds];
    createConfig.processPool = [self processPool];
    createConfig.apis = [self apis];
    createConfig.extraScriptStart = @"var testGlobalFunc = function (params) {var res = JSON.parse(decodeURIComponent(params));console.log(res);return true;}";
    
    ZHWebLoadConfig *loadConfig = [ZHWebLoadConfig new];
    loadConfig.cachePolicy = nil;
    loadConfig.timeoutInterval = nil;
    loadConfig.readAccessURL = [NSURL fileURLWithPath:[ZHWebView getDocumentFolder]];
    
    
    ZHWebConfig *config = [ZHWebConfig new];
    config.mpConfig = mpConfig;
    config.createConfig = createConfig;
    config.loadConfig = loadConfig;
    
    return config;
}

- (ZHCtxConfig *)createContextConfig{
    ZHCtxMpConfig *mpConfig = [ZHCtxMpConfig new];
    mpConfig.appId = nil;
    mpConfig.envVersion = nil;
    mpConfig.loadFileName = nil;
    mpConfig.presetFilePath = nil;
    mpConfig.presetFileInfo = nil;
    
    ZHCtxCreateConfig *createConfig = [ZHCtxCreateConfig new];
    createConfig.apis = [self apis];
    
    ZHCtxLoadConfig *loadConfig = [ZHCtxLoadConfig new];
    
    ZHCtxConfig *config = [ZHCtxConfig new];
    config.mpConfig = mpConfig;
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
    ZHCtxConfig *contextConfig = [self createContextConfig];
    self.context = [[ZHJSContext alloc] initWithGlobalConfig:contextConfig];
    NSURL *url = [NSURL fileURLWithPath:[[[NSBundle mainBundle] pathForResource:@"TestBundle" ofType:@"bundle"] stringByAppendingPathComponent:@"test.js"]];
    [self.context renderWithUrl:url baseURL:nil loadConfig:contextConfig.loadConfig loadStartBlock:^(NSURL *runSandBoxURL) {
        
    } loadFinishBlock:^(NSDictionary *info, NSError *error) {
        NSLog(@"--------------------");
    }];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        JSValue *parseFunc = [self.context objectForKeyedSubscript:@"aa"];
//        [parseFunc callWithArguments:@[]];
//        [self.context evaluateScript:@"var bb = function(){console.log('22222222')}"];
//        parseFunc = [self.context objectForKeyedSubscript:@"aa"];
//        [parseFunc callWithArguments:@[]];
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//
//            JSValue *parseFunc = [self.context objectForKeyedSubscript:@"aa"];
//            [parseFunc callWithArguments:@[]];
//        });
//    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self testJSContext];
//    return;
    
    
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
////    ZHCustomExtra1Api *extr1 = [ZHCustomExtra1Api new];
////    [self.context addApis:@[extr1] completion:^(NSArray<id<ZHJSApiProtocol>> *successApis, NSArray<id<ZHJSApiProtocol>> *failApis, id res, NSError *error) {
////        JSValue *addApiTestValue = [self.context objectForKeyedSubscript:@"addApiTest"];
////        [addApiTestValue callWithArguments:@[]];
////
////
////        [self.context removeApis:@[extr1] completion:^(NSArray<id<ZHJSApiProtocol>> *successApis, NSArray<id<ZHJSApiProtocol>> *failApis, id res, NSError *error) {
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
    ZHWebFetchConfig *fetchConfig = [[ZHWebFetchConfig alloc] init];
    fetchConfig.appId = [self currentTemplateKey];
    fetchConfig.fullInfo = nil;
    ZHWebView *webView = [mg fetchWebView:fetchConfig];
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
    
    //配置controller
    ZHWebApiOpConfig *apiOpConfig = [[ZHWebApiOpConfig alloc] init];
    apiOpConfig.belong_controller = self;
    apiOpConfig.status_controller = self;
    apiOpConfig.navigationItem = self.navigationItem;
    apiOpConfig.navigationBar = self.navigationController.navigationBar;
    apiOpConfig.router_navigationController = self.navigationController;
    webView.globalConfig.apiOpConfig = apiOpConfig;
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
    webView.zh_debugSocketDelegate = target;
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
//        ZHCustomExtra1Api *extraApi = [ZHCustomExtra1Api new];
//        [self.webView addApis:@[extraApi] completion:^(NSArray<id<ZHJSApiProtocol>> *successApis, NSArray<id<ZHJSApiProtocol>> *failApis, id res, NSError *error) {
//            NSLog(@"--------------------");
//            [self.webView evaluateJs:@"window.addApiTest();" completionHandler:^(id res, NSError *error) {
//                NSLog(@"--------------------");
//
//
//                [self.webView removeApis:@[extraApi] completion:^(NSArray<id<ZHJSApiProtocol>> *successApis, NSArray<id<ZHJSApiProtocol>> *failApis, id res, NSError *error) {
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
    
    [self.context destroyContext];
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

#pragma mark - ZHWebViewDebugSocketDelegate

- (void)zh_webViewReadyRefresh:(ZHWebView *)webView{
}
- (void)zh_webViewStartRefresh:(ZHWebView *)webView{
    [self doLoadWebView:webView];
}
@end
