//
//  ZHDPWindow.h
//  ZHJSNative
//
//  Created by EM on 2021/5/31.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZHDPFloat.h"// 调试面板浮窗
#import "ZHDebugPanel.h"// 调试面板

@interface ZHDPWindow : UIWindow
+ (instancetype)window;
@property (nonatomic,strong) ZHDPFloat *floatView;
@property (nonatomic,strong) ZHDebugPanel *debugPanel;

- (void)showFloat;
- (void)hideFloat;
- (void)updateFloatFrame:(CGRect)rect;
- (void)showDebugPanel;
- (void)hideDebugPanel;
- (void)updateDebugPanelFrame:(CGRect)rect;
@end
