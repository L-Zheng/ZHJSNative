//
//  ZHWebViewManager.h
//  ZHJSNative
//
//  Created by EM on 2020/4/10.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "ZHJSApiProtocol.h"
@class ZHWebView;
@class ZHWebViewConfiguration;

//NS_ASSUME_NONNULL_BEGIN

@interface ZHWebViewManager : NSObject

+ (instancetype)shareManager;
//+ (void)install;

#pragma mark - webview

/// 预加载webview
/// @param config 配置
/// @param finish 加载完成回调
- (void)preReadyWebView:(ZHWebViewConfiguration *)config
                 finish:(void (^) (NSDictionary *info, NSError *error))finish;

//查找预加载的webview
- (ZHWebView *)fetchWebView:(NSString *)key;

/// 加载webView  包含有模板小程序更新逻辑 沙盒拷贝逻辑
/// @param webView webView
/// @param config config
/// @param finish 回调
- (void)loadWebView:(ZHWebView *)webView
             config:(ZHWebViewConfiguration *)config
             finish:(void (^) (NSDictionary *info, NSError *error))finish;

/// 重新下载模板文件加载webView
/// @param webView webView
/// @param config config
/// @param downLoadStart 下载开始回调
/// @param downLoadFinish 下载完成回调
/// @param finish webview加载完成回调
- (void)retryLoadWebView:(ZHWebView *)webView
                  config:(ZHWebViewConfiguration *)config
           downLoadStart:(void (^) (void))downLoadStart
          downLoadFinish:(void (^) (NSDictionary *info ,NSError *error))downLoadFinish
                  finish:(void (^) (NSDictionary *info ,NSError *error))finish;

//调试下使用
- (void)loadOnlineDebugWebView:(ZHWebView *)webView
                           url:(NSURL *)url
                        config:(ZHWebViewConfiguration *)config
                        finish:(void (^) (NSDictionary *info, NSError *error))finish;
- (void)loadLocalDebugWebView:(ZHWebView *)webView
                   templateFolder:(NSString *)templateFolder
                       config:(ZHWebViewConfiguration *)config
                       finish:(void (^) (NSDictionary *info, NSError *error))finish;

#pragma mark - cache

//清理WebView加载缓存
- (void)cleanWebViewLoadCache;
@end

//NS_ASSUME_NONNULL_END
