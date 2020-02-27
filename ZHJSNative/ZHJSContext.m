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
    
    //设置异常回调
    [context setExceptionHandler:^(JSContext *context, JSValue *exception){
        NSLog(@"❌ZHJSContext异常");
        NSLog(@"%@", exception);
    }];
    [context registerLogAPI];
    [context registerAPI];
    
    //运算js
    [context evaluateScript:[NSString stringWithContentsOfURL:[NSURL fileURLWithPath:[ZHUtil jsPath]] encoding:NSUTF8StringEncoding error:nil]];
    
    return context;
}

//注入console.log
- (void)registerLogAPI{
    __weak __typeof__(self) __self = self;
    [self.handler fetchJSContextLogApi:^(NSString *apiPrefix, NSDictionary *apiBlockMap) {
        [__self setObject:apiBlockMap forKeyedSubscript:apiPrefix];
    }];
}
- (void)registerAPI{
    __weak __typeof__(self) __self = self;
    [self.handler fetchJSContextApi:^(NSString *apiPrefix, NSDictionary *apiBlockMap) {
        [__self setObject:apiBlockMap forKeyedSubscript:apiPrefix];
    }];
}

#pragma mark - public

- (JSValue *)runJsFunc:(NSString *)funcName arguments:(NSArray *)arguments{
    if (funcName.length == 0) {
        return nil;
    }
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
