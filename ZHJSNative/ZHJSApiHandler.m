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
#import "ZHJSInternalSocketApiHandler.h"
#import "ZHJSInternalCustomApiHandler.h"
#import <objc/runtime.h>

@interface ZHJSApiHandler ()
@property (nonatomic,strong) NSDictionary <NSString *, NSDictionary *> *apiMap;

@property (nonatomic,strong) NSArray <ZHJSInternalApiHandler <ZHJSApiProtocol> *> *internalApiHandlers;
@property (nonatomic,strong) NSArray <id <ZHJSApiProtocol>> *outsideApiHandlers;
@end

@implementation ZHJSApiHandler

#pragma mark - init

- (instancetype)initWithApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers{
    self = [super init];
    if (self) {
        //m默认内部api
        NSArray *internalApiHandlers = @[
            [[ZHJSInternalSocketApiHandler alloc] init],
            [[ZHJSInternalCustomApiHandler alloc] init]
        ];
        for (ZHJSInternalApiHandler *handler in internalApiHandlers) {
            handler.apiHandler = self;
        }
        self.internalApiHandlers = [internalApiHandlers copy];
        //外部api
        self.outsideApiHandlers = apiHandlers;
        
        //设置
        __weak __typeof__(self) __self = self;
        __block NSMutableDictionary *apiMap = [NSMutableDictionary dictionary];
        
        void (^block) (NSArray <id <ZHJSApiProtocol>> *) = ^(NSArray <id <ZHJSApiProtocol>> *handlers){
            for (id <ZHJSApiProtocol> handler in handlers) {
                NSString *jsPrefix = [__self fetchJSApiPrefix:handler];
                if (!jsPrefix || jsPrefix.length == 0) continue;
                [apiMap setValue:@{@"handler": handler, @"map": [__self fetchApiMap:handler]} forKey:jsPrefix];
            }
        };
        block(self.internalApiHandlers);
        block(self.outsideApiHandlers);
        self.apiMap = [apiMap copy];
    }
    return self;
}

//获取方法映射表
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

//遍历方法映射表
- (void)enumApiMap:(BOOL (^)(NSString *apiPrefix, id <ZHJSApiProtocol> handler, NSDictionary *apiMap))block{
    if (!block) return;
    [self.apiMap enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL *stop) {
        NSString *apiPrefix = key;
        NSDictionary *apiMap = [obj valueForKey:@"map"];
        id <ZHJSApiProtocol> handler = [obj valueForKey:@"handler"];
        
        BOOL isStop = block(apiPrefix, handler, apiMap);
        if (isStop) *stop = YES;
    }];
}

//获取方法名
- (void)fetchSelectorByName:(NSString *)jsMethodName apiPrefix:(NSString *)apiPrefix callBack:(void (^) (id target, SEL sel))callBack{
    if (!callBack) return;
    
    if (!jsMethodName ||
        ![jsMethodName isKindOfClass:[NSString class]] ||
        jsMethodName.length == 0 ||
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
    
    ZHJSApiMethodItem *item = apiMap[jsMethodName];
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
