//
//  ZHWebViewDebugConfiguration.h
//  ZHJSNative
//
//  Created by EM on 2020/6/24.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZHWebView.h"

//NS_ASSUME_NONNULL_BEGIN

//调试配置
@interface ZHWebViewDebugConfiguration : NSObject

#pragma mark - init

+ (instancetype)configuration;
@property (nonatomic,weak) ZHWebView *webView;
+ (void)setupDebugEnable:(BOOL)enable;
+ (BOOL)fetchDebugEnable;

// 调试模式
@property (nonatomic, assign, readonly) ZHWebViewDebugModel debugModel;

#pragma mark - float view

//- (void)showFlowView;
- (void)updateFloatViewTitle:(NSString *)title;
- (void)updateFloatViewLocation;

#pragma mark - enable
    
// 长连接调试【切换调试模式】 浮窗
@property (nonatomic,assign,readonly) BOOL debugModelEnable;
// 手动刷新 浮窗
@property (nonatomic,assign,readonly) BOOL refreshEnable;
// webview 中添加 log调试控制台
@property (nonatomic,assign,readonly) BOOL logOutputWebviewEnable;
// console.log 输出到 Xcode调试控制台
@property (nonatomic,assign,readonly) BOOL logOutputXcodeEnable;
// 弹窗显示 webview异常  window.onerror
@property (nonatomic,assign,readonly) BOOL alertWebViewErrorEnable;
// 弹窗显示 JSContext异常
@property (nonatomic,assign,readonly) BOOL alertJsContextErrorEnable;
// 禁用webview长按弹出菜单
@property (nonatomic,assign,readonly) BOOL touchCalloutEnable;
// 版本 运行iOS8模式
+ (BOOL)availableIOS11;
+ (BOOL)availableIOS10;
+ (BOOL)availableIOS9;
@end

//NS_ASSUME_NONNULL_END
