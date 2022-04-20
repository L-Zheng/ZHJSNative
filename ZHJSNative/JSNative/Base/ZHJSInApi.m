//
//  ZHJSInApi.m
//  ZHJSNative
//
//  Created by EM on 2020/12/20.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHJSInApi.h"

@interface ZHJSInApiModule : NSObject <ZHJSApiProtocol>
@end
@implementation ZHJSInApiModule

ZHJS_EXPORT_FUNC(stop, @(NO))
- (void)js_stop:(ZHJSApiArgItem *)arg{
    NSLog(@"-------%s---------", __func__);
}
ZHJS_EXPORT_FUNC(stopSync, @(YES))
 - (NSString *)js_stopSync:(ZHJSApiArgItem *)arg{
     NSLog(@"-------%s---------", __func__);
     return [NSString stringWithUTF8String:__func__];
 }

//js api方法名前缀  如：fund
- (NSString *)zh_jsApiPrefixName{
    return @"zhengvoiceIn";
}
//ios api方法名前缀 如：js_
- (NSString *)zh_iosApiPrefixName{
    return @"js_";
}
@end




@implementation ZHJSInApi

- (NSDictionary *)js_getJsonSync:(ZHJSApiArgItem *)arg0 arg:(ZHJSApiArgItem *)arg p1:(ZHJSApiArgItem *)p1 p2:(id)p2 p3:(id)p3 p4:(id)p4 p5:(id)p5 p6:(id)p6 p7:(id)p7 p8:(id)p8 p9:(id)p9{
    
    ZHJSApiCallJsArgItem *callArg0 = [ZHJSApiCallJsArgItem item];
    callArg0.jsFuncArgDatas = @[@"x1", @"x2"];
    callArg0.alive = YES;
    callArg0.jsFuncArgResBlock = ^ZHJSApi_CallJsResNativeBlock_Header {
        NSLog(@"success res: %@--error:%@",jsResItem.result, jsResItem.error);
        return [ZHJSApiCallJsResNativeResItem item];
    };
    if (arg0.callItem.jsFuncArg_callArg) {
        arg0.callItem.jsFuncArg_callArg(callArg0);
    }
    if (arg0.callItem.jsFuncArg_callA) {
        arg0.callItem.jsFuncArg_callA(@"x1", YES);
    }
    if (arg0.callItem.jsFuncArg_call) {
        arg0.callItem.jsFuncArg_m_call(@[@"x1", @"x2"]);
    }
    
//    ZHJSApiCallJsArgItem *callArgItem = [ZHJSApiCallJsArgItem item];
//    callArgItem.successDatas = @[@"x1", @"x2"];
//    callArgItem.error = nil;
//    callArgItem.alive = YES;
//    callArgItem.jsResSuccessBlock = ^ZHJSApi_CallJsResNativeBlock_Header {
//        NSLog(@"success res: %@--error:%@",jsResItem.result, jsResItem.error);
//        return [ZHJSApiCallJsResNativeResItem item];
//    };
//    callArgItem.jsResFailBlock = ^ZHJSApi_CallJsResNativeBlock_Header {
//        NSLog(@"fail res: %@--error:%@",jsResItem.result, jsResItem.error);
//        return [ZHJSApiCallJsResNativeResItem item];
//    };
//    callArgItem.jsResCompleteBlock = ^ZHJSApi_CallJsResNativeBlock_Header {
//        NSLog(@"complete res: %@--error:%@",jsResItem.result, jsResItem.error);
//        return [ZHJSApiCallJsResNativeResItem item];
//    };
//
//    if (arg.callItem.callArg) arg.callItem.callArg(callArgItem);
////    if (p1.callItem.call) p1.callItem.call(@"2222", nil);
    
    return @{@"sdfd": @"22222", @"sf": @(YES)};
}

- (void)js_commonLinkTo:(ZHJSApiArgItem *)arg p1:(ZHJSApiArgItem *)p1 p2:(id)p2 p3:(id)p3 p4:(id)p4 p5:(id)p5 p6:(id)p6 p7:(id)p7 p8:(id)p8 p9:(id)p9{
    
    ZHJSApiCallJsItem *item1 = arg.callItem;
    ZHJSApiCallJsItem *item2 = p1.callItem;
    
    if (item1.callA) item1.callA(@"1111", nil, YES);
    if (item2.call) item2.call(@"2222", nil);
    
    if (item1.call) item1.call(@"3333", nil);
    NSLog(@"-------%s---------", __func__);
}
- (void)js_commonLinkTo11:(ZHJSApiArgItem *)arg{
   ZHJSApiCallJsItem *item1 = arg.callItem;
   if (item1.call) item1.call(@"2222", nil);
}
ZHJS_EXPORT_FUNC(getTest111, @(YES))
 - (NSNumber *)js_getTest111:(ZHJSApiArgItem *)arg{
     NSLog(@"-------%s---------", __func__);
     return @(22);
}

ZHJS_EXPORT_FUNC(getNumberSync, @(YES))
 - (NSNumber *)js_getNumberSync:(ZHJSApiArgItem *)arg{
     NSLog(@"-------%s---------", __func__);
     return @(22);
 }
ZHJS_EXPORT_FUNC(getBoolSync, @(YES))
 - (NSNumber *)js_getBoolSync:(ZHJSApiArgItem *)arg{
     NSLog(@"-------%s---------", __func__);
     return @(YES);
 }
ZHJS_EXPORT_FUNC(getStringSync, @(YES), @"5.4.2", @{@"dd": @"vvv"})
 - (NSString *)js_getStringSync:(ZHJSApiArgItem *)arg{
     NSLog(@"-------%s---------", __func__);
     return @"dfgewrefdwd";
 }

- (id <ZHJSPageProtocol>)jsPage{
    return self.webView?:self.jsContext;
}

//js api方法名前缀  如：fund
- (NSString *)zh_jsApiPrefixName{
    return @"zheng";
}
//ios api方法名前缀 如：js_
- (NSString *)zh_iosApiPrefixName{
    return @"js_";
}
//js api注入完成通知H5事件的名称
- (NSString *)zh_jsApiInjectFinishEventName{
    return @"zhengApiInjectFinishEvent";
}
- (NSArray <id<ZHJSApiProtocol>> *)zh_jsApiModules{
    return @[[[ZHJSInApiModule alloc] init]];
}

- (void)dealloc{
    NSLog(@"%s", __func__);
}

@end
