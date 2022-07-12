//
//  JSContext+JsBridge.m
//  JsBridge
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "JSContext+JsBridge.h"
#import <objc/runtime.h>

@interface JSContext (__JsBridge)

@end

@implementation JSContext (JsBridge)

#pragma mark - getter

- (void)setJsBridge:(JsBridgeCtxHandler *)jsBridge{
    objc_setAssociatedObject(self, @selector(jsBridge), jsBridge, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (JsBridgeCtxHandler *)jsBridge{
    JsBridgeCtxHandler *jsBridge = objc_getAssociatedObject(self, _cmd);
    if (!jsBridge) {
        jsBridge = [[JsBridgeCtxHandler alloc] init];
        jsBridge.jsCtx = self;
        [self setJsBridge:jsBridge];
    }
    return jsBridge;
}

@end
