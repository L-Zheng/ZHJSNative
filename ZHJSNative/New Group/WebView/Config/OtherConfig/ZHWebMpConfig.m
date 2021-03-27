//
//  ZHWebMpConfig.m
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHWebMpConfig.h"

@implementation ZHWebMpConfig
- (NSString *)envVersion{
    if (!_envVersion ||
        ![_envVersion isKindOfClass:[NSString class]] ||
        _envVersion.length == 0 ) {
        return @"release";
    }
    return _envVersion;
}
- (NSDictionary *)formatInfo{
    return @{
        @"appId": self.appId?:@"",
        @"loadFileName": self.loadFileName?:@"",
        @"presetFilePath": self.presetFilePath?:@""
    };
}
- (void)dealloc{
    NSLog(@"%s", __func__);
}
@end
