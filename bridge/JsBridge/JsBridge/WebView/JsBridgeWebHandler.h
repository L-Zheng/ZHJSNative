//
//  JsBridgeWebHandler.h
//  JsBridge
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "JsBridgeHandler.h"
#import <WebKit/WebKit.h>
@class JsBridgeWebView;

static NSString * const JsBridgeWebHandlerKey = @"com.wkwebview.myjsbridge.handler";

// socket调试代理：监听 vue-cli-service serve的刷新事件
@protocol JsBridgeWebViewSocketDelegate <NSObject>
@optional
// 准备刷新
- (void)jsBridgeWebViewSocketRefreshReady:(JsBridgeWebView *)webView;
// 开始刷新
- (void)jsBridgeWebViewSocketRefreshStart:(JsBridgeWebView *)webView;
@end


@interface JsBridgeWebHandler : JsBridgeHandler <WKScriptMessageHandler, WKUIDelegate>

@property (nonatomic,weak) id <WKUIDelegate> outUIDelegate;
@property (nonatomic,weak) id <JsBridgeWebViewSocketDelegate> socketDelegate;
@property (nonatomic,weak) JsBridgeWebView *web;

#pragma mark - api

- (void)addApis:(NSArray *)apis cold:(BOOL)cold complete:(void (^)(id res, NSError *error))complete;
- (void)removeApis:(NSArray *)apis cold:(BOOL)cold complete:(void (^)(id res, NSError *error))complete;

#pragma mark - js sdk

- (NSString *)jssdk_api_support;

#pragma mark - error

- (void)captureException:(BOOL)cold handler:(void (^) (id exception))handler;

#pragma mark - console

- (void)captureConsole:(BOOL)cold handler:(void (^) (NSString *flag, NSArray *args))handler;
- (void)captureVConsole:(BOOL)cold complete:(void (^) (id res, NSError *error))complete;

#pragma mark - socket

- (void)captureSocket:(BOOL)cold complete:(void (^) (id res, NSError *error))complete;

#pragma mark - parse

- (NSString *)parseObjToStr:(id)data;
@end

