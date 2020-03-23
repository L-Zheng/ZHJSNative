//
//  ZHController.m
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHController.h"
#import "ZHWebView.h"
#import "ZHUtil.h"
#import "ZHJSContext.h"

@interface ZHController ()<ZHWebViewSocketDebugDelegate>
@property (nonatomic, strong) ZHWebView *webView;
@property (nonatomic, strong) ZHJSContext *context;

@end

@implementation ZHController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self config];
    
    //运算js
//    self.context = [ZHJSContext createContext];
//    [self.context evaluateScript:[NSString stringWithContentsOfURL:[NSURL fileURLWithPath:[ZHUtil jsPath]] encoding:NSUTF8StringEncoding error:nil]];
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
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self.webView loadUrl:[NSURL fileURLWithPath:[ZHUtil htmlPath]] finish:^(BOOL success) {
//            
//        }];
//    });
}

- (void)config{
    [self configView];
    [self configWebView];
}

- (void)configView{
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor whiteColor];
//    self.view.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255.0)/ 255.0 green:arc4random_uniform(255.0)/ 255.0 blue:arc4random_uniform(255.0)/ 255.0 alpha:1.0];
}

- (void)configNavigaitonBar:(BOOL)animated{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    UINavigationBar *bar = self.navigationController.navigationBar;
    bar.translucent = NO;
}

- (void)configWebView{
    ZHWebView *webView = [ZHWebView createWebView];
    NSURL *url = [NSURL fileURLWithPath:[ZHUtil htmlPath]];
    
//    url = [NSURL fileURLWithPath:@"/Users/em/Desktop/My/ZHCode/GitHubCode/ZHJSNative/ZHJSNative/TestBundle.bundle/test.html"];
//    url = [NSURL URLWithString:@"http://172.31.35.80:8081"];
    
    __weak __typeof__(self) __self = self;
    [webView loadUrl:url finish:^(BOOL success) {
        [__self configDebugOption:@"刷新"];
    }];
    
    [self configWebViewFrame:webView];
    [self.view addSubview:webView];
    self.webView = webView;
    webView.socketDebugDelegate = self;
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
    [self.webView removeFromSuperview];
    [self config];
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
