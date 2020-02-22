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

@implementation ZHJSHandler

/** ⚠️⚠️⚠️添加API步骤：
 1、customApiKeys方法添加方法名
 2、实现方法：
    带有回调的方法：第二个参数必须为callBack  不能改动
       - (void)<#functionName#><##>:(NSDictionary *)params callBack:(void (^) (id result, NSError *error))callBack{}
    没有有回调的方法：
       - (void)<#functionName#><##>:(NSDictionary *)params{}
 */
#pragma mark - event

//apis
- (NSArray *)customApiKeys{
    return @[
        @"request",
        @"getJsonSync",
        @"getNumberSync",
        @"getBoolSync",
        @"getStringSync",
        @"commonLinkTo"
    ];
}

- (void)request:(NSDictionary *)info callBack:(void (^) (id result, NSError *error))callBack{
    NSString *url = [info objectForKey:@"url"];
    NSString *method = [[info objectForKey:@"method"] uppercaseString];
    NSMutableDictionary *headers = [info objectForKey:@"header"];
    NSDictionary *parameters = [info objectForKey:@"data"];
    if (!parameters || ![parameters isKindOfClass:[NSDictionary class]]) {
        parameters = @{};
    }if (!headers || ![headers isKindOfClass:[NSDictionary class]]) {
        headers = [@{} mutableCopy];
    }
    
    NSMutableURLRequest *request = nil;
    if ([method isEqualToString:@"POST"]) {
        BOOL isAppendParams = YES;
        //参数拼接Url
        if (isAppendParams) {
            NSURL *aURL = [NSURL URLWithString:(parameters.count ? [NSString stringWithFormat:@"%@?%@", url, [self queryString:parameters]] : url)];
            request = [NSMutableURLRequest requestWithURL:aURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
        }else{
            request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
            //参数放Body
            NSString *contentType = [request valueForHTTPHeaderField:@"Content-Type"];
            if ([contentType isEqualToString:@"application/x-www-form-urlencoded"]) {
                NSData *data = [[self queryString:parameters] dataUsingEncoding:NSUTF8StringEncoding];
                if (data) [request setHTTPBody:data];
            }else{
                NSData *data = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
                if (data) [request setHTTPBody:data];
            }
        }
        [request setHTTPMethod:@"POST"];
    } else {
        NSURL *aURL = [NSURL URLWithString:(parameters.count ? [NSString stringWithFormat:@"%@?%@", url, [self queryString:parameters]] : url)];
        request = [NSMutableURLRequest requestWithURL:aURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
        [request setHTTPMethod:@"GET"];
    }
    //header参数
    for (NSString *filedkey in headers) {
        [request setValue:headers[filedkey] forHTTPHeaderField:filedkey];
    }
    [request setHTTPShouldHandleCookies:NO];
    if (![request valueForHTTPHeaderField:@"Content-Type"]) {
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }
    [request setValue:@"iPhone" forHTTPHeaderField:@"User-Agent"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSLog(@"👉-ios-request--api发起请求");
    NSLog(@"%@", @{
        @"request-url": request.URL.absoluteString,
        @"js-url": url,
        @"js-method": method,
        @"js-params": parameters,
        @"js-headers": headers
    });
    
    //创建请求 Task
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:
                                      ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!callBack) return;
        //解析返回的数据
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError * (^createError) (NSString *desc) = ^(NSString *desc){
                return [NSError errorWithDomain:@"fund-news-request" code:404 userInfo:@{NSLocalizedDescriptionKey: desc}];
            };
            NSLog(@"👉-ios-request--api请求回调");
            NSLog(@"%@", @{
                @"url": response.URL.absoluteString?:@""
            });
            
            if (error) {
                callBack(nil, error);
                return;
            }
            if (!data) {
                callBack(nil, createError(@"没有数据"));
                return;
            }
            if (!response || ![response isKindOfClass:[NSHTTPURLResponse class]]) {
                callBack(nil, createError((response ? @"不是NSHTTPURLResponse响应" : @"response为空")));
                return;
            }
            
            id result = nil;
            NSError *jsonError = nil;
//            [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
            if (jsonError || !result) {
                callBack(nil, createError(@"解析json失败"));
                return;
            }
            NSLog(@"👉-ios-request--api回调数据");
            NSLog(@"%@",result);
            callBack(@{@"data": result?:@{},
                       @"statusCode": @([(NSHTTPURLResponse *)response statusCode])
            }, nil);
        });
    }];
    [dataTask resume];
}
- (NSString *)queryString:(NSDictionary *)parameters{
    __block NSMutableArray *arguments = [NSMutableArray array];
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (obj == [NSNull null] ||
            ![key isKindOfClass:[NSString class]]) return;
        if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]]) {
            obj = [NSString stringWithFormat:@"%@", obj];
        }else{
            return;
        }
        NSString *encodedKey   = [key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSString *encodedValue = [obj stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSString *kvPair       = [NSString stringWithFormat:@"%@=%@", encodedKey, encodedValue];
        [arguments addObject:kvPair];
    }];
    return [arguments componentsJoinedByString:@"&"];
}


- (NSDictionary *)getJsonSync:(NSDictionary *)params{
    return @{@"sdfd": @"22222", @"sf": @(YES)};
}
- (NSNumber *)getNumberSync:(NSDictionary *)params{
    return @(22);
}
- (NSNumber *)getBoolSync:(NSDictionary *)params{
    return @(YES);
}
- (NSString *)getStringSync:(NSDictionary *)params{
    return @"dfgewrefdwd";
}
- (void)commonLinkTo:(NSDictionary *)params{
    NSLog(@"-------commonLinkTo------------");
    NSLog(@"%@",params);
}

#pragma mark - api

//JSContext注入的api
- (NSDictionary *)jsContextApiMap{
    NSArray *apis = [self customApiKeys];
    NSMutableDictionary *map = [NSMutableDictionary dictionary];
    for (NSString *key in apis) {
        [map setValue:[self jsContextApiMapBlock:key] forKey:key];
    }
    return [map copy];
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
            return [__self runNativeFunc:[NSString stringWithFormat:@"%@:",key] params1:params params2:nil];
        }
        
        //获取回调方法
        JSValue *successFunc = [paramsValue valueForProperty:success];
        JSValue *failFunc = [paramsValue valueForProperty:fail];
        void (^block)(id, NSError *) = ^(id result, NSError *error) {
            if (!error && result) {
                [successFunc callWithArguments:@[result]];
            }else{
                id desc = error ? error.localizedDescription : @"没有数据";
                [failFunc callWithArguments:@[desc]];
            }
        };
        return [__self runNativeFunc:[NSString stringWithFormat:@"%@:%@:",key, [__self callFunctionParamsKey]] params1:params params2:block];
        
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
        return [self runNativeFunc:[NSString stringWithFormat:@"%@:",methodName] params1:params params2:nil];
    }
    
    //需要回调方法
    NSString *successId = [params valueForKey:[self fetchCallSuccessFuncKey]];
    NSString *failId = [params valueForKey:[self fetchCallFailFuncKey]];
    BOOL isHasCallFunction = (successId.length || failId.length);
    if (isHasCallFunction) {
        __weak __typeof__(self) __self = self;
        void (^block)(id, NSError *) = ^(id result, NSError *error) {
            if (!error) {
                [__self callBackJsFunc:successId data:result callBack:nil];
            }else{
                [__self callBackJsFunc:failId data:error.localizedDescription callBack:nil];
            }
        };
        return [self runNativeFunc:[NSString stringWithFormat:@"%@:%@:",methodName, [self callFunctionParamsKey]] params1:params params2:block];
    }
    
    //不需要回调方法
    return [self runNativeFunc:[NSString stringWithFormat:@"%@:",methodName] params1:params params2:nil];
}

//同步处理js的调用
- (id)handleJSFuncSync:(NSDictionary *)jsInfo{
    return [self handleScriptMessage:jsInfo];
}

//运行原生方法
- (id)runNativeFunc:(NSString *)methodName params1:(id)params1 params2:(id)params2{
    SEL sel = NSSelectorFromString(methodName);
    if (![self respondsToSelector:sel]) return nil;
    
    NSMethodSignature *signature = [self methodSignatureForSelector:sel];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:self];
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

//异步处理js的调用

- (id)handleJSFunc:(NSDictionary *)jsInfo{
    if (!jsInfo || ![jsInfo isKindOfClass:[NSDictionary class]]) return nil;
    
    NSString *methodValue = [jsInfo valueForKey:@"methodName"];
    
    NSString *methodName = [NSString stringWithFormat:@"%@:",methodValue];
    id params = [jsInfo objectForKey:@"params"];
    SEL sel = NSSelectorFromString(methodName);
    if (![self respondsToSelector:sel]) {
        methodName = methodValue;
        sel = NSSelectorFromString(methodName);
        if (![self respondsToSelector:sel]) return nil;
    }
    
    NSMethodSignature *signature = [self methodSignatureForSelector:sel];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:self];
    [invocation setSelector:sel];

    //设置参数
    NSMutableArray *paramsArr = [@[] mutableCopy];
    if (params) {
        [paramsArr addObject:params];
    }
    if (paramsArr.count > 0) {
        NSUInteger i = 1;
        for (id object in paramsArr) {
            id tempObject = object;
            [invocation setArgument:&tempObject atIndex:++i];
        }
    }
    //运行
    [invocation invoke];
    
    if ([signature methodReturnLength]) {
        id res;
        [invocation getReturnValue:&res];
        return res;
    }
    return nil;
}


//js消息回调
- (void)callBackJsFunc:(NSString *)funcId data:(id)result callBack:(void (^) (id data, NSError *error))callBack{
    if (funcId.length == 0 || !result) return;
    result = @{@"funcId": funcId, @"data": result};
    [self.webView postMessageToJs:@"FNCallBack" params:result completionHandler:^(id res, NSError *error) {
        if (callBack) callBack(res, error);
    }];
}

//带有回调方法的js事件 调用原生方法名的第二个参数
- (NSString *)callFunctionParamsKey{
    return @"callBack";
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
