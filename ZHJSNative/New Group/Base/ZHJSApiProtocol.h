//
//  ZHJSApiProtocol.h
//  ZHJSNative
//
//  Created by EM on 2020/3/24.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

// 调用js函数（success、fail、complete）的返回值
static NSString * const ZHJSResSuccessBlockKey = @"ZHJSResSuccessBlockKey";
static NSString * const ZHJSResFailBlockKey = @"ZHJSResFailBlockKey";
static NSString * const ZHJSResCompleteBlockKey = @"ZHJSResCompleteBlockKey";
#define ZHJSResBlockHeader id(id result, NSError *error, ...)
typedef id(^ZHJSResBlock)(id result, NSError *error, ...);
/**js传递给原生的参数：（json格式 && 有success、fail、complete函数），
 就会带有此key值ZHJSApiBlockKey，其value是个block（ZHJSApiArgsBlock类型）,可用于回调给js
 */
static NSString * const ZHJSApiBlockKey = @"ZHJSApiBlockKey";
/** Block
 调用说明（⚠️最少三个参数，一律以nil结尾）：call(xx, xx, ..., nil)
 参数说明...
    回调数据：                                      id result
    调用js函数（success、fail）：       NSError *error
    允许多次调用js函数：                     NSNumber *alive    @(YES)、@(NO)
    调用js函数（success、fail、complete）的返回值： NSDictionary *runResBlockMap
                             @{
                                 ZHJSResSuccessBlockKey: ^ZHJSResBlockHeader{
                                     // 参数result、error
                                     NSLog(@"%@--%@",result, error);
                                     // 获取所有block参数
                                     NSMutableArray *bArgs = [NSMutableArray array];
                                     va_list bList; id bArg;
                                     va_start(bList, error);
                                     while ((bArg = va_arg(bList, id))) {
                                         [bArgs addObject:bArg];
                                     }
                                     va_end(bList);
                                     return nil;
                                 },
                                 ZHJSResFailBlockKey: ^ZHJSResBlockHeader{
                                     NSLog(@"%@--%@",result, error);
                                     return nil;
                                 },
                                 ZHJSResCompleteBlockKey: ^ZHJSResBlockHeader{
                                     NSLog(@"%@--%@",result, error);
                                     return nil;
                                 }
                             }
 */
typedef id(^ZHJSApiArgsBlock)(id result, NSError *error, ...);

@protocol ZHJSApiProtocol <NSObject>
@required
/**  方法说明
 如： js中要使用api ---->  fund.request({})      zh_iosApiPrefixName = @'js_"
 则：- (NSString *)zh_jsApiPrefixName{return @"fund"}
 对应的原生方法实现 - (void)js_request:(NSDictionary *)params params1:(id)params1 <#xxx:(id)xxx#> callBack:(ZHJSApiArgsBlock)callBack{}
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
   - (void)js_<#functionName#>:(id)params params1:(id)params1 <#xxx:(id)xxx#> callBack:(ZHJSApiArgsBlock)callBack{}

 同步方法
   //返回JS类型Object
   - (NSDictionary *)js_<#functionName#>Sync{}
   - (NSDictionary *)js_<#functionName#>Sync:(id)params params1:(id)params1 <#xxx:(id)xxx#> callBack:(ZHJSApiArgsBlock)callBack{}

   //返回JS类型Array
   - (NSArray *)js_<#functionName#>Sync{}
   - (NSArray *)js_<#functionName#>Sync:(id)params params1:(id)params1 <#xxx:(id)xxx#> callBack:(ZHJSApiArgsBlock)callBack{}

   //返回JS类型String
   - (NSString *)js_<#functionName#>Sync{}
   - (NSString *)js_<#functionName#>Sync:(id)params params1:(id)params1 <#xxx:(id)xxx#> callBack:(ZHJSApiArgsBlock)callBack{}

   //返回JS类型Number
   - (NSNumber *)js_<#functionName#>Sync{}
   - (NSNumber *)js_<#functionName#>Sync:(id)params params1:(id)params1 <#xxx:(id)xxx#> callBack:(ZHJSApiArgsBlock)callBack{}
   
   //返回JS类型Boolean：@(YES)、@(NO)
   - (NSNumber *)js_<#functionName#>Sync{}
   - (NSNumber *)js_<#functionName#>Sync:(id)params params1:(id)params1 <#xxx:(id)xxx#> callBack:(ZHJSApiArgsBlock)callBack{}
 */
@end
