//
//  ZHJSApiHandler.m
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHJSApiHandler.h"
#import "ZHJSHandler.h"
#import "ZHWebView.h"
#import "ZHJSInternalApiHandler.h"
#import <objc/runtime.h>

@interface ZHJSApiHandler ()
@property (nonatomic,strong) NSDictionary <NSString *, NSDictionary *> *apiMap;
@property (nonatomic,strong) NSDictionary <NSString *, ZHJSApiMethodItem *> *internalApiMap;
@property (nonatomic,strong) NSDictionary <NSString *, ZHJSApiMethodItem *> *outsideApiMap;

@property (nonatomic,strong) id <ZHJSApiProtocol> outsideApiHandler;
@property (nonatomic,strong) ZHJSInternalApiHandler <ZHJSApiProtocol> *internalApiHandler;
@end

@implementation ZHJSApiHandler

#pragma mark - init

- (instancetype)initWithApiHandler:(id <ZHJSApiProtocol>)apiHandler{
    self = [super init];
    if (self) {
        self.internalApiHandler = [[ZHJSInternalApiHandler alloc] init];
        self.internalApiHandler.apiHandler = self;
        
        self.outsideApiHandler = apiHandler;
        
        self.internalApiMap = [self fetchInternalApiMap];
        self.outsideApiMap = [self fetchOutsideApiMap];
        
        NSMutableDictionary *apiMap = [NSMutableDictionary dictionary];
        NSString *jsPrefix = [self fetchInternalJSApiPrefix];
        if (jsPrefix.length) {
            [apiMap setValue:@{@"handler": self.internalApiHandler, @"map": self.internalApiMap} forKey:jsPrefix];
        }
        jsPrefix = [self fetchOutsideJSApiPrefix];
        if (jsPrefix.length) {
            [apiMap setValue:@{@"handler": self.outsideApiHandler, @"map": self.outsideApiMap} forKey:jsPrefix];
        }
        self.apiMap = [apiMap copy];
    }
    return self;
}

//获取方法映射表
- (NSDictionary *)fetchInternalApiMap{
    return [self fetchApiMap:self.internalApiHandler];
}
- (NSDictionary *)fetchOutsideApiMap{
    return [self fetchApiMap:self.outsideApiHandler];
}
- (NSDictionary *)fetchApiMap:(id <ZHJSApiProtocol>)api{
    NSString *nativeMethodPrefix = [self fetchNativeApiPrefix:api];
    if (!nativeMethodPrefix || nativeMethodPrefix.length == 0) return @{};
    
    NSMutableDictionary <NSString *, ZHJSApiMethodItem *> *resMethodMap = [@{} mutableCopy];
    
    unsigned int count;
    Method *methods = class_copyMethodList([api class], &count);
    
    for (int i = 0; i < count; i++){
        Method method = methods[i];
        SEL selector = method_getName(method);
        NSString *nativeName = NSStringFromSelector(selector);
        if (![nativeName hasPrefix:nativeMethodPrefix]) continue;
        
        NSString *jsName = [nativeName substringFromIndex:nativeMethodPrefix.length];
        if ([jsName containsString:@":"]) {
            NSArray *subNames = [jsName componentsSeparatedByString:@":"];
            jsName = (subNames.count > 0 ? subNames[0] : jsName);
        }
        ZHJSApiMethodItem *item = [[ZHJSApiMethodItem alloc] init];
        item.jsMethodName = jsName;
        item.nativeMethodName = nativeName;
        [resMethodMap setValue:item forKey:jsName];
        //        执行方法
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        //        [self performSelector:NSSelectorFromString(name) withObject:nil];
#pragma clang diagnostic pop
    }
    free(methods);
    
    return [resMethodMap copy];
}

//查找原生api方法前缀js_
- (NSString *)fetchNativeApiPrefix:(id <ZHJSApiProtocol>)api{
    if (!api) return nil;
    if (api && [api respondsToSelector:@selector(zh_iosApiPrefixName)]) {
        NSString *res = [api zh_iosApiPrefixName];
        if ([res isKindOfClass:[NSString class]] && res.length) {
            return res;
        }
    }
    return nil;
}

//查找js api方法前缀fund
- (NSString *)fetchInternalJSApiPrefix{
    return [self fetchJSApiPrefix:self.internalApiHandler];
}
- (NSString *)fetchOutsideJSApiPrefix{
    return [self fetchJSApiPrefix:self.outsideApiHandler];
}
- (NSString *)fetchJSApiPrefix:(id <ZHJSApiProtocol>)api{
    if (!api) return nil;
    if (api && [api respondsToSelector:@selector(zh_jsApiPrefixName)]) {
        NSString *res = [api zh_jsApiPrefixName];
        if ([res isKindOfClass:[NSString class]] && res.length) {
            return res;
        }
    }
    return nil;
}

#pragma mark - public

//获取方法名
- (void)fetchSelectorByName:(NSString *)methodName apiPrefix:(NSString *)apiPrefix callBack:(void (^) (id target, SEL sel))callBack{
    if (!callBack) return;
    
    if (!methodName ||
        ![methodName isKindOfClass:[NSString class]] ||
        methodName.length == 0 ||
        !apiPrefix ||
        ![apiPrefix isKindOfClass:[NSString class]] ||
        apiPrefix.length == 0 ){
        callBack(nil, nil);
        return;
    }
    NSDictionary *map = [self.apiMap valueForKey:apiPrefix];
    if (!map){
        callBack(nil, nil);
        return;
    }
    
    id <ZHJSApiProtocol> handler = [map valueForKey:@"handler"];
    NSDictionary *apiMap = [map valueForKey:@"map"];
    
    ZHJSApiMethodItem *item = apiMap[methodName];
    if (!item || !item.nativeMethodName) {
        callBack(nil, nil);
        return;
    }
    
    SEL sel = NSSelectorFromString(item.nativeMethodName);
    if (!handler || ![handler respondsToSelector:sel]) {
        callBack(nil, nil);
        return;
    }
    callBack(handler, sel);
}
- (void)dealloc{
    NSLog(@"-------%s---------", __func__);
}

@end

@implementation ZHJSApiMethodItem
- (BOOL)isSync{
    return [self.jsMethodName hasSuffix:@"Sync"];
}
@end
