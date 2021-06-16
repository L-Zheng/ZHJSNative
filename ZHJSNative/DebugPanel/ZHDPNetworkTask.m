//
//  ZHDPNetworkTask.m
//  ZHJSNative
//
//  Created by EM on 2021/6/3.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPNetworkTask.h"
#import "ZHDPManager.h"// 调试面板管理
#import <objc/runtime.h>
/*截获系统请求
 
 NSURLSession.NSURLSessionConfiguration.protocolClasses
 系统会按照protocolClasses数组下的class  依次进行决议
 ProtocolB  + (BOOL)canInitWithRequest:
 ProtocolA  + (BOOL)canInitWithRequest:

 ProtocolB   ProtocolA
 return NO   return NO   交由系统处理
 return NO   return YES
                         依次调用
                         ProtocolA->
                         startLoading->
                         canInitWithRequest->
                         if ([NSURLProtocol propertyForKey:@"xx" inRequest:request] ) {
                             return NO;
                         }->
                         ProtocolB->
                         canInitWithRequest->
                         // 如果此时返回YES  会交给ProtocolB处理 造成混乱 请求可能丢弃
                         if ([NSURLProtocol propertyForKey:@"xxx" inRequest:request] ) {
                             return NO;
                         }->
 return YES   return NO
                         依次调用
                         ProtocolB->
                         startLoading->
                         canInitWithRequest->
                         if ([NSURLProtocol propertyForKey:@"xx" inRequest:request] ) {
                             return NO;
                         }->
                         ProtocolA->
                         canInitWithRequest->
                         // 如果此时返回YES  会交给ProtocolA处理 造成混乱 请求可能丢弃
                         if ([NSURLProtocol propertyForKey:@"xxx" inRequest:request] ) {
                             return NO;
                         }->
 return YES   return YES  同上
 */

typedef NSURLSessionConfiguration *(*ZHDPSessionConfigConstructor)(id,SEL);

static ZHDPSessionConfigConstructor zhdp_orig_defaultSessionConfiguration;
static ZHDPSessionConfigConstructor zhdp_orig_ephemeralSessionConfiguration;

static NSURLSessionConfiguration * zhdp_addSessionConfiguration(NSURLSessionConfiguration *config){
    if ([config respondsToSelector:@selector(protocolClasses)] && [config respondsToSelector:@selector(setProtocolClasses:)]) {
        NSMutableArray *urlProtocolClasses = [NSMutableArray arrayWithArray:config.protocolClasses];
        Class protoCls = ZHDPNetworkTaskProtocol.class;
        if (![urlProtocolClasses containsObject:protoCls]) {
            [urlProtocolClasses insertObject:protoCls atIndex:0];
        }
        config.protocolClasses = urlProtocolClasses;
    }
    return config;
}
static NSURLSessionConfiguration * zhdp_replaced_defaultSessionConfiguration(id self, SEL _cmd){
    NSURLSessionConfiguration *config = zhdp_orig_defaultSessionConfiguration(self,_cmd);
    return zhdp_addSessionConfiguration(config);
}
static NSURLSessionConfiguration * zhdp_replaced_ephemeralSessionConfiguration(id self, SEL _cmd){
    NSURLSessionConfiguration *config = zhdp_orig_ephemeralSessionConfiguration(self,_cmd);
    return zhdp_addSessionConfiguration(config);
}
IMP zhdp_replaceMethod(SEL selector, IMP newImpl, Class affectedClass, BOOL isClassMethod){
    Method origMethod = isClassMethod ? class_getClassMethod(affectedClass, selector) : class_getInstanceMethod(affectedClass, selector);
    IMP origImpl = method_getImplementation(origMethod);

    if (!class_addMethod(isClassMethod ? object_getClass(affectedClass) : affectedClass, selector, newImpl, method_getTypeEncoding(origMethod))){
        method_setImplementation(origMethod, newImpl);
    }
    return origImpl;
}
extern NSURLCacheStoragePolicy zhdp_cacheStoragePolicyForRequestAndResponse(NSURLRequest * request, NSHTTPURLResponse * response)
    // See comment in header.
{
    BOOL                        cacheable;
    NSURLCacheStoragePolicy     result;

    // First determine if the request is cacheable based on its status code.
    
    switch ([response statusCode]) {
        case 200:
        case 203:
        case 206:
        case 301:
        case 304:
        case 404:
        case 410: {
            cacheable = YES;
        } break;
        default: {
            cacheable = NO;
        } break;
    }

    // If the response might be cacheable, look at the "Cache-Control" header in
    // the response.

    // IMPORTANT: We can't rely on -rangeOfString: returning valid results if the target
    // string is nil, so we have to explicitly test for nil in the following two cases.
    
    if (cacheable) {
        NSString *  responseHeader;
        
        responseHeader = [[response allHeaderFields][@"Cache-Control"] lowercaseString];
        if ( (responseHeader != nil) && [responseHeader rangeOfString:@"no-store"].location != NSNotFound) {
            cacheable = NO;
        }
    }

    // If we still think it might be cacheable, look at the "Cache-Control" header in
    // the request.

    if (cacheable) {
        NSString *  requestHeader;

        requestHeader = [[request allHTTPHeaderFields][@"Cache-Control"] lowercaseString];
        if ( (requestHeader != nil)
          && ([requestHeader rangeOfString:@"no-store"].location != NSNotFound)
          && ([requestHeader rangeOfString:@"no-cache"].location != NSNotFound) ) {
            cacheable = NO;
        }
    }

    // Use the cacheable flag to determine the result.
    
    if (cacheable) {
    
        // This code only caches HTTPS data in memory.  This is inline with earlier versions of
        // iOS.  Modern versions of iOS use file protection to protect the cache, and thus are
        // happy to cache HTTPS on disk.  I've not made the correspondencing change because
        // it's nice to see all three cache policies in action.
    
        if ([[[[request URL] scheme] lowercaseString] isEqual:@"https"]) {
            result = NSURLCacheStorageAllowedInMemoryOnly;
        } else {
            result = NSURLCacheStorageAllowed;
        }
    } else {
        result = NSURLCacheStorageNotAllowed;
    }

    return result;
}

@interface ZHDPNetworkTaskProtocol ()<NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@property (atomic, strong) NSURLConnection  *connection;
@property (atomic, strong) NSURLResponse    *response;
@property (atomic, strong) NSMutableData    *data;
@property (atomic, strong) NSDate   *startDate;
@end

@implementation ZHDPNetworkTaskProtocol
+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        zhdp_orig_defaultSessionConfiguration = (ZHDPSessionConfigConstructor)zhdp_replaceMethod(@selector(defaultSessionConfiguration), (IMP)zhdp_replaced_defaultSessionConfiguration, [NSURLSessionConfiguration class], YES);
        
        zhdp_orig_ephemeralSessionConfiguration = (ZHDPSessionConfigConstructor)zhdp_replaceMethod(@selector(ephemeralSessionConfiguration), (IMP)zhdp_replaced_ephemeralSessionConfiguration, [NSURLSessionConfiguration class], YES);
    });
}
+ (NSString *)URLProperty{
    return NSStringFromClass(self);
}
+ (BOOL)canInitWithRequest:(NSURLRequest *)request{
    // return YES:拦截   return NO:不拦截
    
    
    if (!ZHDPMg().networkTask.interceptEnable) {
        return NO;
    }
    
    // 只处理http请求
    if (![request.URL.scheme isEqualToString:@"http"] &&
        ![request.URL.scheme isEqualToString:@"https"]) {
        return NO;
    }
    // 防止重复请求
    if ([NSURLProtocol propertyForKey:[self URLProperty] inRequest:request] ) {
        return NO;
    }
    // 只截获的url
    NSArray <NSString *> *onlyURLs = @[];
    if (onlyURLs.count > 0) {
        NSString *url = [request.URL.absoluteString lowercaseString];
        for (NSString *tUrl in onlyURLs) {
            if ([url rangeOfString:[tUrl lowercaseString]].location != NSNotFound)
                return YES;
        }
        return NO;
    }
    
    // 默认全部截获
    return YES;
}
//返回规范的request
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request{
    return request;
}
// 判断两个请求是否是同一个请求，如果是，则可以使用缓存数据，默认为YES
+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b{
    return [super requestIsCacheEquivalent:a toRequest:b];
}
- (void)startLoading{
    self.data = [NSMutableData data];
    self.startDate = [NSDate date];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:[self.class URLProperty] inRequest:mutableReqeust];
    self.connection = [NSURLConnection connectionWithRequest:mutableReqeust delegate:self];

#pragma clang diagnostic pop
}
- (void)stopLoading{
    if (self.connection) {
        [self.connection cancel];
        self.connection = nil;
    }
    [ZHDPMg() zh_test_addNetwork:self.startDate request:self.request response:self.response responseData: self.data];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (!error) {
        [[self client] URLProtocolDidFinishLoading:self];
    } else {
        [[self client] URLProtocol:self didFailWithError:error];
    }
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    return YES;
}

//解決發送IP地址的HTTPS請求 證書驗證
- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (!challenge) {
        return;
    }
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        //構造一個NSURLCredential發送給發起方
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
    } else {
        //對於其他驗證方法直接進行處理流程
        [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
}

#pragma GCC diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [[self client] URLProtocol:self didReceiveAuthenticationChallenge:challenge];
}
- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [[self client] URLProtocol:self didCancelAuthenticationChallenge:challenge];
}
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    if ([[protectionSpace authenticationMethod] isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        return YES;
    }
    return NO;
}
#pragma GCC diagnostic pop



#pragma mark - NSURLConnectionDataDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSURLCacheStoragePolicy cacheStoragePolicy = NSURLCacheStorageNotAllowed;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        cacheStoragePolicy = zhdp_cacheStoragePolicyForRequestAndResponse(connection.originalRequest, (NSHTTPURLResponse *) response);
    }
    
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:cacheStoragePolicy];
    self.response = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [[self client] URLProtocol:self didLoadData:data];
    [self.data appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
//    [[self client] URLProtocol:self cachedResponseIsValid:cachedResponse];
    return cachedResponse;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[self client] URLProtocolDidFinishLoading:self];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    //重定向 状态码 >=300 && < 400
    if (response && [response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger status = httpResponse.statusCode;
        if (status >= 300 && status < 400) {
            [self.client URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
            //记得设置成nil，要不然正常请求会请求两次
            request = nil;
        }
    }
    return request;
}
- (void)dealloc{
    [NSURLProtocol unregisterClass:[self class]];
}
@end


@interface ZHDPNetworkTask ()
@property (nonatomic,strong) ZHDPNetworkTaskProtocol *taskProtocol;
@end
@implementation ZHDPNetworkTask

- (void)interceptNetwork{
    self.interceptEnable = YES;
    [NSURLProtocol registerClass:[ZHDPNetworkTaskProtocol class]];
}
- (void)cancelNetwork{
    self.interceptEnable = NO;
    [NSURLProtocol unregisterClass:[ZHDPNetworkTaskProtocol class]];
}

- (NSData *)convertToDataByInputStream:(NSInputStream *)stream{
    if (!stream || ![stream isKindOfClass:NSInputStream.class]) {
        return nil;
    }
    NSMutableData * data = [NSMutableData data];
    [stream open];
    NSInteger result;
    uint8_t buffer[1024]; // BUFFER_LEN can be any positive integer
    
    while((result = [stream read:buffer maxLength:1024]) != 0) {
        if(result > 0) {
            // buffer contains result bytes of data to be handled
            [data appendBytes:buffer length:result];
        } else {
            // The stream had an error. You can get an NSError object using [iStream streamError]
            if (result<0) {
//                [NSException raise:@"STREAM_ERROR" format:@"%@", [stream streamError]];
                return nil;//liman
            }
        }
    }
    return data;
}

- (ZHDPNetworkTaskProtocol *)taskProtocol{
    if (!_taskProtocol) {
        _taskProtocol = [[ZHDPNetworkTaskProtocol alloc] init];
    }
    return _taskProtocol;
}

@end


