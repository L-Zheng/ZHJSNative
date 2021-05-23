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
    if (![self respondsToSelector:sel]) return;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:sel withObject:params];
#pragma clang diagnostic pop
}

- (void)socketDidOpen:(NSDictionary *)params{
    
}
- (void)socketDidReceiveMessage:(NSDictionary *)params{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![params isKindOfClass:[NSDictionary class]]) return;
        NSString *type = [params valueForKey:@"type"];
        if (![type isKindOfClass:[NSString class]]) return;
        
        NSObject *target = self.webView.debugItem;
        
        if ([type isEqualToString:@"invalid"]) {
            if ([target respondsToSelector:@selector(webViewCallReadyRefresh)]) {
                [target performSelector:@selector(webViewCallReadyRefresh) withObject:nil];
            }
            if ([target respondsToSelector:@selector(webViewCallStartRefresh:)]) {
                [NSObject cancelPreviousPerformRequestsWithTarget:target selector:@selector(webViewCallStartRefresh:) object:nil];
            }
            return;
        }
        if ([type isEqualToString:@"hash"]) {
            if ([target respondsToSelector:@selector(webViewCallStartRefresh:)]) {
                [NSObject cancelPreviousPerformRequestsWithTarget:target selector:@selector(webViewCallStartRefresh:) object:nil];
            }
            return;
        }
        if ([type isEqualToString:@"ok"] || [type isEqualToString:@"warnings"]) {
            if ([target respondsToSelector:@selector(webViewCallStartRefresh:)]) {
                [NSObject cancelPreviousPerformRequestsWithTarget:target selector:@selector(webViewCallStartRefresh:) object:nil];
                [target performSelector:@selector(webViewCallStartRefresh:) withObject:nil afterDelay:0.3];
            }
            return;
        }
    });
}
- (void)socketDidError:(NSDictionary *)params{
    
}
- (void)socketDidClose:(NSDictionary *)params{
    
}

//js api方法名前缀  如：fund
- (NSString *)zh_jsApiPrefixName{
    return @"ZhengSocket";
}
//ios api方法名前缀 如：js_
- (NSString *)zh_iosApiPrefixName{
    return @"js_";
}
//js api注入完成通知H5事件的名称
- (NSString *)zh_jsApiInjectFinishEventName{
    return @"ZhengSocketApiInjectFinishEvent";
}

- (void)dealloc{
    NSLog(@"%s", __func__);
}

@end
