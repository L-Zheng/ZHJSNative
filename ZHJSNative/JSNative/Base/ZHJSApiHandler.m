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
/**
@{
    @"fund": @[
                @{
                    @"api": id <ZHJSApiProtocol>,
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

@property (nonatomic,strong) NSArray <id <ZHJSApiProtocol>> *internalApis;
@property (nonatomic,strong) NSMutableArray <id <ZHJSApiProtocol>> *outsideApis;
@end

@implementation ZHJSApiHandler

#pragma mark - init

- (NSMutableDictionary<NSString *,NSArray *> *)apiMap{
    if (!_apiMap) {
        _apiMap = [@{} mutableCopy];
    }
    return _apiMap;
}

- (instancetype)initWithApis:(NSArray <id <ZHJSApiProtocol>> *)inApis apis:(NSArray <id <ZHJSApiProtocol>> *)apis{
    self = [super init];
    if (self) {
        //默认内部api
        NSMutableArray *internalApis = [@[] mutableCopy];
        if (inApis && [inApis isKindOfClass:NSArray.class] && inApis.count > 0) {
            [internalApis addObjectsFromArray:inApis];
        }
        // 处理
        [self config:internalApis outsideApis:[apis?:@[] mutableCopy]];
    }
    return self;
}

- (void)config:(NSArray <id <ZHJSApiProtocol>> *)internalApis outsideApis:(NSArray <id <ZHJSApiProtocol>> *)outsideApis{
    self.internalApis = [internalApis copy];
    self.outsideApis = [outsideApis?:@[] mutableCopy];
    //查找api
    NSArray *mergeApis = [self.internalApis arrayByAddingObjectsFromArray:self.outsideApis];
    [self addApiMap:self.apiMap apis:mergeApis];
}

- (NSArray<id<ZHJSApiProtocol>> *)apis{
    return [self.outsideApis copy];
}

//查找构造api
- (void)addApiMap:(NSMutableDictionary *)apiMap apis:(NSArray <id <ZHJSApiProtocol>> *)apis{
    for (id <ZHJSApiProtocol> api in apis) {
        
        NSString *jsPrefix = [self fetchJSApiPrefix:api];
        if (!jsPrefix || jsPrefix.length == 0) continue;
        
        NSMutableArray *items = ([apiMap objectForKey:jsPrefix] ?: [@[] mutableCopy]);
        [items insertObject:@{
            @"api": api,
            @"map": [self fetchNativeApiMap:api]
        } atIndex:0];
        
        [apiMap setObject:items forKey:jsPrefix];
    }
}
- (void)removeApiMap:(NSMutableDictionary *)apiMap apis:(NSArray <id <ZHJSApiProtocol>> *)apis{
    
    for (id <ZHJSApiProtocol> api in apis) {
        
        NSString *jsPrefix = [self fetchJSApiPrefix:api];
        if (!jsPrefix || jsPrefix.length == 0) continue;
        
        NSMutableArray *items = [[apiMap objectForKey:jsPrefix]?:@[] mutableCopy];
        if (items.count == 0) continue;
        
        NSMutableArray *removeItems = [@[] mutableCopy];
        
        for (NSDictionary *map in items) {
            id <ZHJSApiProtocol> originApi = [map objectForKey:@"api"];
            if (![api isEqual:originApi]) continue;
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
- (void)addApis:(NSArray <id <ZHJSApiProtocol>> *)apis completion:(void (^) (NSArray <id <ZHJSApiProtocol>> *successApis, NSArray <id <ZHJSApiProtocol>> *failApis, NSError *error))completion{
    
    NSMutableArray *successApis = [@[] mutableCopy];
    NSMutableArray *failApis = [@[] mutableCopy];
    
    for (id <ZHJSApiProtocol> api in apis) {
        
        if ([self.outsideApis containsObject:api]) {
            [failApis addObject:api];
            continue;
        }
        
        [self.outsideApis addObject:api];
        [self addApiMap:self.apiMap apis:@[api]];
        
        [successApis addObject:api];
    }
    
    if (completion) completion([successApis copy], [failApis copy], nil);
}
- (void)removeApis:(NSArray <id <ZHJSApiProtocol>> *)apis completion:(void (^) (NSArray <id <ZHJSApiProtocol>> *successApis, NSArray <id <ZHJSApiProtocol>> *failApis, NSError *error))completion{
    
    NSMutableArray *successApis = [@[] mutableCopy];
    NSMutableArray *failApis = [@[] mutableCopy];
    
    for (id <ZHJSApiProtocol> api in apis) {
        
        if (![self.outsideApis containsObject:api]) {
            [failApis addObject:api];
            continue;
        }
        
        [self.outsideApis removeObject:api];
        [self removeApiMap:self.apiMap apis:@[api]];
        [successApis addObject:api];
    }
    
    if (completion) completion(successApis, failApis, nil);
}

//获取某个api的方法映射表
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
                NSNumber *syncNum = [funcConfig objectForKey:@"sync"];
                item.sync = syncNum ? syncNum.boolValue : [jsName hasSuffix:@"Sync"];
                item.supportVersion = [funcConfig objectForKey:@"supportVersion"];
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
    
    [apiMap enumerateKeysAndObjectsUsingBlock:^(NSString *apiPrefix, NSArray *prefixItems, BOOL *prefixStop) {
        
        NSMutableDictionary <NSString *, ZHJSApiRegisterItem *> *functionMap = [@{} mutableCopy];
        
        // 倒序
        [prefixItems enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *prefixItem, NSUInteger idx, BOOL *apiStop) {
            //            id <ZHJSApiProtocol> api = [prefixItem objectForKey:@"api"];
            NSDictionary *map = [prefixItem objectForKey:@"map"];
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

//遍历方法映射表->获取所有api
- (void)enumRegsiterApiMap:(void (^)(NSString *apiPrefix, NSDictionary <NSString *, ZHJSApiRegisterItem *> *apiMap))block{
    if (!block) return;
    
    //转换成注册api
    NSDictionary *mergeApiMap = [self parseApiMapToRegsiterApiMap:self.apiMap];
    [mergeApiMap enumerateKeysAndObjectsUsingBlock:^(NSString *apiPrefix, NSDictionary *apiMap, BOOL *stop) {
        if (block) block(apiPrefix, apiMap);
    }];
}

//遍历方法映射表->获取api注入完成事件名
- (void)enumRegsiterApiInjectFinishEventNameMap:(void (^)(NSString *apiPrefix, NSString *apiInjectFinishEventName))block{
    if (!block) return;
    /**
     @{
             @"fund" : @"fundJSBridgeReady"
             @"Zheng" : @"ZhengJSBridgeReady"
     }
     */
    NSMutableDictionary <NSString *, NSString *> *resMap = [@{} mutableCopy];
    
    // 遍历api总映射表，正序查找（映射表里面最新的api是插入到最前面） id<ZHJSApiProtocol>，直到找到 注入完成事件名
    NSDictionary *apiMap = self.apiMap.copy;
    [apiMap enumerateKeysAndObjectsUsingBlock:^(NSString *apiPrefix, NSArray *prefixItems, BOOL *prefixStop) {
        // 正序遍历
        for (NSDictionary *prefixItem in prefixItems) {
            id <ZHJSApiProtocol> api = [prefixItem objectForKey:@"api"];
            if (!api || ![api conformsToProtocol:@protocol(ZHJSApiProtocol)] ||
                ![api respondsToSelector:@selector(zh_jsApiInjectFinishEventName)]) {
                continue;
            }
            NSString *name = [api zh_jsApiInjectFinishEventName];
            if (!name || ![name isKindOfClass:NSString.class] || name.length == 0) {
                continue;
            }
            [resMap setObject:name forKey:apiPrefix];
            break;
        }
    }];
    [resMap enumerateKeysAndObjectsUsingBlock:^(NSString *apiPrefix, NSString *injectFinishEventName, BOOL *stop) {
        if (block) block(apiPrefix, injectFinishEventName);
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
    
    NSArray *prefixItems = [self.apiMap objectForKey:apiPrefix];
    if (!prefixItems || prefixItems.count == 0) {
        callBack(nil, nil);
        return;
    }
    
    SEL selRes = nil;
    id targetRes = nil;
    
    for (NSDictionary *prefixItem in prefixItems) {
        id <ZHJSApiProtocol> api = [prefixItem objectForKey:@"api"];
        NSDictionary *map = [prefixItem objectForKey:@"map"];
        
        NSArray <ZHJSApiRegisterItem *> *items = map[jsMethodName];
        
        if (items.count == 0) continue;
        
        ZHJSApiRegisterItem *item = items[0];
        if (!item || !item.nativeMethodName) continue;

        SEL sel = NSSelectorFromString(item.nativeMethodName);
        if (!api || ![api respondsToSelector:sel]) continue;
        
        selRes = sel;
        targetRes = api;
        break;
    }
    
    callBack(targetRes, selRes);
}
- (void)dealloc{
    NSLog(@"%s", __func__);
}

@end
