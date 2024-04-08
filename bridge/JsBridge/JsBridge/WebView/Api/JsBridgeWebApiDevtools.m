//
//  JsBridgeWebApiDevtools.m
//  JsBridge
//
//  Created by EM on 2024/4/7.
//

#import "JsBridgeWebApiDevtools.h"
#import "JsBridgeWebView.h"
#import "JsBridgeWebHandler.h"

@implementation JsBridgeWebApiDevtoolsSocket
- (void)js_connect:(JsBridgeApiArgItem *)arg1{
    if (self.connect) self.connect(arg1.jsData);
}
- (void)js_onOpen:(JsBridgeApiArgItem *)arg1{
    if (self.onOpen) {
        self.onOpen(^(id msg) {
            arg1.callItem.jsFuncArg_call(msg);
        });
    }
}
- (void)js_onMessage:(JsBridgeApiArgItem *)arg1{
    if (self.onMessage) {
        self.onMessage(^(id msg) {
            arg1.callItem.jsFuncArg_callA(msg, YES);
        });
    }
}
- (void)js_send:(JsBridgeApiArgItem *)arg1{
    if (self.send) self.send(arg1.jsData);
}

- (NSString *)jsBridge_jsApiPrefix{
    return @"JsBridge_DevtoolsSocket";
}
- (NSString *)jsBridge_iosApiPrefix{
    return @"js_";
}
- (BOOL)jsBridge_privateApi{
    return YES;
}
@end


@implementation JsBridgeWebApiDevtools

- (void)injectJs:(NSDictionary *)info{
    if (!info || ![info isKindOfClass:NSDictionary.class] || info.allKeys.count == 0) {
        return;
    }
    NSString *urlStr = [info valueForKey:@"url"];
    NSString *src = [info valueForKey:@"src"];
    if (!src || ![src isKindOfClass:NSString.class] || src.length == 0) {
        return;
    }
    NSURL *url = [NSURL URLWithString:src];
    if (!url) {
        return;
    }
    __weak __typeof__(self) weakSelf = self;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 5.0;
    request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    NSURLSession *se = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    NSURLSessionDataTask *task = [se dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data || ![data isKindOfClass:NSData.class] || data.length == 0) {
            return;
        }
        NSString *jsStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (!jsStr || ![jsStr isKindOfClass:NSString.class] || jsStr.length == 0) {
            return;
        }
        jsStr = [NSString stringWithFormat:@"if (!window.FundDevtoolsServerUrl) { window.FundDevtoolsServerUrl = '%@'; %@; }", urlStr, jsStr];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.jsBridge.web runJs:jsStr cold:NO complete:nil];
        });
    }];
    [task resume];
}
- (void)js_open:(JsBridgeApiArgItem *)arg1{
    __weak __typeof__(self) weakSelf = self;
    if (self.open && arg1.callItem) {
        self.open(^(NSDictionary *info) {
            /* 可能存在跨域问题,
             不能直接使用script加载 http://localhost:8080/target.js,
             需要下载后注入, 另外使用script加载会存在缓存
            */
//            arg1.callItem.jsFuncArg_call(info);
            [weakSelf injectJs:info];
        });
    }
}

- (NSString *)jsBridge_jsApiPrefix{
    return @"JsBridge_Devtools";
}
- (NSString *)jsBridge_iosApiPrefix{
    return @"js_";
}
- (BOOL)jsBridge_privateApi{
    return YES;
}


@end
