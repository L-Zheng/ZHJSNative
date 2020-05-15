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
@class ZHJSApiMethodItem;

//NS_ASSUME_NONNULL_BEGIN

@interface ZHJSApiHandler : NSObject

- (instancetype)initWithApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers;

@property (nonatomic,weak) ZHJSHandler *handler;

//api映射表
- (void)enumRegsiterApiMap:(void (^)(NSString *apiPrefix, NSDictionary <NSString *, ZHJSApiMethodItem *> *apiMap))block;

//获取方法名
- (void)fetchSelectorByName:(NSString *)jsMethodName apiPrefix:(NSString *)apiPrefix callBack:(void (^) (id target, SEL sel))callBack;

@end

@interface ZHJSApiMethodItem : NSObject
@property (nonatomic,copy) NSString *jsMethodName;
@property (nonatomic,copy) NSString *nativeMethodName;
@property (nonatomic,assign, readonly) BOOL isSync;
@end
//NS_ASSUME_NONNULL_END
