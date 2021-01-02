//
//  ZHJSApiProtocol.h
//  ZHJSNative
//
//  Created by EM on 2020/3/24.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZHJSApiCallItem.h"

@protocol ZHJSApiProtocol <NSObject>
@required
/**  方法说明
 如： js中要使用api ---->  fund.request({})      zh_iosApiPrefixName = @'js_"
 则：- (NSString *)zh_jsApiPrefixName{return @"fund"}
 对应的原生方法实现 - (void)js_request:(NSDictionary *)params params1:(id)params1 <#xxx:(id)xxx#> callItem:(ZHJSApiCallItem *)callItem{}
 */
//js api方法名前缀  如：fund
- (NSString *)zh_jsApiPrefixName;
//ios api方法名前缀 如：js_
- (NSString *)zh_iosApiPrefixName;

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
   - (void)js_<#functionName#>:(id)params{}
   - (void)js_<#functionName#>:(id)params params1:(id)params1 <#xxx:(id)xxx#> callItem:(ZHJSApiCallItem *)callItem{}

 同步方法
   //返回JS类型Object
   - (NSDictionary *)js_<#functionName#>Sync{}
   - (NSDictionary *)js_<#functionName#>Sync:(id)params params1:(id)params1 <#xxx:(id)xxx#> callItem:(ZHJSApiCallItem *)callItem{}

   //返回JS类型Array
   - (NSArray *)js_<#functionName#>Sync{}
   - (NSArray *)js_<#functionName#>Sync:(id)params params1:(id)params1 <#xxx:(id)xxx#> callItem:(ZHJSApiCallItem *)callItem{}

   //返回JS类型String
   - (NSString *)js_<#functionName#>Sync{}
   - (NSString *)js_<#functionName#>Sync:(id)params params1:(id)params1 <#xxx:(id)xxx#> callItem:(ZHJSApiCallItem *)callItem{}

   //返回JS类型Number
   - (NSNumber *)js_<#functionName#>Sync{}
   - (NSNumber *)js_<#functionName#>Sync:(id)params params1:(id)params1 <#xxx:(id)xxx#> callItem:(ZHJSApiCallItem *)callItem{}
   
   //返回JS类型Boolean：@(YES)、@(NO)
   - (NSNumber *)js_<#functionName#>Sync{}
   - (NSNumber *)js_<#functionName#>Sync:(id)params params1:(id)params1 <#xxx:(id)xxx#> callItem:(ZHJSApiCallItem *)callItem{}
 */
@end
