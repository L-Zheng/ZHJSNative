//
//  ZHJSContext.h
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "ZHJSApiProtocol.h"
#import "ZHContextConfig.h"
#import "ZHContextDebugItem.h"
#import "ZHJSPageItem.h" // WebView/JSContext页面信息数据
@class ZHJSPageProtocol;//页面协议

//NS_ASSUME_NONNULL_BEGIN

@interface ZHJSContext : JSContext <ZHJSPageProtocol>

#pragma mark - init

- (instancetype)initWithGlobalConfig:(ZHContextConfig *)globalConfig;
//- (instancetype)initWithCreateConfig:(ZHContextCreateConfig *)createConfig;
@property (nonatomic,strong,readonly) NSArray <id <ZHJSApiProtocol>> *apiHandlers;

#pragma mark - config

@property (nonatomic,strong) ZHContextConfig *globalConfig;
@property (nonatomic,strong) ZHContextMpConfig *mpConfig;
@property (nonatomic,strong) ZHContextCreateConfig *createConfig;
@property (nonatomic,strong) ZHContextLoadConfig *loadConfig;
// 调试配置
@property (nonatomic, strong) ZHContextDebugItem *debugItem;

#pragma mark - api

//添加移除api
- (void)addApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, id res, NSError *error))completion;
- (void)removeApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, id res, NSError *error))completion;

#pragma mark - render

/// 加载js
/// @param url 加载的url路径
/// @param baseURL 【JSContext运行所需的资源根目录，如果为nil，默认为url的上级目录】
/// @param loadConfig loadConfig
/// @param loadStartBlock  回调
/// @param loadFinishBlock  回调
- (void)renderWithUrl:(NSURL *)url
              baseURL:(NSURL *)baseURL
           loadConfig:(ZHContextLoadConfig *)loadConfig
       loadStartBlock:(void (^) (NSURL *runSandBoxURL))loadStartBlock
      loadFinishBlock:(void (^) (NSDictionary *info, NSError *error))loadFinishBlock;

#pragma mark - render url

@property (nonatomic, strong) NSURL *renderURL;
//运行的沙盒目录
@property (nonatomic, copy, readonly) NSURL *runSandBoxURL;

- (JSValue *)runJsFunc:(NSString *)funcName arguments:(NSArray *)arguments;

#pragma mark - mp

@property (nonatomic,strong) ZHJSContextItem *contextItem;


@end

//NS_ASSUME_NONNULL_END
