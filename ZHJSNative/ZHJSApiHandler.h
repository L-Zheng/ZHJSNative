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

- (instancetype)initWithApiHandler:(id <ZHJSApiProtocol>)apiHandler;

@property (nonatomic,weak) ZHJSHandler *handler;
@property (nonatomic,strong) id <ZHJSApiProtocol> outsideApiHandler;

@property (nonatomic,strong, readonly) NSDictionary <NSString *, ZHJSApiMethodItem *> *internalApiMap;
@property (nonatomic,strong, readonly) NSDictionary <NSString *, ZHJSApiMethodItem *> *outsideApiMap;

//api方法名
- (NSString *)fetchInternalJSApiPrefix;
- (NSString *)fetchOutsideJSApiPrefix;
//获取方法名
- (void)fetchSelectorByName:(NSString *)methodName apiPrefix:(NSString *)apiPrefix callBack:(void (^) (id target, SEL sel))callBack;

@end

@interface ZHJSApiMethodItem : NSObject
@property (nonatomic,copy) NSString *jsMethodName;
@property (nonatomic,copy) NSString *nativeMethodName;
@property (nonatomic,assign, readonly) BOOL isSync;
@end
//NS_ASSUME_NONNULL_END
