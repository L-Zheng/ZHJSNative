//
//  ZHJSApiHandler.h
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZHJSApiProtocol.h"

//NS_ASSUME_NONNULL_BEGIN

@interface ZHJSApiHandler : NSObject

- (instancetype)initWithApis:(NSArray <id <ZHJSApiProtocol>> *)inApis apis:(NSArray <id <ZHJSApiProtocol>> *)apis;

@property (nonatomic,strong,readonly) NSArray <id <ZHJSApiProtocol>> *apis;

//添加移除api
- (void)addApis:(NSArray <id <ZHJSApiProtocol>> *)apis completion:(void (^) (NSArray <id <ZHJSApiProtocol>> *successApis, NSArray <id <ZHJSApiProtocol>> *failApis, NSError *error))completion;
- (void)removeApis:(NSArray <id <ZHJSApiProtocol>> *)apis completion:(void (^) (NSArray <id <ZHJSApiProtocol>> *successApis, NSArray <id <ZHJSApiProtocol>> *failApis, NSError *error))completion;

//api映射表
- (void)enumRegsiterApiMap:(void (^)(NSString *apiPrefix, NSDictionary <NSString *, ZHJSApiRegisterItem *> *apiMap, NSDictionary *apiModuleMap))block;
//遍历方法映射表->获取api注入完成事件名
- (void)enumRegsiterApiInjectFinishEventNameMap:(void (^)(NSString *apiPrefix, NSString *apiInjectFinishEventName))block;
//获取方法名
- (void)fetchSelectorByName:(NSString *)jsMethodName apiPrefix:(NSString *)apiPrefix jsModuleName:(NSString *)jsModuleName callBack:(void (^) (id target, SEL sel))callBack;

@end
//NS_ASSUME_NONNULL_END
