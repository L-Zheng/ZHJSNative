//
//  ZHJSDebugManager.h
//  ZHJSNative
//
//  Created by EM on 2021/5/24.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZHWebDebugItem.h"
#import "ZHCtxDebugItem.h"

/** 👉全局调试配置 */
@interface ZHJSDebugManager : NSObject

+ (instancetype)shareManager;

// web
- (BOOL)setWebDebugAlertErrorEnable:(BOOL)enable;
- (BOOL)getWebDebugAlertErrorEnable;
- (BOOL)setWebDebugGlobalEnable:(BOOL)enable;
- (BOOL)getWebDebugGlobalEnable;
- (ZHWebDebugItem *)getWebDebugGlobalItem:(NSString *)key;

// ctx
- (BOOL)setCtxDebugAlertErrorEnable:(BOOL)enable;
- (BOOL)getCtxDebugAlertErrorEnable;
- (BOOL)setCtxDebugGlobalEnable:(BOOL)enable;
- (BOOL)getCtxDebugGlobalEnable;
- (ZHCtxDebugItem *)getCtxDebugGlobalItem:(NSString *)key;

- (BOOL)availableIOS11;
- (BOOL)availableIOS10;
- (BOOL)availableIOS9;

@end

__attribute__((unused)) static ZHJSDebugManager * ZHJSDebugMg() {
    return [ZHJSDebugManager shareManager];
}

