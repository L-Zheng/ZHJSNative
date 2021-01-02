//
//  ZHJSHandler.m
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHJSHandler.h"
#import "ZHJSContext.h"
#import "ZHWebView.h"
#import <objc/runtime.h>
#import "ZHJSInWebSocketApi.h"

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

@interface ZHJSInvocation : NSInvocation
// 强引用target 防止invoke执行时释放
@property (nonatomic,strong) id zhjs_target;
@end
@implementation ZHJSInvocation
#ifdef DEBUG
- (void)dealloc{
    NSLog(@"%s",__func__);
}
#endif
@end


@interface ZHJSHandler ()
@end

@implementation ZHJSHandler

#pragma mark - init

- (NSArray<id<ZHJSApiProtocol>> *)apiHandlers{
    return [self.apiHandler apiHandlers];
}

//添加移除api
- (void)addApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, NSString *jsCode, NSError *error))completion{
    __weak __typeof__(self) __self = self;
    [self.apiHandler addApiHandlers:apiHandlers completion:^(NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, NSError *error) {
        if (error) {
            if (completion) completion(successApiHandlers, failApiHandlers, nil, error);
            return;
        }
        //直接添加  会覆盖掉先前定义的
        NSString *jsCode = [__self fetchWebViewApi:NO];
        if (completion) completion(successApiHandlers, failApiHandlers, jsCode, nil);
    }];
}
- (void)removeApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, NSString *jsCode, NSError *error))completion{
    
    __weak __typeof__(self) __self = self;
    
    //先重置掉原来定义的所有api
    NSString *resetApiJsCode = [self fetchWebViewApi:YES];
    
    [self.apiHandler removeApiHandlers:apiHandlers completion:^(NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, NSError *error) {
        if (error) {
            if (completion) completion(successApiHandlers, failApiHandlers, nil, error);
            return;
        }
        //添加新的api
        NSString *newApiJsCode = [__self fetchWebViewApi:NO];
        NSString *resJsCode = [NSString stringWithFormat:@"%@%@", resetApiJsCode?:@"", newApiJsCode];
        if (completion) completion(successApiHandlers, failApiHandlers, resJsCode, nil);
    }];
}

#pragma mark - JSContext api
//JSContext注入的api
- (void)fetchJSContextLogApi:(void (^) (NSString *apiPrefix, NSDictionary *apiBlockMap))callBack{
    if (!callBack) return;
    void (^logBlock)(void) = ^(){
        NSArray *args = [JSContext currentArguments];
        if (args.count == 0) return;
        if (args.count == 1) {
            NSLog(@"👉JSCore log >>: %@",[args[0] toObject]);
            return;
        }
        NSMutableArray *messages = [NSMutableArray array];
        for (JSValue *obj in args) {
            [messages addObject:[obj toObject]];
        }
        NSLog(@"👉JSCore log >>: %@", messages);
    };
    callBack(@"console", @{@"log": logBlock});
}
- (void)fetchJSContextApi:(void (^) (NSString *apiPrefix, NSDictionary *apiBlockMap))callBack{
    if (!callBack) return;
    __weak __typeof__(self) __self = self;
    
    [self.apiHandler enumRegsiterApiMap:^(NSString *apiPrefix, NSDictionary<NSString *,ZHJSApiMethodItem *> *apiMap) {
        NSDictionary *resMap = [__self fetchJSContextNativeImpMap:apiPrefix apiMap:apiMap];
        callBack(resMap ? apiPrefix : nil, resMap);
    }];
}
//- (void)fetchJSContextApiWithApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers callBack:(void (^) (NSString *apiPrefix, NSDictionary *apiBlockMap))callBack{
//    if (!callBack) return;
//    __weak __typeof__(self) __self = self;
//    [self.apiHandler fetchRegsiterApiMap:apiHandlers block:^(NSString *apiPrefix, NSDictionary<NSString *,ZHJSApiMethodItem *> *apiMap) {
//        NSDictionary *resMap = [__self fetchJSContextNativeImpMap:apiPrefix apiMap:apiMap];
//        callBack(resMap ? apiPrefix : nil, resMap);
//    }];
//}

- (NSDictionary *)fetchJSContextNativeImpMap:(NSString *)apiPrefix apiMap:(NSDictionary <NSString *,ZHJSApiMethodItem *> *)apiMap{
    if (![apiPrefix isKindOfClass:[NSString class]] || apiPrefix.length == 0) {
        return nil;
    }
    NSMutableDictionary *resMap = [NSMutableDictionary dictionary];
    __weak __typeof__(self) __self = self;
    [apiMap enumerateKeysAndObjectsUsingBlock:^(NSString *jsMethod, ZHJSApiMethodItem *item, BOOL *stop) {
        //设置方法实现
        [resMap setValue:[__self jsContextApiMapNativeImp:jsMethod apiPrefix:apiPrefix] forKey:jsMethod];
    }];
    return [resMap copy];
}
//JSContext调用原生实现
- (id)jsContextApiMapNativeImp:(NSString *)key apiPrefix:(NSString *)apiPrefix{
    if (!key || key.length == 0) return nil;
    __weak __typeof__(self) __self = self;
    
    //处理js的事件
    id (^apiBlock)(void) = ^(){
        //获取参数
        NSArray *jsArgs = [ZHJSContext currentArguments];
        //js没传参数
        if (jsArgs.count == 0) {
            return [__self runNativeFunc:key apiPrefix:apiPrefix arguments:@[]];
        }
         // 第一个参数的success fail complete回调
        ZHJSApiCallItem *firstCallItem = nil;
        
        //处理参数
        NSMutableArray *resArgs = [NSMutableArray array];
        for (NSUInteger idx = 0; idx < jsArgs.count; idx++) {
            JSValue *jsArg = jsArgs[idx];
            // 转换成原生类型
            id nativeValue = [__self jsValueToNative:jsArg];
            if (!nativeValue || ![nativeValue isKindOfClass:NSDictionary.class]) {
                [resArgs addObject:nativeValue?:[NSNull null]];
                continue;
            }
            
            NSMutableDictionary *newParams = [(NSDictionary *)nativeValue mutableCopy];
            //获取回调方法
            NSString *success = __self.fetchJSContextCallSuccessFuncKey;
            NSString *fail = __self.fetchJSContextCallFailFuncKey;
            NSString *complete = __self.fetchJSContextCallCompleteFuncKey;
            BOOL hasCallFunction = ([jsArg hasProperty:success] || [jsArg hasProperty:fail] || [jsArg hasProperty:complete]);
            //不需要回调方法
            if (!hasCallFunction) {
                [resArgs addObject:nativeValue];
                continue;
            }
            //需要回调
            JSValue *successFunc = [jsArg valueForProperty:success];
            JSValue *failFunc = [jsArg valueForProperty:fail];
            JSValue *completeFunc = [jsArg valueForProperty:complete];
            ZHJSApiInCallBlock block = ^ZHJSApi_InCallBlock_Header{
                id result = argItem.result;
                NSError *error = argItem.error;
                
                if (!error && successFunc) {
                    // 运行参数里的success方法
                    // [paramsValue invokeMethod:success withArguments:@[result]];
                    JSValue *resValue = [successFunc callWithArguments:result ? @[result] : @[]];
                    argItem.callSuccess([ZHJSApiRunJsReturnItem item:[__self jsValueToNative:resValue] error:nil]);
                }
                if (error && failFunc) {
                    NSString *errorDesc = error.userInfo[NSLocalizedDescriptionKey];
                    id desc = (errorDesc ?: @"发生错误");
                    JSValue *resValue = [failFunc callWithArguments:@[desc]];
                    argItem.callFail([ZHJSApiRunJsReturnItem item:[__self jsValueToNative:resValue] error:nil]);
                }
                /**
                 js方法 complete: () => {}，complete: (res) => {}
                 callWithArguments: @[]  原生不传参数 res=null   上面里两个方法都运行正常 js不会报错
                 callWithArguments: @[]  原生传参数 上面里两个都运行正常
                 */
                if (completeFunc) {
                    JSValue *resValue = [completeFunc callWithArguments:@[]];
                    argItem.callComplete([ZHJSApiRunJsReturnItem item:[__self jsValueToNative:resValue] error:nil]);
                }
                return [ZHJSApiCallReturnItem item];
            };
            
            ZHJSApiCallItem *callItem = [ZHJSApiCallItem itemWithBlock:block];
            [newParams setObject:callItem forKey:ZHJSApiCallItemKey];
            [resArgs addObject:newParams.copy];
            
            if (idx == 0) firstCallItem = callItem;
        }
        
        if (firstCallItem) [resArgs addObject:firstCallItem];
        return [__self runNativeFunc:key apiPrefix:apiPrefix arguments:resArgs.copy];
    };
    return apiBlock;
}

/**JSContext中：js类型-->JSValue类型 对应关系
 Date：[JSValue toDate]=[NSDate class]
 function：[JSValue toObject]=[NSDictionary class]    [jsValue isObject]=YES
 null：[JSValue toObject]=[NSNull null]
 undefined：[JSValue toObject]=nil
 boolean：[JSValue toObject]=@(YES) or @(NO)  [NSNumber class]
 number：[JSValue toObject]= [NSNumber class]
 string：[JSValue toObject]= [NSString class]   [jsValue isObject]=NO
 array：[JSValue toObject]= [NSArray class]    [jsValue isObject]=YES
 json：[JSValue toObject]= [NSDictionary class]    [jsValue isObject]=YES
 */
- (id)jsValueToNative:(JSValue *)jsValue{
    if (!jsValue) return nil;
    if (@available(iOS 9.0, *)) {
        if (jsValue.isDate) {
            return [jsValue toDate];
        }
        if (jsValue.isArray) {
            return [jsValue toArray];
        }
    }
    if (@available(iOS 13.0, *)) {
        if (jsValue.isSymbol) {
            return nil;
        }
    }
    if (jsValue.isNull || jsValue.isUndefined) {
        return nil;
    }
    if (jsValue.isString || jsValue.isNumber || jsValue.isBoolean){
        return [jsValue toObject];
    }
    if (jsValue.isObject){
        return [jsValue toObject];
    }
    return [jsValue toObject];
}

#pragma mark - WebView api
//WebView注入的api
- (NSString *)fetchWebViewLogApi{
    //以下代码由logEvent.js压缩而成
    NSString *formatJS = [NSString stringWithContentsOfFile:[ZHJSHandler jsLogEventPath] encoding:NSUTF8StringEncoding error:nil];
    NSString *jsCode = [NSString stringWithFormat:formatJS, ZHJSHandlerLogName];
    return jsCode;
}
- (NSString *)fetchWebViewErrorApi{
    //以下代码由errorEvent.js压缩而成
    NSString *formatJS = [NSString stringWithContentsOfFile:[ZHJSHandler jsErrorEventPath] encoding:NSUTF8StringEncoding error:nil];
    NSString *jsCode = [NSString stringWithFormat:formatJS, ZHJSHandlerErrorName];
//    jsCode = @"";
    return jsCode;
}
- (NSString *)fetchWebViewSocketApi{
    ZHJSInWebSocketApi *socketApi = [[ZHJSInWebSocketApi alloc] init];
    if (![socketApi conformsToProtocol:@protocol(ZHJSApiProtocol)] ||
        ![socketApi respondsToSelector:@selector(zh_jsApiPrefixName)]) return nil;
    
    NSString *jsPrefix = [socketApi zh_jsApiPrefixName];
    
    if (jsPrefix.length == 0) return nil;
    //以下代码由socketEvent.js压缩而成
    NSString *formatJS = [NSString stringWithContentsOfFile:[ZHJSHandler jsSocketEventPath] encoding:NSUTF8StringEncoding error:nil];
    NSString *jsCode = [NSString stringWithFormat:formatJS, jsPrefix];
    return jsCode;
}
- (NSString *)fetchWebViewTouchCalloutApi{
    NSString *jsCode = @"document.documentElement.style.webkitUserSelect='none';document.documentElement.style.webkitTouchCallout='none';";
    return jsCode;
}
- (NSString *)fetchWebViewSupportApi{
    //以下代码由event.js压缩而成
    NSString *formatJS = [NSString stringWithContentsOfFile:[ZHJSHandler jsEventPath] encoding:NSUTF8StringEncoding error:nil];
    NSMutableString *res = [NSMutableString string];
    [res appendFormat:formatJS,
     ZHJSHandlerName,
     self.fetchWebViewCallSuccessFuncKey,
     self.fetchWebViewCallFailFuncKey,
     self.fetchWebViewCallCompleteFuncKey,
     self.fetchWebViewCallFuncName,
     self.fetchWebViewGeneratorApiFuncName];
    return [res copy];
}

- (NSString *)fetchWebViewApi:(BOOL)isReset{
    NSMutableString *res = [NSMutableString string];
    [self.apiHandler enumRegsiterApiMap:^(NSString *apiPrefix, NSDictionary<NSString *,ZHJSApiMethodItem *> *apiMap) {
        //因为要移除api  apiMap设定写死传@{}
        NSString *jsCode = [self fetchWebViewApiJsCode:apiPrefix apiMap:isReset ? @{} : apiMap];
        if (jsCode) [res appendString:jsCode];
    }];
    return [res copy];
}
- (NSString *)fetchWebViewApiJsCode:(NSString *)apiPrefix apiMap:(NSDictionary <NSString *,ZHJSApiMethodItem *> *)apiMap{
    if (![apiPrefix isKindOfClass:[NSString class]] || apiPrefix.length == 0) return nil;
    
    NSMutableString *code = [NSMutableString string];
    
    [code appendString:@"{"];
    [apiMap enumerateKeysAndObjectsUsingBlock:^(NSString *jsMethod, ZHJSApiMethodItem *item, BOOL *stop) {
        [code appendFormat:@"%@:{sync:%@},", jsMethod, (item.isSync ? @"true" : @"false")];
    }];
    // 删除最后一个逗号
    NSRange range = [code rangeOfString:@"," options:NSBackwardsSearch];
    if (range.location != NSNotFound){
        [code deleteCharactersInRange:range];
    }
    [code appendString:@"}"];
    
    return [NSString stringWithFormat:@"var %@=%@('%@',%@);",apiPrefix, self.fetchWebViewGeneratorApiFuncName, apiPrefix, code];
}

- (NSString *)fetchWebViewApiFinish{
    //api注入完成通知
    NSString *jsCode = [NSString stringWithFormat:@"var ZhengReadyEvent = document.createEvent('Event');ZhengReadyEvent.initEvent('%@');window.dispatchEvent(ZhengReadyEvent);", self.fetchWebViewApiFinishFlag];
    return jsCode;
}

#pragma mark - exception

//异常弹窗
- (void)showWebViewException:(NSDictionary *)exception{
    // 异常抛出
    id <ZHWebViewExceptionDelegate> de = self.webView.zh_exceptionDelegate;
    if (ZHCheckDelegate(de, @selector(webViewException:info:))) {
        [de webViewException:self.webView info:exception];
    }
    // 调试弹窗
    if (self.webView.debugConfig.alertWebViewErrorEnable) {
        [self showException:@"WebView JS异常" exception:exception];
    }
}
- (void)showJSContextException:(NSDictionary *)exception{
    if (self.jsContext.debugConfig.alertJsContextErrorEnable) {
        [self showException:@"JSCore异常" exception:exception];
    }
}
- (void)showException:(NSString *)title exception:(NSDictionary *)exception{
    if (!exception || ![exception isKindOfClass:[NSDictionary class]] || exception.allKeys.count == 0) return;
    
    NSMutableDictionary *info = [exception mutableCopy];
    
    id stackRes = nil;
    NSString *stack = [info valueForKey:@"stack"];
    if ([stack isKindOfClass:[NSString class]] && stack.length) {
        //Vue报错是string类型
        if ([stack containsString:@"\n"]) {
            NSInteger limit = 3;
            NSMutableArray *arr = [[stack componentsSeparatedByString:@"\n"] mutableCopy];
            if (arr.count > limit) {
                [arr removeObjectsInRange:NSMakeRange(limit, arr.count - limit)];
            }
            stackRes = [arr copy];
        }else{
            NSInteger limit = 200;
            if (stack.length > limit) stack = [stack substringToIndex:limit];
            stackRes = stack;
        }
    }else{
        //html js报错是json类型
        stackRes = stack;
    }
    if (stackRes) [info setValue:stackRes forKey:@"stack"];
    
    ZHErrorAlertController *alert = [ZHErrorAlertController alertControllerWithTitle:title message:[info description] preferredStyle:UIAlertControllerStyleAlert];
    __weak __typeof__(self) __self = self;
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
    }];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"关闭所有" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        UIViewController *last = [__self fetchActivityCtrl].presentingViewController;
        while ([last isKindOfClass:[ZHErrorAlertController class]]) {
            last = last.presentingViewController;
        }
        [last dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:action];
    [alert addAction:action1];
    [[self fetchActivityCtrl] presentViewController:alert animated:YES completion:nil];
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
        NSLog(@"👉Web log >>: %@", message.body);
        return;
    }
    if ([message.name isEqualToString:ZHJSHandlerErrorName]) {
        /** 异常回调
         没有try cach方法 js直接报错   会回调
         有try cach方法 catch方法抛出异常throw error;   会回调
         有try cach方法 catch方法没有抛出异常throw error;   不会回调
         */
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
    NSString *apiPrefix = [jsInfo valueForKey:@"apiPrefix"];
    NSArray *jsArgs = [jsInfo valueForKey:@"args"];
    if (!jsArgs || ![jsArgs isKindOfClass:NSArray.class] || jsArgs.count == 0) {
        return [self runNativeFunc:jsMethodName apiPrefix:apiPrefix arguments:@[]];
    }
    /**  WebView中：js类型-->原生类型 对应关系
     Date：         params=[NSString class]，Date经JSON.stringify转换为string，@"2020-12-29T05:06:55.383Z"
     function：    params=[NSNull null]，function经JSON.stringify转换为null，原生接受为NSNull
     null：           params=[NSNull null]，null经JSON.stringify转换为null，原生接受为NSNull
     undefined： params=[NSNull null]，undefined经JSON.stringify转换为null，原生接受为NSNull
     boolean：    params=@(YES) or @(NO)  [NSNumber class]
     number：    params= [NSNumber class]
     string：        params= [NSString class]
     array：         params= [NSArray class]
     json：          params= [NSDictionary class]
     */
     __weak __typeof__(self) __self = self;
    // 第一个参数的success fail complete回调
    ZHJSApiCallItem *firstCallItem = nil;
    //处理参数
    NSMutableArray *resArgs = [NSMutableArray array];
    for (NSUInteger idx = 0; idx < jsArgs.count; idx++) {
        id jsArg = jsArgs[idx];
        if (![jsArg isKindOfClass:[NSDictionary class]]) {
            [resArgs addObject:jsArg];
            continue;
        }
        NSMutableDictionary *newParams = [(NSDictionary *)jsArg mutableCopy];
        //获取回调方法
        NSString *successId = [newParams valueForKey:[self fetchWebViewCallSuccessFuncKey]];
        NSString *failId = [newParams valueForKey:[self fetchWebViewCallFailFuncKey]];
        NSString *completeId = [newParams valueForKey:[self fetchWebViewCallCompleteFuncKey]];
        BOOL hasCallFunction = (successId.length || failId.length || completeId.length);
        //不需要回调方法
        if (!hasCallFunction) {
            [resArgs addObject:jsArg];
            continue;
        }
        //需要回调
        ZHJSApiInCallBlock block = ^ZHJSApi_InCallBlock_Header{
            id result = argItem.result;
            NSError *error = argItem.error;
            BOOL alive = argItem.alive;
            
            if (!error && successId.length) {
                [__self callBackJsFunc:successId data:result?:[NSNull null] alive:alive callBack:^(id jsRes, NSError *jsError) {
                    argItem.callSuccess([ZHJSApiRunJsReturnItem item:jsRes error:jsError]);
                }];
            }
            if (error && failId.length) {
                NSString *errorDesc = error.userInfo[NSLocalizedDescriptionKey];
                id desc = (errorDesc ?: @"发生错误");
                [__self callBackJsFunc:failId data:desc alive:alive callBack:^(id jsRes, NSError *jsError) {
                    argItem.callFail([ZHJSApiRunJsReturnItem item:jsRes error:jsError]);
                }];
            }
            if (completeId.length) {
                [__self callBackJsFunc:completeId data:[NSNull null] alive:alive callBack:^(id jsRes, NSError *jsError) {
                    argItem.callComplete([ZHJSApiRunJsReturnItem item:jsRes error:jsError]);
                }];
            }
            return [ZHJSApiCallReturnItem item];
        };
        ZHJSApiCallItem *callItem = [ZHJSApiCallItem itemWithBlock:block];
        [newParams setObject:callItem forKey:ZHJSApiCallItemKey];
        [resArgs addObject:newParams.copy];
        
        if (idx == 0) firstCallItem = callItem;
    }
    if (firstCallItem) [resArgs addObject:firstCallItem];
    
    return [self runNativeFunc:jsMethodName apiPrefix:apiPrefix arguments:resArgs.copy];
}
//运行原生方法
- (id)runNativeFunc:(NSString *)jsMethodName apiPrefix:(NSString *)apiPrefix arguments:(NSArray *)arguments{
    __block id value = nil;
    [self.apiHandler fetchSelectorByName:jsMethodName apiPrefix:apiPrefix callBack:^(id target, SEL sel) {
        if (!target || !sel) return;
        
        NSMethodSignature *sig = [target methodSignatureForSelector:sel];
        ZHJSInvocation *invo = [ZHJSInvocation invocationWithMethodSignature:sig];
        invo.zhjs_target = target;
        [invo setTarget:target];
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
                // 各种类型：https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-%20CH100
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
        /**运行函数：
         https://developer.apple.com/documentation/foundation/nsinvocation/1437838-retainarguments?language=objc
         invoke调用后不会立即执行方法，与performSelector一样，等待运行循环触发
         而为了提高效率，NSInvocation不会保留 调用所需的参数
         因此，在调用之前参数可能会被释放，App crash
         */
        if (!invo.argumentsRetained) {
            [invo retainArguments];
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
        /**返回值是什么类型 就要用什么类型接口  否则crash
         const char *returnType = [signature methodReturnType];   strcmp(returnType, @encode(float))==0
         id ：接受NSObject类型
         BOOL：接受BOOL类型
         ...
         */
        id __unsafe_unretained res = nil;
        if ([sig methodReturnLength]) [invo getReturnValue:&res];
        value = res;
        
        invo = nil;
        
        //    void *res = NULL;
        //    if ([signature methodReturnLength]) [invocation getReturnValue:&res];
        //    return (__bridge id)res;
    }];
    return value;
}
- (id)runNativeFunc11:(NSString *)methodName params1:(id)params1 params2:(id)params2{
    SEL sel = NSSelectorFromString(methodName);
    if (![self respondsToSelector:sel]) return nil;
    //此方法可能存在crash:  javascriptCore调用api的时候【野指针错误】
    @try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [self performSelector:sel withObject:params1 withObject:params2];
#pragma clang diagnostic pop
    } @catch (NSException *exception) {
        NSLog(@"------runNativeFunc--------------");
        NSLog(@"%@",exception);
    } @finally {
        
    }
}

//js消息回调
- (void)callBackJsFunc:(NSString *)funcId data:(id)result alive:(BOOL)alive callBack:(void (^) (id jsRes, NSError *jsError))callBack{
    /**
     data:[NSNull null]  对应js的Null类型
     */
    if (funcId.length == 0) return;
    result = @{@"funcId": funcId, @"data": result?:[NSNull null], @"alive": @(alive)};
    [self.webView postMessageToJs:self.fetchWebViewCallFuncName params:result completionHandler:^(id res, NSError *error) {
        if (callBack) callBack((!res || [res isEqual:[NSNull null]]) ? nil : res, error);
    }];
}

#pragma mark - getter

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
- (NSString *)fetchWebViewCallFuncName{
    return @"ZhengIosToWebViewCallBack";
}
- (NSString *)fetchWebViewGeneratorApiFuncName{
    return @"ZhengWebViewGeneratorAPI";
}
- (NSString *)fetchWebViewCallSuccessFuncKey{
    return @"ZhengCallBackSuccessKey";
}
- (NSString *)fetchWebViewCallFailFuncKey{
    return @"ZhengCallBackFailKey";
}
- (NSString *)fetchWebViewCallCompleteFuncKey{
    return @"ZhengCallBackCompleteKey";
}
- (NSString *)fetchWebViewApiFinishFlag{
    return @"ZhengJSBridgeReady";
}

- (void)dealloc{
    NSLog(@"%s", __func__);
}


#pragma mark - File Path
+ (NSString *)jsEventPath{
    return [self pathWithName:@"min-event.js"];
}
+ (NSString *)jsLogEventPath{
    return [self pathWithName:@"min-log.js"];
}
+ (NSString *)jsErrorEventPath{
    return [self pathWithName:@"min-error.js"];
}
+ (NSString *)jsSocketEventPath{
    return [self pathWithName:@"min-socket.js"];
}
+ (NSString *)pathWithName:(NSString *)name{
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TestBundle" ofType:@"bundle"]];
    NSString *destPath = [bundle pathForResource:name.stringByDeletingPathExtension ofType:name.pathExtension];
    return destPath;
}
@end

@implementation ZHErrorAlertController
@end
