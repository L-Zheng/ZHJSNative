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
+ (BOOL)isUsePreLoadWebView;

#pragma mark - webview
- (ZHWebView *)createWebView;
- (ZHWebView *)fetchWebView;

- (void)loadWebView:(ZHWebView *)webView finish:(void (^) (BOOL success))finish;
@end

NS_ASSUME_NONNULL_END
