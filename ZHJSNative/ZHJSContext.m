//
//  ZHJSContext.m
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHJSContext.h"
#import "ZHUtil.h"
#import "ZHJSHandler.h"

@interface ZHJSContext ()
//事件处理
@property (nonatomic,strong) ZHJSHandler *handler;
@end

@implementation ZHJSContext

+ (ZHJSContext *)createContext{
    //创建虚拟机
    JSVirtualMachine *vm = [[JSVirtualMachine alloc] init];
    ZHJSContext *context = [[ZHJSContext alloc] initWithVirtualMachine:vm];
    
    //事件
    context.handler = [[ZHJSHandler alloc] init];
    context.handler.jsContext = context;
    
    //注入api
    [context registerException];
    [context registerLogAPI];
    [context registerAPI];
    
    //运算js
//    [context evaluateScript:[NSString stringWithContentsOfURL:[NSURL fileURLWithPath:[ZHUtil jsPath]] encoding:NSUTF8StringEncoding error:nil]];
    
    return context;
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
    __weak __typeof__(self) __self = self;
    [self.handler fetchJSContextApi:^(NSString *apiPrefix, NSDictionary *apiBlockMap) {
        if (apiBlockMap.allKeys.count == 0) return;
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
    NSLog(@"-------%s---------", __func__);
}

@end
