//
//  ZHWebConfig.m
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHWebConfig.h"

@implementation ZHWebConfig
- (NSDictionary *)formatInfo{
    return @{
        @"createConfig": [self.createConfig formatInfo]?:@{},
        @"loadConfig": [self.loadConfig formatInfo]?:@{},
        @"apiOpConfig": [self.apiOpConfig formatInfo]?:@{},
        @"mpConfig": [self.mpConfig formatInfo]?:@{}
    };
}
- (void)dealloc{
    NSLog(@"%s", __func__);
}
@end
