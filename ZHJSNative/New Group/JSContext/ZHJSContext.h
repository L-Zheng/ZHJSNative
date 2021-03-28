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
#import "ZHCtxConfig.h"
#import "ZHCtxDebugItem.h"
#import "ZHJSPageItem.h" // WebView/JSContext页面信息数据
@class ZHJSPageProtocol;//页面协议

//NS_ASSUME_NONNULL_BEGIN

@interface ZHJSContext : JSContext <ZHJSPageProtocol>

#pragma mark - init

- (instancetype)initWithGlobalConfig:(ZHCtxConfig *)globalConfig;
//- (instancetype)initWithCreateConfig:(ZHCtxCreateConfig *)createConfig;
@property (nonatomic,strong,readonly) NSArray <id <ZHJSApiProtocol>> *apis;

#pragma mark - config

@property (nonatomic,strong) ZHCtxConfig *globalConfig;
@property (nonatomic,strong) ZHCtxMpConfig *mpConfig;
@property (nonatomic,strong) ZHCtxCreateConfig *createConfig;
@property (nonatomic,strong) ZHCtxLoadConfig *loadConfig;
// 调试配置
@property (nonatomic, strong) ZHCtxDebugItem *debugItem;

#pragma mark - api

//添加移除api
- (void)addApis:(NSArray <id <ZHJSApiProtocol>> *)apis completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApis, NSArray<id<ZHJSApiProtocol>> *failApis, id res, NSError *error))completion;
- (void)removeApis:(NSArray <id <ZHJSApiProtocol>> *)apis completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApis, NSArray<id<ZHJSApiProtocol>> *failApis, id res, NSError *error))completion;

#pragma mark - render

/// 加载js
/// @param url 加载的url路径
/// @param baseURL 【JSContext运行所需的资源根目录，如果为nil，默认为url的上级目录】
/// @param loadConfig loadConfig
/// @param loadStartBlock  回调
/// @param loadFinishBlock  回调
- (void)renderWithUrl:(NSURL *)url
              baseURL:(NSURL *)baseURL
           loadConfig:(ZHCtxLoadConfig *)loadConfig
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
