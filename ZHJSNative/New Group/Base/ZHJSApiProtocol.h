//
//  ZHJSApiProtocol.h
//  ZHJSNative
//
//  Created by EM on 2020/3/24.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

//NS_ASSUME_NONNULL_BEGIN

typedef void(^ZHJSApiBlock)(id result, NSError *error);
typedef void(^ZHJSApiAliveBlock)(id result, NSError *error, BOOL alive);

@protocol ZHJSApiProtocol <NSObject>
@required
/**  方法说明
 如： js中要使用api ---->  fund.request({})      zh_iosApiPrefixName = @'js_"
 则：- (NSString *)zh_jsApiPrefixName{return @"fund"}
 对应的原生方法实现 - (void)js_request:(NSDictionary *)params callBack:(ZHJSApiBlock)callBack{}
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
 callBack参数：
        ZHJSApiBlock：只能调用一次，再次调用无效
        ZHJSApiAliveBlock：
            alive：YES 可调用多次
            alive：NO 只能调用一次，再次调用无效
 异步方法
   - (void)js_<#functionName#>{}
   - (void)js_<#functionName#>:(id)params{}
   - (void)js_<#functionName#>:(id)params callBack:(ZHJSApiBlock)callBack{}
   - (void)js_<#functionName#>:(id)params callBack:(ZHJSApiAliveBlock)callBack{}

 同步方法
   //返回JS类型Object
   - (NSDictionary *)js_<#functionName#>Sync{}
   - (NSDictionary *)js_<#functionName#>Sync:(id)params{} callBack:(ZHJSApiBlock)callBack{}
   - (NSDictionary *)js_<#functionName#>Sync:(id)params{} callBack:(ZHJSApiAliveBlock)callBack{}

   //返回JS类型Array
   - (NSArray *)js_<#functionName#>Sync{}
   - (NSArray *)js_<#functionName#>Sync:(id)params{} callBack:(ZHJSApiBlock)callBack{}
   - (NSArray *)js_<#functionName#>Sync:(id)params{} callBack:(ZHJSApiAliveBlock)callBack{}

   //返回JS类型String
   - (NSString *)js_<#functionName#>Sync{}
   - (NSString *)js_<#functionName#>Sync:(id)params{} callBack:(ZHJSApiBlock)callBack{}
   - (NSString *)js_<#functionName#>Sync:(id)params{} callBack:(ZHJSApiAliveBlock)callBack{}

   //返回JS类型Number
   - (NSNumber *)js_<#functionName#>Sync{}
   - (NSNumber *)js_<#functionName#>Sync:(id)params{} callBack:(ZHJSApiBlock)callBack{}
   - (NSNumber *)js_<#functionName#>Sync:(id)params{} callBack:(ZHJSApiAliveBlock)callBack{}
   
   //返回JS类型Boolean：@(YES)、@(NO)
   - (NSNumber *)js_<#functionName#>Sync{}
   - (NSNumber *)js_<#functionName#>Sync:(id)params{} callBack:(ZHJSApiBlock)callBack{}
   - (NSNumber *)js_<#functionName#>Sync:(id)params{} callBack:(ZHJSApiAliveBlock)callBack{}
 */
@end

//NS_ASSUME_NONNULL_END
