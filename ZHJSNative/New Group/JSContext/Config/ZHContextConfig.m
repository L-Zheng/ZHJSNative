//
//  ZHContextConfig.m
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHContextConfig.h"

@implementation ZHContextConfig
- (NSDictionary *)formatInfo{
    return @{
        @"mpConfig": [self.mpConfig formatInfo]?:@{},
        @"createConfig": [self.createConfig formatInfo]?:@{},
        @"loadConfig": [self.loadConfig formatInfo]?:@{},
        @"apiOpConfig": [self.apiOpConfig formatInfo]?:@{}
    };
}
- (void)dealloc{
    NSLog(@"%s", __func__);
}
@end
