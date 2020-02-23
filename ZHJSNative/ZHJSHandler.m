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
    }
    return self;
}

#pragma mark - api

//JSContext注入的api
- (NSDictionary *)jsContextApiMap{
    NSDictionary *apiMap = [self.apiHandler fetchApiMethodMap];
    NSMutableDictionary *resMap = [NSMutableDictionary dictionary];
    
    __weak __typeof__(self) __self = self;
    [apiMap enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        [resMap setValue:[__self jsContextApiMapBlock:key] forKey:key];
    }];
    return [resMap copy];
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
//WebView注入的api
+ (NSString *)webViewApiSource{
    NSString *handlerJS = [NSString stringWithContentsOfFile:[ZHUtil jsEventPath] encoding:NSUTF8StringEncoding error:nil];
//    handlerJS = [handlerJS stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return handlerJS;
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
    NSLog(@"----ZHJSHandler-------dealloc---------");
}

@end
