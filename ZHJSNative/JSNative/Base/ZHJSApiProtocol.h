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
/* 通信各个阶段数据类型
 同步通信： [原生->js]  const res = fund.testSync(xxx);
     A：web各阶段数据类型
         1、ZHJSApiProtocol同步函数返回数据(默认返回nil)
         2、web代理回调数据: 包装数据(@{@"data": result}转NSString)然后调用completionHandler回调 -(void)webView:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:
         3、web接收数据:  var res = prompt(JSON.stringify(params)); 解析数据res.data 然后作为返回值返回
         4、api调用者获取到的数据:  var res = fund.getXXXSync();

         nil                   --> nil       --> [object Null]   --> [object Undefined]
         NSNull                --> NSString  --> [object String] --> [object Null]
         @(YES)/@(NO)          --> NSString  --> [object String] --> [object Boolean]
         NSArray               --> NSString  --> [object String] --> [object Array]
         NSNumber              --> NSString  --> [object String] --> [object Number]
         NSDictionary          --> NSString  --> [object String] --> [object Object]
         NSString(包含空字符串)  --> NSString  --> [object String] --> [object String]
         ...                   --> 空字符串   --> [object String] --> [object Null]

     B：JSCore各阶段数据类型
         1、ZHJSApiProtocol同步函数返回数据(默认返回nil)
         2、中间层处理
         3、api调用者获取到的数据 var res = fund.getXXXSync();

         nil           --> 无  --> [object Undefined]
         NSNull        --> 无  --> [object Null]
         @(YES)/@(NO)  --> 无  --> [object Boolean]
         NSArray       --> 无  --> [object Array]
         NSNumber      --> 无  --> [object Number]
         NSDictionary  --> 无  --> [object Object]
         NSString      --> 无  --> [object String]
 
 异步通信： [js->原生]  fund.test(xxx)  xxx传参类型
     A：web各阶段数据类型 (ZHJSApiProtocol异步函数返回值: 丢弃不予处理，web端 const res = fund.getTest111(Undefined); 执行后  res为[object Undefined]类型)
         1、api调用者传参数据:  const res = fund.getTest111(Undefined);
         2、web端包装数据: {apiPrefix: 'fund', methodName: 'getTest111', methodSync: false, args: resArgs}
         3、webkit发送到原生:
             经JSON.stringify()处理:
                 [object Undefined]/[object Function]数据会被转化为[object Null]
                 [object Date]数据会被转化为[object String]
             window.webkit.messageHandlers[xx].postMessage(JSON.parse(JSON.stringify(params)))
         4、原生web代理接收数据: (数据message.body) -(void)userContentController:didReceiveScriptMessage:
         5、原生解析参数数据:  NSDictionary.args[index]
         6、ZHJSApiProtocol异步函数接收数据: ZHJSApiArgItem.jsData = ((!jsData || [jsData isEqual:[NSNull null]]) ? nil : jsData)

         [object Undefined] --> [object Object] --> [object Object] --> NSDictionary --> NSNull                 --> nil
         [object Null]      --> [object Object] --> [object Object] --> NSDictionary --> NSNull                 --> nil
         [object Function]  --> [object Object] --> [object Object] --> NSDictionary --> NSDictionary           --> NSDictionary
         [object Boolean]   --> [object Object] --> [object Object] --> NSDictionary --> NSNumber[@(YES)/@(NO)] --> NSNumber
         [object Array]     --> [object Object] --> [object Object] --> NSDictionary --> NSArray                --> NSArray
         [object Number]    --> [object Object] --> [object Object] --> NSDictionary --> NSNumber               --> NSNumber
         [object Date]      --> [object Object] --> [object Object] --> NSDictionary --> NSString               --> NSString
         [object String]    --> [object Object] --> [object Object] --> NSDictionary --> NSString               --> NSString
         [object Object]    --> [object Object] --> [object Object] --> NSDictionary --> NSDictionary           --> NSDictionary
 
     B、JSCore各阶段数据类型 (ZHJSApiProtocol异步函数返回值: 参见JSCore同步通信)
         1、api调用者传参数据:  const res = fund.getTest111(Undefined);
         2、原生接收JSValue参数类型: JSValue
         3、原生接收JSValue参数转数据: [JSValue toObject]
         4、ZHJSApiProtocol异步函数接收数据: ZHJSApiArgItem.jsData = ((!jsData || [jsData isEqual:[NSNull null]]) ? nil : jsData)

         [object Undefined] --> .isUndefined=YES                --> nil                     --> nil
         [object Null]      --> .isNull=YES                     --> NSNull                  --> nil
         [object Function]  --> .isObject=YES                   --> NSDictionary            --> NSDictionary
         [object Boolean]   --> .isBoolean=YES                  --> NSNumber[@(YES)/@(NO)]  --> NSNumber
         [object Array]     --> .isArray=YES && .isObject=YES   --> NSArray                 --> NSArray
         [object Number]    --> .isNumber=YES                   --> NSNumber                --> NSNumber
         [object Date]      --> .isDate=YES                     --> 待测试
         [object String]    --> .isString=YES && .isObject=NO   --> NSString                --> NSString
         [object Object]    --> .isObject=YES                   --> NSDictionary            --> NSDictionary
 
 异步通信回调： [原生->js]  fund.test({success: function(e){}})  回调e参数类型
     A、web回调各阶段数据类型
         1、ZHJSApiProtocol异步函数回调传参: ZHJSApiCallJsItem.call()
         2、包装数据成数组:
         3、evaluateJavaScript函数通知web:
         4、web端数据接收:
         5、web端数据解析:
         6、api调用者获得的回调参数e: fund.test({success: function(e){}})
             若原生回调1个参数, web端用两个参数接收，第二个参数 e2 为 [object Undefined]
                 fund.test({success: function(e1, e2){}})
         nil                   --> @[]              --> NSDictionary --> [object Object] --> [object Array] --> [object Undefined]
         NSNull                --> @[NSNull]        --> NSDictionary --> [object Object] --> [object Array] --> [object Null]
         @(YES)/@(NO)          --> @[NSNumber]      --> NSDictionary --> [object Object] --> [object Array] --> [object Boolean]
         NSArray               --> @[NSArray]       --> NSDictionary --> [object Object] --> [object Array] --> [object Array]
         NSNumber              --> @[NSNumber]      --> NSDictionary --> [object Object] --> [object Array] --> [object Number]
         NSDictionary          --> @[NSDictionary]  --> NSDictionary --> [object Object] --> [object Array] --> [object Object]
         NSString(包含空字符串)  --> @[NSString]      --> NSDictionary --> [object Object] --> [object Array] --> [object String]
     B、JSCore各阶段数据类型
         1、ZHJSApiProtocol异步函数回调传参: ZHJSApiCallJsItem.call()
         2、包装数据成数组调用[JSValue callWithArguments]:
         3、api调用者获得的回调参数e: fund.test({success: function(e){}})
             若原生回调1个参数, web端用两个参数接收，第二个参数 e2 为 [object Undefined]
                 fund.test({success: function(e1, e2){}})
         nil                   --> @[]              --> [object Undefined]
         NSNull                --> @[NSNull]        --> [object Null]
         @(YES)/@(NO)          --> @[NSNumber]      --> [object Boolean]
         NSArray               --> @[NSArray]       --> [object Array]
         NSNumber              --> @[NSNumber]      --> [object Number]
         NSDictionary          --> @[NSDictionary]  --> [object Object]
         NSString(包含空字符串)  --> @[NSString]      --> [object String]
 */
@end
