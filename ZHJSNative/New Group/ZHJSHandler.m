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
#import "ZHJSApiHandler.h"
#import <objc/runtime.h>
#import "ZHJSInternalSocketApiHandler.h"

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

@interface ZHJSHandler ()
@property (nonatomic,strong) ZHJSApiHandler *apiHandler;
@end

@implementation ZHJSHandler

#pragma mark - init

- (instancetype)initWithApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers{
    self = [super init];
    if (self) {
        self.apiHandler = [[ZHJSApiHandler alloc] initWithApiHandlers:apiHandlers];
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

    __weak __typeof__(self) __self = self;
    
    [self.apiHandler enumApiMap:^BOOL(NSString *apiPrefix, id <ZHJSApiProtocol> handler, NSDictionary *apiMap) {
        if (![apiPrefix isKindOfClass:[NSString class]] || apiPrefix.length == 0) {
            callBack(nil, nil);
            return NO;
        }
        NSMutableDictionary *resMap = [NSMutableDictionary dictionary];
        [apiMap enumerateKeysAndObjectsUsingBlock:^(NSString *jsMethod, ZHJSApiMethodItem *item, BOOL *stop) {
            //设置方法实现
            [resMap setValue:[__self jsContextApiMapBlock:jsMethod apiPrefix:apiPrefix] forKey:jsMethod];
        }];
        callBack(apiPrefix, [resMap copy]);
        return NO;
    }];
}
//JSContext调用原生实现
- (id)jsContextApiMapBlock:(NSString *)key apiPrefix:(NSString *)apiPrefix{
    if (!key || key.length == 0) return nil;
    __weak __typeof__(self) __self = self;
    
    //处理js的事件
    id (^apiBlock)(void) = ^(){
        //获取参数
        NSArray *arguments = [ZHJSContext currentArguments];
        JSValue *jsValue = (arguments.count == 0) ? nil : arguments[0];
        //js没传参数
        if (!jsValue) {
            return [__self runNativeFunc:key apiPrefix:apiPrefix arguments:@[]];
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
            return [__self runNativeFunc:key apiPrefix:apiPrefix arguments:@[]];
        }
        NSDictionary *params = [jsValue toObject];
        if (![params isKindOfClass:[NSDictionary class]]) {
            return [__self runNativeFunc:key apiPrefix:apiPrefix arguments:@[params]];
        }
        
        //是否需要回调
        NSString *success = __self.fetchJSContextCallSuccessFuncKey;
        NSString *fail = __self.fetchJSContextCallFailFuncKey;
        NSString *complete = __self.fetchJSContextCallCompleteFuncKey;
        BOOL hasCallFunction = ([jsValue hasProperty:success] ||
                                [jsValue hasProperty:fail] ||
                                [jsValue hasProperty:complete]);
        if (!hasCallFunction) {
            return [__self runNativeFunc:key apiPrefix:apiPrefix arguments:@[params]];
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
        return [__self runNativeFunc:key apiPrefix:apiPrefix arguments:@[params, block]];
    };
    return apiBlock;
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
    __block NSString *jsPrefix = nil;
    
    [self.apiHandler enumApiMap:^BOOL(NSString *apiPrefix, id <ZHJSApiProtocol> handler, NSDictionary *apiMap) {
        if (![apiPrefix isKindOfClass:[NSString class]] || apiPrefix.length == 0) return NO;
        if ([handler isKindOfClass:[ZHJSInternalSocketApiHandler class]]) {
            jsPrefix = [(ZHJSInternalSocketApiHandler *)handler zh_jsApiPrefixName];
            return YES;
        }
        return NO;
    }];
    
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
- (NSString *)fetchWebViewApi{
    //以下代码由event.js压缩而成
    NSString *formatJS = [NSString stringWithContentsOfFile:[ZHJSHandler jsEventPath] encoding:NSUTF8StringEncoding error:nil];
    __block NSMutableString *res = [NSMutableString string];
    [res appendFormat:formatJS,
     ZHJSHandlerName,
     self.fetchWebViewCallSuccessFuncKey,
     self.fetchWebViewCallFailFuncKey,
     self.fetchWebViewCallCompleteFuncKey,
     self.fetchWebViewCallFuncName,
     self.fetchWebViewGeneratorApiFuncName];
    
    [self.apiHandler enumApiMap:^BOOL(NSString *apiPrefix, id <ZHJSApiProtocol> handler, NSDictionary *apiMap) {
        if (![apiPrefix isKindOfClass:[NSString class]] || apiPrefix.length == 0) return NO;
        
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
        
        [res appendFormat:@"const %@=%@('%@',%@);",apiPrefix, self.fetchWebViewGeneratorApiFuncName, apiPrefix, code];
        return NO;
    }];
    
    return [res copy];
}
- (NSString *)fetchWebViewApiFinish{
    //api注入完成通知
    NSString *jsCode = [NSString stringWithFormat:@"var ZhengReadyEvent = document.createEvent('Event');ZhengReadyEvent.initEvent('%@');window.dispatchEvent(ZhengReadyEvent);", self.fetchWebViewApiFinishFlag];
    return jsCode;
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
        return [self runNativeFunc:jsMethodName apiPrefix:apiPrefix arguments:@[]];
    }
    if (![params isKindOfClass:[NSDictionary class]]) {
        return [self runNativeFunc:jsMethodName apiPrefix:apiPrefix arguments:@[params]];
    }
    
    //回调方法
    NSString *successId = [params valueForKey:[self fetchWebViewCallSuccessFuncKey]];
    NSString *failId = [params valueForKey:[self fetchWebViewCallFailFuncKey]];
    NSString *completeId = [params valueForKey:[self fetchWebViewCallCompleteFuncKey]];
    BOOL hasCallFunction = (successId.length || failId.length || completeId.length);
    //不需要回调方法
    if (!hasCallFunction) {
        return [self runNativeFunc:jsMethodName apiPrefix:apiPrefix arguments:@[params]];
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
    return [self runNativeFunc:jsMethodName apiPrefix:apiPrefix arguments:@[params, block]];
}
//运行原生方法
- (id)runNativeFunc:(NSString *)jsMethodName apiPrefix:(NSString *)apiPrefix arguments:(NSArray *)arguments{
    __block id value = nil;
    [self.apiHandler fetchSelectorByName:jsMethodName apiPrefix:apiPrefix callBack:^(id target, SEL sel) {
        if (!target || !sel) return;
        
        NSMethodSignature *sig = [target methodSignatureForSelector:sel];
        NSInvocation *invo = [NSInvocation invocationWithMethodSignature:sig];
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
        value = res;
        
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
- (void)callBackJsFunc:(NSString *)funcId data:(id)result alive:(BOOL)alive callBack:(void (^) (id data, NSError *error))callBack{
    /**
     data:[NSNull null]  对应js的Null类型
     */
    if (funcId.length == 0) return;
    result = @{@"funcId": funcId, @"data": result?:[NSNull null], @"alive": @(alive)};
    [self.webView postMessageToJs:self.fetchWebViewCallFuncName params:result completionHandler:^(id res, NSError *error) {
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
- (NSString *)fetchWebViewApiFinishFlag{
    return @"ZhengJSBridgeReady";
}

- (void)dealloc{
    NSLog(@"-------%s---------", __func__);
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
