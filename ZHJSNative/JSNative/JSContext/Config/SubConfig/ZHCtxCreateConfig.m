//
//  ZHCtxCreateConfig.m
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHCtxCreateConfig.h"

@implementation ZHCtxCreateConfig
- (instancetype)init{
    self = [super init];
    if (self) {
        self.injectInAPI = YES;
    }
    return self;
}
- (void)dealloc{
    NSLog(@"%s", __func__);
}
@end
