//
//  ZHContextDebugManager.h
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZHContextDebugItem.h"

/** 👉Context 全局调试配置 */
@interface ZHContextDebugManager : NSObject

+ (instancetype)shareManager;

- (void)setDebugEnable:(BOOL)enable;
- (BOOL)getDebugEnable;

- (ZHContextDebugItem *)getConfigItem:(NSString *)key;

- (BOOL)availableIOS11;
- (BOOL)availableIOS10;
- (BOOL)availableIOS9;
@end

__attribute__((unused)) static ZHContextDebugManager * ZHContextDebugMg() {
    return [ZHContextDebugManager shareManager];
}

