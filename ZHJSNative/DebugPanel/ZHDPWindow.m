//
//  ZHDPWindow.m
//  ZHJSNative
//
//  Created by EM on 2021/5/31.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPWindow.h"
#import "ZHDPManager.h"

@interface ZHDPWindow ()
@property (nonatomic, assign) CGRect debugPanelRect;
@property (nonatomic, assign) CGRect floatRect;
@end

@implementation ZHDPWindow
+ (instancetype)window{
    ZHDPWindow *window = [[ZHDPWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    return window;
}

#pragma mark - override

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configData];
        [self configUI];
    }
    return self;
}
- (void)layoutSubviews{
    [super layoutSubviews];
    
    self.floatView.frame = self.floatRect;
    
    if (_debugPanel) {
        self.debugPanel.frame = self.debugPanelRect;
    }
}
- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
}
- (void)didMoveToSuperview{
}
- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if ([view isKindOfClass:self.class]) {
        return nil;
    } else {
        return view;
    }
}

#pragma mark - config

- (void)configData{
}
- (void)configUI{
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor clearColor];
    
    /** 系统长按弹出菜单位于视图：
     UITextEffectsWindow：UICalloutBar      windowLevel = UIWindowLevelNormal + 10 = 10
     因此：WXAWindow 的 windowLevel 不能超过 10 ，否则 系统弹出菜单 会被 WXAWindow 盖住
     
     UIWindowLevelNormal：0
     UIWindowLevelAlert：2000
     UIWindowLevelStatusBar：1000
     */
    self.windowLevel = UIWindowLevelNormal+5;
    self.hidden = NO;
    self.alpha = 1.0;
    
    // 在iOS13之前创建上面的代码能让window直接显示出来，
    // iOS13有了SceneDelegate之后上面的代码无法让window直接显示出来
    __weak __typeof__(self) weakSelf = self;
    if (@available(iOS 13.0, *)) {
        [[NSNotificationCenter defaultCenter] addObserverForName:UISceneWillConnectNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            weakSelf.windowScene = note.object;
        }];
        if ([UIApplication sharedApplication].windows.count > 0) {
            for (UIWindow * defaultWindow in [UIApplication sharedApplication].windows) {
                if (defaultWindow.windowLevel == UIWindowLevelNormal) {
                    weakSelf.windowScene = defaultWindow.windowScene;
                }
            }
        }
    }
    [self addNotification];
}

#pragma mark - notification

- (void)addNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChanged:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChanged:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)keyboardWillChanged:(NSNotification *)note{
    
    if (self.debugPanel.status != ZHDebugPanelStatus_Show) {
        return;
    }
    
    CGRect frame = [[[note userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
//    CGFloat duration = [[[note userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    UIEdgeInsets safeAreaInsets = [ZHDPMg() fetchKeyWindowSafeAreaInsets];
    
    BOOL show = [note.name isEqualToString:UIKeyboardWillShowNotification];
    CGFloat W = self.debugPanel.frame.size.width;
    CGFloat H = self.debugPanel.frame.size.height;
    CGFloat X = self.debugPanel.frame.origin.x;
    CGFloat Y = self.debugPanel.frame.origin.y - (show ? frame.size.height : -frame.size.height);
    if (Y <= safeAreaInsets.top + 10) {
        Y = safeAreaInsets.top + 10;
    }
    if (Y >= self.bounds.size.height - H) {
        Y = self.bounds.size.height - H;
    }
    [self updateDebugPanelFrame:CGRectMake(X, Y, W, H)];
}

#pragma mark - show hide

- (void)showView:(UIView *)view{
    if (!view) return;
    UIView *inView = self;
    if (!view.superview) {
        [inView addSubview:view];
        return;
    }
    if ([view.superview isEqual:inView]) {
        return;
    }
    [inView addSubview:view];
}
- (void)showFloat{
    if (CGRectEqualToRect(self.floatRect, CGRectZero)) {
        CGFloat W = 100;
        CGFloat H = 40;
        CGFloat X = self.bounds.size.width - W;
        CGFloat Y = (self.bounds.size.height - H) * 0.5;
        [self updateFloatFrame:CGRectMake(X, Y, W, H)];
    }
    
    [self showView:self.floatView];
    
    self.floatView.alpha = 0.0;
    [UIView animateWithDuration:0.25 animations:^{
        self.floatView.alpha = 1.0;
    }];
}
- (void)hideFloat{
    if (!_floatView) return;
    
    self.floatView.alpha = 1.0;
    [UIView animateWithDuration:0.25 animations:^{
        self.floatView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.floatView removeFromSuperview];
    }];
}
- (void)updateFloatFrame:(CGRect)rect{
    self.floatRect = rect;
    self.floatView.frame = self.floatRect;
}
- (void)showDebugPanel{
    [self showView:self.debugPanel];
    [self updateDebugPanelFrameWhenShowHide:NO];
    
    [UIView animateWithDuration:0.25 animations:^{
        [self updateDebugPanelFrameWhenShowHide:YES];
    }];
}
- (void)updateDebugPanelFrame:(CGRect)rect{
    self.debugPanelRect = rect;
    self.debugPanel.frame = self.debugPanelRect;
}
- (void)updateDebugPanelFrameWhenShowHide:(BOOL)show{
    CGFloat originW = self.debugPanel.frame.size.width;
    CGFloat originH = self.debugPanel.frame.size.height;
    
    CGFloat W = originW > 0 ? originW : self.bounds.size.width;
    CGFloat H = originH > 0 ? originH : self.bounds.size.height * 0.5;
    CGFloat X = self.bounds.size.width - W;
    CGFloat Y = self.bounds.size.height - (show ? H : 0);

    [self updateDebugPanelFrame:CGRectMake(X, Y, W, H)];
}
- (void)hideDebugPanel{
    if (!_debugPanel) return;
    [self endEditing:YES];
    
    [UIView animateWithDuration:0.25 animations:^{
        [self updateDebugPanelFrameWhenShowHide:NO];
    } completion:^(BOOL finished) {
        [self.debugPanel removeFromSuperview];
    }];
}

#pragma mark - getter

- (ZHDPFloat *)floatView{
    if (!_floatView) {
        _floatView = [[ZHDPFloat alloc] initWithFrame:CGRectZero];
        _floatView.tapBlock = ^{
            [ZHDPMg() switchDebugPanel];
        };
        _floatView.doubleTapBlock = ^{
            [ZHDPMg() close];
        };
    }
    return _floatView;
}
- (ZHDebugPanel *)debugPanel{
    if (!_debugPanel) {
        _debugPanel = [[ZHDebugPanel alloc] initWithFrame:CGRectZero];
    }
    return _debugPanel;
}
@end
