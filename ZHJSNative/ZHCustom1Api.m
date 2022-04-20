//
//  ZHCustom1Api.m
//  ZHJSNative
//
//  Created by Zheng on 2020/3/28.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHCustom1Api.h"
@interface ZHCustom1ApiModule_A : NSObject<ZHJSApiProtocol>
@end
@implementation ZHCustom1ApiModule_A

ZHJS_EXPORT_FUNC(resume, @(NO))
- (void)js_resume:(ZHJSApiArgItem *)arg{
    NSLog(@"-------%s---------", __func__);
}
ZHJS_EXPORT_FUNC(resumeSync, @(YES))
 - (NSString *)js_resumeSync:(ZHJSApiArgItem *)arg{
     NSLog(@"-------%s---------", __func__);
     return [NSString stringWithUTF8String:__func__];
 }

//js api方法名前缀  如：fund
- (NSString *)zh_jsApiPrefixName{
    return @"zhengvoice1A";
}
//ios api方法名前缀 如：js_
- (NSString *)zh_iosApiPrefixName{
    return @"js_";
}
@end



@implementation ZHCustom1Api

- (void)js_commonLinkTo11:(ZHJSApiArgItem *)arg{
    NSLog(@"-------%s---------", __func__);
    NSLog(@"%@",arg.jsonData);
}

//js api方法名前缀  如：fund
- (NSString *)zh_jsApiPrefixName{
    return @"zheng1";
}
//ios api方法名前缀 如：js_
- (NSString *)zh_iosApiPrefixName{
    return @"js_";
}
- (NSArray <id<ZHJSApiProtocol>> *)zh_jsApiModules{
    return @[[[ZHCustom1ApiModule_A alloc] init]];
}

- (void)dealloc{
    NSLog(@"%s", __func__);
}
@end
