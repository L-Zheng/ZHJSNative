//
//  ZHJSApiProtocol.h
//  ZHJSNative
//
//  Created by EM on 2020/3/24.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZHJSApiItem.h"

#define ZHJS_Export_Func_Config_Prefix_Format @"ZHJS_Export_Func_Config_Prefix_%@"
#define ZHJS_EXPORT_FUNC_CONFIG_INTERNAL(selArg, ...) \
- (NSDictionary *)ZHJS_Export_Func_Config_Prefix_ ## selArg { \
    NSDictionary *(^block)(id selStr, ...) = ^NSDictionary *(id selStr, ...){ \
        NSMutableArray *bArgs = [NSMutableArray array]; \
        va_list bList; id bArg; \
        va_start(bList, selStr); \
        while ((bArg = va_arg(bList, id))) { \
            [bArgs addObject:bArg]; \
        } \
        va_end(bList); \
        NSMutableDictionary *config = [NSMutableDictionary dictionary]; \
        NSUInteger idx = 0; \
        if (bArgs.count > idx && [bArgs[idx] isKindOfClass:[NSNumber class]]) { \
            [config setObject:@([(NSNumber *)bArgs[idx] boolValue]) forKey:@"sync"]; \
        } \
        idx = 1; \
        if (bArgs.count > idx && [bArgs[idx] isKindOfClass:[NSString class]] && [(NSString *)bArgs[idx] length] > 0) { \
            [config setObject:bArgs[idx] forKey:@"supportVersion"]; \
        } \
        idx = 2; \
        if (bArgs.count > idx && [bArgs[idx] isKindOfClass:[NSDictionary class]]) { \
            [config setObject:bArgs[idx] forKey:@"extraInfo"]; \
        } \
        return config.copy; \
    }; \
    return block(@" ## selArg ## ", ## __VA_ARGS__, nil);\
}
#define ZHJS_EXPORT_FUNC(sel, ...) ZHJS_EXPORT_FUNC_CONFIG_INTERNAL(sel, ## __VA_ARGS__)


@protocol ZHJSApiProtocol <NSObject>
@required
/**  方法说明
 如： js中要使用api ---->  fund.request({})      zh_iosApiPrefixName = @'js_"
 则：- (NSString *)zh_jsApiPrefixName{return @"fund"}
 对应的原生方法实现 - (void)js_request:(ZHJSApiArgItem *)arg <#xxx:(ZHJSApiArgItem *)xxx#>{}
 */
//js api方法名前缀  如：fund
- (NSString *)zh_jsApiPrefixName;
//ios api方法名前缀 如：js_
- (NSString *)zh_iosApiPrefixName;

@optional
//js api注入完成通知H5事件的名称(WebView可能需要)
// h5监听代码： window.addEventListener('xxx', () => {});
- (NSString *)zh_jsApiInjectFinishEventName;
/**
 ⚠️⚠️⚠️添加API步骤：
 在服从协议ZHJSApiProtocol的类中实现方法即可：
 id参数：js类型-->原生类型 对应关系
        function：    params=[NSNull null]，function经JSON.stringify转换为null，原生接受为NSNull
        null：           params=[NSNull null]，null经JSON.stringify转换为null，原生接受为NSNull
        undefined： params=[NSNull null]，undefined经JSON.stringify转换为null，原生接受为NSNull
        boolean：    params=@(YES) or @(NO)  [NSNumber class]
        number：    params= [NSNumber class]
        string：        params= [NSString class]
        array：         params= [NSArray class]
        json：          params= [NSDictionary class]
 异步方法
   - (void)js_<#functionName#>{}
   - (void)js_<#functionName#>:(ZHJSApiArgItem *)arg{}
   - (void)js_<#functionName#>:(ZHJSApiArgItem *)arg <#xxx:(ZHJSApiArgItem *)xxx#>{}

 同步方法
   //返回JS类型Object
   - (NSDictionary *)js_<#functionName#>Sync{}
   - (NSDictionary *)js_<#functionName#>Sync:(ZHJSApiArgItem *)arg <#xxx:(ZHJSApiArgItem *)xxx#>{}

   //返回JS类型Array
   - (NSArray *)js_<#functionName#>Sync{}
   - (NSArray *)js_<#functionName#>Sync:(ZHJSApiArgItem *)arg <#xxx:(ZHJSApiArgItem *)xxx#>{}

   //返回JS类型String
   - (NSString *)js_<#functionName#>Sync{}
   - (NSString *)js_<#functionName#>Sync:(ZHJSApiArgItem *)arg <#xxx:(ZHJSApiArgItem *)xxx#>{}

   //返回JS类型Number
   - (NSNumber *)js_<#functionName#>Sync{}
   - (NSNumber *)js_<#functionName#>Sync:(ZHJSApiArgItem *)arg <#xxx:(ZHJSApiArgItem *)xxx#>{}
   
   //返回JS类型Boolean：@(YES)、@(NO)
   - (NSNumber *)js_<#functionName#>Sync{}
   - (NSNumber *)js_<#functionName#>Sync:(ZHJSApiArgItem *)arg <#xxx:(ZHJSApiArgItem *)xxx#>{}
 */
@end
