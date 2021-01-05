//
//  ZHJSInWebFundApi.m
//  ZHJSNative
//
//  Created by EM on 2020/12/20.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHJSInWebFundApi.h"

@implementation ZHJSInWebFundApi

#pragma mark - api

 - (void)js_request:(NSDictionary *)info callItem:(ZHJSApiCallItem *)callItem{
     NSLog(@"-------%s---------", __func__);
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
         if (!callItem.call) return;
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
                 callItem.call(nil, error);
                 return;
             }
             if (!data) {
                 callItem.call(nil, createError(@"没有数据"));
                 return;
             }
             if (!response || ![response isKindOfClass:[NSHTTPURLResponse class]]) {
                 callItem.call(nil, createError((response ? @"不是NSHTTPURLResponse响应" : @"response为空")));
                 return;
             }
             
             id result = nil;
             NSError *jsonError = nil;
 //            [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
             result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
             if (jsonError || !result) {
                 callItem.call(nil, createError(@"解析json失败"));
                 return;
             }
             NSLog(@"👉-ios-request--api回调数据");
             NSLog(@"%@",result);
             callItem.call(@{@"data": result?:@{},
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

 - (NSDictionary *)js_getJsonSync:(NSDictionary *)params p1:(NSDictionary *)p1 p2:(id)p2 p3:(id)p3 p4:(id)p4 p5:(id)p5 p6:(id)p6 p7:(id)p7 p8:(id)p8 p9:(id)p9 callItem:(ZHJSApiCallItem *)callItem{
     
     ZHJSApiCallArgItem *callArgItem = [ZHJSApiCallArgItem item];
     callArgItem.successData = @"lkjhg";
     callArgItem.error = nil;
     callArgItem.alive = YES;
     callArgItem.jsReturnSuccessBlock = ^ZHJSApi_RunJsReturnBlock_Header {
         NSLog(@"success res: %@--%@",jsReturnItem.result, jsReturnItem.error);
         return [ZHJSApiRuniOSReturnItem item];
     };
     callArgItem.jsReturnFailBlock = ^ZHJSApi_RunJsReturnBlock_Header {
         NSLog(@"fail res: %@--%@",jsReturnItem.result, jsReturnItem.error);
         return [ZHJSApiRuniOSReturnItem item];
     };
     callArgItem.jsReturnCompleteBlock = ^ZHJSApi_RunJsReturnBlock_Header {
         NSLog(@"complete res: %@--%@",jsReturnItem.result, jsReturnItem.error);
         return [ZHJSApiRuniOSReturnItem item];
     };
     
     ZHJSApiCallItem *item1 = params[ZHJSApiCallItemKey];
     ZHJSApiCallItem *item2 = p1[ZHJSApiCallItemKey];
     
     if (item1) item1.callArg(callArgItem);
     if (item2) item2.call(@"2222", nil);
     
     callItem.call(@"3333", nil);
     return @{@"sdfd": @"22222", @"sf": @(YES)};
 }
ZHJS_EXPORT_FUNC(getNumberSync, @(YES))
 - (NSNumber *)js_getNumberSync:(NSDictionary *)params{
     NSLog(@"-------%s---------", __func__);
     return @(22);
 }
ZHJS_EXPORT_FUNC(getBoolSync, @(YES))
 - (NSNumber *)js_getBoolSync:(NSDictionary *)params{
     NSLog(@"-------%s---------", __func__);
     return @(YES);
 }
ZHJS_EXPORT_FUNC(getStringSync, @(YES), @{@"dd": @"vvv"})
 - (NSString *)js_getStringSync:(NSDictionary *)params{
     NSLog(@"-------%s---------", __func__);
     return @"dfgewrefdwd";
 }
 - (void)js_commonLinkTo:(NSDictionary *)params p1:(id)p1 p2:(id)p2 p3:(id)p3 p4:(id)p4 p5:(id)p5 p6:(id)p6 p7:(id)p7 p8:(id)p8 p9:(id)p9 callItem:(ZHJSApiCallItem *)callItem{
     
     ZHJSApiCallItem *item1 = params[ZHJSApiCallItemKey];
     ZHJSApiCallItem *item2 = p1[ZHJSApiCallItemKey];
     
     item1.callA(@"1111", nil, YES);
     item2.call(@"2222", nil);
     
     callItem.call(@"3333", nil);
     NSLog(@"-------%s---------", __func__);
 }
- (void)js_commonLinkTo11:(NSDictionary *)params callItem:(ZHJSApiCallItem *)callItem{
    callItem.call(@"2222", nil);
}

#pragma mark - ZHJSApiProtocol

//js api方法名前缀  如：fund
- (NSString *)zh_jsApiPrefixName{
    return @"fund";
}
//ios api方法名前缀 如：js_
- (NSString *)zh_iosApiPrefixName{
    return @"js_";
}

- (void)dealloc{
    NSLog(@"%s", __func__);
}

@end
