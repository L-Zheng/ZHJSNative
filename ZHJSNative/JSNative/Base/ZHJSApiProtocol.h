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
 如： js中要使用api ---->  myApi.request({})      zh_iosApiPrefixName = @'js_"
 则：- (NSString *)zh_jsApiPrefixName{return @"myApi"}
 对应的原生方法实现 - (void)js_request:(ZHJSApiArgItem *)arg <#xxx:(ZHJSApiArgItem *)xxx#>{}
 */
//js api方法名前缀  如：myApi
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
 
 👉只有Web的[异步/同步]通信： [js->原生]  myApi.test(xxx) 时，数据类型对应不上
    xxx传参类型 为 [object Undefined] 时，此时原生接收到的数据为NSNull类型而不是nil
 
 👉同步通信返回值： [原生->js]  const res = myApi.testSync(xxx);
     A：web各阶段数据类型
         1、ZHJSApiProtocol同步函数返回数据(默认返回nil)
         2、web代理回调数据: 包装数据(@{@"data": result}转NSString)然后调用completionHandler回调 -(void)webView:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:
         3、web接收数据:  var res = prompt(JSON.stringify(params)); 解析数据res.data 然后作为返回值返回
         4、api调用者获取到的数据:  var res = myApi.getXXXSync();

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
         3、api调用者获取到的数据 var res = myApi.getXXXSync();

         nil           --> 无  --> [object Undefined]
         NSNull        --> 无  --> [object Null]
         @(YES)/@(NO)  --> 无  --> [object Boolean]
         NSArray       --> 无  --> [object Array]
         NSNumber      --> 无  --> [object Number]
         NSDictionary  --> 无  --> [object Object]
         NSString      --> 无  --> [object String]
 
 👉[异步/同步]通信： [js->原生]  myApi.test(xxx)  xxx传参类型
     A：web各阶段数据类型 (ZHJSApiProtocol异步函数返回值: 丢弃不予处理，web端 const res = myApi.getTest111(Undefined); 执行后  res为[object Undefined]类型)
         1、api调用者传参数据:  const res = myApi.getTest111(Undefined);
         2、web端包装数据: {apiPrefix: 'myApi', methodName: 'getTest111', methodSync: false, args: resArgs}
         3、webkit发送到原生:
             经JSON.stringify()处理:
                 [object Undefined]/[object Function]数据会被转化为[object Null]
                 [object Date]数据会被转化为[object String]
             异步发送方式: window.webkit.messageHandlers[xx].postMessage(JSON.parse(JSON.stringify(params)))
             同步发送方式: prompt(JSON.stringify(params));
         4、原生web代理接收数据:
             异步接收方式: (数据message.body 类型:NSDictionary) -(void)userContentController:didReceiveScriptMessage:
             同步接收方式: (数据prompt 类型:NSString) -(void)webView:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:
         5、原生解析参数数据:  NSDictionary.args[index]
         6、ZHJSApiProtocol异步函数接收数据: ZHJSApiArgItem.jsData = ((!jsData || [jsData isEqual:[NSNull null]]) ? nil : jsData)

         [object Undefined] --> [object Object] --> 异步[object Object]/同步[object String] --> 异步NSDictionary/同步NSString --> NSNull                 --> nil
         [object Null]      --> [object Object] --> 异步[object Object]/同步[object String] --> 异步NSDictionary/同步NSString --> NSNull                 --> nil
         [object Function]  --> [object Object] --> 异步[object Object]/同步[object String] --> 异步NSDictionary/同步NSString --> NSDictionary           --> NSDictionary
         [object Boolean]   --> [object Object] --> 异步[object Object]/同步[object String] --> 异步NSDictionary/同步NSString --> NSNumber[@(YES)/@(NO)] --> NSNumber
         [object Array]     --> [object Object] --> 异步[object Object]/同步[object String] --> 异步NSDictionary/同步NSString --> NSArray                --> NSArray
         [object Number]    --> [object Object] --> 异步[object Object]/同步[object String] --> 异步NSDictionary/同步NSString --> NSNumber               --> NSNumber
         [object Date]      --> [object Object] --> 异步[object Object]/同步[object String] --> 异步NSDictionary/同步NSString --> NSString               --> NSString
         [object String]    --> [object Object] --> 异步[object Object]/同步[object String] --> 异步NSDictionary/同步NSString --> NSString               --> NSString
         [object Object]    --> [object Object] --> 异步[object Object]/同步[object String] --> 异步NSDictionary/同步NSString --> NSDictionary           --> NSDictionary
 
     B、JSCore各阶段数据类型 (ZHJSApiProtocol异步函数返回值: 参见JSCore同步通信)
         1、api调用者传参数据:  const res = myApi.getTest111(Undefined);
         2、原生接收JSValue参数类型: JSValue
         3、原生接收JSValue参数转数据: [JSValue toObject]
         4、ZHJSApiProtocol异步函数接收数据: ZHJSApiArgItem.jsData = ((!jsData || [jsData isEqual:[NSNull null]]) ? nil : jsData)

         [object Undefined] --> .isUndefined=YES                --> nil                     --> nil
         [object Null]      --> .isNull=YES                     --> NSNull                  --> nil
         [object Function]  --> .isObject=YES                   --> NSDictionary            --> NSDictionary
         [object Boolean]   --> .isBoolean=YES                  --> NSNumber[@(YES)/@(NO)]  --> NSNumber
         [object Array]     --> .isArray=YES && .isObject=YES   --> NSArray                 --> NSArray
         [object Number]    --> .isNumber=YES                   --> NSNumber                --> NSNumber
         [object Date]      --> .isDate=YES                     --> 待测试❌
         [object String]    --> .isString=YES && .isObject=NO   --> NSString                --> NSString
         [object Object]    --> .isObject=YES                   --> NSDictionary            --> NSDictionary
 
 👉[异步/同步]通信回调： [原生->js]  myApi.test({success: function(e){}})  回调e参数类型
     A、web回调各阶段数据类型
         1、ZHJSApiProtocol异步函数回调传参: ZHJSApiCallJsItem.call()
         2、包装数据成数组:
         3、evaluateJavaScript函数通知web:
         4、web端数据接收:
         5、web端数据解析:
         6、api调用者获得的回调参数e: myApi.test({success: function(e){}})
             若原生回调1个参数, web端用两个参数接收，第二个参数 e2 为 [object Undefined]
                 myApi.test({success: function(e1, e2){}})
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
         3、api调用者获得的回调参数e: myApi.test({success: function(e){}})
             若原生回调1个参数, web端用两个参数接收，第二个参数 e2 为 [object Undefined]
                 myApi.test({success: function(e1, e2){}})
         nil                   --> @[]              --> [object Undefined]
         NSNull                --> @[NSNull]        --> [object Null]
         @(YES)/@(NO)          --> @[NSNumber]      --> [object Boolean]
         NSArray               --> @[NSArray]       --> [object Array]
         NSNumber              --> @[NSNumber]      --> [object Number]
         NSDictionary          --> @[NSDictionary]  --> [object Object]
         NSString(包含空字符串)  --> @[NSString]      --> [object String]
 
 
 👉[异步/同步]通信回调后，js处理后返回原生的数据： [js->原生]  myApi.test({success: function(e){return xxx}})  xxx参数类型
     A、web各阶段数据类型
         1、api调用者返回数据xxx:  const res = myApi.test({success: function(e){return xxx}});
         2、原生web执行函数获取到的数据: evaluateJavaScript:completionHandler:
         3、原生数据处理: ZHJSApiCallJsResItem.result = ((!result || [result isEqual:[NSNull null]]) ? nil : result)
         4、ZHJSApiProtocol异步函数中获取到的js返回数据 jsResItem.result:
             ^ZHJSApi_CallJsResNativeBlock_Header {
                 NSLog(@"success res: %@--error:%@",jsResItem.result, jsResItem.error);
                 return [ZHJSApiCallJsResNativeResItem item];
             };

         [object Undefined] --> nil                     --> nil             --> nil
         [object Null]      --> NSNull                  --> nil             --> nil
         [object Function]  --> NSDictionary            --> NSDictionary    --> NSDictionary
         [object Boolean]   --> NSNumber[@(YES)/@(NO)]  --> NSNumber        --> NSNumber
         [object Array]     --> NSArray                 --> NSArray         --> NSArray
         [object Number]    --> NSNumber                --> NSNumber        --> NSNumber
         [object Date]      --> 待测试❌
         [object String]    --> NSString                --> NSString        --> NSString
         [object Object]    --> NSDictionary            --> NSDictionary    --> NSDictionary
 
 
     B、JSCore各阶段数据类型
         1、api调用者返回数据xxx:  const res = myApi.test({success: function(e){return xxx}});
         2、原生JSCore执行函数获取到的数据JSValue: [JSValue callWithArguments]
         3、原生接收JSValue参数转数据: [JSValue toObject]
         4、ZHJSApiProtocol异步函数中获取到的js返回数据 jsResItem.result:
             ^ZHJSApi_CallJsResNativeBlock_Header {
                 NSLog(@"success res: %@--error:%@",jsResItem.result, jsResItem.error);
                 return [ZHJSApiCallJsResNativeResItem item];
             };
 
         [object Undefined] --> .isUndefined=YES                --> nil                     --> nil
         [object Null]      --> .isNull=YES                     --> NSNull                  --> nil
         [object Function]  --> .isObject=YES                   --> NSDictionary            --> NSDictionary
         [object Boolean]   --> .isBoolean=YES                  --> NSNumber[@(YES)/@(NO)]  --> NSNumber
         [object Array]     --> .isArray=YES && .isObject=YES   --> NSArray                 --> NSArray
         [object Number]    --> .isNumber=YES                   --> NSNumber                --> NSNumber
         [object Date]      --> .isDate=YES                     --> 待测试❌
         [object String]    --> .isString=YES && .isObject=NO   --> NSString                --> NSString
         [object Object]    --> .isObject=YES                   --> NSDictionary            --> NSDictionary
         
 */
@end
