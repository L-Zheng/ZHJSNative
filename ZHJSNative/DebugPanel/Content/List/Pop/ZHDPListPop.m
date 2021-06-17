//
//  ZHDPListPop.m
//  ZHJSNative
//
//  Created by EM on 2021/5/29.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListPop.h"
#import "ZHDPManager.h"// 调试面板管理
#import "ZHDPList.h"// 列表

@interface ZHDPListPop ()

// 默认宽度
@property (nonatomic, assign) CGFloat defaultW;

@property (nonatomic, strong) UIPanGestureRecognizer *panGes;
@property (nonatomic, copy) void (^panGesBlock) (void);
@property (nonatomic, assign) CGPoint gesStartPoint;
@property (nonatomic, assign) CGRect gesStartFrame;
@end
@implementation ZHDPListPop

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

    [self updateArrowBtnFrame];
    
    CGFloat X = CGRectGetMaxX(self.arrowBtn.frame);
    CGFloat W = self.frame.size.width - X;
    CGFloat H = self.frame.size.height;
    CGFloat Y = 0;
    self.shadowView.frame = CGRectMake(X, Y, W, H);

    self.bgBtn.frame = self.list.bounds;
}
- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
    BOOL show = self.superview;
    if (!show) return;
}
- (void)didMoveToSuperview{
    [super didMoveToSuperview];
}

// 子类重写
- (CGFloat)focusW{
    return 30.0;
}
- (CGFloat)minRevealW{
    return [self focusW];
}
- (CGFloat)defaultPopW{
    return [self minPopW];
}
- (CGFloat)minPopW{
    return 85;
}
- (CGFloat)maxPopW{
    return self.list.bounds.size.width - 10;
}
- (void)updateFrame{
}
- (void)show{
    // self.realW = [self defaultPopW];
    self.realRevealW = self.realW;
    self.arrowBtn.selected = YES;
    [self updateArrowBtnFrame];

    if ([self allowMaskWhenShow]) {
        [self.bgBtn removeFromSuperview];
        [self.list insertSubview:self.bgBtn belowSubview:self];
        self.bgBtn.alpha = 0.0;
        [self doAnimation:^{
            self.bgBtn.alpha = 0.3;
        } completion:^(BOOL finished) {
            
        }];
    }
}
- (void)hide{
    // self.realW = [self minPopW];
    self.realRevealW = [self minRevealW];
    self.arrowBtn.selected = NO;
    [self updateArrowBtnFrame];

    [self doAnimation:^{
        self.bgBtn.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.bgBtn removeFromSuperview];
    }];
}
- (BOOL)allowMaskWhenShow{
    return YES;
}
- (void)reloadList{
}

- (BOOL)isShow{
    return self.arrowBtn.selected;
}
- (void)reloadListInstant{
    [self reloadList];
}
- (void)reloadListFrequently{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadList) object:nil];
    [self performSelector:@selector(reloadList) withObject:nil afterDelay:0.25];
}
- (void)doAnimation:(void (^)(void))animation completion:(void (^ __nullable)(BOOL finished))completion{
    [UIView animateWithDuration:0.25 animations:animation completion:completion];
}

#pragma mark - config

- (void)configData{
    self.realW = [self defaultPopW];
    self.realRevealW = [self minRevealW];
}
- (void)configUI{
//    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor clearColor];
    
    [self addGesture];
    
    [self addSubview:self.arrowBtn];
    [self addSubview:self.shadowView];
}

#pragma mark - frame

- (void)updateArrowBtnFrame{
    CGFloat X = 0;
    CGFloat W = self.focusW;
    CGFloat H = self.arrowBtn.isSelected ? self.frame.size.height : W * 2;
    CGFloat Y = (self.frame.size.height - H) * 0.5;
    self.arrowBtn.frame = CGRectMake(X, Y, W, H);
}

#pragma mark - click

- (void)bgBtnClick:(UIButton *)btn{
    [self arrowBtnClick:self.arrowBtn];
}
- (void)arrowBtnClick:(UIButton *)btn{
    if (btn.isSelected) {
        [self hide];
    }else{
        [self show];
    }
}

#pragma mark - gesture

- (void)addGesture{
    self.panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    [self addGestureRecognizer:self.panGes];
}
- (void)panGesture:(UIPanGestureRecognizer *)panGes{
    UIView *superview = self.superview;
    CGFloat superW = superview.frame.size.width;
    CGFloat superH = superview.frame.size.height;
    __weak __typeof__(self) weakSelf = self;
    
    if (panGes.state == UIGestureRecognizerStateBegan) {
        self.gesStartPoint = [panGes locationInView:superview];
        self.gesStartFrame = self.frame;
    } else if (panGes.state == UIGestureRecognizerStateChanged){

        CGPoint velocity = [panGes velocityInView:superview];
        NSLog(@"%.f",velocity.x);
        CGPoint p = [panGes locationInView:superview];
        CGFloat offsetX = p.x - self.gesStartPoint.x;
        CGFloat offSetY = p.y - self.gesStartPoint.y;
        
        CGRect realRect = CGRectZero;
        
        if (![self isShow]) {
            CGFloat hideW = (self.gesStartFrame.size.width - (superW - self.gesStartFrame.origin.x));
            CGFloat X = self.gesStartFrame.origin.x + offsetX;
            if (X <= 10) X = 10;
            CGFloat Y = self.gesStartFrame.origin.y;
            self.realW = self.gesStartFrame.size.width + (offsetX >= 0 ? 0 : (-offsetX <= hideW ? 0 : (-offsetX - hideW)));
            if (self.realW >= [self maxPopW]) self.realW = [self maxPopW];
            self.realRevealW = (superW - self.gesStartFrame.origin.x) + (-offsetX);
            realRect = (CGRect){{X, Y}, {self.realW, self.gesStartFrame.size.height}};
            
            // 向右拖动
            if (offsetX >= 0) {
                self.panGesBlock = ^{
                    //hide
                    [weakSelf hide];
                };
            }
            // 向左拖动
            else{
                // 拖动距离 < 隐藏视图宽度的一半
                if (fabs(offsetX) < hideW * 0.5) {
                    self.panGesBlock = ^{
                        //hide
                        [weakSelf hide];
                    };
                }
                // 拖动距离 <= 隐藏视图宽度
                else if (fabs(offsetX) <= hideW){
                    self.panGesBlock = ^{
                        //show
                        [weakSelf show];
                    };
                }
                // 拖动距离 > 隐藏视图宽度
                else{
                    self.panGesBlock = ^{
                        //show
                        [weakSelf show];
                    };
                }
            }
        }else{
            CGFloat cWidth = self.gesStartFrame.size.width + (-offsetX);
            if (cWidth <= 0) cWidth = 0;
            
            CGFloat X = self.gesStartFrame.origin.x + offsetX;
            if (X <= 10) X = 10;
            CGFloat Y = self.gesStartFrame.origin.y;
            self.realW = (offsetX >= 0 ? (cWidth >= [self minPopW] ? cWidth : [self minPopW]) : cWidth);
            if (self.realW >= [self maxPopW]) self.realW = [self maxPopW];
            self.realRevealW = (superW - self.gesStartFrame.origin.x) + (-offsetX);
            realRect = (CGRect){{X, Y}, {self.realW, self.gesStartFrame.size.height}};
            
            // 向右拖动
            if (offsetX >= 0) {
                if ([self minPopW] > 0) {
                    // 拖动后宽度 >= minPopW
                    if (cWidth >= [self minPopW]) {
                        //show
                        // [self show];
                    }
                    // 拖动后宽度 < minPopW
                    else {
                        CGFloat hideW = ([self minPopW] - [self minRevealW]);
                        CGFloat cHideW = (X + self.realW - superW);
                        
                        // 当前隐藏视图宽度 < 隐藏视图宽度的一半
                        if (cHideW < hideW * 0.5) {
                            self.panGesBlock = ^{
                                //show
                                [weakSelf show];
                            };
                        }
                        // 当前隐藏视图宽度 >= 隐藏视图宽度
                        else if (cHideW <= hideW){
                            self.panGesBlock = ^{
                                //hide
                                [weakSelf hide];
                            };
                        }
                        // 当前隐藏视图宽度 > 隐藏视图宽度
                        else{
                            self.panGesBlock = ^{
                                //hide
                                [weakSelf hide];
                            };
                        }
                    }
                }else{
                    if (cWidth <= [self focusW] * 2) {
                        self.panGesBlock = ^{
                            //hide
                            [weakSelf hide];
                        };
                    }
                }
            }
            // 向左拖动
            else{
            }
        }
        
        self.frame = realRect;
        
    } else if (panGes.state == UIGestureRecognizerStateEnded ||
               panGes.state == UIGestureRecognizerStateCancelled ||
               panGes.state == UIGestureRecognizerStateFailed){
        
        if (self.panGesBlock) {
            self.panGesBlock();
            self.panGesBlock = nil;
        }
    }
}

#pragma mark - getter

- (UIButton *)bgBtn{
    if (!_bgBtn) {
        _bgBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        _bgBtn.backgroundColor = [UIColor blackColor];
        [_bgBtn addTarget:self action:@selector(bgBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _bgBtn;
}
- (ZHDPListPopShadow *)shadowView{
    if (!_shadowView) {
        _shadowView = [[ZHDPListPopShadow alloc] initWithFrame:CGRectZero];
    }
    return _shadowView;
}
- (UIButton *)arrowBtn{
    if (!_arrowBtn) {
        _arrowBtn = [[UIButton alloc] initWithFrame:CGRectZero];
//        _arrowBtn.backgroundColor = [UIColor orangeColor];
//        CGFloat W = 5;
//        CGFloat X = (self.focusW - W) * 0.5;
//        CGFloat Y = 0;
//        CGFloat H = self.focusW / sin(M_PI / 6.0);
//        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(X, Y, W, H)];
//        view.layer.masksToBounds = YES;
//        view.layer.cornerRadius = W * 0.5;
//        view.backgroundColor = [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1.0];
//        view.transform = CGAffineTransformMakeRotation(M_PI / 6.0);
//        [_arrowBtn addSubview:view];
//
//        W = 5;
//        X = (self.focusW - W) * 0.5;
//        H = self.focusW / sin(M_PI / 6.0);
//        Y = CGRectGetMaxY(view.frame) - (H * (1 - cos(M_PI / 6.0)) + W);
//        view = [[UIView alloc] initWithFrame:CGRectMake(X, Y, W, H)];
//        view.layer.masksToBounds = YES;
//        view.layer.cornerRadius = W * 0.5;
//        view.backgroundColor = [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1.0];
//        view.transform = CGAffineTransformMakeRotation(-M_PI / 6.0);
//        [_arrowBtn addSubview:view];
//        _arrowBtn.frame = CGRectMake(0, 0, self.focusW, CGRectGetMaxY(view.frame));
        _arrowBtn.backgroundColor = [UIColor clearColor];
        _arrowBtn.alpha = 0.7;
        [_arrowBtn setTitle:@"\ue68d" forState:UIControlStateNormal];
        [_arrowBtn setTitle:@"\ue68e" forState:UIControlStateSelected];
        [_arrowBtn setTitleColor:[ZHDPMg() defaultColor] forState:UIControlStateNormal];
        [_arrowBtn setTitleColor:[ZHDPMg() selectColor] forState:UIControlStateSelected];
        _arrowBtn.titleLabel.font = [ZHDPMg() iconFontWithSize:25];
        _arrowBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
        [_arrowBtn addTarget:self action:@selector(arrowBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _arrowBtn;
}

@end
