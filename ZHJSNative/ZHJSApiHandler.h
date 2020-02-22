//
//  ZHJSApiHandler.h
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZHJSApiHandler : NSObject

@property (nonatomic,strong,readonly) NSString *methodPrefix;
@property (nonatomic,strong,readonly) NSDictionary *apiMethodMap;


- (SEL)fetchSelectorByName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
