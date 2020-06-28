//
//  ZHJSInternalApiHandler.m
//  ZHJSNative
//
//  Created by EM on 2020/3/24.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHJSInternalApiHandler.h"
#import "ZHJSApiHandler.h"
#import "ZHJSHandler.h"

@implementation ZHJSInternalApiHandler


- (ZHWebView *)webView{
    return self.apiHandler.handler.webView;
}

//js api方法名前缀  如：fund
- (NSString *)zh_jsApiPrefixName{
    return @"zheng";
}
//ios api方法名前缀 如：js_
- (NSString *)zh_iosApiPrefixName{
    return @"js_";
}

- (void)dealloc{
    NSLog(@"%s", __func__);
}

@end
