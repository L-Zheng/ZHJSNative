//
//  ZHWebView.h
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "ZHJSApiProtocol.h"
@class ZHWebView;

typedef NS_ENUM(NSInteger, ZHWebViewExceptionOperate) {
    ZHWebViewExceptionOperateNothing     = 0,//不做任何操作
    ZHWebViewExceptionOperateReload      = 1,//WebView重新load
    ZHWebViewExceptionOperateNewInit      = 2,//重新初始化新的WebView
};

//NS_ASSUME_NONNULL_BEGIN

/** socket调试代理 */
@protocol ZHWebViewSocketDebugDelegate <NSObject>
@optional
- (void)webViewReadyRefresh:(ZHWebView *)webView;
- (void)webViewRefresh:(ZHWebView *)webView;
@end

/** 重写系统代理 */
@protocol ZHWKNavigationDelegate <WKNavigationDelegate>
@end
@protocol ZHWKUIDelegate <WKUIDelegate>
@end
@protocol ZHScrollViewDelegate <UIScrollViewDelegate>
@end


@interface ZHWebView : WKWebView

#pragma mark - load call

@property (nonatomic,copy, readonly) void (^loadFinish) (BOOL success);
@property (nonatomic, assign, readonly) BOOL loadSuccess;
@property (nonatomic, assign, readonly) BOOL loadFail;

#pragma mark - delegate

@property (nonatomic,weak) id <ZHWebViewSocketDebugDelegate> zh_socketDebugDelegate;
@property (nonatomic,weak) id <ZHWKNavigationDelegate> zh_navigationDelegate;
@property (nonatomic,weak) id <ZHWKUIDelegate> zh_UIDelegate;
@property (nonatomic,weak) id <ZHScrollViewDelegate> zh_scrollViewDelegate;

#pragma mark - init

- (instancetype)initWithApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers;
- (instancetype)initWithFrame:(CGRect)frame apiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers;
@property (nonatomic,strong,readonly) NSArray <id <ZHJSApiProtocol>> *apiHandlers;

#pragma mark - Exception

/** 检查WebView异常 ：白屏*/
- (ZHWebViewExceptionOperate)checkException;

#pragma mark - encode

+ (NSString *)encodeObj:(id)data;

#pragma mark - loads

/** 加载h5 */
- (void)loadUrl:(NSURL *)url allowingReadAccessToURL:(NSURL *)readAccessURL finish:(void (^) (BOOL success))finish;

/** 发送js消息 */
- (void)postMessageToJs:(NSString *)funcName params:(NSDictionary *)params completionHandler:(void (^)(id res, NSError *error))completionHandler;
- (void)evaluateJs:(NSString *)js completionHandler:(void (^)(id res, NSError *error))completionHandler;

#pragma mark - clear

- (void)clearCache;

@end

//NS_ASSUME_NONNULL_END
