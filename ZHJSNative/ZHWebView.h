//
//  ZHWebView.h
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
@class ZHJSHandler;
@class ZHWebViewDelegate;
@class ZHWebView;

//NS_ASSUME_NONNULL_BEGIN

@protocol ZHWebViewSocketDebugDelegate <NSObject>
- (void)webViewReadyRefresh:(ZHWebView *)webView;
- (void)webViewRefresh:(ZHWebView *)webView;
@end


@interface ZHWebView : WKWebView

@property (nonatomic,strong) ZHJSHandler *handler;
@property (nonatomic,strong) ZHWebViewDelegate *zh_delegate;

@property (nonatomic,copy, readonly) void (^loadFinish) (BOOL success);
@property (nonatomic, assign, readonly) BOOL loadSuccess;
@property (nonatomic, assign, readonly) BOOL loadFail;

@property (nonatomic,weak) id <ZHWebViewSocketDebugDelegate> socketDebugDelegate;

+ (ZHWebView *)createWebView;

/** 加载h5 */
- (void)loadUrl:(NSURL *)url finish:(void (^) (BOOL success))finish;

/** 发送js消息 */
- (void)postMessageToJs:(NSString *)funcName params:(NSDictionary *)params completionHandler:(void (^)(id res, NSError *error))completionHandler;

#ifdef DEBUG
//socket链接调试
- (void)socketDidOpen:(NSDictionary *)params;
- (void)socketDidReceiveMessage:(NSDictionary *)params;
- (void)socketDidError:(NSDictionary *)params;
- (void)socketDidClose:(NSDictionary *)params;
#endif

@end

//NS_ASSUME_NONNULL_END
