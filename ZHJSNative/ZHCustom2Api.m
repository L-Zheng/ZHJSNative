//
//  ZHCustom2Api.m
//  ZHJSNative
//
//  Created by EM on 2020/5/15.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHCustom2Api.h"

@implementation ZHCustom2Api

- (void)js_commonLinkTo11:(ZHJSApiArgItem *)arg{
    NSLog(@"-------%s---------", __func__);
    NSLog(@"%@",arg.jsonData);
}

//js api方法名前缀  如：fund
- (NSString *)zh_jsApiPrefixName{
    return @"zheng2";
}
//ios api方法名前缀 如：js_
- (NSString *)zh_iosApiPrefixName{
    return @"js_";
}

- (void)dealloc{
    NSLog(@"%s", __func__);
}

@end
