//
//  ZHCustom1ApiHandler.m
//  ZHJSNative
//
//  Created by Zheng on 2020/3/28.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHCustom1ApiHandler.h"

@implementation ZHCustom1ApiHandler

- (void)js_commonLinkTo:(NSDictionary *)params{
    NSLog(@"-------%s---------", __func__);
    NSLog(@"%@",params);
}

//js api方法名前缀  如：fund
- (NSString *)zh_jsApiPrefixName{
    return @"fund1";
}
//ios api方法名前缀 如：js_
- (NSString *)zh_iosApiPrefixName{
    return @"js_";
}

- (void)dealloc{
    NSLog(@"-------%s---------", __func__);
}
@end
