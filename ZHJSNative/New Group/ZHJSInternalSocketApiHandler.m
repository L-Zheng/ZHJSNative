//
//  ZHJSInternalSocketApiHandler.m
//  ZHJSNative
//
//  Created by Zheng on 2020/3/28.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHJSInternalSocketApiHandler.h"
#import "ZHWebView.h"

@implementation ZHJSInternalSocketApiHandler

//socket链接调试
/** socket调试代理  声明方法 */
- (void)js_socketDidOpen:(NSDictionary *)params{
    [self socketPerformSel:__func__ params:params];
}
- (void)js_socketDidReceiveMessage:(NSDictionary *)params{
    NSLog(@"---------js_socketDidReceiveMessage-----------");
    NSLog(@"%@",params);
    [self socketPerformSel:__func__ params:params];
}
- (void)js_socketDidError:(NSDictionary *)params{
    [self socketPerformSel:__func__ params:params];
}
- (void)js_socketDidClose:(NSDictionary *)params{
    [self socketPerformSel:__func__ params:params];
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
