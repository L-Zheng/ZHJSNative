//
//  ZHContextDebugItem.m
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHContextDebugItem.h"
#import "ZHContextDebugManager.h"
#import "ZHJSContext.h"

@interface ZHContextDebugItem ()
@property (nonatomic,assign) BOOL debugEnable;
@end

@implementation ZHContextDebugItem

+ (instancetype)configuration:(ZHJSContext *)jsContext{
    ZHContextDebugItem *config = [[ZHContextDebugItem alloc] init];
    config.jsContext = jsContext;
    
    config.debugEnable = [ZHContextDebugMg() getDebugEnable];
    
    ZHContextDebugItem *item = [ZHContextDebugMg() getConfigItem:jsContext.globalConfig.mpConfig.appId];
    
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
