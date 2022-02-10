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

- (NSArray<id<ZHJSApiProtocol>> *)apis{
    return [self.apiHandler apis];
}

//添加移除api
- (void)addApis:(NSArray <id <ZHJSApiProtocol>> *)apis completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApis, NSArray<id<ZHJSApiProtocol>> *failApis, NSString *jsCode, NSError *error))completion{
    __weak __typeof__(self) __self = self;
    [self.apiHandler addApis:apis completion:^(NSArray<id<ZHJSApiProtocol>> *successApis, NSArray<id<ZHJSApiProtocol>> *failApis, NSError *error) {
        if (error) {
            if (completion) completion(successApis, failApis, nil, error);
            return;
        }
        //直接添加  会覆盖掉先前定义的
        NSString *jsCode = [__self fetchWebViewApi:NO];
        if (completion) completion(successApis, failApis, jsCode, nil);
    }];
}
- (void)removeApis:(NSArray <id <ZHJSApiProtocol>> *)apis completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApis, NSArray<id<ZHJSApiProtocol>> *failApis, NSString *jsCode, NSError *error))completion{
    
    __weak __typeof__(self) __self = self;
    
    //先重置掉原来定义的所有api
    NSString *resetApiJsCode = [self fetchWebViewApi:YES];
    
    [self.apiHandler removeApis:apis completion:^(NSArray<id<ZHJSApiProtocol>> *successApis, NSArray<id<ZHJSApiProtocol>> *failApis, NSError *error) {
        if (error) {
            if (completion) completion(successApis, failApis, nil, error);
            return;
        }
        //添加新的api
        NSString *newApiJsCode = [__self fetchWebViewApi:NO];
        NSString *resJsCode = [NSString stringWithFormat:@"%@%@", resetApiJsCode?:@"", newApiJsCode];
        if (completion) completion(successApis, failApis, resJsCode, nil);
    }];
}

#pragma mark - JSContext api
//JSContext注入的api
- (void)fetchJSContextConsoleApi:(void (^) (NSString *apiPrefix, NSDictionary *apiBlockMap))callBack{
    if (!callBack) return;
    
    // 自定义输出
    void (^block) (NSArray *, NSString *) = ^(NSArray *args, NSString *flag){
        if (args.count == 0) return;
        id (^formatLog)(JSValue *) = ^id(JSValue *aJSValue){
            if ([aJSValue isUndefined]) {
                return @"the params is [object Undefined]";
            }
            if ([aJSValue isNull]) {
                return @"the params is [object Null]";
            }
            return [aJSValue toObject];
        };
        
        if (args.count == 1) {
            NSLog(@"👉JSCore %@ >>: %@", flag, formatLog(args[0]));
            return;
        }
        NSMutableArray *messages = [NSMutableArray array];
        for (JSValue *obj in args) {
            [messages addObject:formatLog(obj)?:@"null"];
        }
        NSLog(@"👉JSCore %@ >>: %@", flag, messages);
    };
    BOOL prjDebug = NO;
#ifdef DEBUG
    prjDebug = YES;
#endif
    
    __weak __typeof__(self) weakSelf = self;
    /*
     JSValue 对 JSContext是强引用  不能直接在block里面使用JSValue
     也不能使用weakJSValue  在setObject: forKeyedSubscript:方法被调用后 原有的JSValue被释放
     
     有条件地持有（conditional retain）
        在以下两种情况任何一个满足的情况下保证其管理的JSValue被持有不被释放：
            可以通过JavaScript的对象图找到该JSValue。【即在JavaScript环境中存在该JSValue】
            可以通过native对象图找到该JSManagedValue。【即在JSVirtualMachine中存在JSManagedValue，那么JSManagedValue弱引用的JSValue即使引用数为0，也不会释放】
        如果以上条件都不满足，JSManagedValue对象就会将其value置为nil并释放该JSValue
     
     源代码: JSManagedValue内部实现
         + (JSManagedValue *)managedValueWithValue:(JSValue *)value andOwner:(id)owner
         {
             // 这里的JSManagedValue并没有对JSValue进行强引用
             JSManagedValue *managedValue = [[self alloc] initWithValue:value];
             // context对应的virtualMachine对value进行了强持有
             [value.context.virtualMachine addManagedReference:managedValue withOwner:owner];
             return [managedValue autorelease];
         }
         - (void)dealloc
         {
             JSVirtualMachine *virtualMachine = [[[self value] context] virtualMachine];
             if (virtualMachine) {
                 NSMapTable *copy = [m_owners copy];
                 for (id owner in [copy keyEnumerator]) {
                     size_t count = reinterpret_cast<size_t>(NSMapGet(m_owners, owner));
                     while (count--)
                         [virtualMachine removeManagedReference:self withOwner:owner];
                 }
                 [copy release];
             }

             [self disconnectValue];
             [m_owners release];
             [super dealloc];
         }
     
     JSManagedValue.m_owners强引用owner
     JSVirtualMachine.ownedObjects强引用owner
     */
    // 注入console  使用JSManagedValue
    /*
    NSMutableDictionary *resMap = [NSMutableDictionary dictionary];
    JSValue *oriConsole = [self.jsContext objectForKeyedSubscript:@"console"];
    NSArray *flagsMap = @[@[@"debug"],@[@"error"],@[@"info"],@[@"log"],@[@"warn"]];
    for (NSArray *flags in flagsMap) {
        NSString *flag = flags[0];
        JSManagedValue *jsManaged = nil;
        if (prjDebug) {
            JSValue *flagJs = [oriConsole objectForKeyedSubscript:flag];
            jsManaged = flagJs ? [JSManagedValue managedValueWithValue:flagJs andOwner:self] : nil;
        }
        void (^flagJsBlock) (void) = ^{
            NSArray *args = [JSContext currentArguments];
            // 回调原始输出方法 用于safari调试console输出
            if (prjDebug) {
                [[jsManaged value] callWithArguments:args];
            }
            // 回调自定义输出
            block(args, flag);
        };
        if (oriConsole) {
            [oriConsole setObject:[flagJsBlock copy] forKeyedSubscript:flag];
        }else{
            [resMap setObject:[flagJsBlock copy] forKey:flag];
        }
    }
    callBack(oriConsole ? nil : @"console", oriConsole ? nil : resMap.copy);
    */
    
    
   // 注入console  强引用JSValue 手动解除循环引用 destroyContext
    NSMutableDictionary *resMap = [NSMutableDictionary dictionary];
    JSValue *oriConsole = [self.jsContext objectForKeyedSubscript:@"console"];
    NSArray *flagsMap = @[@[@"debug"],@[@"error"],@[@"info"],@[@"log"],@[@"warn"]];
    for (NSArray *flags in flagsMap) {
        NSString *flag = flags[0];
        if (prjDebug) {
            JSValue *flagJs = [oriConsole objectForKeyedSubscript:flag];
            [self.jsContext setConsole:flagJs forKey:flag];
        }
        void (^flagJsBlock) (void) = ^{
            NSArray *args = [JSContext currentArguments];
            // 回调原始输出方法 用于safari调试console输出
            if (prjDebug) {
                [[weakSelf.jsContext getConsoleForKey:flag] callWithArguments:args];
            }
            // 回调自定义输出
            block(args, flag);
        };
        if (oriConsole) {
            [oriConsole setObject:[flagJsBlock copy] forKeyedSubscript:flag];
        }else{
            [resMap setObject:[flagJsBlock copy] forKey:flag];
        }
    }
    callBack(oriConsole ? nil : @"console", oriConsole ? nil : resMap.copy);
}
- (void)fetchJSContextApi:(void (^) (NSString *apiPrefix, NSDictionary *apiBlockMap))callBack{
    if (!callBack) return;
    __weak __typeof__(self) __self = self;
    
    [self.apiHandler enumRegsiterApiMap:^(NSString *apiPrefix, NSDictionary<NSString *,ZHJSApiRegisterItem *> *apiMap) {
        NSDictionary *resMap = [__self fetchJSContextNativeImpMap:apiPrefix apiMap:apiMap];
        callBack(resMap ? apiPrefix : nil, resMap);
    }];
}
//- (void)fetchJSContextApiWithApis:(NSArray <id <ZHJSApiProtocol>> *)apis callBack:(void (^) (NSString *apiPrefix, NSDictionary *apiBlockMap))callBack{
//    if (!callBack) return;
//    __weak __typeof__(self) __self = self;
//    [self.apiHandler fetchRegsiterApiMap:apis block:^(NSString *apiPrefix, NSDictionary<NSString *,ZHJSApiRegisterItem *> *apiMap) {
//        NSDictionary *resMap = [__self fetchJSContextNativeImpMap:apiPrefix apiMap:apiMap];
//        callBack(resMap ? apiPrefix : nil, resMap);
//    }];
//}

- (NSDictionary *)fetchJSContextNativeImpMap:(NSString *)apiPrefix apiMap:(NSDictionary <NSString *,ZHJSApiRegisterItem *> *)apiMap{
    if (![apiPrefix isKindOfClass:[NSString class]] || apiPrefix.length == 0) {
        return nil;
    }
    NSMutableDictionary *resMap = [NSMutableDictionary dictionary];
    __weak __typeof__(self) __self = self;
    [apiMap enumerateKeysAndObjectsUsingBlock:^(NSString *jsMethod, ZHJSApiRegisterItem *item, BOOL *stop) {
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
    id (^apiBlock)(void) = ^id(void){
        //获取参数
        NSArray *jsArgs = [ZHJSContext currentArguments];
        //js没传参数
        if (jsArgs.count == 0) {
            return [__self runNativeFunc:key apiPrefix:apiPrefix arguments:@[]];
        }
        
        //处理参数
        NSMutableArray *resArgs = [NSMutableArray array];
        for (NSUInteger idx = 0; idx < jsArgs.count; idx++) {
            JSValue *jsArg = jsArgs[idx];
            
            ZHJSApiInCallBlock jsFuncArgBlock = ^ZHJSApi_InCallBlock_Header{
                if (!__self) {
                    return [ZHJSApiCallJsNativeResItem item];
                }
                NSArray *jsFuncArgDatas = argItem.jsFuncArgDatas;
                // BOOL alive = argItem.alive;
                // 如果jsArg不是js的function类型  调用callWithArguments函数也不会报错
                JSValue *resValue = [jsArg callWithArguments:((jsFuncArgDatas && [jsFuncArgDatas isKindOfClass:NSArray.class]) ? jsFuncArgDatas : @[])];
                if (argItem.jsFuncArgResBlock) {
                    argItem.jsFuncArgResBlock([ZHJSApiCallJsResItem item:[__self jsValueToNative:resValue] error:nil]);
                }
                return [ZHJSApiCallJsNativeResItem item];
            };
            
            // 转换成原生类型
            id nativeValue = [__self jsValueToNative:jsArg];
            if (!nativeValue || ![nativeValue isKindOfClass:NSDictionary.class]) {
                [resArgs addObject:[ZHJSApiArgItem item:__self.jsPage jsData:nativeValue callItem:[ZHJSApiCallJsItem itemWithSFCBlock:nil jsFuncArgBlock:jsFuncArgBlock]]];
                continue;
            }
            
            //获取回调方法
            NSString *success = __self.fetchJSContextCallSuccessFuncKey;
            NSString *fail = __self.fetchJSContextCallFailFuncKey;
            NSString *complete = __self.fetchJSContextCallCompleteFuncKey;
            BOOL hasCallFunction = ([jsArg hasProperty:success] || [jsArg hasProperty:fail] || [jsArg hasProperty:complete]);
            //不需要回调方法
            if (!hasCallFunction) {
                [resArgs addObject:[ZHJSApiArgItem item:__self.jsPage jsData:nativeValue callItem:[ZHJSApiCallJsItem itemWithSFCBlock:nil jsFuncArgBlock:jsFuncArgBlock]]];
                continue;
            }
            //需要回调
            JSValue *successFunc = [jsArg valueForProperty:success];
            JSValue *failFunc = [jsArg valueForProperty:fail];
            JSValue *completeFunc = [jsArg valueForProperty:complete];
            ZHJSApiInCallBlock block = ^ZHJSApi_InCallBlock_Header{
                if (!__self) {
                    return [ZHJSApiCallJsNativeResItem item];
                }
                NSArray *successDatas = argItem.successDatas;
                NSArray *failDatas = argItem.failDatas;
                NSArray *completeDatas = argItem.completeDatas;
                NSError *error = argItem.error;
                
                /** JSValue callWithArguments 调用js function
                 如果JSValue对应的不是js function，而是js array/number或其他数据 调用[JSValue callWithArguments:]函数，不会崩溃，可正常使用
                 原生传参@[]
                    success: function () {}
                    success: function (res) {}   res为[object Undefined]类型
                    success: function (res, res1) {}   res/res1均为[object Undefined]类型
                 原生传参@[[NSNull null]]
                    success: function () {}
                    success: function (res) {}   res为[object Null]类型
                    success: function (res, res1) {}   res为[object Null]类型  res1为[object Undefined]类型
                 原生传参@[@"x1"]
                    success: function () {}
                    success: function (res) {}   res为[object String]类型
                    success: function (res, res1) {}   res为[object String]类型  res1为[object Undefined]类型
                 原生传参@[@"x1", @"x2"]
                    success: function () {}
                    success: function (res) {}   res为[object String]类型
                    success: function (res, res1, res2) {}   res/res1均为[object String]类型  res2为[object Undefined]类型
                 */
                if (!error && successFunc) {
                    // 运行参数里的success方法
                    // [paramsValue invokeMethod:success withArguments:@[successData]];
                    JSValue *resValue = [successFunc callWithArguments:((successDatas && [successDatas isKindOfClass:NSArray.class]) ? successDatas : @[])];
                    if (argItem.jsResSuccessBlock) {
                        argItem.jsResSuccessBlock([ZHJSApiCallJsResItem item:[__self jsValueToNative:resValue] error:nil]);
                    }
                }
                if (error && failFunc) {
                    JSValue *resValue = [failFunc callWithArguments:((failDatas && [failDatas isKindOfClass:NSArray.class]) ? failDatas : @[])];
                    if (argItem.jsResFailBlock) {
                        argItem.jsResFailBlock([ZHJSApiCallJsResItem item:[__self jsValueToNative:resValue] error:nil]);
                    }
                }
                /**
                 js方法 complete: () => {}，complete: (res) => {}
                 callWithArguments: @[]  原生不传参数 res=null   上面里两个方法都运行正常 js不会报错
                 callWithArguments: @[]  原生传参数 上面里两个都运行正常
                 */
                if (completeFunc) {
                    JSValue *resValue = [completeFunc callWithArguments:((completeDatas && [completeDatas isKindOfClass:NSArray.class]) ? completeDatas : @[])];
                    if (argItem.jsResCompleteBlock) {
                        argItem.jsResCompleteBlock([ZHJSApiCallJsResItem item:[__self jsValueToNative:resValue] error:nil]);
                    }
                }
                return [ZHJSApiCallJsNativeResItem item];
            };
            
            [resArgs addObject:[ZHJSApiArgItem item:__self.jsPage jsData:nativeValue callItem:[ZHJSApiCallJsItem itemWithSFCBlock:block jsFuncArgBlock:nil]]];
        }
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
        return [jsValue toObject];
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
- (NSString *)fetchWebViewConsoleApi{
    NSString *formatJS = [NSString stringWithContentsOfFile:[ZHJSHandler jsConsolePath] encoding:NSUTF8StringEncoding error:nil];
    NSString *jsCode = [NSString stringWithFormat:@"%@; var vConsole = new VConsole();", formatJS];
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
     self.fetchWebViewJsToNativeMethodSyncKey,
     self.fetchWebViewJsToNativeMethodAsyncKey,
     self.fetchWebViewCallSuccessFuncKey,
     self.fetchWebViewCallFailFuncKey,
     self.fetchWebViewCallCompleteFuncKey,
     self.fetchWebViewJsFunctionArgKey,
     self.fetchWebViewCallFuncName,
     self.fetchWebViewGeneratorApiFuncName];
    return [res copy];
}

- (NSString *)fetchWebViewApi:(BOOL)isReset{
    NSMutableString *res = [NSMutableString string];
    [self.apiHandler enumRegsiterApiMap:^(NSString *apiPrefix, NSDictionary<NSString *,ZHJSApiRegisterItem *> *apiMap) {
        //因为要移除api  apiMap设定写死传@{}
        NSString *jsCode = [self fetchWebViewApiJsCode:apiPrefix apiMap:isReset ? @{} : apiMap];
        if (jsCode) [res appendString:jsCode];
    }];
    return [res copy];
}
- (NSString *)fetchWebViewApiJsCode:(NSString *)apiPrefix apiMap:(NSDictionary <NSString *,ZHJSApiRegisterItem *> *)apiMap{
    if (![apiPrefix isKindOfClass:[NSString class]] || apiPrefix.length == 0) return nil;
    
    NSMutableString *code = [NSMutableString string];
    
    [code appendString:@"{"];
    [apiMap enumerateKeysAndObjectsUsingBlock:^(NSString *jsMethod, ZHJSApiRegisterItem *item, BOOL *stop) {
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
    /**
     // h5监听  @"window.addEventListener('fundJSBridgeReady', () => {});"
     //api注入完成通知  事件名称ZhengJSBridgeReady
     NSString *jsCode = [NSString stringWithFormat:@"var ZhengReadyEvent = document.createEvent('Event');ZhengReadyEvent.initEvent('%@');window.dispatchEvent(ZhengReadyEvent);", self.fetchWebViewApiFinishFlag];
     return jsCode;
     */
    __block NSMutableString *resCode = [NSMutableString string];
    [self.apiHandler enumRegsiterApiInjectFinishEventNameMap:^(NSString *apiPrefix, NSString *apiInjectFinishEventName) {
        if (apiPrefix && [apiPrefix isKindOfClass:NSString.class] && apiPrefix.length > 0 &&
            apiInjectFinishEventName && [apiInjectFinishEventName isKindOfClass:NSString.class] && apiInjectFinishEventName.length > 0) {
            [resCode appendFormat:@"var ZhengReadyEvent_%@ = document.createEvent('Event');ZhengReadyEvent_%@.initEvent(\"%@\");window.dispatchEvent(ZhengReadyEvent_%@);", apiPrefix, apiPrefix, apiInjectFinishEventName, apiPrefix];
        }
    }];
    return resCode.copy;
}

#pragma mark - exception

//异常弹窗
- (void)showWebViewException:(NSDictionary *)exception{
    // 异常抛出
    id <ZHWebViewExceptionDelegate> de = self.webView.zh_exceptionDelegate;
    if (ZHCheckDelegate(de, @selector(zh_webView:exception:))) {
        [de zh_webView:self.webView exception:exception];
    }
    // 调试弹窗
    if (self.webView.debugItem.alertWebErrorEnable) {
        [self showException:@"WebView JS异常" exception:exception];
    }
}
- (void)showJSContextException:(NSDictionary *)exception{
    if (self.jsContext.debugItem.alertCtxErrorEnable) {
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
    void (^closeAll)(UIAlertAction *action) = ^(UIAlertAction *action){
        UIViewController *last = [__self fetchActivityCtrl].presentingViewController;
        while ([last isKindOfClass:[ZHErrorAlertController class]]) {
            last = last.presentingViewController;
        }
        [last dismissViewControllerAnimated:YES completion:nil];
    };
    [alert addAction:[UIAlertAction actionWithTitle:@"复制" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [UIPasteboard generalPasteboard].string = [info description];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"关闭当前窗口" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"关闭所有窗口" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        closeAll(action);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"永久关闭窗口" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        closeAll(action);
        if (__self.webView) {
            __self.webView.debugItem.alertWebErrorEnable = NO;
            [ZHJSDebugMg() setWebDebugAlertErrorEnable:NO];
        }
        if (__self.jsContext) {
            __self.jsContext.debugItem.alertCtxErrorEnable = NO;
            [ZHJSDebugMg() setCtxDebugAlertErrorEnable:NO];
        }
    }]];
    /*
     web页面 点击返回键 可能会执行evaluateJavaScript，由于执行的js函数可能不存在，造成js报错，随即 presentViewController弹窗，此时又立即调用函数 [navigationController popViewControllerAnimated:]  系统不会处理navigationController，造成不会返回
     此处延时弹窗
     */
    [self performSelector:@selector(showExceptionInternal:) withObject:alert afterDelay:0.3];
}
- (void)showExceptionInternal:(ZHErrorAlertController *)alert{
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
        NSLog(@"👉Web log >>: %@\n", message.body);
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
- (BOOL)allowHandleScriptMessage:(NSDictionary *)jsInfo{
    // js同步、异步函数标识
    NSString *jsMethodSyncKey = [jsInfo valueForKey:@"methodSync"];
    if (!jsMethodSyncKey || ![jsMethodSyncKey isKindOfClass:NSString.class] || jsMethodSyncKey.length == 0) {
        return NO;
    }
    NSString *syncKey = [self fetchWebViewJsToNativeMethodSyncKey];
    NSString *asyncKey = [self fetchWebViewJsToNativeMethodAsyncKey];
    if ([jsMethodSyncKey isEqualToString:syncKey] ||
        [jsMethodSyncKey isEqualToString:asyncKey]) {
        return YES;
    }
    return NO;
}
- (id)handleScriptMessage:(NSDictionary *)jsInfo{
    if (!jsInfo || ![jsInfo isKindOfClass:[NSDictionary class]]) return nil;
    // 检查是否允许处理此消息
    if (![self allowHandleScriptMessage:jsInfo]) {
        return nil;
    }
    // 解析消息
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
    //处理参数
    NSMutableArray *resArgs = [NSMutableArray array];
    for (NSUInteger idx = 0; idx < jsArgs.count; idx++) {
        id jsArg = jsArgs[idx];
        if (![jsArg isKindOfClass:[NSDictionary class]]) {
            [resArgs addObject:[ZHJSApiArgItem item:self.jsPage jsData:jsArg callItem:nil]];
            continue;
        }
        NSDictionary *newParams = (NSDictionary *)jsArg;
        //获取回调方法
        NSString *successId = [newParams valueForKey:[self fetchWebViewCallSuccessFuncKey]];
        NSString *failId = [newParams valueForKey:[self fetchWebViewCallFailFuncKey]];
        NSString *completeId = [newParams valueForKey:[self fetchWebViewCallCompleteFuncKey]];
        NSString *jsFuncArgId = [newParams valueForKey:[self fetchWebViewJsFunctionArgKey]];
        BOOL hasCallFunction = (successId.length || failId.length || completeId.length || jsFuncArgId.length);
        //不需要回调方法
        if (!hasCallFunction) {
            [resArgs addObject:[ZHJSApiArgItem item:self.jsPage jsData:jsArg callItem:nil]];
            continue;
        }
        //js function 参数回调
        if (jsFuncArgId.length) {
            ZHJSApiInCallBlock block = ^ZHJSApi_InCallBlock_Header{
                if (!__self) {
                    return [ZHJSApiCallJsNativeResItem item];
                }
                NSArray *jsFuncArgDatas = argItem.jsFuncArgDatas;
                BOOL alive = argItem.alive;
                
                [__self callBackJsFunc:jsFuncArgId datas:jsFuncArgDatas alive:alive callBack:^(id jsRes, NSError *jsError) {
                    if (argItem.jsFuncArgResBlock) {
                        argItem.jsFuncArgResBlock([ZHJSApiCallJsResItem item:jsRes error:jsError]);
                    }
                }];
                return [ZHJSApiCallJsNativeResItem item];
            };
            [resArgs addObject:[ZHJSApiArgItem item:self.jsPage jsData:jsArg callItem:[ZHJSApiCallJsItem itemWithSFCBlock:nil jsFuncArgBlock:block]]];
        }else{
            //js success/fail/complete 回调
            ZHJSApiInCallBlock block = ^ZHJSApi_InCallBlock_Header{
                if (!__self) {
                    return [ZHJSApiCallJsNativeResItem item];
                }
                NSArray *successDatas = argItem.successDatas;
                NSArray *failDatas = argItem.failDatas;
                NSArray *completeDatas = argItem.completeDatas;
                NSError *error = argItem.error;
                BOOL alive = argItem.alive;
                
                if (!error && successId.length) {
                    [__self callBackJsFunc:successId datas:successDatas alive:alive callBack:^(id jsRes, NSError *jsError) {
                        if (argItem.jsResSuccessBlock) {
                            argItem.jsResSuccessBlock([ZHJSApiCallJsResItem item:jsRes error:jsError]);
                        }
                    }];
                }
                if (error && failId.length) {
                    [__self callBackJsFunc:failId datas:failDatas alive:alive callBack:^(id jsRes, NSError *jsError) {
                        if (argItem.jsResFailBlock) {
                            argItem.jsResFailBlock([ZHJSApiCallJsResItem item:jsRes error:jsError]);
                        }
                    }];
                }
                if (completeId.length) {
                    [__self callBackJsFunc:completeId datas:completeDatas alive:alive callBack:^(id jsRes, NSError *jsError) {
                        if (argItem.jsResCompleteBlock) {
                            argItem.jsResCompleteBlock([ZHJSApiCallJsResItem item:jsRes error:jsError]);
                        }
                    }];
                }
                return [ZHJSApiCallJsNativeResItem item];
            };
            [resArgs addObject:[ZHJSApiArgItem item:self.jsPage jsData:jsArg callItem:[ZHJSApiCallJsItem itemWithSFCBlock:block jsFuncArgBlock:nil]]];
        }
    }
    return [self runNativeFunc:jsMethodName apiPrefix:apiPrefix arguments:resArgs.copy];
}
//运行原生方法
- (id)runNativeFunc:(NSString *)jsMethodName apiPrefix:(NSString *)apiPrefix arguments:(NSArray <ZHJSApiArgItem *> *)arguments{
    __block id value = nil;
    [self.apiHandler fetchSelectorByName:jsMethodName apiPrefix:apiPrefix callBack:^(id target, SEL sel) {
        if (!target || !sel) return;
        
        NSMethodSignature *sig = [target methodSignatureForSelector:sel];
        NSInvocation *invo = [ZHJSInvocation invocationWithMethodSignature:sig];
        if ([invo isKindOfClass:[ZHJSInvocation class]]) {
            ((ZHJSInvocation *)invo).zhjs_target = target;
        }
        [invo setTarget:target];
        [invo setSelector:sel];
        
        if ([arguments isKindOfClass:[NSArray class]]) {
            NSInteger count = MIN(arguments.count, sig.numberOfArguments - 2);
            for (int idx = 0; idx < count; idx++) {
                ZHJSApiArgItem *arg = arguments[idx];
                int argIdx = idx + 2;
                //id object类型
                [invo setArgument:&arg atIndex:argIdx];
            }
        }
        if (!invo.argumentsRetained) {
            [invo retainArguments];
        }
        //运行
        [invo invoke];
        id __unsafe_unretained res = nil;
        if ([sig methodReturnLength]) [invo getReturnValue:&res];
        value = res;
        
        invo = nil;
    }];
    return value;
}
- (id)runNativeFunc_old_basicData:(NSString *)jsMethodName apiPrefix:(NSString *)apiPrefix arguments:(NSArray *)arguments{
    __block id value = nil;
    [self.apiHandler fetchSelectorByName:jsMethodName apiPrefix:apiPrefix callBack:^(id target, SEL sel) {
        if (!target || !sel) return;
        
        NSMethodSignature *sig = [target methodSignatureForSelector:sel];
        NSInvocation *invo = [ZHJSInvocation invocationWithMethodSignature:sig];
        if ([invo isKindOfClass:[ZHJSInvocation class]]) {
            ((ZHJSInvocation *)invo).zhjs_target = target;
        }
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
- (void)callBackJsFunc:(NSString *)funcId datas:(NSArray *)datas alive:(BOOL)alive callBack:(void (^) (id jsRes, NSError *jsError))callBack{
    if (funcId.length == 0) return;
    NSDictionary *sendParams = @{@"funcId": funcId, @"data": ((datas && [datas isKindOfClass:NSArray.class]) ? datas : @[]), @"alive": @(alive)};
    [self.webView postMessageToJs:self.fetchWebViewCallFuncName params:sendParams completionHandler:^(id res, NSError *error) {
        if (callBack) callBack(res, error);
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
- (NSString *)fetchWebViewJsFunctionArgKey{
    return @"ZhengJSToNativeFunctionArgKey";
}
- (NSString *)fetchWebViewJsToNativeMethodSyncKey{
    return @"ZhengJSToNativeMethodSyncKey";
}
- (NSString *)fetchWebViewJsToNativeMethodAsyncKey{
    return @"ZhengJSToNativeMethodAsyncKey";
}

- (void)dealloc{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    NSLog(@"%s", __func__);
}


#pragma mark - File Path
+ (NSString *)jsEventPath{
    return [self pathWithName:@"min-event.js"];
}
+ (NSString *)jsLogEventPath{
    return [self pathWithName:@"min-log.js"];
}
+ (NSString *)jsConsolePath{
    return [self pathWithName:@"vconsole.min.js"];
}
+ (NSString *)jsErrorEventPath{
    return [self pathWithName:@"min-error.js"];
}
+ (NSString *)jsSocketEventPath{
    return [self pathWithName:@"min-socket.js"];
}
+ (NSString *)pathWithName:(NSString *)name{
    return [[NSBundle mainBundle] pathForResource:name.stringByDeletingPathExtension ofType:name.pathExtension];
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TestBundle" ofType:@"bundle"]];
    return [bundle pathForResource:name.stringByDeletingPathExtension ofType:name.pathExtension];
}
@end

@implementation ZHErrorAlertController
@end
