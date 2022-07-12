//
//  DemoApiModule.m
//  JsBridge
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "DemoApiModule.h"

@implementation DemoApiModule
- (void)js_play:(JsBridgeApiArgItem *)arg{
    NSLog(@"%@", arg.jsData);
}
//js api方法名前缀
- (NSString *)jsBridge_jsApiPrefix{
    return @"voice";
}
//ios api方法名前缀 如：js_
- (NSString *)jsBridge_iosApiPrefix{
    return @"js_";
}
@end
