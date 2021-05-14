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
#import "ZHJSApiHandler.h"
@class ZHJSContext;
@class ZHWebView;

//NS_ASSUME_NONNULL_BEGIN

static NSString * const ZHJSHandlerName = @"ZHJSEventHandler";
static NSString * const ZHJSHandlerLogName = @"ZHJSLogEventHandler";
static NSString * const ZHJSHandlerErrorName = @"ZHJSErrorEventHandler";

@interface ZHJSHandler : NSObject<WKScriptMessageHandler>

@property (nonatomic,strong) ZHJSApiHandler *apiHandler;
@property (nonatomic,strong,readonly) NSArray <id <ZHJSApiProtocol>> *apis;

@property (nonatomic,weak) id <ZHJSPageProtocol> jsPage;
@property (nonatomic,weak) ZHWebView *webView;
@property (nonatomic,weak) ZHJSContext *jsContext;

//添加移除api
- (void)addApis:(NSArray <id <ZHJSApiProtocol>> *)apis completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApis, NSArray<id<ZHJSApiProtocol>> *failApis, NSString *jsCode, NSError *error))completion;
- (void)removeApis:(NSArray <id <ZHJSApiProtocol>> *)apis completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApis, NSArray<id<ZHJSApiProtocol>> *failApis, NSString *jsCode, NSError *error))completion;

//JSContext注入的api
- (void)fetchJSContextApi:(void (^) (NSString *apiPrefix, NSDictionary *apiBlockMap))callBack;
//- (void)fetchJSContextApiWithApis:(NSArray <id <ZHJSApiProtocol>> *)apis callBack:(void (^) (NSString *apiPrefix, NSDictionary *apiBlockMap))callBack;
- (void)fetchJSContextLogApi:(void (^) (NSString *apiPrefix, NSDictionary *apiBlockMap))callBack;
//WebView注入的api
- (NSString *)fetchWebViewLogApi;
- (NSString *)fetchWebViewConsoleApi;
- (NSString *)fetchWebViewErrorApi;
- (NSString *)fetchWebViewSocketApi;
- (NSString *)fetchWebViewTouchCalloutApi;
- (NSString *)fetchWebViewSupportApi;
- (NSString *)fetchWebViewApi:(BOOL)isReset;
- (NSString *)fetchWebViewApiFinish;
//异常弹窗
- (void)showWebViewException:(NSDictionary *)exception;
- (void)showJSContextException:(NSDictionary *)exception;

// 获取顶层视图Controller
- (UIViewController *)fetchActivityCtrl;


//处理js消息
- (BOOL)allowHandleScriptMessage:(NSDictionary *)jsInfo;
- (id)handleScriptMessage:(NSDictionary *)jsInfo;
@end



@interface ZHErrorAlertController : UIAlertController
@end


//NS_ASSUME_NONNULL_END
