//
//  JsBridgeCtxHandler.m
//  JsBridge
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "JsBridgeCtxHandler.h"
#import "JsBridgeHandler_Private.h"

@interface JsBridgeCtxHandler ()
@property (nonatomic,retain) NSMutableDictionary <NSString *, JSValue *> *consoleMap;
@end

@implementation JsBridgeCtxHandler

- (id)jsPage{
    return self.jsCtx;
}

#pragma mark - api

- (void)addApis:(NSArray *)apis{
    [super addApis:apis];
    // 直接添加, 会覆盖掉先前定义的
    [self jsapi_makeAll:NO];
}
- (void)removeApis:(NSArray *)apis{
    // 先重置掉原来定义的所有api
    [self jsapi_makeAll:YES];
    // 添加
    [super removeApis:apis];
    // 添加新的api
    [self jsapi_makeAll:NO];
}

#pragma mark - js api

- (void)jsapi_makeAll:(BOOL)clear{
    __weak __typeof__(self) weakSelf = self;
    [self enumRegsiterApiMap:^(NSString *apiPrefix, NSDictionary <NSString *, JsBridgeApiRegisterItem *> *apiMap, NSDictionary *apiModuleMap) {
        if (!apiPrefix || ![apiPrefix isKindOfClass:[NSString class]] || apiPrefix.length == 0) return;
        if (clear) {
            //因为要移除api  apiMap设定写死传@{}
            [weakSelf.jsCtx setObject:@{} forKeyedSubscript:apiPrefix];
            return;
        }
        // 处理api
        NSDictionary *resApiMap = [weakSelf jsapi_makeApi:apiPrefix jsModuleName:nil apiMap:apiMap];
        // 处理api module
        NSDictionary *resApiModuleMap = [weakSelf jsapi_makeModule:apiPrefix apiModuleMap:apiModuleMap];
        // 回调
        NSMutableDictionary *resMap = (resApiMap || resApiModuleMap ? [NSMutableDictionary dictionary] : nil);
        if (resApiMap) {
            [resMap addEntriesFromDictionary:resApiMap];
        }
        if (resApiModuleMap) {
            [resMap addEntriesFromDictionary:resApiModuleMap];
        }
        if (resMap && [resMap isKindOfClass:NSDictionary.class] && resMap.allKeys.count > 0) {
            [weakSelf.jsCtx setObject:resMap.copy forKeyedSubscript:apiPrefix];
        }
    }];
}
- (NSDictionary *)jsapi_makeApi:(NSString *)apiPrefix jsModuleName:(NSString *)jsModuleName apiMap:(NSDictionary <NSString *,JsBridgeApiRegisterItem *> *)apiMap{
    if (![apiPrefix isKindOfClass:[NSString class]] || apiPrefix.length == 0) {
        return nil;
    }
    NSMutableDictionary *resMap = [NSMutableDictionary dictionary];
    [apiMap enumerateKeysAndObjectsUsingBlock:^(NSString *jsMethod, JsBridgeApiRegisterItem *item, BOOL *stop) {
        //设置方法实现
        [resMap setValue:[self jsapi_makeApiImp:jsMethod apiPrefix:apiPrefix jsModuleName:jsModuleName] forKey:jsMethod];
    }];
    return [resMap copy];
}
- (NSDictionary *)jsapi_makeModule:(NSString *)apiPrefix apiModuleMap:(NSDictionary *)apiModuleMap{
    if (![apiPrefix isKindOfClass:[NSString class]] || apiPrefix.length == 0 || !apiModuleMap) {
        return nil;
    }
    NSMutableDictionary *resMap = [NSMutableDictionary dictionary];
    [apiModuleMap enumerateKeysAndObjectsUsingBlock:^(NSString *jsModuleName, NSDictionary *moduleMap, BOOL *stop) {
        NSMutableDictionary *moduleImpMap = [NSMutableDictionary dictionary];
        [moduleMap enumerateKeysAndObjectsUsingBlock:^(NSString *jsMethod, JsBridgeApiRegisterItem *item, BOOL *stop) {
            //设置方法实现
            [moduleImpMap setValue:[self jsapi_makeApiImp:jsMethod apiPrefix:apiPrefix jsModuleName:jsModuleName] forKey:jsMethod];
        }];
        [resMap setObject:moduleImpMap.copy forKey:jsModuleName];
    }];
    NSDictionary *blockMap = resMap.copy;
    
    NSMutableDictionary *returnMap = [@{
        @"registerModules": [^id (void){
            return blockMap;
        } copy],
        @"requireModule": [^id (void){
            //获取参数
            NSArray *jsArgs = [JSContext currentArguments];
            //js没传参数
            if (jsArgs.count == 0) {
                return nil;
            }
            JSValue *jsArg = jsArgs[0];
            if (!jsArg.isString) {
                return nil;
            }
            NSString *moduleName = [jsArg toString];
            return [blockMap objectForKey:moduleName];
        } copy]
    } mutableCopy];
    
    /** 将moduleName同步到api中,即：myApi.xx() = myApi.requireModule('xx') */
    [blockMap enumerateKeysAndObjectsUsingBlock:^(NSString *moduleName, id obj, BOOL * stop) {
        [returnMap setObject:[^id (void){
            return [blockMap objectForKey:moduleName];
        } copy] forKey:moduleName];
    }];
    
    return returnMap.copy;
}
// JSContext调用原生实现
- (id)jsapi_makeApiImp:(NSString *)jsMethod apiPrefix:(NSString *)apiPrefix jsModuleName:(NSString *)jsModuleName{
    if (!jsMethod || jsMethod.length == 0) return nil;
    __weak __typeof__(self) weakSelf = self;
    //处理js的事件
    id (^apiBlock)(void) = ^id(void){
        //获取参数
        NSArray *jsArgs = [JSContext currentArguments];
        //js没传参数
        if (jsArgs.count == 0) {
            return [weakSelf runNativeFunc:jsMethod apiPrefix:apiPrefix jsModuleName:jsModuleName arguments:@[]];
        }
        
        //处理参数
        NSMutableArray *resArgs = [NSMutableArray array];
        for (NSUInteger idx = 0; idx < jsArgs.count; idx++) {
            JSValue *jsArg = jsArgs[idx];
            
            JsBridgeApiInCallBlock jsFuncArgBlock = ^JsBridgeApi_InCallBlock_Header{
                if (!weakSelf) {
                    return [JsBridgeApiCallJsNativeResItem item];
                }
                NSArray *jsFuncArgDatas = argItem.jsFuncArgDatas;
                // BOOL alive = argItem.alive;
                // 如果jsArg不是js的function类型  调用callWithArguments函数也不会报错
                JSValue *resValue = [jsArg callWithArguments:((jsFuncArgDatas && [jsFuncArgDatas isKindOfClass:NSArray.class]) ? jsFuncArgDatas : @[])];
                if (argItem.jsFuncArgResBlock) {
                    argItem.jsFuncArgResBlock([JsBridgeApiCallJsResItem item:[weakSelf parseJSValueToObj:resValue] error:nil]);
                }
                return [JsBridgeApiCallJsNativeResItem item];
            };
            
            // 转换成原生类型
            id nativeValue = [weakSelf parseJSValueToObj:jsArg];
            if (!nativeValue || ![nativeValue isKindOfClass:NSDictionary.class]) {
                [resArgs addObject:[JsBridgeApiArgItem item:weakSelf.jsPage jsData:nativeValue callItem:[JsBridgeApiCallJsItem itemWithSFCBlock:nil jsFuncArgBlock:jsFuncArgBlock]]];
                continue;
            }
            
            //获取回调方法
            NSString *success = weakSelf.jskey_successFunc;
            NSString *fail = weakSelf.jskey_failFunc;
            NSString *complete = weakSelf.jskey_completeFunc;
            BOOL hasCallFunction = ([jsArg hasProperty:success] || [jsArg hasProperty:fail] || [jsArg hasProperty:complete]);
            //不需要回调方法
            if (!hasCallFunction) {
                [resArgs addObject:[JsBridgeApiArgItem item:weakSelf.jsPage jsData:nativeValue callItem:[JsBridgeApiCallJsItem itemWithSFCBlock:nil jsFuncArgBlock:jsFuncArgBlock]]];
                continue;
            }
            //需要回调
            JSValue *successFunc = [jsArg valueForProperty:success];
            JSValue *failFunc = [jsArg valueForProperty:fail];
            JSValue *completeFunc = [jsArg valueForProperty:complete];
            JsBridgeApiInCallBlock block = ^JsBridgeApi_InCallBlock_Header{
                if (!weakSelf) {
                    return [JsBridgeApiCallJsNativeResItem item];
                }
                NSArray *successDatas = argItem.successDatas;
                NSArray *failDatas = argItem.failDatas;
                NSArray *completeDatas = argItem.completeDatas;
                NSError *error = argItem.error;
                
                /** JSValue callWithArguments 调用js function
                 如果JSValue对应的不是js function，而是js array/number或其他数据 调用[JSValue callWithArguments:]函数，不会崩溃，可正常使用
                 原生传参@[]
                    success: function () {}
                    success: function (res) {}   res为[object Undefined]类型
                    success: function (res, res1) {}   res/res1均为[object Undefined]类型
                 原生传参@[[NSNull null]]
                    success: function () {}
                    success: function (res) {}   res为[object Null]类型
                    success: function (res, res1) {}   res为[object Null]类型  res1为[object Undefined]类型
                 原生传参@[@"x1"]
                    success: function () {}
                    success: function (res) {}   res为[object String]类型
                    success: function (res, res1) {}   res为[object String]类型  res1为[object Undefined]类型
                 原生传参@[@"x1", @"x2"]
                    success: function () {}
                    success: function (res) {}   res为[object String]类型
                    success: function (res, res1, res2) {}   res/res1均为[object String]类型  res2为[object Undefined]类型
                 */
                if (!error && successFunc) {
                    // 运行参数里的success方法
                    // [paramsValue invokeMethod:success withArguments:@[successData]];
                    JSValue *resValue = [successFunc callWithArguments:((successDatas && [successDatas isKindOfClass:NSArray.class]) ? successDatas : @[])];
                    if (argItem.jsResSuccessBlock) {
                        argItem.jsResSuccessBlock([JsBridgeApiCallJsResItem item:[weakSelf parseJSValueToObj:resValue] error:nil]);
                    }
                }
                if (error && failFunc) {
                    JSValue *resValue = [failFunc callWithArguments:((failDatas && [failDatas isKindOfClass:NSArray.class]) ? failDatas : @[])];
                    if (argItem.jsResFailBlock) {
                        argItem.jsResFailBlock([JsBridgeApiCallJsResItem item:[weakSelf parseJSValueToObj:resValue] error:nil]);
                    }
                }
                /**
                 js方法 complete: () => {}，complete: (res) => {}
                 callWithArguments: @[]  原生不传参数 res=null   上面里两个方法都运行正常 js不会报错
                 callWithArguments: @[]  原生传参数 上面里两个都运行正常
                 */
                if (completeFunc) {
                    JSValue *resValue = [completeFunc callWithArguments:((completeDatas && [completeDatas isKindOfClass:NSArray.class]) ? completeDatas : @[])];
                    if (argItem.jsResCompleteBlock) {
                        argItem.jsResCompleteBlock([JsBridgeApiCallJsResItem item:[weakSelf parseJSValueToObj:resValue] error:nil]);
                    }
                }
                return [JsBridgeApiCallJsNativeResItem item];
            };
            
            [resArgs addObject:[JsBridgeApiArgItem item:weakSelf.jsPage jsData:nativeValue callItem:[JsBridgeApiCallJsItem itemWithSFCBlock:block jsFuncArgBlock:nil]]];
        }
        return [weakSelf runNativeFunc:jsMethod apiPrefix:apiPrefix jsModuleName:jsModuleName arguments:resArgs.copy];
    };
    return [apiBlock copy];
}

#pragma mark - js sdk

- (NSString *)jskey_successFunc{
    return @"success";
}
- (NSString *)jskey_failFunc{
    return @"fail";
}
- (NSString *)jskey_completeFunc{
    return @"complete";
}

#pragma mark - exception

- (void)captureException:(void (^) (id exception))handler{
    /* 异常回调
     没有try cach方法 js直接报错   会回调
     有try cach方法 catch方法抛出异常throw error;   会回调
     有try cach方法 catch方法没有抛出异常throw error;   不会回调
     */
    [self.jsCtx setExceptionHandler:^(JSContext *context, JSValue *exception){
        if (handler) {
            handler([exception toObject]);
            return;
        }
        NSLog(@"👉JSCore Exception: %@", [exception toDictionary]);
    }];
}

#pragma mark - console

- (void)captureConsole:(void (^) (NSString *flag, NSArray *args))handler{
    __weak __typeof__(self) weakSelf = self;
    void (^block) (NSArray *, NSString *) = ^(NSArray *args, NSString *flag){
        if (!weakSelf) return;
        NSMutableArray *res = [NSMutableArray array];
        for (JSValue *arg in args) {
            [res addObject:[weakSelf parseJSValue:arg]];
        }
        if (handler) {
            handler(flag, res.copy);
            return;
        }
        NSLog(@"👉JSCore Console: flag: %@ args: %@", flag, res.copy);
    };
    /*
     JSValue 对 JSContext是强引用  不能直接在block里面使用JSValue
     也不能使用weakJSValue  在setObject: forKeyedSubscript:方法被调用后 原有的JSValue被释放
     
     有条件地持有（conditional retain）
        在以下两种情况任何一个满足的情况下保证其管理的JSValue被持有不被释放：
            可以通过JavaScript的对象图找到该JSValue。【即在JavaScript环境中存在该JSValue】
            可以通过native对象图找到该JSManagedValue。【即在JSVirtualMachine中存在JSManagedValue，那么JSManagedValue弱引用的JSValue即使引用数为0，也不会释放】
        如果以上条件都不满足，JSManagedValue对象就会将其value置为nil并释放该JSValue
     
     源代码: JSManagedValue内部实现
         + (JSManagedValue *)managedValueWithValue:(JSValue *)value andOwner:(id)owner
         {
             // 这里的JSManagedValue并没有对JSValue进行强引用
             JSManagedValue *managedValue = [[self alloc] initWithValue:value];
             // context对应的virtualMachine对value进行了强持有
             [value.context.virtualMachine addManagedReference:managedValue withOwner:owner];
             return [managedValue autorelease];
         }
         - (void)dealloc
         {
             JSVirtualMachine *virtualMachine = [[[self value] context] virtualMachine];
             if (virtualMachine) {
                 NSMapTable *copy = [m_owners copy];
                 for (id owner in [copy keyEnumerator]) {
                     size_t count = reinterpret_cast<size_t>(NSMapGet(m_owners, owner));
                     while (count--)
                         [virtualMachine removeManagedReference:self withOwner:owner];
                 }
                 [copy release];
             }

             [self disconnectValue];
             [m_owners release];
             [super dealloc];
         }
     
     JSManagedValue.m_owners强引用owner
     JSVirtualMachine.ownedObjects强引用owner
     */
    // 注入console  使用JSManagedValue
    /*
    NSMutableDictionary *resMap = [NSMutableDictionary dictionary];
    JSValue *oriConsole = [self.jsContext objectForKeyedSubscript:@"console"];
    NSArray *flagsMap = @[@[@"debug"],@[@"error"],@[@"info"],@[@"log"],@[@"warn"]];
    for (NSArray *flags in flagsMap) {
        NSString *flag = flags[0];
        JSManagedValue *jsManaged = nil;
        if (prjDebug) {
            JSValue *flagJs = [oriConsole objectForKeyedSubscript:flag];
            jsManaged = flagJs ? [JSManagedValue managedValueWithValue:flagJs andOwner:self] : nil;
        }
        void (^flagJsBlock) (void) = ^{
            NSArray *args = [JSContext currentArguments];
            // 回调原始输出方法 用于safari调试console输出
            if (prjDebug) {
                [[jsManaged value] callWithArguments:args];
            }
            // 回调自定义输出
            block(args, flag);
        };
        if (oriConsole) {
            [oriConsole setObject:[flagJsBlock copy] forKeyedSubscript:flag];
        }else{
            [resMap setObject:[flagJsBlock copy] forKey:flag];
        }
    }
    callBack(oriConsole ? nil : @"console", oriConsole ? nil : resMap.copy);
    */
    
    BOOL prjDebug = NO;
//#ifdef DEBUG
//    prjDebug = YES;
//#endif
    NSMutableDictionary *resMap = [NSMutableDictionary dictionary];
    JSValue *oriConsole = [self.jsCtx objectForKeyedSubscript:@"console"];
    NSArray *flagsMap = @[@[@"debug"],@[@"error"],@[@"info"],@[@"log"],@[@"warn"]];
    for (NSArray *flags in flagsMap) {
        NSString *flag = flags[0];
        if (prjDebug) {
            JSValue *flagJs = [oriConsole objectForKeyedSubscript:flag];
            [self setConsole:flagJs forKey:flag];
        }
        void (^flagJsBlock) (void) = ^{
            NSArray *args = [JSContext currentArguments];
            // 回调原始输出方法 用于safari调试console输出
            if (prjDebug) {
                [[weakSelf getConsoleForKey:flag] callWithArguments:args];
            }
            // 回调自定义输出
            block(args, flag);
        };
        if (oriConsole) {
            [oriConsole setObject:[flagJsBlock copy] forKeyedSubscript:flag];
        }else{
            [resMap setObject:[flagJsBlock copy] forKey:flag];
        }
    }
    if (!oriConsole) {
        [self.jsCtx setObject:resMap.copy forKeyedSubscript:@"console"];
    }
}
- (void)setConsole:(JSValue *)jsValue forKey:(NSString *)key{
    if (!key || ![key isKindOfClass:NSString.class] || key.length == 0 ||
        !jsValue || ![jsValue isKindOfClass:jsValue.class]) {
        return;
    }
    if (!self.consoleMap) {
        self.consoleMap = [NSMutableDictionary dictionary];
    }
    [self.consoleMap setObject:jsValue forKey:key];
}
- (JSValue *)getConsoleForKey:(NSString *)key{
    JSValue *res = nil;
    res = [self.consoleMap objectForKey:key];
    return res;
}
- (void)destroyContext{
    // 解除循环引用
    [self.consoleMap removeAllObjects];
}

#pragma mark - parse

/**JSContext中：js类型-->JSValue类型 对应关系
 Date：[JSValue toDate]=[NSDate class]
 function：[JSValue toObject]=[NSDictionary class]    [jsValue isObject]=YES
 null：[JSValue toObject]=[NSNull null]
 undefined：[JSValue toObject]=nil
 boolean：[JSValue toObject]=@(YES) or @(NO)  [NSNumber class]
 number：[JSValue toObject]= [NSNumber class]
 string：[JSValue toObject]= [NSString class]   [jsValue isObject]=NO
 array：[JSValue toObject]= [NSArray class]    [jsValue isObject]=YES
 json：[JSValue toObject]= [NSDictionary class]    [jsValue isObject]=YES
 */
- (id)parseJSValueToObj:(JSValue *)jsVal{
    return [self parseJSValue:jsVal][@"data"];
}
- (NSDictionary *)parseJSValue:(JSValue *)jsVal{
    NSString *type = @"[object 未知类型]"; id data = nil;
    
    BOOL ios9 = NO;
    if (@available(iOS 9.0, *)) {
        ios9 = YES;
    }
    BOOL ios13 = NO;
    if (@available(iOS 13.0, *)) {
        ios13 = YES;
    }
    
    if (!jsVal || ![jsVal isKindOfClass:JSValue.class]) {
        type = type;
        data = nil;
    }
    else if (jsVal.isUndefined) {
        type = @"[object Undefined]";
        data = [jsVal toObject];
    }
    else if (jsVal.isNull) {
        type = @"[object Null]";
        data = [jsVal toObject];
    }
    else if (jsVal.isBoolean) {
        type = @"[object Boolean]";
        data = @([jsVal toBool]);
    }
    else if (jsVal.isNumber) {
        type = @"[object Number]";
        data = [jsVal toNumber];
    }
    else if (jsVal.isString) {
        type = @"[object String]";
        data = [jsVal toString];
    }
    else if (ios9 && jsVal.isArray) {
        type = @"[object Array]";
        data = [jsVal toArray];
    }
    else if (ios9 && jsVal.isDate) {
        type = @"[object Date]";
        data = [jsVal toDate];
    }
    else if (ios13 && jsVal.isSymbol) {
        type = @"[object Symbol]";
        data = nil;
    }
    else if (jsVal.isObject) {
        type = @"[object Object]";
        data = [jsVal toObject];
    }
    else {
        type = type;
        data = [jsVal toObject];
    }
    NSMutableDictionary *res = [NSMutableDictionary dictionary];
    [res setObject:type forKey:@"type"];
    if (data) {
        [res setObject:data forKey:@"data"];
    }
    return res.copy;
}
@end
