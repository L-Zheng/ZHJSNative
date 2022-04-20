//
//  ZHCustomApi.m
//  ZHJSNative
//
//  Created by EM on 2020/3/24.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHCustomApi.h"
#import "ZHEmotion.h"

@interface ZHCustomApiModule_A : NSObject <ZHJSApiProtocol>
@end
@implementation ZHCustomApiModule_A
ZHJS_EXPORT_FUNC(play, @(NO))
- (void)js_play:(ZHJSApiArgItem *)arg{
    NSLog(@"-------%s---------", __func__);
}
ZHJS_EXPORT_FUNC(playSync, @(YES))
 - (NSString *)js_playSync:(ZHJSApiArgItem *)arg{
     NSLog(@"-------%s---------", __func__);
     return [NSString stringWithUTF8String:__func__];
 }
//js api方法名前缀  如：fund
- (NSString *)zh_jsApiPrefixName{
    return @"zhengvoice0A";
}
//ios api方法名前缀 如：js_
- (NSString *)zh_iosApiPrefixName{
    return @"js_";
}
@end


@interface ZHCustomApiModule_B : NSObject <ZHJSApiProtocol>
@end
@implementation ZHCustomApiModule_B
- (void)js_pauseA:(ZHJSApiArgItem *)arg{
    NSLog(@"-------%s---------", __func__);
}
- (void)js_pause:(ZHJSApiArgItem *)arg{
    NSLog(@"-------%s---------", __func__);
}
ZHJS_EXPORT_FUNC(pauseSync, @(YES))
 - (NSString *)js_pauseSync:(ZHJSApiArgItem *)arg{
     NSLog(@"-------%s---------", __func__);
     return [NSString stringWithUTF8String:__func__];
 }
//js api方法名前缀  如：fund
- (NSString *)zh_jsApiPrefixName{
    return @"zhengvoice0B";
}
//ios api方法名前缀 如：js_
- (NSString *)zh_iosApiPrefixName{
    return @"js_";
}
@end


@interface ZHCustomApiModule_C : NSObject <ZHJSApiProtocol>
@end
@implementation ZHCustomApiModule_C
- (void)js_pause:(ZHJSApiArgItem *)arg{
    NSLog(@"-------%s---------", __func__);
}
ZHJS_EXPORT_FUNC(pauseSync, @(YES))
 - (NSString *)js_pauseSync:(ZHJSApiArgItem *)arg{
     NSLog(@"-------%s---------", __func__);
     return [NSString stringWithUTF8String:__func__];
 }
//js api方法名前缀  如：fund
- (NSString *)zh_jsApiPrefixName{
    return @"zhengvoice0C";
}
//ios api方法名前缀 如：js_
- (NSString *)zh_iosApiPrefixName{
    return @"js_";
}
@end



@implementation ZHCustomApi

#pragma mark - api

ZHJS_EXPORT_FUNC(getTest111, @(NO))
 - (NSNumber *)js_getTest111:(ZHJSApiArgItem *)arg{
     NSLog(@"-------%s---------", __func__);
     return @(22);
}

- (NSNumber *)js_getNumberSync:(ZHJSApiArgItem *)arg{
    NSLog(@"-------%s---------", __func__);
    return @(22);
}
- (NSNumber *)js_getBoolSync:(ZHJSApiArgItem *)arg{
    NSLog(@"-------%s---------", __func__);
    return @(YES);
}
ZHJS_EXPORT_FUNC(getStringSync, @(YES), @"9.4.2", @{@"dd": @"vvv"})
- (NSString *)js_getStringSync:(ZHJSApiArgItem *)arg{
    NSLog(@"-------%s---------", __func__);
    return @"dfgewrefdwd";
}

- (NSDictionary *)js_getEmotionResourceSync:(ZHJSApiArgItem *)arg{
    return [ZHEmotion shareManager].emotionMap;
}
//获取大表情资源
- (NSDictionary *)js_getBigEmotionResourceSync:(ZHJSApiArgItem *)arg{
    return [ZHEmotion shareManager].bigEmotionMap;
}


//js api方法名前缀  如：fund
- (NSString *)zh_jsApiPrefixName{
    return @"zheng0";
}
//ios api方法名前缀 如：js_
- (NSString *)zh_iosApiPrefixName{
    return @"js_";
}
- (NSArray <id<ZHJSApiProtocol>> *)zh_jsApiModules{
    return @[[[ZHCustomApiModule_A alloc] init], [[ZHCustomApiModule_B alloc] init], [[ZHCustomApiModule_C alloc] init]];
}

- (void)dealloc{
    NSLog(@"%s", __func__);
}
@end
