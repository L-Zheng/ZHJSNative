//
//  JsBridgeHandler_private.h
//  JsBridge
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JsBridgeProtocol.h"

@interface JsBridgeHandler (JsBridgePrivate)
// 添加移除api
- (void)addApis:(NSArray *)apis;
- (void)removeApis:(NSArray *)apis;

// api映射表
- (void)enumRegsiterApiMap:(void (^)(NSString *apiPrefix, NSDictionary *apiMap, NSDictionary *apiModuleMap))block;
// 遍历方法映射表->获取api注入完成事件名
- (void)enumRegsiterApiInjectFinishEventNameMap:(void (^)(NSString *apiPrefix, NSString *apiInjectFinishEventName))block;
// 获取方法名
- (void)fetchSelectorByName:(NSString *)jsMethodName apiPrefix:(NSString *)apiPrefix jsModuleName:(NSString *)jsModuleName callBack:(void (^) (id target, SEL sel))callBack;
// 获取所有注册的jsApiPrefix
- (NSArray *)fetchJsApiPrefixAll;

- (id)runNativeFunc:(NSString *)jsMethodName apiPrefix:(NSString *)apiPrefix jsModuleName:(NSString *)jsModuleName arguments:(NSArray <JsBridgeApiArgItem *> *)arguments;

#pragma mark - parse

- (NSDictionary *)parseException:(id)exception;

@end
