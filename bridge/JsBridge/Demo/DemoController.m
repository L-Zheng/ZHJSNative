//
//  ZHJSWebTestController.m
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "DemoController.h"
#import "DemoWebView.h"
#import "DemoApi.h"
#import "DemoApiModule.h"

@interface DemoController ()<JsBridgeWebViewSocketDelegate, WKUIDelegate, WKNavigationDelegate>
@property (nonatomic,strong) DemoWebView *web;
@end


@implementation DemoController

#pragma mark - life cycle

- (void)viewDidLoad{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self loadWeb];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (@available(iOS 11.0, *)) {
        self.web.frame = (CGRect){CGPointZero, {self.view.bounds.size.width, self.view.bounds.size.height - self.view.safeAreaInsets.bottom}};
    } else {
        self.web.frame = self.view.bounds;
    }
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    UINavigationBar *bar = self.navigationController.navigationBar;
    bar.translucent = YES;
    bar.barTintColor = [UIColor whiteColor];
}

#pragma mark - load

- (void)loadWeb{
    self.web = [[DemoWebView alloc] initWithFrame:self.view.bounds];
    self.web.navigationDelegate = self;
    self.web.UIDelegate = self;
    if (!self.web.superview) [self.view addSubview:self.web];
    
    JsBridgeWebHandler *jsBridge = self.web.jsBridge;
    BOOL cold = YES;
    
    jsBridge.socketDelegate = self;
    [jsBridge captureSocket:cold complete:^(id res, NSError *error) {}];
    
    [jsBridge captureException:cold handler:^(id exception) {
        NSLog(@"exception: %@", exception);
    }];
    [jsBridge captureConsole:cold handler:^(NSString *flag, NSArray *args) {
        NSLog(@"console: %@ %@", flag, args);
    }];
    [jsBridge captureVConsole:cold complete:^(id res, NSError *error) {}];
    
    [jsBridge addApis:@[[[DemoApi alloc] init]] cold:cold complete:^(id res, NSError *error) {
        
    }];
    
    [self reloadWeb];
}
- (void)reloadWeb{
    NSString *urlStr = @"http://172.31.35.71:8080";
//    urlStr = @"https://www.baidu.com";
    [self.web loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]]];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    self.navigationItem.title = webView.title;
    
//    [self.web sendMsgToJs:@[@"render"] params:@{@"sf": @[@"123", @"lll"]} complete:^(id res, NSError *error) {
//        NSLog(@"✅ res:%@ error:%@", res, error);
//    }];
}

#pragma mark - WKUIDelegate

// 页面是弹出窗口 _blank 处理
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

#pragma mark - JsBridgeWebViewSocketDelegate

// 准备刷新
- (void)jsBridgeWebViewSocketRefreshReady:(JsBridgeWebView *)webView{
    NSLog(@"准备刷新");
}
// 开始刷新
- (void)jsBridgeWebViewSocketRefreshStart:(JsBridgeWebView *)webView{
    NSLog(@"开始刷新");
    [self reloadWeb];
}

#pragma mark - dealloc

- (void)dealloc{
    //清空代理 【scrollView.delegate】 否则iOS8上会崩溃
    if (!_web) return;
    _web.scrollView.delegate = nil;
    _web.UIDelegate = nil;
    _web.navigationDelegate = nil;
}

@end
