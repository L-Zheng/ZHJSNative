//
//  ZHContextBaseConfig.h
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ZHJSContext;

@interface ZHContextBaseConfig : NSObject
@property (nonatomic,weak) ZHJSContext *jsContext;
- (NSDictionary *)formatInfo;
@end

