//
//  ZHJSApiHandler.m
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHJSApiHandler.h"
#import "ZHJSHandler.h"
#import "ZHWebDebugItem.h"
#import "ZHJSInWebSocketApi.h"
#import "ZHJSInWebFundApi.h"
#import "ZHJSInContextFundApi.h"
#import <objc/runtime.h>

@interface ZHJSApiHandler ()
/**
@{
    @"fund": @[
                @{
                    @"handler": id <ZHJSApiProtocol>,
                    @"map" : @{
                            @"getSystemInfoSync": @[
                                    //本类
                                    ZHJSApiRegisterItem1,
                                    //父类
                                    ZHJSApiRegisterItem2,
                                    //父类的父类
                                    ZHJSApiRegisterItem3
                            ]
                    }
                }
    ]
}
 */
@property (nonatomic,strong) NSMutableDictionary <NSString *, NSArray *> *apiMap;

@property (nonatomic,strong) NSArray <ZHJSInApi <ZHJSApiProtocol> *> *internalApiHandlers;
@property (nonatomic,strong) NSMutableArray <id <ZHJSApiProtocol>> *outsideApiHandlers;

@property (nonatomic,weak) ZHJSHandler *handler;
@end

@implementation ZHJSApiHandler

#pragma mark - init

- (NSMutableDictionary<NSString *,NSArray *> *)apiMap{
    if (!_apiMap) {
        _apiMap = [@{} mutableCopy];
    }
    return _apiMap;
}

- (instancetype)initWithWebHandler:(ZHJSHandler *)handler
                         debugItem:(ZHWebDebugItem *)debugItem
                       apiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers{
    self = [super init];
    if (self) {
        self.handler = handler;
        
        //默认内部api
        NSMutableArray *internalApiHandlers = [@[] mutableCopy];
        if (debugItem && debugItem.debugModeEnable) {
            [internalApiHandlers addObject:[[ZHJSInWebSocketApi alloc] init]];
        }
        [internalApiHandlers addObject:[[ZHJSInWebFundApi alloc] init]];
        for (ZHJSInApi *handler in internalApiHandlers) {
            handler.apiHandler = self;
        }
        
        [self config:internalApiHandlers outsideApiHandlers:[apiHandlers?:@[] mutableCopy]];
    }
    return self;
}
- (instancetype)initWithContextHandler:(ZHJSHandler *)handler
                             debugItem:(ZHCtxDebugItem *)debugItem
                             apiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers{
    self = [super init];
    if (self) {
        self.handler = handler;
        
        //默认内部api
        NSMutableArray *internalApiHandlers = [@[] mutableCopy];
        [internalApiHandlers addObject:[[ZHJSInContextFundApi alloc] init]];
        for (ZHJSInApi *handler in internalApiHandlers) {
            handler.apiHandler = self;
        }
        
        [self config:internalApiHandlers outsideApiHandlers:[apiHandlers?:@[] mutableCopy]];
    }
    return self;
}

- (void)config:(NSArray <ZHJSInApi <ZHJSApiProtocol> *> *)internalApiHandlers outsideApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)outsideApiHandlers{
    self.internalApiHandlers = [internalApiHandlers copy];
    self.outsideApiHandlers = [outsideApiHandlers?:@[] mutableCopy];
    //查找api
    NSArray *mergeHandlers = [self.internalApiHandlers arrayByAddingObjectsFromArray:self.outsideApiHandlers];
    [self addApiMap:self.apiMap handlers:mergeHandlers];
}

- (NSArray<id<ZHJSApiProtocol>> *)apiHandlers{
    return [self.outsideApiHandlers copy];
}

//查找构造api
- (void)addApiMap:(NSMutableDictionary *)apiMap handlers:(NSArray <id <ZHJSApiProtocol>> *)handlers{
    for (id <ZHJSApiProtocol> handler in handlers) {
        
        NSString *jsPrefix = [self fetchJSApiPrefix:handler];
        if (!jsPrefix || jsPrefix.length == 0) continue;
        
        NSMutableArray *items = ([apiMap objectForKey:jsPrefix] ?: [@[] mutableCopy]);
        [items insertObject:@{
            @"handler": handler,
            @"map": [self fetchNativeApiMap:handler]
        } atIndex:0];
        
        [apiMap setObject:items forKey:jsPrefix];
    }
}
- (void)removeApiMap:(NSMutableDictionary *)apiMap handlers:(NSArray <id <ZHJSApiProtocol>> *)handlers{
    
    for (id <ZHJSApiProtocol> handler in handlers) {
        
        NSString *jsPrefix = [self fetchJSApiPrefix:handler];
        if (!jsPrefix || jsPrefix.length == 0) continue;
        
        NSMutableArray *items = [[apiMap objectForKey:jsPrefix]?:@[] mutableCopy];
        if (items.count == 0) continue;
        
        NSMutableArray *removeItems = [@[] mutableCopy];
        
        for (NSDictionary *map in items) {
            id <ZHJSApiProtocol> handlerT = [map objectForKey:@"handler"];
            if (![handler isEqual:handlerT]) continue;
            [removeItems addObject:map];
        }
        if (removeItems.count > 0) {
            [items removeObjectsInArray:removeItems];
            if (items.count == 0) {
                [apiMap removeObjectForKey:jsPrefix];
            }else{
                [apiMap setObject:items forKey:jsPrefix];
            }
        }
    }
}

//添加移除api
- (void)addApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers completion:(void (^) (NSArray <id <ZHJSApiProtocol>> *successApiHandlers, NSArray <id <ZHJSApiProtocol>> *failApiHandlers, NSError *error))completion{
    
    NSMutableArray *successHandler = [@[] mutableCopy];
    NSMutableArray *failHandler = [@[] mutableCopy];
    
    for (id <ZHJSApiProtocol> handler in apiHandlers) {
        
        if ([self.outsideApiHandlers containsObject:handler]) {
            [failHandler addObject:handler];
            continue;
        }
        
        [self.outsideApiHandlers addObject:handler];
        [self addApiMap:self.apiMap handlers:@[handler]];
        
        [successHandler addObject:handler];
    }
    
    if (completion) completion([successHandler copy], [failHandler copy], nil);
}
- (void)removeApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers completion:(void (^) (NSArray <id <ZHJSApiProtocol>> *successApiHandlers, NSArray <id <ZHJSApiProtocol>> *failApiHandlers, NSError *error))completion{
    
    NSMutableArray *successHandler = [@[] mutableCopy];
    NSMutableArray *failHandler = [@[] mutableCopy];
    
    for (id <ZHJSApiProtocol> handler in apiHandlers) {
        
        if (![self.outsideApiHandlers containsObject:handler]) {
            [failHandler addObject:handler];
            continue;
        }
        
        [self.outsideApiHandlers removeObject:handler];
        [self removeApiMap:self.apiMap handlers:@[handler]];
        [successHandler addObject:handler];
    }
    
    if (completion) completion(successHandler, failHandler, nil);
}

//获取某个handler的方法映射表
- (NSDictionary *)fetchNativeApiMap:(id <ZHJSApiProtocol>)api{
    NSString *nativeMethodPrefix = [self fetchNativeApiPrefix:api];
    if (!nativeMethodPrefix || nativeMethodPrefix.length == 0) return @{};
    
    NSMutableDictionary <NSString *, NSArray <ZHJSApiRegisterItem *> *> *resMethodMap = [@{} mutableCopy];
    
    //运行时 仅能获取本类中的所有方法 父类中的拿不到
    Class opCalss = object_getClass(api);
    
    while (opCalss &&
           ![NSStringFromClass(opCalss) isEqualToString:NSStringFromClass([NSObject class])]) {
        
        unsigned int count;
        Method *methods = class_copyMethodList(opCalss, &count);
        
        for (int i = 0; i < count; i++){
            SEL selector = method_getName(methods[i]);
            
            NSString *nativeName = NSStringFromSelector(selector);
            if (![nativeName hasPrefix:nativeMethodPrefix]) continue;
            
            NSString *jsName = [nativeName substringFromIndex:nativeMethodPrefix.length];
            if (jsName.length == 0) continue;
            
            if ([jsName containsString:@":"]) {
                NSArray *subNames = [jsName componentsSeparatedByString:@":"];
                if (subNames.count == 0) continue;
                jsName = subNames[0];
            }
            
            ZHJSApiRegisterItem *item = [[ZHJSApiRegisterItem alloc] init];
            item.jsMethodName = jsName;
            item.nativeMethodName = nativeName;
            item.nativeMethodInClassName = NSStringFromClass(opCalss);
            item.nativeInstance = api;
            
            // 如果有func配置，优先使用
            SEL syncSel = NSSelectorFromString([NSString stringWithFormat:ZHJS_Export_Func_Config_Prefix_Format, jsName]);
            if (syncSel && [api respondsToSelector:syncSel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                NSDictionary *funcConfig = [api performSelector:syncSel];
                NSNumber *syncNum = funcConfig[@"sync"];
                item.sync = syncNum ? syncNum.boolValue : NO;
#pragma clang diagnostic pop
            }else{
                item.sync = [jsName hasSuffix:@"Sync"];
            }
                        
            NSMutableArray <ZHJSApiRegisterItem *> *items = [resMethodMap objectForKey:jsName] ?: [@[] mutableCopy];
            [items addObject:item];
            
            [resMethodMap setObject:items forKey:jsName];
            
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            //        [self performSelector:NSSelectorFromString(name) withObject:nil];
#pragma clang diagnostic pop
        }
        free(methods);
        
        opCalss = class_getSuperclass(opCalss);
    }
    
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

//转换成注册api
- (NSDictionary *)parseApiMapToRegsiterApiMap:(NSDictionary *)apiMap{
    if (!apiMap || ![apiMap isKindOfClass:[NSDictionary class]] ||
        apiMap.allKeys.count == 0) return nil;
    //合并api
    NSMutableDictionary *mergeApiMap = [@{} mutableCopy];
    
    [apiMap enumerateKeysAndObjectsUsingBlock:^(NSString *apiPrefix, NSArray *handlerMaps, BOOL *stop) {
        
        NSMutableDictionary <NSString *, ZHJSApiRegisterItem *> *functionMap = [@{} mutableCopy];
        
        // 倒叙
        [handlerMaps enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *handlerMap, NSUInteger idx, BOOL *handlerStop) {
            //            id <ZHJSApiProtocol> handler = [handlerMap objectForKey:@"handler"];
            NSDictionary *map = [handlerMap objectForKey:@"map"];
            [map enumerateKeysAndObjectsUsingBlock:^(NSString *jsMethod, NSArray *methodItems, BOOL *mapStop) {
                if (methodItems.count > 0) {
                    [functionMap setObject:methodItems[0] forKey:jsMethod];
                }
            }];
            
        }];
        /**
         @{
             @"fund" : @{
                     @"getSystemInfoSync" : ZHJSApiRegisterItem
             }
         }
         */
        [mergeApiMap setObject:functionMap forKey:apiPrefix];
    }];
    return [mergeApiMap copy];
}

//遍历方法映射表
- (void)enumRegsiterApiMap:(void (^)(NSString *apiPrefix, NSDictionary <NSString *, ZHJSApiRegisterItem *> *apiMap))block{
    if (!block) return;
    
    //转换成注册api
    NSDictionary *mergeApiMap = [self parseApiMapToRegsiterApiMap:self.apiMap];
    [mergeApiMap enumerateKeysAndObjectsUsingBlock:^(NSString *apiPrefix, NSDictionary *apiMap, BOOL *stop) {
        if (block) block(apiPrefix, apiMap);
    }];
}
//- (void)fetchRegsiterApiMap:(NSArray <id <ZHJSApiProtocol>> *)handlers block:(void (^)(NSString *apiPrefix, NSDictionary <NSString *, ZHJSApiRegisterItem *> *apiMap))block{
//    if (!handlers || handlers.count == 0) {
//        if (block) block(nil, nil);
//        return;
//    }
//    //构造api
//    NSMutableDictionary *apiMap = [@{} mutableCopy];
//    [self addApiMap:apiMap handlers:handlers];
//
//    //转换成注册api
//    NSDictionary *mergeApiMap = [self parseApiMapToRegsiterApiMap:apiMap];
//    [mergeApiMap enumerateKeysAndObjectsUsingBlock:^(NSString *apiPrefix, NSDictionary *apiMap, BOOL *stop) {
//        if (block) block(apiPrefix, apiMap);
//    }];
//}

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
    
    NSArray *handlerMaps = [self.apiMap objectForKey:apiPrefix];
    if (!handlerMaps || handlerMaps.count == 0) {
        callBack(nil, nil);
        return;
    }
    
    SEL selRes = nil;
    id targetRes = nil;
    
    for (NSDictionary *handlerMap in handlerMaps) {
        id <ZHJSApiProtocol> handler = [handlerMap objectForKey:@"handler"];
        NSDictionary *map = [handlerMap objectForKey:@"map"];
        
        NSArray <ZHJSApiRegisterItem *> *items = map[jsMethodName];
        
        if (items.count == 0) continue;
        
        ZHJSApiRegisterItem *item = items[0];
        if (!item || !item.nativeMethodName) continue;

        SEL sel = NSSelectorFromString(item.nativeMethodName);
        if (!handler || ![handler respondsToSelector:sel]) continue;
        
        selRes = sel;
        targetRes = handler;
        break;
    }
    
    callBack(targetRes, selRes);
}
- (void)dealloc{
    NSLog(@"%s", __func__);
}

@end
