//
//  ZHWebViewManager.h
//  ZHJSNative
//
//  Created by EM on 2020/4/10.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ZHWebView;

NS_ASSUME_NONNULL_BEGIN

@interface ZHWebViewManager : NSObject

+ (instancetype)shareManager;
+ (void)install;

//是否使用预先加载的webview
+ (BOOL)isUsePreWebView;

#pragma mark - webview

- (ZHWebView *)fetchWebView;
- (void)recycleWebView:(ZHWebView *)webView;

- (ZHWebView *)createWebView;
- (void)loadWebView:(ZHWebView *)webView finish:(void (^) (BOOL success))finish;
@end

NS_ASSUME_NONNULL_END
