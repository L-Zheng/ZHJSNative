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

//创建 error
__attribute__((unused)) static BOOL ZHCheckDelegate(id delegate, SEL sel) {
    if (!delegate || !sel) return NO;
    return [delegate respondsToSelector:sel];
}

@interface ZHWebView ()<WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic,copy) void (^loadFinish) (BOOL success);
@property (nonatomic, assign) BOOL loadSuccess;
@property (nonatomic, assign) BOOL loadFail;

@property (nonatomic,strong) UIGestureRecognizer *pressGes;

@property (nonatomic, strong) ZHJSHandler *handler;
//外部handler
@property (nonatomic,strong) NSArray <id <ZHJSApiProtocol>> *apiHandlers;
@end

@implementation ZHWebView

- (instancetype)initWithApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers{
    
    ZHJSHandler *handler = [[ZHJSHandler alloc] initWithApiHandlers:apiHandlers];
    
    WKUserContentController *userContent = [[WKUserContentController alloc] init];
    
    //注入api
    NSArray *apis = @[
        //log
        @{
            @"code": [handler fetchWebViewLogApi]?:@"",
            @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentStart),
            @"mainFrameOnly": @(YES)
        },
        //error
        @{
            @"code": [handler fetchWebViewErrorApi]?:@"",
            @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentStart),
            @"mainFrameOnly": @(YES)
        },
#ifdef DEBUG
        //websocket js用于监听socket链接
        @{
            @"code": [handler fetchWebViewSocketApi]?:@"",
            @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentStart),
            @"mainFrameOnly": @(YES)
        },
        //禁用webview长按弹出菜单
        @{
            @"code": [handler fetchWebViewTouchCalloutApi]?:@"",
            @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentEnd),
            @"mainFrameOnly": @(YES)
        },
#endif
        //api js
        @{
            @"code": [handler fetchWebViewApi]?:@"",
            @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentStart),
            @"mainFrameOnly": @(YES)
        },
        //api 注入完成
        @{
            @"code": [handler fetchWebViewApiFinish]?:@"",
            @"jectionTime": @(WKUserScriptInjectionTimeAtDocumentEnd),
            @"mainFrameOnly": @(YES)
        }
    ];
    for (NSDictionary *map in apis) {
        NSString *code = [map valueForKey:@"code"];
        if (code.length == 0) continue;
        NSNumber *jectionTime = [map valueForKey:@"jectionTime"];
        NSNumber *mainFrameOnly = [map valueForKey:@"mainFrameOnly"];
        WKUserScript *script = [[WKUserScript alloc] initWithSource:code injectionTime:jectionTime.integerValue forMainFrameOnly:mainFrameOnly.boolValue];
        [userContent addUserScript:script];
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
        self.apiHandlers = apiHandlers;
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
    if (ZHCheckDelegate(self.zh_socketDebugDelegate, @selector(webViewReadyRefresh:))) {
        [self.zh_socketDebugDelegate webViewReadyRefresh:self];
    }
}
- (void)socketCallRefresh{
    if (ZHCheckDelegate(self.zh_socketDebugDelegate, @selector(webViewRefresh:))) {
        [self.zh_socketDebugDelegate webViewRefresh:self];
    }
}
#endif

@end
