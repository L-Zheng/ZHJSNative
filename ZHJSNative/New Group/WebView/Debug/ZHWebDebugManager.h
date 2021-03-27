//
//  ZHWebDebugManager.h
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZHWebDebugItem.h"

/** 👉web 全局调试配置 */
@interface ZHWebDebugManager : NSObject

+ (instancetype)shareManager;

- (void)setDebugEnable:(BOOL)enable;
- (BOOL)getDebugEnable;

- (ZHWebDebugItem *)getConfigItem:(NSString *)key;

- (BOOL)availableIOS11;
- (BOOL)availableIOS10;
- (BOOL)availableIOS9;
@end

__attribute__((unused)) static ZHWebDebugManager * ZHWebDebugMg() {
    return [ZHWebDebugManager shareManager];
}

