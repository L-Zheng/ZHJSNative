//
//  ZHCustom2ApiHandler.m
//  ZHJSNative
//
//  Created by EM on 2020/5/15.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHCustom2ApiHandler.h"

@implementation ZHCustom2ApiHandler

- (void)js_commonLinkTo11:(NSDictionary *)params{
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
    NSLog(@"%s", __func__);
}

@end
