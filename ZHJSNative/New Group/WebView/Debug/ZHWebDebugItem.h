//
//  ZHWebDebugItem.h
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ZHWebView;

/** 👉单个web调试配置 */

typedef NS_ENUM(NSInteger, ZHWebDebugMode) {
    ZHWebDebugMode_Release     = 0, //release模式
    ZHWebDebugMode_Local      = 1, //本地拷贝js调试
    ZHWebDebugMode_Online      = 2, //链接线上地址调试
};
__attribute__((unused)) static NSDictionary * ZHWebDebugModeMap() {
    return @{
        @(ZHWebDebugMode_Release): @"release调试模式",
        @(ZHWebDebugMode_Local): @"本机js调试模式",
        @(ZHWebDebugMode_Online): @"socket调试模式"
    };
}
__attribute__((unused)) static NSString * ZHWebDebugDescByMode(ZHWebDebugMode mode) {
    return [ZHWebDebugModeMap() objectForKey:@(mode)];
}

@interface ZHWebDebugItem : NSObject

@property (nonatomic, assign) ZHWebDebugMode debugMode;
@property (nonatomic, copy) NSString *socketUrlStr;
@property (nonatomic, copy) NSString *localUrlStr;


+ (instancetype)configuration:(ZHWebView *)webview;
@property (nonatomic,weak) ZHWebView *webView;

#pragma mark - float view

- (void)showFloatView;
- (void)updateFloatViewTitle:(NSString *)title;
- (void)updateFloatViewLocation;

#pragma mark - Call ZHWebViewDebugSocketDelegate

- (void)webViewCallReadyRefresh;
- (void)webViewCallStartRefresh:(NSDictionary *)info;

#pragma mark - enable
    
// 长连接调试【切换调试模式】 浮窗
@property (nonatomic,assign,readonly) BOOL debugModeEnable;
// 手动刷新 浮窗
@property (nonatomic,assign,readonly) BOOL refreshEnable;
// web 中添加 log调试控制台
@property (nonatomic,assign,readonly) BOOL logOutputWebEnable;
// console.log 输出到 Xcode调试控制台
@property (nonatomic,assign,readonly) BOOL logOutputXcodeEnable;
// 弹窗显示 web异常  window.onerror
@property (nonatomic,assign,readonly) BOOL alertWebErrorEnable;
// 禁用web长按弹出菜单
@property (nonatomic,assign,readonly) BOOL touchCalloutEnable;
@end
