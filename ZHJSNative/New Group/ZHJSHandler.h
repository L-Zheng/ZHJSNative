//
//  ZHJSHandler.h
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "ZHJSApiProtocol.h"
@class ZHJSContext;
@class ZHWebView;
@class ZHJSApiHandler;

//NS_ASSUME_NONNULL_BEGIN

static NSString * const ZHJSHandlerName = @"ZHJSEventHandler";
static NSString * const ZHJSHandlerLogName = @"ZHJSLogEventHandler";
static NSString * const ZHJSHandlerErrorName = @"ZHJSErrorEventHandler";

@interface ZHJSHandler : NSObject<WKScriptMessageHandler>

- (instancetype)initWithApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers;

@property (nonatomic,weak) ZHWebView *webView;
@property (nonatomic,weak) ZHJSContext *jsContext;

//JSContext注入的api
- (void)fetchJSContextApi:(void (^) (NSString *apiPrefix, NSDictionary *apiBlockMap))callBack;
- (void)fetchJSContextLogApi:(void (^) (NSString *apiPrefix, NSDictionary *apiBlockMap))callBack;
//WebView注入的api
- (NSString *)fetchWebViewLogApi;
- (NSString *)fetchWebViewErrorApi;
- (NSString *)fetchWebViewSocketApi;
- (NSString *)fetchWebViewTouchCalloutApi;
- (NSString *)fetchWebViewApi;
- (NSString *)fetchWebViewApiFinish;
//异常弹窗
- (void)showWebViewException:(NSDictionary *)exception;
- (void)showJSContextException:(NSDictionary *)exception;


//处理js消息
- (id)handleScriptMessage:(NSDictionary *)jsInfo;
@end



@interface ZHErrorAlertController : UIAlertController
@end


//NS_ASSUME_NONNULL_END
