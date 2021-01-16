//
//  ZHJSInWebSocketApi.m
//  ZHJSNative
//
//  Created by EM on 2020/12/20.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHJSInWebSocketApi.h"
#import "ZHWebView.h"

@implementation ZHJSInWebSocketApi

//socket链接调试
/** socket调试代理  声明方法 */
- (void)js_socketDidOpen:(ZHJSApiArgItem *)arg{
    [self socketPerformSel:__func__ params:arg.jsonData];
}
- (void)js_socketDidReceiveMessage:(ZHJSApiArgItem *)arg{
    NSLog(@"---------js_socketDidReceiveMessage-----------");
    NSLog(@"%@",arg.jsonData);
    [self socketPerformSel:__func__ params:arg.jsonData];
}
- (void)js_socketDidError:(ZHJSApiArgItem *)arg{
    [self socketPerformSel:__func__ params:arg.jsonData];
}
- (void)js_socketDidClose:(ZHJSApiArgItem *)arg{
    [self socketPerformSel:__func__ params:arg.jsonData];
}
- (void)socketPerformSel:(const char *)funcName params:(NSDictionary *)params{
    NSString *funcStr = [NSString stringWithUTF8String:funcName];
    NSString *prefix = [self zh_iosApiPrefixName];
    NSString *matchStr = [NSString stringWithFormat:@"%@ %@", NSStringFromClass([self class]), prefix];
    NSRange range = [funcStr rangeOfString:matchStr];
    funcStr = [funcStr substringWithRange:NSMakeRange(range.location + range.length, funcStr.length - range.location - range.length - 1)];
    
    SEL sel = NSSelectorFromString(funcStr);
    if (![self.webView.debugConfig respondsToSelector:sel]) return;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.webView.debugConfig performSelector:sel withObject:params];
#pragma clang diagnostic pop
}

//js api方法名前缀  如：fund
- (NSString *)zh_jsApiPrefixName{
    return @"ZhengSocket";
}
//ios api方法名前缀 如：js_
- (NSString *)zh_iosApiPrefixName{
    return @"js_";
}

- (void)dealloc{
    NSLog(@"%s", __func__);
}

@end
