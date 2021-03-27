//
//  ZHJSApiHandler.h
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZHJSApiProtocol.h"
@class ZHJSHandler;
@class ZHWebDebugItem;
@class ZHContextDebugItem;

//NS_ASSUME_NONNULL_BEGIN

@interface ZHJSApiHandler : NSObject

- (instancetype)initWithWebHandler:(ZHJSHandler *)handler
                         debugItem:(ZHWebDebugItem *)debugItem
                       apiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers;

- (instancetype)initWithContextHandler:(ZHJSHandler *)handler
                             debugItem:(ZHContextDebugItem *)debugItem
                             apiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers;

@property (nonatomic,weak,readonly) ZHJSHandler *handler;
@property (nonatomic,strong,readonly) NSArray <id <ZHJSApiProtocol>> *apiHandlers;

//添加移除api
- (void)addApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers completion:(void (^) (NSArray <id <ZHJSApiProtocol>> *successApiHandlers, NSArray <id <ZHJSApiProtocol>> *failApiHandlers, NSError *error))completion;
- (void)removeApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers completion:(void (^) (NSArray <id <ZHJSApiProtocol>> *successApiHandlers, NSArray <id <ZHJSApiProtocol>> *failApiHandlers, NSError *error))completion;

//api映射表
- (void)enumRegsiterApiMap:(void (^)(NSString *apiPrefix, NSDictionary <NSString *, ZHJSApiRegisterItem *> *apiMap))block;
//- (void)fetchRegsiterApiMap:(NSArray <id <ZHJSApiProtocol>> *)handlers block:(void (^)(NSString *apiPrefix, NSDictionary <NSString *, ZHJSApiRegisterItem *> *apiMap))block;
//获取方法名
- (void)fetchSelectorByName:(NSString *)jsMethodName apiPrefix:(NSString *)apiPrefix callBack:(void (^) (id target, SEL sel))callBack;

@end
//NS_ASSUME_NONNULL_END
