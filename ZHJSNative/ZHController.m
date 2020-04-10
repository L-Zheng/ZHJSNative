//
//  ZHController.m
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHController.h"
#import "ZHWebView.h"
#import "ZHJSContext.h"
#import "ZHWebViewManager.h"

@interface ZHController ()<ZHWebViewSocketDebugDelegate>
@property (nonatomic, strong) ZHWebView *webView;
@property (nonatomic, strong) ZHJSContext *context;
@end

@implementation ZHController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self config:NO];
    
    //运算js
    //    self.context = [[ZHJSContext alloc] initWithApiHandlers:@[[[ZHCustomApiHandler alloc] init], [[ZHCustom1ApiHandler alloc] init]]];
    //    NSURL *url = [NSURL fileURLWithPath:[ZHUtil jsPath]];
    //    url = [NSURL fileURLWithPath:@"/Users/zheng/Desktop/ZHCode/GitHubCode/ZHJSNative/ZHJSNative/TestBundle.bundle/test.js"];
    //    [self.context evaluateScript:[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self configWebViewFrame:self.webView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self configNavigaitonBar:animated];
    NSLog(@"----✅viewWillAppear----");
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    NSLog(@"----✅viewDidAppear----");
    [self configGesture];
}

- (void)config:(BOOL)debugReload{
    [self configView];
    [self configWebView:debugReload];
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

- (void)configWebView:(BOOL)debugReload{
    ZHWebViewManager *mg = [ZHWebViewManager shareManager];
    __weak __typeof__(self) __self = self;
    //渲染
    void (^render)(ZHWebView *) = ^(ZHWebView *webView){
        __self.navigationItem.title = webView.title;
//        [__self readyRender:nil];
    };
    
    //配置
    void (^config)(ZHWebView *) = ^(ZHWebView *webView){
        //配置view
        [__self configWebViewFrame:webView];
        if (!webView.superview) [__self.view addSubview:webView];
        __self.webView = webView;
        //配置代理
        [__self configWebViewDelegate:webView target:__self];
        //配置handler
    };
    
    if (debugReload) {
        [mg loadWebView:self.webView finish:^(BOOL success) {
            if (success) {
                config(__self.webView);
                render(__self.webView);
                [__self configDebugOption:@"刷新"];
            }
        }];
        return;
    }

    
    //查找可用WebView
    ZHWebView *webView = nil;
    if (![ZHWebViewManager isUsePreWebView]) {
        webView = nil;
    }else{
        webView = [mg fetchWebView];
    }
    
    if (webView) {
        //检查是否异常
        ZHWebViewExceptionOperate operate = [webView checkException];
        if (operate == ZHWebViewExceptionOperateNothing) {
            config(webView);
            render(webView);
            return;
        }else if (operate == ZHWebViewExceptionOperateReload){
        }else if (operate == ZHWebViewExceptionOperateNewInit){
            webView = [mg createWebView];
        }
    }else{
        webView = [mg createWebView];
    }
    [mg loadWebView:webView finish:^(BOOL success) {
        if (success) {
            config(webView);
            render(webView);
            [__self configDebugOption:@"刷新"];
        }
    }];
    if (!webView.superview) [self.view addSubview:webView];
}
- (void)configWebViewDelegate:(ZHWebView *)webView target:(id)target{
    webView.zh_navigationDelegate = target;
    webView.zh_UIDelegate = target;
    webView.zh_socketDebugDelegate = target;
}

- (void)configWebViewFrame:(WKWebView *)webView{
    if (@available(iOS 11.0, *)) {
        webView.frame = (CGRect){CGPointZero, {self.view.bounds.size.width, self.view.bounds.size.height - self.view.safeAreaInsets.bottom}};
    } else {
        webView.frame = self.view.bounds;
    }
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
    NSLog(@"-------%s---------", __func__);
}

#pragma mark - ZHWebViewSocketDebugDelegate

- (void)webViewReadyRefresh:(ZHWebView *)webView{
    [self configDebugOption:@"准备中..."];
}
- (void)webViewRefresh:(ZHWebView *)webView{
    [self refreshWebView];
}

- (void)refreshWebView{
    [self configDebugOption:@"刷新中..."];
    
    /** presented 与dismiss同时进行 会crash */
//    if ([self.presentedViewController isKindOfClass:[UIAlertController class]]) {
//        [self dismissViewControllerAnimated:YES completion:nil];
//    }
    //清除代理
    [self configWebViewDelegate:self.webView target:nil];
    [self config:YES];
}

- (void)configDebugOption:(NSString *)title{
    #ifdef DEBUG
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(refreshWebView)];
    NSMutableArray *rightItems = [NSMutableArray array];
//    if (self.navigationItem.rightBarButtonItems.count > 0) {
//        [rightItems addObject:self.navigationItem.rightBarButtonItems.firstObject];
//    }
    [rightItems addObject:item];
    self.navigationItem.rightBarButtonItems = rightItems;
    #endif
}
@end
