//
//  DemoApi.m
//  JsBridge
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "DemoApi.h"
#import "DemoApiModule.h"

@implementation DemoApi

JsBridge_Export_Func(getSystemInfo, @(YES), @"5.4.2", @{@"a": @"b"})
- (void)js_getSystemInfo:(JsBridgeApiArgItem *)arg{
    NSDictionary *res = [self js_getSystemInfoSync:nil];
    NSDictionary *fail = @{@"data": @"fail-ios"};
    NSDictionary *complete = @{@"data": @"complete-ios"};
    
    JsBridgeApiCallJsItem *call = arg.callItem;
    if (call) {
        NSError *error = [[NSError alloc] initWithDomain:@"sf" code:404 userInfo:@{NSLocalizedDescriptionKey: @"sf"}];
//        call.call(res, error);
        call.callSFCA(res, fail, complete, error, NO);
//        call.callSFC(res, fail, complete, error);
//        call.callA(res, nil, NO);
//        call.call(res, nil);
    }
}
- (NSDictionary *)js_getSystemInfoSync:(JsBridgeApiArgItem *)arg{
    return @{@"func": @"js_getSystemInfoSync"};
}
//js api方法名前缀
- (NSString *)jsBridge_jsApiPrefix{
    return @"MyApi";
}
//ios api方法名前缀 如：js_
- (NSString *)jsBridge_iosApiPrefix{
    return @"js_";
}
//js api注入完成通知H5事件的名称(WebView可能需要)
// h5监听代码： window.addEventListener('xxx', () => {});
- (NSString *)jsBridge_jsApiInjectFinishEventName{
    return @"MyApiInjectFinish";
}
// api module实例
- (NSArray <id<JsBridgeApiProtocol>> *)jsBridge_apiModules{
    return @[[[DemoApiModule alloc] init]];
}

@end
