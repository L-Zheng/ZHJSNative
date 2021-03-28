//
//  ZHCustom1Api.m
//  ZHJSNative
//
//  Created by Zheng on 2020/3/28.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHCustom1Api.h"

@implementation ZHCustom1Api

- (void)js_commonLinkTo11:(ZHJSApiArgItem *)arg{
    NSLog(@"-------%s---------", __func__);
    NSLog(@"%@",arg.jsonData);
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
    NSLog(@"%s", __func__);
}
@end
