//
//  ZHContextDebugItem.h
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ZHJSContext;

typedef NS_ENUM(NSInteger, ZHContextDebugMode) {
    ZHContextDebugMode_Release     = 0, //release模式
    ZHContextDebugMode_Local      = 1, //本地拷贝js调试
    ZHContextDebugMode_Online      = 2, //链接线上地址调试
};
__attribute__((unused)) static NSDictionary * ZHContextDebugModeMap() {
    return @{
        @(ZHContextDebugMode_Release): @"release调试模式",
        @(ZHContextDebugMode_Local): @"本机js调试模式",
        @(ZHContextDebugMode_Online): @"socket调试模式"
    };
}
__attribute__((unused)) static NSString * ZHContextDebugDescByMode(ZHContextDebugMode mode) {
    return [ZHContextDebugModeMap() objectForKey:@(mode)];
}

/** 👉JSContext 调试配置 */
@interface ZHContextDebugItem : NSObject

@property (nonatomic, assign) ZHContextDebugMode debugMode;

#pragma mark - init

+ (instancetype)configuration:(ZHJSContext *)jsContext;
@property (nonatomic,weak) ZHJSContext *jsContext;

#pragma mark - enable
    
// 长连接调试【切换调试模式】 浮窗
@property (nonatomic,assign,readonly) BOOL debugModeEnable;
// console.log 输出到 Xcode调试控制台
@property (nonatomic,assign,readonly) BOOL logOutputXcodeEnable;
// 弹窗显示 JSContext异常
@property (nonatomic,assign,readonly) BOOL alertContextErrorEnable;

@end

