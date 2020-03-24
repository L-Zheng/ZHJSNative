//
//  ZHWebViewDelegate.m
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHWebViewDelegate.h"
#import "ZHWebView.h"
#import "ZHJSHandler.h"

@interface ZHWebViewDelegate() 

@end


@implementation ZHWebViewDelegate

- (id <ZHWKNavigationDelegate>)fetchNaviDelegate{
    return self.webView.zh_navigationDelegate;
}
- (id <ZHWKUIDelegate>)fetchUIDelegate{
    return self.webView.zh_UIDelegate;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(ZHWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    if (webView.loadFinish) {
        webView.loadFinish(NO);
    }
    [[self fetchNaviDelegate] webView:webView didFailNavigation:navigation withError:error];
}

- (void)webView:(ZHWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    if (webView.loadFinish) {
        webView.loadFinish(YES);
    }
    [[self fetchNaviDelegate] webView:webView didFinishNavigation:navigation];
}

- (void)webView:(ZHWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    NSLog(@"-----❌didFailProvisionalNavigation---------------");
    NSLog(@"%@",error);
    [[self fetchNaviDelegate] webView:webView didFailProvisionalNavigation:navigation withError:error];
}

- (void)webView:(ZHWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    
    id <ZHWKNavigationDelegate> de = [self fetchNaviDelegate];
    if (de) {
        [de webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
        return;
    }
    
    if ([navigationAction.request.URL.scheme isEqualToString:@"file"]) {
        if (decisionHandler) {
            decisionHandler(WKNavigationActionPolicyAllow);
        }
        return;
    }
    if (decisionHandler) {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

#pragma mark - WKUIDelegate

// 页面是弹出窗口 _blank 处理
- (WKWebView *)webView:(ZHWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    id <ZHWKUIDelegate> de = [self fetchUIDelegate];
    if (de) {
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
    
    id result = [self.webView.handler handleScriptMessage:receiveInfo];
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
    NSData *data = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
    if (!data) {
        if (completionHandler) completionHandler(nil);
        return;
    }
    if (completionHandler) completionHandler([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

- (void)dealloc{
    NSLog(@"-------%s---------", __func__);
}

@end
