//
//  ZHCtxDebugItem.m
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHCtxDebugItem.h"
#import "ZHJSDebugManager.h"
#import "ZHJSContext.h"

@interface ZHCtxDebugItem ()
@end

@implementation ZHCtxDebugItem

+ (instancetype)defaultItem{
    ZHCtxDebugItem *item = [[ZHCtxDebugItem alloc] init];
    [item configProperty:nil];
    return item;
}
+ (instancetype)item:(ZHJSContext *)jsContext{
    ZHCtxDebugItem *item = [ZHJSDebugMg() getCtxDebugGlobalItem:jsContext.globalConfig.mpConfig.appId];
    
    ZHCtxDebugItem *resItem = [item sameItem];
    resItem.jsContext = jsContext;
    return resItem;
}
- (ZHCtxDebugItem *)sameItem{
    ZHCtxDebugItem *resItem = [[ZHCtxDebugItem alloc] init];
    [resItem configProperty:self];
    return resItem;
}
- (void)configProperty:(ZHCtxDebugItem *)item{
    self.debugMode = item ? item.debugMode : ZHCtxDebugMode_Release;
    self.jsContext = item ? item.jsContext : nil;
    
    BOOL globalDebugEnable = [ZHJSDebugMg() getCtxDebugGlobalEnable];
    
    self.debugModeEnable = item ? item.debugModeEnable : globalDebugEnable;
    self.logOutputXcodeEnable = item ? item.logOutputXcodeEnable : globalDebugEnable;
    self.alertCtxErrorEnable = item ? item.alertCtxErrorEnable : [ZHJSDebugMg() getCtxDebugAlertErrorEnable];
}
@end
