//
//  ZHWebLoadConfig.m
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHWebLoadConfig.h"

@implementation ZHWebLoadConfig
- (NSDictionary *)formatInfo{
    return @{
        @"cachePolicy": self.cachePolicy?:@"",
        @"timeoutInterval": self.timeoutInterval?:@"",
        @"readAccessURL": self.readAccessURL.absoluteString ?: @""
    };
}
- (void)dealloc{
    NSLog(@"%s", __func__);
}
@end
