//
//  ZHJSInApi.m
//  ZHJSNative
//
//  Created by EM on 2020/12/20.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHJSInApi.h"
#import "ZHJSApiHandler.h"
#import "ZHJSHandler.h"

@implementation ZHJSInApi

- (ZHWebView *)webView{
    return self.apiHandler.handler.webView;
}

- (ZHJSContext *)jsContext{
    return self.apiHandler.handler.jsContext;
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
