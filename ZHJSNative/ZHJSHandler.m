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
#import <objc/runtime.h>

//设置NSInvocation参数
#define ZH_Invo_Set_Arg(invo, arg, idx, cType, type, op)\
case cType:{\
    if ([arg respondsToSelector:@selector(op)]) {\
        type *_tmp = malloc(sizeof(type));\
        memset(_tmp, 0, sizeof(type));\
        *_tmp = [arg op];\
        [invo setArgument:_tmp atIndex:idx];\
    }\
    break;\
}

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
    NSDictionary <NSString *, ZHJSApiMethodItem *> *apiMap = [self.apiHandler fetchApiMethodMap];
    
    NSMutableDictionary *resMap = [NSMutableDictionary dictionary];
    __weak __typeof__(self) __self = self;
    [apiMap enumerateKeysAndObjectsUsingBlock:^(NSString *key, ZHJSApiMethodItem *item, BOOL *stop) {
        //设置方法实现
        [resMap setValue:[__self jsContextApiMapBlock:key] forKey:key];
    }];
    callBack(apiPrefix, [resMap copy]);
}
//JSContext调用原生实现
- (id)jsContextApiMapBlock:(NSString *)key{
    if (!key || key.length == 0) return nil;
    __weak __typeof__(self) __self = self;
    
    //处理js的事件
    id (^apiBlock)(void) = ^(){
        //获取参数
        NSArray *arguments = [ZHJSContext currentArguments];
        JSValue *jsValue = (arguments.count == 0) ? nil : arguments[0];
        //js没传参数
        if (!jsValue) {
            return [__self runNativeFunc:key arguments:@[]];
        }
        /**
         null：[JSValue toObject]=[NSNull null]
         undefined：[JSValue toObject]=nil
         boolean：[JSValue toObject]=@(YES) or @(NO)  [NSNumber class]
         number：[JSValue toObject]= [NSNumber class]
         string：[JSValue toObject]= [NSString class]   [jsValue isObject]=NO
         array：[JSValue toObject]= [NSArray class]    [jsValue isObject]=YES
         json：[JSValue toObject]= [NSDictionary class]    [jsValue isObject]=YES
         */
        if ([jsValue isNull] || [jsValue isUndefined]) {
            return [__self runNativeFunc:key arguments:@[]];
        }
        NSDictionary *params = [jsValue toObject];
        if (![params isKindOfClass:[NSDictionary class]]) {
            return [__self runNativeFunc:key arguments:@[params]];
        }
        
        //是否需要回调
        NSString *success = __self.fetchJSContextCallSuccessFuncKey;
        NSString *fail = __self.fetchJSContextCallFailFuncKey;
        NSString *complete = __self.fetchJSContextCallCompleteFuncKey;
        BOOL hasCallFunction = ([jsValue hasProperty:success] ||
                                [jsValue hasProperty:fail] ||
                                [jsValue hasProperty:complete]);
        if (!hasCallFunction) {
            return [__self runNativeFunc:key arguments:@[params]];
        }
        
        //获取回调方法
        JSValue *successFunc = [jsValue valueForProperty:success];
        JSValue *failFunc = [jsValue valueForProperty:fail];
        JSValue *completeFunc = [jsValue valueForProperty:complete];
        ZHJSApiAliveBlock block = ^(id result, NSError *error, BOOL alive) {
            if (!error && result) {
                //运行参数里的success方法
                //                [paramsValue invokeMethod:success withArguments:@[result]];
                if (successFunc) [successFunc callWithArguments:@[result]];
            }else{
                NSString *errorDesc = error.localizedDescription;
                id desc = error ? (errorDesc.length ? errorDesc : @"发生错误") : @"没有数据";
                //运行参数里的fail方法
                //                [paramsValue invokeMethod:fail withArguments:@[result]];
                if (failFunc) [failFunc callWithArguments:@[desc]];
            }
            /**
             js方法 complete: () => {}，complete: (res) => {}
             callWithArguments: @[]  原生不传参数 res=null   上面里两个方法都运行正常 js不会报错
             callWithArguments: @[]  原生传参数 上面里两个都运行正常
             */
            if (completeFunc) [completeFunc callWithArguments:@[]];
        };
        return [__self runNativeFunc:key arguments:@[params, block]];
    };
    return apiBlock;
}

#pragma mark - WebView api
//WebView注入的api
- (NSString *)fetchWebViewLogApi{
//        NSString *handlerJS = [NSString stringWithContentsOfFile:[ZHUtil jsLogEventPath] encoding:NSUTF8StringEncoding error:nil];
//        return handlerJS;
    
    //以下代码由logEvent.js压缩而成
    NSString *jsCode = [NSString stringWithFormat:
    @"const FNJSToNativeLogHandlerName='%@';console.log=(oriLogFunc=>{return function(...args){oriLogFunc.call(console,...args);let errorRes=[];const parseData=data=>{let res=null;const type=Object.prototype.toString.call(data);if(type=='[object Null]'||type=='[object String]'||type=='[object Number]'){res=data}else if(type=='[object Function]'){res=data.toString()}else if(type=='[object Undefined]'){res='Undefined'}else if(type=='[object Boolean]'){res=data?'true':'false'}else if(type=='[object Object]'){res={};for(const key in data){const el=data[key];res[key]=parseData(el)}}else if(type=='[object Array]'){res=[];data.forEach(el=>{res.push(parseData(el))})}else if(type=='[object Error]'){res=data;errorRes.push(res)}else if(type=='[object Window]'){res=data.toString()}else{res=data}return res};const params=arguments;const type=Object.prototype.toString.call(params);const argCount=params.length;if(type!='[object Arguments]')return;let iosRes=[];const fetchVaule=idx=>{return argCount>idx?params[idx]:'无此参数'};if(argCount==0)return;if(argCount==1){iosRes=parseData(fetchVaule(0))}else{for(let idx=0;idx<argCount;idx++){iosRes.push(parseData(fetchVaule(idx)))}}try{const handler=window.webkit.messageHandlers[FNJSToNativeLogHandlerName];handler.postMessage(JSON.parse(JSON.stringify(iosRes)))}catch(error){}return;if(errorRes.length==0)return;if(!window.onerror)return;try{errorRes.forEach(el=>{window.onerror(el)})}catch(error){}}})(console.log);", ZHJSHandlerLogName];
    return jsCode;
}
- (NSString *)fetchWebViewErrorApi{
//        NSString *handlerJS = [NSString stringWithContentsOfFile:[ZHUtil jsErrorEventPath] encoding:NSUTF8StringEncoding error:nil];
//        return handlerJS;
    
    //以下代码由errorEvent.js压缩而成
    NSString *jsCode = [NSString stringWithFormat:
    @"const FNJSToNativeErrorHandlerName='%@';window.onerror=(oriFunc=>{return function(...args){if(oriFunc)oriFunc.apply(window,args);const params=arguments;const type=Object.prototype.toString.call(params);const argCount=params.length;if(type!='[object Arguments]')return;if(argCount==0)return;const invaildDesc='无此参数';const fetchVaule=idx=>{return argCount>idx?params[idx]:invaildDesc};const iosRes={msg:fetchVaule(0),url:fetchVaule(1),line:fetchVaule(2),column:fetchVaule(3),stack:fetchVaule(4)};const res=JSON.parse(JSON.stringify(iosRes));try{const handler=window.webkit.messageHandlers[FNJSToNativeErrorHandlerName];handler.postMessage(res)}catch(error){}}})(window.onerror);", ZHJSHandlerErrorName];
    return jsCode;
}
- (NSString *)fetchWebViewApi{
//    NSString *handlerJS = [NSString stringWithContentsOfFile:[ZHUtil jsEventPath] encoding:NSUTF8StringEncoding error:nil];
//    return handlerJS;
    
    //获取js方法映射表
    NSDictionary <NSString *, ZHJSApiMethodItem *> *apiMap = [self.apiHandler fetchApiMethodMap];
    //生成jsCode
    NSMutableString *apiConfigStr = [NSMutableString string];
    [apiConfigStr appendString:@"{"];
    [apiMap enumerateKeysAndObjectsUsingBlock:^(NSString *key, ZHJSApiMethodItem *item, BOOL *stop) {
        [apiConfigStr appendFormat:@"%@:{sync:%@},", key, (item.isSync ? @"true" : @"false")];
    }];
    // 删除最后一个逗号
    NSRange range = [apiConfigStr rangeOfString:@"," options:NSBackwardsSearch];
    if (range.location != NSNotFound){
        [apiConfigStr deleteCharactersInRange:range];
    }
    [apiConfigStr appendString:@"}"];
    
    //以下代码由event.js压缩而成
    NSString *res = [NSString stringWithFormat:@"const FNCommonAPI=%@;const FNJSToNativeHandlerName='%@';const FNCallBackSuccessKey='%@';const FNCallBackFailKey='%@';const FNCallBackCompleteKey='%@';const FNJSType=(()=>{let type={};const typeArr=['String','Object','Number','Array','Undefined','Function','Null','Symbol','Boolean'];for(let i=0;i<typeArr.length;i++){(name=>{type['is'+name]=(obj=>{return Object.prototype.toString.call(obj)=='[object '+name+']'})})(typeArr[i])}return type})();const FNCallBackMap={};const FNCallBack=params=>{if(!FNJSType.isString(params)||!params){return}const newParams=JSON.parse(decodeURIComponent(params));if(!FNJSType.isObject(newParams)){return}const funcId=newParams.funcId;const res=newParams.data;const alive=newParams.alive;let randomKey='',funcNameKey='';const matchKey=key=>{if(!funcId.endsWith(key))return false;randomKey=funcId.replace(new RegExp(key,'g'),'');funcNameKey=key;return true};const matchRes=matchKey(FNCallBackSuccessKey)||matchKey(FNCallBackFailKey)||matchKey(FNCallBackCompleteKey);if(!matchRes)return;let funcMap=FNCallBackMap[randomKey];if(!FNJSType.isObject(funcMap))return;const func=funcMap[funcNameKey];if(!FNJSType.isFunction(func))return;try{func(res)}catch(error){console.log('CallBack-error');console.log(error)}if(alive)return;if(funcNameKey==FNCallBackCompleteKey){FNRemoveCallBack(randomKey)}};const FNAddCallBack=(randomKey,funcNameKey,func)=>{let funcMap=FNCallBackMap[randomKey];if(!FNJSType.isObject(funcMap)){const map={};map[funcNameKey]=func;FNCallBackMap[randomKey]=map;return}if(funcMap.hasOwnProperty(funcNameKey))return;funcMap[funcNameKey]=func;FNCallBackMap[randomKey]=funcMap};const FNRemoveCallBack=randomKey=>{if(!FNCallBackMap.hasOwnProperty(randomKey))return;delete FNCallBackMap[randomKey]};const FNHandleCallBackParams=(methodName,params)=>{if(!FNJSType.isObject(params)){return params}const randomKey=`-${methodName}-${(new Date).getTime()}-${Math.floor(Math.random()*1e4)}-`;let newParams=params;const success=params.success;if(success&&FNJSType.isFunction(success)){const funcId=randomKey+FNCallBackSuccessKey;FNAddCallBack(randomKey,FNCallBackSuccessKey,success);newParams[FNCallBackSuccessKey]=funcId}const fail=params.fail;if(fail&&FNJSType.isFunction(fail)){const funcId=randomKey+FNCallBackFailKey;FNAddCallBack(randomKey,FNCallBackFailKey,fail);newParams[FNCallBackFailKey]=funcId}const complete=params.complete;if(complete&&FNJSType.isFunction(complete)){const funcId=randomKey+FNCallBackCompleteKey;FNAddCallBack(randomKey,FNCallBackCompleteKey,complete);newParams[FNCallBackCompleteKey]=funcId}return newParams};const FNSendParams=(methodName,params,sync=false)=>{let newParams=params;let res={};if(!sync){newParams=FNHandleCallBackParams(methodName,params)}const haveParms=!(FNJSType.isNull(newParams)||FNJSType.isUndefined(newParams));res=haveParms?{methodName:methodName,params:newParams}:{methodName:methodName};return sync?res:JSON.parse(JSON.stringify(res))};const FNSendParamsSync=(methodName,params)=>{return FNSendParams(methodName,params,true)};const FNSendNative=params=>{const handler=window.webkit.messageHandlers[FNJSToNativeHandlerName];handler.postMessage(params)};const FNSendNativeSync=params=>{let res=prompt(JSON.stringify(params));try{res=JSON.parse(res);return res.data}catch(error){console.log('❌SendNativeSync--error');console.log(error)}return null};const %@=(()=>{const apiMap=FNCommonAPI;let res={};for(const key in apiMap){if(!apiMap.hasOwnProperty(key)){continue}const config=apiMap[key];const isSync=config.hasOwnProperty('sync')?config.sync:false;const func=isSync?params=>{return FNSendNativeSync(FNSendParamsSync(key,params))}:params=>{FNSendNative(FNSendParams(key,params))};res[key]=func}return res})();", apiConfigStr, ZHJSHandlerName, self.fetchWebViewCallSuccessFuncKey, self.fetchWebViewCallFailFuncKey, self.fetchWebViewCallCompleteFuncKey, [self.apiHandler fetchApiMethodPrefixName]];
    return res;
}

#pragma mark - exception

//异常弹窗
- (void)showWebViewException:(NSDictionary *)exception{
    [self showException:@"WebView JS异常" exception:exception];
}
- (void)showJSContextException:(NSDictionary *)exception{
    [self showException:@"JSCore异常" exception:exception];
}
- (void)showException:(NSString *)title exception:(NSDictionary *)exception{
#ifdef DEBUG
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:[exception description] preferredStyle:UIAlertControllerStyleAlert];
    __weak __typeof__(alert) weakAlert = alert;
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [weakAlert.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:action];
    [[self fetchActivityCtrl] presentViewController:alert animated:YES completion:nil];
#endif
}

#pragma mark - activityCtrl

- (UIViewController *)fetchActivityCtrl:(UIViewController *)ctrl{
    UIViewController *topCtrl = ctrl.presentedViewController;
    if (!topCtrl) return ctrl;
    return [self fetchActivityCtrl:topCtrl];
}
- (UIViewController *)fetchActivityCtrl{
    UIViewController *ctrl = [UIApplication sharedApplication].keyWindow.rootViewController;
    return [self fetchActivityCtrl:ctrl];
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:ZHJSHandlerLogName]) {
        NSLog(@"👉js中的log：");
        NSLog(@"%@", message.body);
        return;
    }
    if ([message.name isEqualToString:ZHJSHandlerErrorName]) {
        NSLog(@"❌WebView js异常");
        NSDictionary *exception = message.body;
        NSLog(@"%@", message.body);
        [self showWebViewException:exception];
        return;
    }
    if ([message.name isEqualToString:ZHJSHandlerName]) {
        NSDictionary *receiveInfo = message.body;
        [self handleScriptMessage:receiveInfo];
        return;
    }
}

#pragma mark - webview-js消息处理
    
//处理WebView js消息
- (id)handleScriptMessage:(NSDictionary *)jsInfo{
    if (!jsInfo || ![jsInfo isKindOfClass:[NSDictionary class]]) return nil;
    NSString *jsMethodName = [jsInfo valueForKey:@"methodName"];

    /** 参数类型
     null、undefined：js端处理掉   jsInfo没有params字段
     boolean：params=@(YES) or @(NO)  [NSNumber class]
     number：params= [NSNumber class]
     string：params= [NSString class]
     array：params= [NSArray class]
     json：params= [NSDictionary class]
     */
    NSDictionary *params = [jsInfo objectForKey:@"params"];
    
    if (!params) {
        return [self runNativeFunc:jsMethodName arguments:@[]];
    }
    if (![params isKindOfClass:[NSDictionary class]]) {
        return [self runNativeFunc:jsMethodName arguments:@[params]];
    }
    
    //回调方法
    NSString *successId = [params valueForKey:[self fetchWebViewCallSuccessFuncKey]];
    NSString *failId = [params valueForKey:[self fetchWebViewCallFailFuncKey]];
    NSString *completeId = [params valueForKey:[self fetchWebViewCallCompleteFuncKey]];
    BOOL hasCallFunction = (successId.length || failId.length || completeId.length);
    //不需要回调方法
    if (!hasCallFunction) {
        return [self runNativeFunc:jsMethodName arguments:@[params]];
    }
    //需要回调
    __weak __typeof__(self) __self = self;
    ZHJSApiAliveBlock block = ^(id result, NSError *error, BOOL alive) {
        if (!error && result) {
            if (successId.length) [__self callBackJsFunc:successId data:result alive:alive callBack:nil];
        }else{
            NSString *errorDesc = error.localizedDescription;
            id desc = error ? (errorDesc.length ? errorDesc : @"发生错误") : @"没有数据";
            if (failId.length) [__self callBackJsFunc:failId data:desc alive:alive callBack:nil];
        }
        if (completeId.length) [__self callBackJsFunc:completeId data:[NSNull null] alive:alive callBack:nil];
    };
    return [self runNativeFunc:jsMethodName arguments:@[params, block]];
}
//运行原生方法
- (id)runNativeFunc:(NSString *)jsMethodName arguments:(NSArray *)arguments{
    SEL sel = [self.apiHandler fetchSelectorByName:jsMethodName];
    if (!sel) return nil;
    
    NSMethodSignature *sig = [self.apiHandler methodSignatureForSelector:sel];
    NSInvocation *invo = [NSInvocation invocationWithMethodSignature:sig];
    [invo setTarget:self.apiHandler];
    [invo setSelector:sel];
    /**
     arguments.cout < 方法本身定义的参数：方法多出来的参数均为nil
     arguments.cout > 方法本身定义的参数：arguments多出来的参数丢弃
     */
    // invocation 有2个隐藏参数，所以 argument 从2开始
    if ([arguments isKindOfClass:[NSArray class]]) {
        NSInteger count = MIN(arguments.count, sig.numberOfArguments - 2);
        for (int idx = 0; idx < count; idx++) {
            id arg = arguments[idx];
            //获取该方法的参数类型
            int argIdx = idx + 2;
            const char *paramType = [sig getArgumentTypeAtIndex:argIdx];
            switch(paramType[0]){
                //char * 类型
                case _C_CHARPTR: {
                    if ([arg respondsToSelector:@selector(UTF8String)]) {
                        char **_tmp = (char **)[arg UTF8String];
                        [invo setArgument:&_tmp atIndex:argIdx];
                    }
                    break;
                }
//                    case _C_LNG:{
//                        if ([arg respondsToSelector:@selector(longValue)]) {
//                            long *_tmp = malloc(sizeof(long));
//                            memset(_tmp, 0, sizeof(long));
//                            *_tmp = [arg longValue];
//                            [invo setArgument:_tmp atIndex:idx];
//                        }
//                        break;
//                    }
                    //基本数据类型
                    ZH_Invo_Set_Arg(invo, arg, argIdx, _C_INT, int, intValue)
                    ZH_Invo_Set_Arg(invo, arg, argIdx, _C_SHT, short, shortValue)
                    ZH_Invo_Set_Arg(invo, arg, argIdx, _C_LNG, long, longValue)
                    ZH_Invo_Set_Arg(invo, arg, argIdx, _C_LNG_LNG, long long, longLongValue)
                    ZH_Invo_Set_Arg(invo, arg, argIdx, _C_UCHR, unsigned char, unsignedCharValue)
                    ZH_Invo_Set_Arg(invo, arg, argIdx, _C_UINT, unsigned int, unsignedIntValue)
                    ZH_Invo_Set_Arg(invo, arg, argIdx, _C_USHT, unsigned short, unsignedShortValue)
                    ZH_Invo_Set_Arg(invo, arg, argIdx, _C_ULNG, unsigned long, unsignedLongValue)
                    ZH_Invo_Set_Arg(invo, arg, argIdx, _C_ULNG_LNG, unsigned long long, unsignedLongLongValue)
                    ZH_Invo_Set_Arg(invo, arg, argIdx, _C_FLT, float, floatValue)
                    ZH_Invo_Set_Arg(invo, arg, argIdx, _C_DBL, double, doubleValue)
                    ZH_Invo_Set_Arg(invo, arg, argIdx, _C_BOOL, bool, boolValue)
                    ZH_Invo_Set_Arg(invo, arg, argIdx, _C_CHR, char, charValue)
                default: {
                    //id object类型
                    [invo setArgument:&arg atIndex:argIdx];
                    break;
                }
            }
            /**
            strcmp(paramType, @encode(float))==0
            strcmp(paramType, @encode(double))==0
            strcmp(paramType, @encode(int))==0
            strcmp(paramType, @encode(id))==0
            strcmp(paramType, @encode(typeof(^{})))==0
             */
        }
    }
    //运行
    [invo invoke];
    
    //        此处crash： https://www.jianshu.com/p/9b4cff40c25c
    //这句代码在执行后的某个时刻会强行释放res，release掉.后面再用res就会报僵尸对象的错  加上__autoreleasing
    //    __autoreleasing id res = nil;
    //    if ([signature methodReturnLength]) [invocation getReturnValue:&res];
    //    id value = res;
    //    return value;
    //
    id __unsafe_unretained res = nil;
    if ([sig methodReturnLength]) [invo getReturnValue:&res];
    id value = res;
    return value;
    
    //    void *res = NULL;
    //    if ([signature methodReturnLength]) [invocation getReturnValue:&res];
    //    return (__bridge id)res;
    
}
- (id)runNativeFunc11:(NSString *)methodName params1:(id)params1 params2:(id)params2{
    SEL sel = NSSelectorFromString(methodName);
    if (![self respondsToSelector:sel]) return nil;
    //此方法可能存在crash:  javascriptCore调用api的时候【野指针错误】
    @try {
        return [self performSelector:sel withObject:params1 withObject:params2];
    } @catch (NSException *exception) {
        NSLog(@"------runNativeFunc--------------");
        NSLog(@"%@",exception);
    } @finally {
        
    }
}

//js消息回调
- (void)callBackJsFunc:(NSString *)funcId data:(id)result alive:(BOOL)alive callBack:(void (^) (id data, NSError *error))callBack{
    /**
     data:[NSNull null]  对应js的Null类型
     */
    if (funcId.length == 0) return;
    result = @{@"funcId": funcId, @"data": result?:[NSNull null], @"alive": @(alive)};
    [self.webView postMessageToJs:@"FNCallBack" params:result completionHandler:^(id res, NSError *error) {
        if (callBack) callBack(res, error);
    }];
}

//获取回调
- (NSString *)fetchJSContextCallSuccessFuncKey{
    return @"success";
}
- (NSString *)fetchJSContextCallFailFuncKey{
    return @"fail";
}
- (NSString *)fetchJSContextCallCompleteFuncKey{
    return @"complete";
}
- (NSString *)fetchWebViewCallSuccessFuncKey{
    return @"ZHCallBackSuccessKey";
}
- (NSString *)fetchWebViewCallFailFuncKey{
    return @"ZHCallBackFailKey";
}
- (NSString *)fetchWebViewCallCompleteFuncKey{
    return @"ZHCallBackCompleteKey";
}

- (void)dealloc{
    NSLog(@"-------%s---------", __func__);
}
@end
