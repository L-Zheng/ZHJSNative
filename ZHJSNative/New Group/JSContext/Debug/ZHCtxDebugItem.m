//
//  ZHCtxDebugItem.m
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHCtxDebugItem.h"
#import "ZHCtxDebugManager.h"
#import "ZHJSContext.h"

@interface ZHCtxDebugItem ()
@property (nonatomic,assign) BOOL debugEnable;
@end

@implementation ZHCtxDebugItem

+ (instancetype)configuration:(ZHJSContext *)jsContext{
    ZHCtxDebugItem *config = [[ZHCtxDebugItem alloc] init];
    config.jsContext = jsContext;
    
    config.debugEnable = [ZHCtxDebugMg() getDebugEnable];
    
    ZHCtxDebugItem *item = [ZHCtxDebugMg() getConfigItem:jsContext.globalConfig.mpConfig.appId];
    
    config.debugMode = item.debugMode;
    
    return config;
}

- (BOOL)debugModeEnable{
    return self.debugEnable;
}
- (BOOL)logOutputXcodeEnable{
    return self.debugEnable;
}
- (BOOL)alertContextErrorEnable{
    return self.debugEnable;
}
@end
