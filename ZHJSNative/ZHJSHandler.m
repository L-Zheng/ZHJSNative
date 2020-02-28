//
//  ZHJSHandler.m
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHJSHandler.h"
#import "ZHUtil.h"
#import "ZHJSContext.h"
#import "ZHWebView.h"
#import "ZHJSApiHandler.h"

@implementation ZHJSHandler

#pragma mark - init

- (instancetype)init{
    self = [super init];
    if (self) {
        self.apiHandler = [[ZHJSApiHandler alloc] init];
        self.apiHandler.handler = self;
    }
    return self;
}

#pragma mark - JSContext api
//JSContext注入的api
- (void)fetchJSContextLogApi:(void (^) (NSString *apiPrefix, NSDictionary *apiBlockMap))callBack{
    if (!callBack) return;
    void (^logBlock)(void) = ^(){
        NSArray *args = [JSContext currentArguments];
        if (args.count == 0) return;
        NSLog(@"👉JSContext中的log:");
        if (args.count == 1) {
            NSLog(@"%@",[args[0] toObject]);
            return;
        }
        NSMutableArray *messages = [NSMutableArray array];
        for (JSValue *obj in args) {
            [messages addObject:[obj toObject]];
        }
        NSLog(@"%@", messages);
    };
    callBack(@"console", @{@"log": logBlock});
}
- (void)fetchJSContextApi:(void (^) (NSString *apiPrefix, NSDictionary *apiBlockMap))callBack{
    if (!callBack) return;
    //获取js方法前缀
    NSString *apiPrefix = [self.apiHandler fetchApiMethodPrefixName];
    //获取js方法映射表
    NSDictionary *apiMap = [self.apiHandler fetchApiMethodMap];
    
    NSMutableDictionary *resMap = [NSMutableDictionary dictionary];
    __weak __typeof__(self) __self = self;
    [apiMap enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        //设置方法实现
        [resMap setValue:[__self jsContextApiMapBlock:key] forKey:key];
    }];
    callBack(apiPrefix, [resMap copy]);
}
- (id)jsContextApiMapBlock:(NSString *)key{
    if (!key || key.length == 0) return nil;
    __weak __typeof__(self) __self = self;
    
    //处理js的事件
    id (^apiBlock)(void) = ^(){
        //获取参数
        NSArray *arguments = [ZHJSContext currentArguments];
        JSValue *paramsValue = (arguments.count == 0) ? nil : arguments[0];
        NSDictionary *params = [paramsValue toDictionary];
        
        //是否需要回调
        JSValueProperty success = @"success";
        JSValueProperty fail = @"fail";
        BOOL isHasCallFunction = ([paramsValue hasProperty:success] || [paramsValue hasProperty:fail]);
        if (!isHasCallFunction) {
            return [__self runNativeFunc:key params1:params params2:nil];
        }
        
        //获取回调方法
        JSValue *successFunc = [paramsValue valueForProperty:success];
        JSValue *failFunc = [paramsValue valueForProperty:fail];
        ZHJSApiBlock block = ^(id result, NSError *error) {
            if (!error && result) {
                [successFunc callWithArguments:@[result]];
            }else{
                id desc = error ? error.localizedDescription : @"没有数据";
                [failFunc callWithArguments:@[desc]];
            }
        };
        return [__self runNativeFunc:key params1:params params2:block];
        
    };
    return apiBlock;
}

#pragma mark - WebView api
//WebView注入的api
- (NSString *)fetchWebViewLogApi{
    NSString *jsCode = [NSString stringWithFormat:
    @"const FNJSToNativeLogHandlerName='%@';console.log=function(oriLogFunc){return function(obj){let newObj=obj;const type=Object.prototype.toString.call(newObj);if(type=='[object Function]'){newObj=newObj.toString()}const res=JSON.parse(JSON.stringify(newObj));const handler=window.webkit.messageHandlers[FNJSToNativeLogHandlerName];handler.postMessage(res);oriLogFunc.call(console,obj)}}(console.log);", ZHJSHandlerLogName];
    return jsCode;
}
- (NSString *)fetchWebViewApi{
//    NSString *handlerJS = [NSString stringWithContentsOfFile:[ZHUtil jsEventPath] encoding:NSUTF8StringEncoding error:nil];
//    return handlerJS;

    //获取js方法前缀
    NSString *apiPrefix = [self.apiHandler fetchApiMethodPrefixName];
    //获取js方法映射表
    NSDictionary *apiMap = [self.apiHandler fetchApiMethodMap];
    NSArray *apiMapKeys = apiMap.allKeys;
    NSUInteger keysCount = apiMapKeys.count;
    
    //生成jsCode
    NSMutableString *apiConfigStr = [NSMutableString string];
    [apiConfigStr appendString:@"{"];
    for (NSUInteger i = 0; i < keysCount; i++) {
        NSString *api = apiMapKeys[i];
        BOOL isSync = [api hasSuffix:@"Sync"];
        [apiConfigStr appendFormat:@"%@:{sync:%@},", api, (isSync ? @"true" : @"false")];
        // 删除最后一个逗号
        if (i == keysCount - 1) {
            NSRange range = [apiConfigStr rangeOfString:@"," options:NSBackwardsSearch];
            if (range.location != NSNotFound){
                [apiConfigStr deleteCharactersInRange:range];
            }
        }
    }
    [apiConfigStr appendString:@"}"];
    
    NSString *res = [NSString stringWithFormat:@"const FNCommonAPI=%@;const FNJSToNativeHandlerName='%@';const FNCallBackSuccessKey='%@';const FNCallBackFailKey='%@';const FNJSType=(()=>{let type={};const typeArr=['String','Object','Number','Array','Undefined','Function','Null','Symbol','Boolean'];for(let i=0;i<typeArr.length;i++){(name=>{type['is'+name]=(obj=>{return Object.prototype.toString.call(obj)=='[object '+name+']'})})(typeArr[i])}return type})();const FNCallBackMap={};const FNCallBack=params=>{if(!FNJSType.isString(params)||!params){return}const newParams=JSON.parse(decodeURIComponent(params));if(!FNJSType.isObject(newParams)){return}const funcId=newParams.funcId;const res=newParams.data;let arr=FNCallBackMap[funcId];if(!FNJSType.isArray(arr)||arr.length==0){return}arr.forEach(el=>{if(FNJSType.isFunction(el)){el(res)}});FNRemoveCallBack(funcId)};const FNAddCallBack=(funcId,func)=>{let arr=FNCallBackMap[funcId];if(!FNJSType.isArray(arr)){arr=[]}if(arr.indexOf(func)==-1){arr.push(func)}FNCallBackMap[funcId]=arr};const FNRemoveCallBack=funcId=>{if(FNCallBackMap.hasOwnProperty(funcId)){delete FNCallBackMap[funcId]}};const FNHandleCallBackParams=(methodName,params)=>{if(!FNJSType.isObject(params)){return params}const CreateRandom=methodName=>{return`-${methodName}-${(new Date).getTime()}-${Math.floor(Math.random()*1e3)}-`};let newParams=params;const success=params.success;if(success&&FNJSType.isFunction(success)){const funcId=FNCallBackSuccessKey+CreateRandom(methodName);FNAddCallBack(funcId,success);newParams[FNCallBackSuccessKey]=funcId}const fail=params.fail;if(fail&&FNJSType.isFunction(fail)){const funcId=FNCallBackFailKey+CreateRandom(methodName);FNAddCallBack(funcId,fail);newParams[FNCallBackFailKey]=funcId}return newParams};const FNSendParams=(methodName,params,sync=false)=>{let res={};if(!sync){const newParams=FNHandleCallBackParams(methodName,params);res=newParams?{methodName:methodName,params:newParams}:{methodName:methodName};return JSON.parse(JSON.stringify(res))}res=params?{methodName:methodName,params:params}:{methodName:methodName};return res};const FNSendParamsSync=(methodName,params)=>{return FNSendParams(methodName,params,true)};const FNSendNative=params=>{const handler=window.webkit.messageHandlers[FNJSToNativeHandlerName];handler.postMessage(params)};const FNSendNativeSync=params=>{let res=prompt(JSON.stringify(params));try{res=JSON.parse(res);return res.data}catch(error){console.log('❌FNSendNativeSync--error');console.log(error)}return null};const %@=(()=>{const apiMap=FNCommonAPI;let res={};for(const key in apiMap){if(!apiMap.hasOwnProperty(key)){continue}const config=apiMap[key];const isSync=config.hasOwnProperty('sync')?config.sync:false;const func=isSync?params=>{return FNSendNativeSync(FNSendParamsSync(key,params))}:params=>{FNSendNative(FNSendParams(key,params))};res[key]=func}return res})();", apiConfigStr, ZHJSHandlerName, self.fetchCallSuccessFuncKey, self.fetchCallFailFuncKey, apiPrefix];
    return res;
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:ZHJSHandlerLogName]) {
        NSLog(@"👉js中的log：");
        NSLog(@"%@", message.body);
        return;
    }
    if ([message.name isEqualToString:ZHJSHandlerName]) {
        NSDictionary *receiveInfo = message.body;
        [self handleScriptMessage:receiveInfo];
        return;
    }
}

#pragma mark - webview-js消息处理
    
//处理js消息
- (id)handleScriptMessage:(NSDictionary *)jsInfo{
    if (!jsInfo || ![jsInfo isKindOfClass:[NSDictionary class]]) return nil;
    
    //获取参数
    NSDictionary *params = [jsInfo objectForKey:@"params"];
    NSString *methodName = [jsInfo valueForKey:@"methodName"];
    
    //不是json数据
    if (![params isKindOfClass:[NSDictionary class]]) {
        return [self runNativeFunc:methodName params1:params params2:nil];
    }
    
    //需要回调方法
    NSString *successId = [params valueForKey:[self fetchCallSuccessFuncKey]];
    NSString *failId = [params valueForKey:[self fetchCallFailFuncKey]];
    BOOL isHasCallFunction = (successId.length || failId.length);
    if (isHasCallFunction) {
        __weak __typeof__(self) __self = self;
        ZHJSApiBlock block = ^(id result, NSError *error) {
            if (!error) {
                [__self callBackJsFunc:successId data:result callBack:nil];
            }else{
                [__self callBackJsFunc:failId data:error.localizedDescription callBack:nil];
            }
        };
        return [self runNativeFunc:methodName params1:params params2:block];
    }
    
    //不需要回调方法
    return [self runNativeFunc:methodName params1:params params2:nil];
}

//运行原生方法
- (id)runNativeFunc:(NSString *)methodName params1:(id)params1 params2:(id)params2{
    SEL sel = [self.apiHandler fetchSelectorByName:methodName];
    if (!sel) return nil;
    
    NSMethodSignature *signature = [self.apiHandler methodSignatureForSelector:sel];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:self.apiHandler];
    [invocation setSelector:sel];
    
    //设置参数
    NSMutableArray *paramsArr = [@[] mutableCopy];
    if (params1) [paramsArr addObject:params1];
    if (params2) [paramsArr addObject:params2];
    if (paramsArr.count > 0) {
        NSUInteger i = 1;
        for (id object in paramsArr) {
            id tempObject = object;
            [invocation setArgument:&tempObject atIndex:++i];
        }
    }
    //运行
    [invocation invoke];
    
    //        此处crash： https://www.jianshu.com/p/9b4cff40c25c
    //这句代码在执行后的某个时刻会强行释放res，release掉.后面再用res就会报僵尸对象的错  加上__autoreleasing
//    __autoreleasing id res = nil;
//    if ([signature methodReturnLength]) [invocation getReturnValue:&res];
//    id value = res;
//    return value;
//
    id __unsafe_unretained res = nil;
    if ([signature methodReturnLength]) [invocation getReturnValue:&res];
    id value = res;
    return value;
    
//    void *res = NULL;
//    if ([signature methodReturnLength]) [invocation getReturnValue:&res];
//    return (__bridge id)res;
//
}
- (id)runNativeFunc11:(NSString *)methodName params1:(id)params1 params2:(id)params2{
    SEL sel = NSSelectorFromString(methodName);
    if (![self respondsToSelector:sel]) return nil;
    //此方法可能存在crash:  javascriptCore调用api的时候
    @try {
        return [self performSelector:sel withObject:params1 withObject:params2];
    } @catch (NSException *exception) {
        NSLog(@"------runNativeFunc--------------");
        NSLog(@"%@",exception);
    } @finally {
        
    }
}

//js消息回调
- (void)callBackJsFunc:(NSString *)funcId data:(id)result callBack:(void (^) (id data, NSError *error))callBack{
    if (funcId.length == 0 || !result) return;
    result = @{@"funcId": funcId, @"data": result};
    [self.webView postMessageToJs:@"FNCallBack" params:result completionHandler:^(id res, NSError *error) {
        if (callBack) callBack(res, error);
    }];
}

//获取回调
- (NSString *)fetchCallSuccessFuncKey{
    return @"FNCallBackSuccessKey";
}
- (NSString *)fetchCallFailFuncKey{
    return @"FNCallBackFailKey";
}

- (void)dealloc{
    NSLog(@"-------%s---------", __func__);
}

@end
