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

@interface ZHWebView ()
@property (nonatomic,copy) void (^loadFinish) (BOOL success);
@property (nonatomic, assign) BOOL loadSuccess;
@property (nonatomic, assign) BOOL loadFail;
@end


@implementation ZHWebView

#pragma mark - init

+ (ZHWebView *)createWebView{
    
    ZHJSHandler *handler = [[ZHJSHandler alloc] init];
    
    
    WKUserContentController *userContent = [[WKUserContentController alloc] init];
    //注入api js
    NSString *apiJSCode = [ZHJSHandler webViewApiSource];
    WKUserScript *apiScript = [[WKUserScript alloc] initWithSource:apiJSCode injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    [userContent addUserScript:apiScript];
    [userContent addScriptMessageHandler:handler name:ZHJSHandlerName];
    
    //注入log
    NSString *jsCode = [NSString stringWithFormat:
    @"console.log = (function(oriLogFunc){\
        return function(obj)\
        {\
            /** 里面的注释必须带有闭合标签   语句后面必须带有; */\
            let newObj = obj;\
            const type = Object.prototype.toString.call(newObj);\
            if (type == '[object Function]')\
            {\
              newObj = newObj.toString();\
            }\
            const res = JSON.parse(JSON.stringify(newObj));\
            window.webkit.messageHandlers.%@.postMessage(res);\
            oriLogFunc.call(console,obj);\
        }\
    })(console.log);", ZHJSHandlerLogName];
    WKUserScript *logScript = [[WKUserScript alloc] initWithSource:jsCode injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    [userContent addUserScript:logScript];
    [userContent addScriptMessageHandler:handler name:ZHJSHandlerLogName];
    
    
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
    
    
    ZHWebView *webView = [[ZHWebView alloc] initWithFrame:CGRectZero configuration:config];
    webView.backgroundColor = [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0];
//    webView.scrollView.bounces = NO;
//    webView.scrollView.alwaysBounceVertical = NO;
//    webView.scrollView.alwaysBounceHorizontal = NO;
    webView.scrollView.showsVerticalScrollIndicator = YES;
    //设置流畅滑动【否则 滑动效果没有减速过快】
    webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    
    if (@available(iOS 11.0, *)) {
        webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }

    webView.handler = handler;
    handler.webView = webView;
    webView.zh_delegate = [[ZHWebViewDelegate alloc] init];
    webView.zh_delegate.webView = webView;
    
    //设置代理
    webView.UIDelegate = webView.zh_delegate;
    webView.navigationDelegate = webView.zh_delegate;
    webView.scrollView.delegate = webView.zh_delegate;
    
    return webView;
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
        [userContent removeScriptMessageHandlerForName:ZHJSHandlerName];
        [userContent removeScriptMessageHandlerForName:ZHJSHandlerLogName];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
    NSLog(@"----EFNewsWebview-------dealloc---------");
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
    NSString *js = [NSString stringWithFormat:@"(%@)(\"%@\")", funcName, paramsStr];
    [self evaluateJavaScript:js completionHandler:^(id _Nullable res, NSError * _Nullable error) {
        if (error) {
            NSLog(@"----❌js:function:%@--error:%@--", funcName, error);
        }else{
            NSLog(@"----✅js:function:%@--返回值:%@--", funcName, res?:@"void");
        }
        if (completionHandler) {
            completionHandler(res, error);
        }
    }];
}

@end
