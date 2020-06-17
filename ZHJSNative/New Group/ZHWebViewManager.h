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

//NS_ASSUME_NONNULL_BEGIN

@interface ZHWebViewManager : NSObject

+ (instancetype)shareManager;
//+ (void)install;

#pragma mark - webview

/// 预加载webview
/// @param key 模板的appId【如：品种页模板的appid】
/// @param frame frame
/// @param loadFileName 加载的html文件【如：index.html】
/// @param presetFolder 内置的模板目录【当本地没有缓存，使用app包内置的模板，传nil则等待下载模板】
/// @param processPool 内容进程池【传nil：会自动创建一个新的processPool，不同的WebView的processPool不同，内容数据不能共享。如要共享内容数据（如： localstorage数据）可自行创建processPool单例，不同的WebView共用此单例】
/// @param readAccessURL WebView可访问的资源目录【如：表情资源，一般传document目录】
/// @param cachePolicy 缓存策略@(NSURLRequestCachePolicy)  默认nil
/// @param timeoutInterval 超时时间  默认nil
/// @param apiHandlers WebView需要注入的api【如：fund API】
/// @param finish 回调
- (void)preReadyWebView:(NSString *)key
                  frame:(CGRect)frame
           loadFileName:(NSString *)loadFileName
           presetFolder:(NSString *)presetFolder
            processPool:(WKProcessPool *)processPool
allowingReadAccessToURL:(NSURL *)readAccessURL
            cachePolicy:(NSNumber *)cachePolicy
        timeoutInterval:(NSNumber *)timeoutInterval
            apiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers
                 finish:(void (^) (BOOL success))finish;

//查找预加载的webview
- (ZHWebView *)fetchWebView:(NSString *)key;

/// 加载webView  包含有模板小程序更新逻辑 沙盒拷贝逻辑
/// @param webView webView
/// @param key 模板的appId【如：品种页模板的appid】
/// @param loadFileName 加载的html文件【如：index.html】
/// @param presetFolder 内置的模板目录【当本地没有缓存，使用app包内置的模板，传nil则等待下载模板】
/// @param readAccessURL WebView可访问的资源目录【如：表情资源，一般传document目录】
/// @param cachePolicy 缓存策略@(NSURLRequestCachePolicy)  默认nil
/// @param timeoutInterval 超时时间  默认nil 
/// @param finish 回调
- (void)loadWebView:(ZHWebView *)webView
                key:(NSString *)key
       loadFileName:(NSString *)loadFileName
       presetFolder:(NSString *)presetFolder
allowingReadAccessToURL:(NSURL *)readAccessURL
        cachePolicy:(NSNumber *)cachePolicy
    timeoutInterval:(NSNumber *)timeoutInterval
             finish:(void (^) (BOOL success))finish;
//- (void)loadWebView:(ZHWebView *)webView key:(NSString *)key loadFolder:(NSString *)loadFolder loadFileName:(NSString *)loadFileName allowingReadAccessToURL:(NSURL *)readAccessURL finish:(void (^) (BOOL success))finish;

#ifdef DEBUG
//调试下使用
- (void)loadOnlineDebugWebView:(ZHWebView *)webView
                           key:(NSString *)key
                           url:(NSURL *)url
                   cachePolicy:(NSNumber *)cachePolicy
               timeoutInterval:(NSNumber *)timeoutInterval
                        finish:(void (^) (BOOL success))finish;

- (void)loadLocalDebugWebView:(ZHWebView *)webView
                          key:(NSString *)key
                   loadFolder:(NSString *)loadFolder
                 loadFileName:(NSString *)loadFileName
      allowingReadAccessToURL:(NSURL *)readAccessURL
                  cachePolicy:(NSNumber *)cachePolicy
              timeoutInterval:(NSNumber *)timeoutInterval
                       finish:(void (^) (BOOL success))finish;
#endif

#pragma mark - cache

//清理WebView加载缓存
- (void)cleanWebViewLoadCache;
@end

//NS_ASSUME_NONNULL_END
