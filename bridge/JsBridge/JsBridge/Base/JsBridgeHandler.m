//
//  JsBridgeHandler.m
//  JsBridge
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "JsBridgeHandler.h"
#import <objc/runtime.h>

//设置NSInvocation参数
#define JsBridge_Invo_Set_Arg(invo, arg, idx, cType, type, op)\
case cType:{\
    if ([arg respondsToSelector:@selector(op)]) {\
        type *_tmp = malloc(sizeof(type));\
        memset(_tmp, 0, sizeof(type));\
        *_tmp = [arg op];\
        [invo setArgument:_tmp atIndex:idx];\
    }\
    break;\
}

@interface JsBridgeInvocation : NSInvocation
// 强引用target 防止invoke执行时释放
@property (nonatomic,strong) id jsBridge_target;
@end
@implementation JsBridgeInvocation
@end


@interface JsBridgeHandler ()
/**
 @{
     @"MyApi": @[
                 @{
                     @"api": id <JsBridgeApiProtocol>,
                     @"map" : @{
                             @"getSystemInfoSync": @[
                                     //本类
                                     JsBridgeApiRegisterItem1,
                                     //父类
                                     JsBridgeApiRegisterItem2,
                                     //父类的父类
                                     JsBridgeApiRegisterItem3
                             ]
                     },
                     @"modules": @[
                         @{
                             @"api": id <JsBridgeApiProtocol>,
                             @"name": @"xxx",
                             @"map" : @{
                                     @"getSystemInfoSync": @[
                                             //本类
                                             JsBridgeApiRegisterItem1,
                                             //父类
                                             JsBridgeApiRegisterItem2,
                                             //父类的父类
                                             JsBridgeApiRegisterItem3
                                     ]
                             },
                         }
                     ]
                 }
     ]
 }
 */
@property (nonatomic,strong) NSMutableDictionary *apiMap;
@property (nonatomic,strong) NSMutableArray *outApis;
@end

@implementation JsBridgeHandler

#pragma mark - api

//添加移除api
- (void)addApis:(NSArray *)apis{
    for (id api in apis) {
        if ([self.outApis containsObject:api]) {
            continue;
        }
        [self.outApis addObject:api];
        [self addApiMap:self.apiMap apis:@[api]];
    }
}
- (void)removeApis:(NSArray *)apis{
    for (id api in apis) {
        if (![self.outApis containsObject:api]) {
            continue;
        }
        [self.outApis removeObject:api];
        [self removeApiMap:self.apiMap apis:@[api]];
    }
}

// 查找构造api
- (void)addApiMap:(NSMutableDictionary *)apiMap apis:(NSArray *)apis{
    for (id api in apis) {
        NSString *jsPrefix = [self fetchJSApiPrefix:api];
        if (!jsPrefix || ![jsPrefix isKindOfClass:[NSString class]] || jsPrefix.length == 0) continue;
        
        NSMutableDictionary *item = [@{
            @"api": api,
            @"map": [self fetchNativeApiMap:api]
        } mutableCopy];
        NSArray *modules = [self fetchJSApiModules:api];
        if (modules && [modules isKindOfClass:NSArray.class]) {
            NSMutableArray *moduleItems = [NSMutableArray array];
            for (id module in modules) {
                if (![module conformsToProtocol:@protocol(JsBridgeApiProtocol)]) {
                    continue;
                }
                [moduleItems insertObject:@{
                    @"api": module,
                    @"name": [self fetchJSApiPrefix:module]?:@"",
                    @"map": [self fetchNativeApiMap:module]
                } atIndex:0];
            }
            [item setObject:moduleItems.copy forKey:@"modules"];
        }
        
        NSMutableArray *items = ([apiMap objectForKey:jsPrefix] ?: [@[] mutableCopy]);
        [items insertObject:item.copy atIndex:0];
        
        [apiMap setObject:items forKey:jsPrefix];
    }
}
- (void)removeApiMap:(NSMutableDictionary *)apiMap apis:(NSArray *)apis{
    for (id api in apis) {
        NSString *jsPrefix = [self fetchJSApiPrefix:api];
        if (!jsPrefix || ![jsPrefix isKindOfClass:[NSString class]] || jsPrefix.length == 0) continue;
        
        NSMutableArray *items = [[apiMap objectForKey:jsPrefix]?:@[] mutableCopy];
        if (items.count == 0) continue;
        
        NSMutableArray *removeItems = [@[] mutableCopy];
        
        for (NSDictionary *map in items) {
            id originApi = [map objectForKey:@"api"];
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

//转换成注册api
- (NSDictionary *)parseApiMapToRegsiterApiMap:(NSDictionary *)apiMap{
    if (!apiMap || ![apiMap isKindOfClass:[NSDictionary class]] ||
        apiMap.allKeys.count == 0) return nil;
    //合并api
    NSMutableDictionary *mergeApiMap = [@{} mutableCopy];
    
    [apiMap enumerateKeysAndObjectsUsingBlock:^(NSString *apiPrefix, NSArray *prefixItems, BOOL *prefixStop) {
        
        NSMutableDictionary *functionMap = [@{} mutableCopy];
        NSMutableDictionary *functionModuleMap = [@{} mutableCopy];
        __block BOOL hasModuleApi = NO;
        
        // 倒序
        [prefixItems enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *prefixItem, NSUInteger idx, BOOL *apiStop) {
            NSDictionary *map = [prefixItem objectForKey:@"map"];
            [map enumerateKeysAndObjectsUsingBlock:^(NSString *jsMethod, NSArray *methodItems, BOOL *mapStop) {
                if (methodItems.count == 0) return;
                [functionMap setObject:methodItems[0] forKey:jsMethod];
            }];
            
            NSArray *modules = [prefixItem objectForKey:@"modules"];
            if (modules && [modules isKindOfClass:NSArray.class]) {
                // 倒序
                [modules enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *module, NSUInteger idx_module, BOOL * stop_module) {
                    NSString *api_moduleName = [module objectForKey:@"name"];
                    if (api_moduleName && [api_moduleName isKindOfClass:NSString.class] && api_moduleName.length > 0) {
                        NSMutableDictionary *moduleNameMap = [functionModuleMap objectForKey:api_moduleName];
                        if (!moduleNameMap) {
                            moduleNameMap = [NSMutableDictionary dictionary];
                            [functionModuleMap setObject:moduleNameMap forKey:api_moduleName];
                        }
                        
                        NSDictionary *api_moduleMap = [module objectForKey:@"map"];
                        [api_moduleMap enumerateKeysAndObjectsUsingBlock:^(NSString *jsMethod, NSArray *methodItems, BOOL *mapStop) {
                            if (methodItems.count == 0) return;
                            [moduleNameMap setObject:methodItems[0] forKey:jsMethod];
                        }];
                    }
                }];
                if (!hasModuleApi) {
                    hasModuleApi = YES;
                }
            }
        }];
        /*
         @{
             @"myApi" : @{
                 @"api": @{
                     @"getSystemInfoSync" : JsBridgeApiRegisterItem
                 }
                 @"api_module": @{
                     @"moduleName": @{
                             @"getSystemInfoSync" : JsBridgeApiRegisterItem
                     }
                 }
             }
         }
        */
        
        NSMutableDictionary *apiPrefixMap = [@{
            @"api": functionMap
        } mutableCopy];
        if (hasModuleApi) {
            [apiPrefixMap addEntriesFromDictionary:@{
                @"api_module": functionModuleMap
            }];
        }
        [mergeApiMap setObject:apiPrefixMap.copy forKey:apiPrefix];
    }];
    return [mergeApiMap copy];
}
//遍历方法映射表->获取所有api
- (void)enumRegsiterApiMap:(void (^)(NSString *apiPrefix, NSDictionary *apiMap, NSDictionary *apiModuleMap))block{
    if (!block) return;
    
    //转换成注册api
    NSDictionary *mergeApiMap = [self parseApiMapToRegsiterApiMap:self.apiMap];
    [mergeApiMap enumerateKeysAndObjectsUsingBlock:^(NSString *apiPrefix, NSDictionary *map, BOOL *stop) {
        if (block) block(apiPrefix, [map objectForKey:@"api"], [map objectForKey:@"api_module"]);
    }];
}
//遍历方法映射表->获取api注入完成事件名
- (void)enumRegsiterApiInjectFinishEventNameMap:(void (^)(NSString *apiPrefix, NSString *apiInjectFinishEventName))block{
    if (!block) return;
    /**
     @{
             @"MyApi" : @"MyApiJSBridgeReady"
     }
     */
    NSMutableDictionary *resMap = [@{} mutableCopy];
    
    // 遍历api总映射表，正序查找（映射表里面最新的api是插入到最前面） id<JsBridgeApiProtocol>，直到找到 注入完成事件名
    NSDictionary *apiMap = self.apiMap.copy;
    [apiMap enumerateKeysAndObjectsUsingBlock:^(NSString *apiPrefix, NSArray *prefixItems, BOOL *prefixStop) {
        // 正序遍历
        for (NSDictionary *prefixItem in prefixItems) {
            id api = [prefixItem objectForKey:@"api"];
            if (!api || ![api conformsToProtocol:@protocol(JsBridgeApiProtocol)] ||
                ![api respondsToSelector:@selector(jsBridge_jsApiInjectFinishEventName)]) {
                continue;
            }
            NSString *name = [api jsBridge_jsApiInjectFinishEventName];
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
- (void)fetchSelectorByName:(NSString *)jsMethodName apiPrefix:(NSString *)apiPrefix jsModuleName:(NSString *)jsModuleName callBack:(void (^) (id target, SEL sel))callBack{
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
    
    if (!jsModuleName || ![jsMethodName isKindOfClass:NSString.class] ||
        jsMethodName.length == 0 || [jsModuleName isEqual:[NSNull null]]) {
        jsModuleName = nil;
    }
    
    NSArray *prefixItems = [self.apiMap objectForKey:apiPrefix];
    if (!prefixItems || prefixItems.count == 0) {
        callBack(nil, nil);
        return;
    }
    
    __block SEL selRes = nil;
    __block id targetRes = nil;
    
    BOOL (^fetchBlock) (NSDictionary *fromItem) = ^ BOOL (NSDictionary *fromItem){
        id api = [fromItem objectForKey:@"api"];
        NSDictionary *map = [fromItem objectForKey:@"map"];
        
        if (!map) return NO;
        NSArray *items = map[jsMethodName];
        if (items.count == 0) return NO;
        
        JsBridgeApiRegisterItem *item = items[0];
        if (!item || !item.nativeMethodName) return NO;

        SEL sel = NSSelectorFromString(item.nativeMethodName);
        if (!api || ![api respondsToSelector:sel]) return NO;
        
        selRes = sel;
        targetRes = api;
        return YES;
    };
    
    for (NSDictionary *prefixItem in prefixItems) {
        if (!jsModuleName) {
            if (fetchBlock(prefixItem)) {
                break;
            }
        }else{
            NSArray *modules = [prefixItem objectForKey:@"modules"];
            if (!modules || ![modules isKindOfClass:NSArray.class]) {
                continue;
            }
            for (NSDictionary *module in modules) {
                NSString *moduleName = [module objectForKey:@"name"];
                if (!moduleName || ![moduleName isKindOfClass:NSString.class] || moduleName.length == 0 ||
                    ![jsModuleName isEqualToString:moduleName]) {
                    continue;
                }
                if (fetchBlock(module)) {
                    break;
                }
            }
            if (selRes && targetRes) {
                break;
            }
        }
    }
    
    callBack(targetRes, selRes);
}
// 获取所有注册的jsApiPrefix
- (NSArray *)fetchJsApiPrefixAll{
    return self.apiMap.allKeys.copy;
}

#pragma mark - JsBridgeApiProtocol

//获取某个api的方法映射表
- (NSDictionary *)fetchNativeApiMap:(id)api{
    NSString *nativeMethodPrefix = [self fetchNativeApiPrefix:api];
    if (!nativeMethodPrefix || nativeMethodPrefix.length == 0) return @{};
    
    NSMutableDictionary *resMethodMap = [@{} mutableCopy];
    
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
            
            JsBridgeApiRegisterItem *item = [[JsBridgeApiRegisterItem alloc] init];
            item.jsMethodName = jsName;
            item.nativeMethodName = nativeName;
            item.nativeMethodInClassName = NSStringFromClass(opCalss);
            item.nativeInstance = api;
            
            // 如果有func配置，优先使用
            SEL syncSel = NSSelectorFromString([NSString stringWithFormat:JsBridge_Export_Func_Config_Prefix_Format, jsName]);
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
                        
            NSMutableArray *items = [resMethodMap objectForKey:jsName] ?: [@[] mutableCopy];
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
- (NSString *)fetchNativeApiPrefix:(id)api{
    if (!api) return nil;
    if (api && [api respondsToSelector:@selector(jsBridge_iosApiPrefix)]) {
        NSString *res = [api jsBridge_iosApiPrefix];
        if ([res isKindOfClass:[NSString class]] && res.length) {
            return res;
        }
    }
    return nil;
}

//查找js api方法前缀
- (NSString *)fetchJSApiPrefix:(id)api{
    if (!api) return nil;
    if (api && [api respondsToSelector:@selector(jsBridge_jsApiPrefix)]) {
        NSString *res = [api jsBridge_jsApiPrefix];
        if ([res isKindOfClass:[NSString class]] && res.length) {
            return res;
        }
    }
    return nil;
}
//查找js module api实例
- (NSArray *)fetchJSApiModules:(id)api{
    if (!api) return nil;
    if (api && [api respondsToSelector:@selector(jsBridge_apiModules)]) {
        NSArray *res = [api jsBridge_apiModules];
        if (res && [res isKindOfClass:NSArray.class]) return res;
    }
    return nil;
}

#pragma mark - getter

- (NSMutableDictionary *)apiMap{
    if (!_apiMap) _apiMap = [NSMutableDictionary dictionary];
    return _apiMap;
}

#pragma mark - run func

// 运行原生方法
- (id)runNativeFunc:(NSString *)jsMethodName apiPrefix:(NSString *)apiPrefix jsModuleName:(NSString *)jsModuleName arguments:(NSArray <JsBridgeApiArgItem *> *)arguments{
    __block id value = nil;
    [self fetchSelectorByName:jsMethodName apiPrefix:apiPrefix jsModuleName:jsModuleName callBack:^(id target, SEL sel) {
        if (!target || !sel) return;
        
        NSMethodSignature *sig = [target methodSignatureForSelector:sel];
        NSInvocation *invo = [JsBridgeInvocation invocationWithMethodSignature:sig];
        if ([invo isKindOfClass:[JsBridgeInvocation class]]) {
            ((JsBridgeInvocation *)invo).jsBridge_target = target;
        }
        [invo setTarget:target];
        [invo setSelector:sel];
        
        if ([arguments isKindOfClass:[NSArray class]]) {
            NSInteger count = MIN(arguments.count, sig.numberOfArguments - 2);
            for (int idx = 0; idx < count; idx++) {
                JsBridgeApiArgItem *arg = arguments[idx];
                int argIdx = idx + 2;
                //id object类型
                [invo setArgument:&arg atIndex:argIdx];
            }
        }
        if (!invo.argumentsRetained) {
            [invo retainArguments];
        }
        //运行
        [invo invoke];
        id __unsafe_unretained res = nil;
        if ([sig methodReturnLength]) [invo getReturnValue:&res];
        value = res;
        
        invo = nil;
    }];
    return value;
}
- (id)runNativeFunc_old_basicData:(NSString *)jsMethodName apiPrefix:(NSString *)apiPrefix jsModuleName:(NSString *)jsModuleName arguments:(NSArray *)arguments{
    __block id value = nil;
    [self fetchSelectorByName:jsMethodName apiPrefix:apiPrefix jsModuleName:jsModuleName callBack:^(id target, SEL sel) {
        if (!target || !sel) return;
        
        NSMethodSignature *sig = [target methodSignatureForSelector:sel];
        NSInvocation *invo = [JsBridgeInvocation invocationWithMethodSignature:sig];
        if ([invo isKindOfClass:[JsBridgeInvocation class]]) {
            ((JsBridgeInvocation *)invo).jsBridge_target = target;
        }
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
                // 各种类型：https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-%20CH100
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
                        JsBridge_Invo_Set_Arg(invo, arg, argIdx, _C_INT, int, intValue)
                        JsBridge_Invo_Set_Arg(invo, arg, argIdx, _C_SHT, short, shortValue)
                        JsBridge_Invo_Set_Arg(invo, arg, argIdx, _C_LNG, long, longValue)
                        JsBridge_Invo_Set_Arg(invo, arg, argIdx, _C_LNG_LNG, long long, longLongValue)
                        JsBridge_Invo_Set_Arg(invo, arg, argIdx, _C_UCHR, unsigned char, unsignedCharValue)
                        JsBridge_Invo_Set_Arg(invo, arg, argIdx, _C_UINT, unsigned int, unsignedIntValue)
                        JsBridge_Invo_Set_Arg(invo, arg, argIdx, _C_USHT, unsigned short, unsignedShortValue)
                        JsBridge_Invo_Set_Arg(invo, arg, argIdx, _C_ULNG, unsigned long, unsignedLongValue)
                        JsBridge_Invo_Set_Arg(invo, arg, argIdx, _C_ULNG_LNG, unsigned long long, unsignedLongLongValue)
                        JsBridge_Invo_Set_Arg(invo, arg, argIdx, _C_FLT, float, floatValue)
                        JsBridge_Invo_Set_Arg(invo, arg, argIdx, _C_DBL, double, doubleValue)
                        JsBridge_Invo_Set_Arg(invo, arg, argIdx, _C_BOOL, bool, boolValue)
                        JsBridge_Invo_Set_Arg(invo, arg, argIdx, _C_CHR, char, charValue)
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
        /**运行函数：
         https://developer.apple.com/documentation/foundation/nsinvocation/1437838-retainarguments?language=objc
         invoke调用后不会立即执行方法，与performSelector一样，等待运行循环触发
         而为了提高效率，NSInvocation不会保留 调用所需的参数
         因此，在调用之前参数可能会被释放，App crash
         */
        if (!invo.argumentsRetained) {
            [invo retainArguments];
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
        /*返回值是什么类型 就要用什么类型接口  否则crash
         const char *returnType = [signature methodReturnType];   strcmp(returnType, @encode(float))==0
         id ：接受NSObject类型
         BOOL：接受BOOL类型
         ...
         */
        id __unsafe_unretained res = nil;
        if ([sig methodReturnLength]) [invo getReturnValue:&res];
        value = res;
        
        invo = nil;
        
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
    } @finally {
        
    }
}

#pragma mark - parse

- (NSDictionary *)parseException:(id)exception{
    if (!exception || ![exception isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSMutableDictionary *res = [exception mutableCopy];
    id stackRes = nil;
    NSString *stack = [res valueForKey:@"stack"];
    if ([stack isKindOfClass:[NSString class]] && stack.length) {
        // Vue报错是string类型
        if ([stack containsString:@"\n"]) {
            NSMutableArray *arr = [[stack componentsSeparatedByString:@"\n"] mutableCopy];
//            NSInteger limit = 10;
//            if (arr.count > limit) {
//                [arr removeObjectsInRange:NSMakeRange(limit, arr.count - limit)];
//            }
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
    if (stackRes) [res setValue:stackRes forKey:@"stack"];
    return res.copy;
}
@end
