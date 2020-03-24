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
     异步方法
       - (void)js_<#functionName#><##>:(NSDictionary *)params{}
       - (void)js_<#functionName#><##>:(NSDictionary *)params callBack:(ZHJSApiBlock)callBack{}
 
     同步方法
       //返回JS类型Object
       - (NSDictionary *)js_<#functionName#><##>Sync:(NSDictionary *)params{}
 
       //返回JS类型Array
       - (NSArray *)js_<#functionName#><##>Sync:(NSDictionary *)params{}
 
       //返回JS类型String
       - (NSString *)js_<#functionName#><##>Sync:(NSDictionary *)params{}
 
       //返回JS类型Number
       - (NSNumber *)js_<#functionName#><##>Sync:(NSDictionary *)params{}
       
       //返回JS类型Boolean：@(YES)、@(NO)
       - (NSNumber *)js_<#functionName#><##>Sync:(NSDictionary *)params{}
 */
@end

//NS_ASSUME_NONNULL_END
