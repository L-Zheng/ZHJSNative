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

- (NSDictionary *)js_getJsonSync:(NSDictionary *)params p1:(NSDictionary *)p1 p2:(id)p2 p3:(id)p3 p4:(id)p4 p5:(id)p5 p6:(id)p6 p7:(id)p7 p8:(id)p8 p9:(id)p9 callBack:(ZHJSApiArgsBlock)callBack{
    
    ZHJSApiArgsBlock block1 = params[ZHJSApiParamsBlockKey];
    ZHJSApiArgsBlock block2 = p1[ZHJSApiParamsBlockKey];
    
    if (block1) {
        NSDictionary *callMap = @{
            ZHJSApiRunResSuccessBlockKey: ^ZHJSApiRunResBlockHeader{
                NSLog(@"%@",result);
                NSLog(@"%@",error);
                return result;
            },
            ZHJSApiRunResFailBlockKey: ^ZHJSApiRunResBlockHeader{
                NSLog(@"%@",result);
                NSLog(@"%@",error);
                return result;
            },
            ZHJSApiRunResCompleteBlockKey: ^ZHJSApiRunResBlockHeader{
                NSLog(@"%@",result);
                NSLog(@"%@",error);
                return result;
            }
        };
        block1(@"lkjhg", nil, @(YES), callMap, nil);
    }
    if (block2) block2(@"2222", nil, nil);
    if (callBack) callBack(@"3333", nil, nil);
    return @{@"sdfd": @"22222", @"sf": @(YES)};
}
- (NSNumber *)js_getNumberSync:(NSDictionary *)params{
    NSLog(@"-------%s---------", __func__);
    return @(22);
}
- (NSNumber *)js_getBoolSync:(NSDictionary *)params{
    NSLog(@"-------%s---------", __func__);
    return @(YES);
}
- (NSString *)js_getStringSync:(NSDictionary *)params{
    NSLog(@"-------%s---------", __func__);
    return @"dfgewrefdwd";
}
- (void)js_commonLinkTo:(NSDictionary *)params p1:(id)p1 p2:(id)p2 p3:(id)p3 p4:(id)p4 p5:(id)p5 p6:(id)p6 p7:(id)p7 p8:(id)p8 p9:(id)p9 callBack:(ZHJSApiArgsBlock)callBack{
    
    ZHJSApiArgsBlock block1 = params[ZHJSApiParamsBlockKey];
    ZHJSApiArgsBlock block2 = p1[ZHJSApiParamsBlockKey];
    
    if (block1) block1(@"1111", nil, @(YES), nil);
    if (block2) block2(@"2222", nil, nil);
    
    if (callBack) callBack(@"3333", nil, nil);
    NSLog(@"-------%s---------", __func__);
}


- (NSDictionary *)js_getEmotionResourceSync:(NSDictionary *)params{
    return [ZHEmotion shareManager].emotionMap;
}
//获取大表情资源
- (NSDictionary *)js_getBigEmotionResourceSync:(NSDictionary *)params{
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
