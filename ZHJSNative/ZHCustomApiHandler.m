//
//  ZHCustomApiHandler.m
//  ZHJSNative
//
//  Created by EM on 2020/3/24.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHCustomApiHandler.h"
#import "ZHEmotion.h"

@implementation ZHCustomApiHandler

#pragma mark - api

- (NSNumber *)js_getNumberSync:(ZHJSApiArgItem *)arg{
    NSLog(@"-------%s---------", __func__);
    return @(22);
}
- (NSNumber *)js_getBoolSync:(ZHJSApiArgItem *)arg{
    NSLog(@"-------%s---------", __func__);
    return @(YES);
}
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
    return @"fund";
}
//ios api方法名前缀 如：js_
- (NSString *)zh_iosApiPrefixName{
    return @"js_";
}

- (void)dealloc{
    NSLog(@"%s", __func__);
}
@end
