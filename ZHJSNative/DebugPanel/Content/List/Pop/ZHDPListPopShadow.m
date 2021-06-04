//
//  ZHDPListPopShadow.m
//  ZHJSNative
//
//  Created by EM on 2021/6/3.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListPopShadow.h"
#import "ZHDPManager.h"// 调试面板管理

@implementation ZHDPListPopShadow

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
}
- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
}
- (void)didMoveToSuperview{
    [super didMoveToSuperview];
    
    if (self.superview) {
        void (^block) (UIView *view) = ^(UIView *view){
            view.layer.cornerRadius = [ZHDPMg() defaultCornerRadius];
            view.clipsToBounds = NO;
            view.layer.masksToBounds = NO;
            view.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
            view.layer.shadowOffset = CGSizeMake(0,0);
            view.layer.shadowOpacity = 0.5;
            view.layer.shadowRadius = 5;
            // 以下代码防止xcode报内存警告  The layer is using dynamic shadows which are expensive to render  【导致了离屏渲染】
    //            view.layer.shadowPath = [UIBezierPath bezierPathWithRect:view.bounds].CGPath;
        };
        block(self);
    }
}

#pragma mark - config

- (void)configData{
}
- (void)configUI{
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor whiteColor];
}

@end
