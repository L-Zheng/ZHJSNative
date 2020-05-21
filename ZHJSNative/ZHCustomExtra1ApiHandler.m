//
//  ZHCustomExtra1ApiHandler.m
//  ZHJSNative
//
//  Created by EM on 2020/5/20.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHCustomExtra1ApiHandler.h"

@implementation ZHCustomExtra1ApiHandler

- (void)js_commonLinkTo1122:(NSDictionary *)params{
    NSLog(@"-------%s---------", __func__);
    NSLog(@"%@",params);
}

- (void)js_commonLinkTo1133:(NSDictionary *)params{
    NSLog(@"-------%s---------", __func__);
    NSLog(@"%@",params);
}

//js api方法名前缀  如：fund
- (NSString *)zh_jsApiPrefixName{
    return @"fundxxxxxxxxxxx";
}
//ios api方法名前缀 如：js_
- (NSString *)zh_iosApiPrefixName{
    return @"js_";
}

- (void)dealloc{
    NSLog(@"-------%s---------", __func__);
}

@end
