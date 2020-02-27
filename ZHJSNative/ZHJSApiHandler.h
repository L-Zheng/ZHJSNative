//
//  ZHJSApiHandler.h
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ZHJSHandler;

//NS_ASSUME_NONNULL_BEGIN

typedef void(^ZHJSApiBlock)(id result, NSError *error);

@interface ZHJSApiHandler : NSObject

@property (nonatomic,weak) ZHJSHandler *handler;

//api方法名
- (NSString *)fetchApiMethodPrefixName;
//api方法map
- (NSDictionary *)fetchApiMethodMap;
//获取方法名
- (SEL)fetchSelectorByName:(NSString *)name;

@end

//NS_ASSUME_NONNULL_END
