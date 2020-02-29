//
//  ZHJSApiHandler.h
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ZHJSHandler;
@class ZHJSApiMethodItem;

//NS_ASSUME_NONNULL_BEGIN

typedef void(^ZHJSApiBlock)(id result, NSError *error);
typedef void(^ZHJSApiAliveBlock)(id result, NSError *error, BOOL alive);

@interface ZHJSApiHandler : NSObject

@property (nonatomic,weak) ZHJSHandler *handler;

//api方法名
- (NSString *)fetchApiMethodPrefixName;
//api方法map
- (NSDictionary <NSString *, ZHJSApiMethodItem *> *)fetchApiMethodMap;
//获取方法名
- (SEL)fetchSelectorByName:(NSString *)name;

@end

@interface ZHJSApiMethodItem : NSObject
@property (nonatomic,copy) NSString *jsMethodName;
@property (nonatomic,copy) NSString *nativeMethodName;
@property (nonatomic,assign, readonly) BOOL isSync;
@end
//NS_ASSUME_NONNULL_END
