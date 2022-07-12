//
//  JsBridgeWebApiSocket.m
//  JsBridge
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "JsBridgeWebApiSocket.h"
#import "JsBridgeWebView.h"

@implementation JsBridgeWebApiSocket

- (void)js_socketDidOpen:(JsBridgeApiArgItem *)arg{
    [self socketPerformSel:__func__ params:arg.jsonData];
}
- (void)js_socketDidReceiveMessage:(JsBridgeApiArgItem *)arg{
    [self socketPerformSel:__func__ params:arg.jsonData];
}
- (void)js_socketDidError:(JsBridgeApiArgItem *)arg{
    [self socketPerformSel:__func__ params:arg.jsonData];
}
- (void)js_socketDidClose:(JsBridgeApiArgItem *)arg{
    [self socketPerformSel:__func__ params:arg.jsonData];
}
- (void)socketPerformSel:(const char *)funcName params:(NSDictionary *)params{
    NSString *funcStr = [NSString stringWithUTF8String:funcName];
    NSString *prefix = [self jsBridge_iosApiPrefix];
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
        
        NSObject *target = self.jsBridge.socketDelegate;
        JsBridgeWebView *web = self.jsBridge.web;
        SEL sel;
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([type isEqualToString:@"invalid"]) {
            sel = @selector(jsBridgeWebViewSocketRefreshReady:);
            if ([target respondsToSelector:sel]) {
                [target performSelector:sel withObject:web];
            }
            sel = @selector(jsBridgeWebViewSocketRefreshStart:);
            if ([target respondsToSelector:sel]) {
                [NSObject cancelPreviousPerformRequestsWithTarget:target selector:sel object:web];
            }
            return;
        }
        if ([type isEqualToString:@"hash"]) {
            sel = @selector(jsBridgeWebViewSocketRefreshStart:);
            if ([target respondsToSelector:sel]) {
                [NSObject cancelPreviousPerformRequestsWithTarget:target selector:sel object:web];
            }
            return;
        }
        if ([type isEqualToString:@"ok"] || [type isEqualToString:@"warnings"]) {
            sel = @selector(jsBridgeWebViewSocketRefreshStart:);
            if ([target respondsToSelector:sel]) {
                [NSObject cancelPreviousPerformRequestsWithTarget:target selector:sel object:web];
                // 清除缓存, 否则ios11以上不会实时刷新最新的改动
                [self clearWebSystemCache:^{
                    [target performSelector:sel withObject:web afterDelay:0.3];
                }];
            }
            return;
        }
#pragma clang diagnostic pop
    });
}
- (void)socketDidError:(NSDictionary *)params{
}
- (void)socketDidClose:(NSDictionary *)params{
}

- (NSString *)jsBridge_jsApiPrefix{
    return @"My_JsBridge_Socket";
}
- (NSString *)jsBridge_iosApiPrefix{
    return @"js_";
}


- (void)clearWebSystemCache:(void (^) (void))complete{
    if (@available(iOS 9.0, *)) {
        WKWebsiteDataStore *dataSource = [WKWebsiteDataStore defaultDataStore];
//        NSMutableSet *set = [WKWebsiteDataStore allWebsiteDataTypes];
        NSMutableSet *set = [NSMutableSet set];
        [set addObjectsFromArray:@[
            WKWebsiteDataTypeDiskCache,//硬盘缓存
            WKWebsiteDataTypeMemoryCache,//内存缓存
            WKWebsiteDataTypeOfflineWebApplicationCache//离线应用缓存
//            WKWebsiteDataTypeCookies,//cookie
//            WKWebsiteDataTypeSessionStorage,//session
//            WKWebsiteDataTypeLocalStorage,//localStorage,cookie的一个兄弟
//            WKWebsiteDataTypeWebSQLDatabases,//数据库
//            WKWebsiteDataTypeIndexedDBDatabases//索引数据库
        ]];
        if (@available(iOS 11.3, *)) {
            [set addObjectsFromArray:@[
                WKWebsiteDataTypeFetchCache,//硬盘fetch缓存
                WKWebsiteDataTypeServiceWorkerRegistrations
            ]];
        }
        [dataSource removeDataOfTypes:set modifiedSince:[NSDate dateWithTimeIntervalSince1970:0] completionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (complete) complete();
            });
        }];
        return;
    }
    NSFileManager *mg = [NSFileManager defaultManager];
    void (^removeFolder)(NSString *) = ^(NSString *folder){
        if ([mg fileExistsAtPath:folder]) {
            [mg removeItemAtPath:folder error:nil];
        }
    };
    NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    NSString *libraryDir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask, YES)[0];
    NSString *tempDir = NSTemporaryDirectory();
    NSString *path1 = [NSString stringWithFormat:@"%@/WebKit/%@/WebsiteData", libraryDir, bundleId];
    NSString *path2 = [NSString stringWithFormat:@"%@/Caches/%@/WebKit", libraryDir, bundleId];
    NSString *path3 = [NSString stringWithFormat:@"%@/%@/WebKit", tempDir, bundleId];
    removeFolder(path1);
    removeFolder(path2);
    removeFolder(path3);
    if (complete) complete();
}

@end
