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
@class ZHJSContext;
@class ZHWebView;

//NS_ASSUME_NONNULL_BEGIN

static NSString * const ZHJSHandlerName = @"ZHJSEventHandler";
static NSString * const ZHJSHandlerLogName = @"ZHJSLogEventHandler";

@interface ZHJSHandler : NSObject<WKScriptMessageHandler>

@property (nonatomic,weak) ZHWebView *webView;
@property (nonatomic,weak) ZHJSContext *jsContext;

//JSContext注入的api
- (NSDictionary *)jsContextApiMap;
//WebView注入的api
+ (NSString *)webViewApiSource;

//同步处理js的调用
- (id)handleJSFuncSync:(NSDictionary *)jsInfo;
@end

//NS_ASSUME_NONNULL_END
