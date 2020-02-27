//
//  ZHJSApiHandler.m
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHJSApiHandler.h"
#import <objc/runtime.h>

@interface ZHJSApiHandler ()
@property (nonatomic,strong) NSDictionary *apiMethodMap;
@end

@implementation ZHJSApiHandler

#pragma mark - api
/** ⚠️⚠️⚠️添加API步骤：
 在下面实现方法即可：
     带有回调的方法
       - (void)js_<#functionName#><##>:(NSDictionary *)params callBack:(ZHJSApiBlock)callBack{}
 
     没有回调的方法
       无返回值
       - (void)js_<#functionName#><##>:(NSDictionary *)params{}
 
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
- (void)js_request:(NSDictionary *)info callBack:(ZHJSApiBlock)callBack{
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
                return [NSError errorWithDomain:@"-request-" code:404 userInfo:@{NSLocalizedDescriptionKey: desc}];
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

- (NSDictionary *)js_getJsonSync:(NSDictionary *)params{
    return @{@"sdfd": @"22222", @"sf": @(YES)};
}
- (NSNumber *)js_getNumberSync:(NSDictionary *)params{
    return @(22);
}
- (NSNumber *)js_getBoolSync:(NSDictionary *)params{
    return @(YES);
}
- (NSString *)js_getStringSync:(NSDictionary *)params{
    return @"dfgewrefdwd";
}
- (void)js_commonLinkTo:(NSDictionary *)params{
    NSLog(@"-------commonLinkTo------------");
    NSLog(@"%@",params);
}


#pragma mark - init

- (instancetype)init{
    self = [super init];
    if (self) {
        self.apiMethodMap = [self getAllApiMethodMap];
    }
    return self;
}

- (NSString *)methodPrefix{
    return @"js_";
}

- (NSDictionary *)getAllApiMethodMap{
    NSMutableDictionary *resMethodMap = [@{} mutableCopy];
    
    unsigned int count;
    Method *methods = class_copyMethodList([self class], &count);
    
    for (int i = 0; i < count; i++){
        Method method = methods[i];
        SEL selector = method_getName(method);
        NSString *name = NSStringFromSelector(selector);
        if (![name hasPrefix:self.methodPrefix]) continue;
        
        NSString *resName = [name substringFromIndex:self.methodPrefix.length];
        if ([resName containsString:@":"]) {
            NSArray *subNames = [resName componentsSeparatedByString:@":"];
            resName = (subNames.count > 0 ? subNames[0] : resName);
        }
//        NSLog(@"-方法名---%@----",resName);
        [resMethodMap setValue:name forKey:resName];
        //        执行方法
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        //        [self performSelector:NSSelectorFromString(name) withObject:nil];
#pragma clang diagnostic pop
    }
    free(methods);
    
    return [resMethodMap copy];
}

#pragma mark - public

//api方法名
- (NSString *)fetchApiMethodPrefixName{
    return @"fund";
}

//api方法map
- (NSDictionary *)fetchApiMethodMap{
    return [self.apiMethodMap copy];
}

//获取方法名
- (SEL)fetchSelectorByName:(NSString *)name{
    if (!name || name.length == 0 || ![self.apiMethodMap.allKeys containsObject:name]) return nil;
    
    NSString *res = self.apiMethodMap[name];
    if (!res) return nil;
    
    SEL sel = NSSelectorFromString(res);
    if (![self respondsToSelector:sel]) return nil;
    return sel;
}

@end
