//
//  ZHDPListPop.h
//  ZHJSNative
//
//  Created by EM on 2021/5/29.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPComponent.h"
#import "ZHDPListPopShadow.h"// pop阴影
@class ZHDPList;

@interface ZHDPListPop : ZHDPComponent
@property (nonatomic,weak) ZHDPList *list;

@property (nonatomic,strong) UIButton *bgBtn;
@property (nonatomic,strong) ZHDPListPopShadow *shadowView;
@property (nonatomic,strong) UIButton *arrowBtn;

// 宽度
@property (nonatomic, assign) CGFloat realW;
// 暴露在屏幕上的宽度
@property (nonatomic, assign) CGFloat realRevealW;

// 子类重写
- (CGFloat)focusW;
- (CGFloat)minRevealW;
- (CGFloat)defaultPopW;
- (CGFloat)minPopW;
- (CGFloat)maxPopW;
- (void)updateFrame;
- (void)show;
- (void)hide;
- (BOOL)allowMaskWhenShow;
- (void)reloadList;

- (void)configData;
- (void)configUI;

// public func
- (BOOL)isShow;
- (void)reloadListInstant;
- (void)reloadListFrequently;
- (void)doAnimation:(void (^)(void))animation completion:(void (^ __nullable)(BOOL finished))completion;
@end
