//
//  ZHJSContext.m
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHJSContext.h"
#import "ZHJSHandler.h"

@interface ZHJSContext ()
@property (nonatomic,strong) ZHJSHandler *handler;
//外部handler
//@property (nonatomic,strong) NSArray <id <ZHJSApiProtocol>> *apiHandlers;
@end

@implementation ZHJSContext

- (instancetype)initWithApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers{
    //创建虚拟机
    JSVirtualMachine *vm = [[JSVirtualMachine alloc] init];
    self = [self initWithVirtualMachine:vm];
    if (self) {
        //事件
        self.handler = [[ZHJSHandler alloc] initWithDebugConfig:nil apiHandlers:apiHandlers];
        self.handler.jsContext = self;
        
//        self.apiHandlers = apiHandlers;
        
        //注入api
        [self registerException];
        [self registerLogAPI];
        [self registerAPI];
        
        //运算js
//            [self evaluateScript:[NSString stringWithContentsOfURL:[NSURL fileURLWithPath:[ZHPath jsPath]] encoding:NSUTF8StringEncoding error:nil]];
        
    }
    return self;
}

- (NSArray<id<ZHJSApiProtocol>> *)apiHandlers{
    return [self.handler apiHandlers];
}

//添加移除api
- (void)addApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, id res, NSError *error))completion{
    __weak __typeof__(self) __self = self;
    [self.handler addApiHandlers:apiHandlers completion:^(NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, NSString *jsCode, NSError *error) {
        if (error) {
            if (completion) completion(successApiHandlers, failApiHandlers, nil, error?:[NSError errorWithDomain:@"" code:404 userInfo:@{NSLocalizedDescriptionKey: @"api注入失败"}]);
            return;
        }
        //直接添加  会覆盖掉先前定义的
        [__self registerAPI];
        if (completion) completion(successApiHandlers, failApiHandlers, @{}, nil);
    }];
}
- (void)removeApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, id res, NSError *error))completion{
    __weak __typeof__(self) __self = self;
    
    //先重置掉原来定义的所有api
    [self removeAPI];
    
    [self.handler removeApiHandlers:apiHandlers completion:^(NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, NSString *jsCode, NSError *error) {
        if (error) {
            if (completion) completion(successApiHandlers, failApiHandlers, nil, error?:[NSError errorWithDomain:@"" code:404 userInfo:@{NSLocalizedDescriptionKey: @"api移除失败"}]);
            return;
        }
        //添加新的api
        [__self registerAPI];
        if (completion) completion(successApiHandlers, failApiHandlers, @{}, nil);
    }];
}

- (void)registerException{
    /** 异常回调
     没有try cach方法 js直接报错   会回调
     有try cach方法 catch方法抛出异常throw error;   会回调
     有try cach方法 catch方法没有抛出异常throw error;   不会回调
     */
    __weak __typeof__(self) __self = self;
    [self setExceptionHandler:^(JSContext *context, JSValue *exception){
        NSLog(@"❌JSContext异常");
        NSMutableDictionary *res = [[exception toDictionary] mutableCopy];
        [res setValue:[exception toString]?:@"" forKey:@"message"];
        NSLog(@"%@", res);
        [__self.handler showJSContextException:[res copy]];
    }];
}
//注入console.log
- (void)registerLogAPI{
    __weak __typeof__(self) __self = self;
    [self.handler fetchJSContextLogApi:^(NSString *apiPrefix, NSDictionary *apiBlockMap) {
        if (apiBlockMap.allKeys.count == 0) return;
        [__self setObject:apiBlockMap forKeyedSubscript:apiPrefix];
    }];
}
- (void)registerAPI{
    [self oprateAPIWithReset:NO];
}
- (void)removeAPI{
    [self oprateAPIWithReset:YES];
}
- (void)oprateAPIWithReset:(BOOL)isReset{
    __weak __typeof__(self) __self = self;
    [self.handler fetchJSContextApi:^(NSString *apiPrefix, NSDictionary *apiBlockMap) {
        if (!apiPrefix || ![apiPrefix isKindOfClass:[NSString class]] || apiPrefix.length == 0) return;
        if (isReset) {
            //因为要移除api  apiMap设定写死传@{}
            [__self setObject:@{} forKeyedSubscript:apiPrefix];
            return;
        }
        if (!apiBlockMap || ![apiBlockMap isKindOfClass:[NSDictionary class]] || apiBlockMap.allKeys.count == 0) return;
        [__self setObject:apiBlockMap forKeyedSubscript:apiPrefix];
    }];
}

#pragma mark - public

- (JSValue *)runJsFunc:(NSString *)funcName arguments:(NSArray *)arguments{
    if (funcName.length == 0) {
        return nil;
    }
    /**objectForKeyedSubscript 只能获取js代码中的 function 与 var 变量  let 与 const 变量不能获取
     如：var test = {}  function test(params) {}
     */
    JSValue *func = [self objectForKeyedSubscript:funcName];
    if (!func.isObject) {
        return nil;
    }
    return [func callWithArguments:arguments];
}

- (void)dealloc{
    NSLog(@"%s", __func__);
}

@end
