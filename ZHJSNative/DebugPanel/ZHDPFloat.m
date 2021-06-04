//
//  ZHDPFloat.m
//  ZHJSNative
//
//  Created by EM on 2021/5/31.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPFloat.h"
#import "ZHDPManager.h"// 调试面板管理

@interface ZHDPFloat ()
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, assign) CGPoint gesStartPoint;
@property (nonatomic, assign) CGRect gesStartFrame;

@end

@implementation ZHDPFloat

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
    
    self.titleLabel.frame = self.bounds;
}
- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
}
- (void)didMoveToSuperview{
}
- (void)dealloc{
}

#pragma mark - config

- (void)configData{
}
- (void)configUI{
    self.clipsToBounds = YES;
    self.backgroundColor = [ZHDPMg() selectColor];
    self.layer.cornerRadius = 5;
    void (^block) (UIView *view) = ^(UIView *view){
        view.clipsToBounds = NO;
        view.layer.masksToBounds = NO;
        view.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
        view.layer.shadowOffset = CGSizeMake(0,0);
        view.layer.shadowOpacity = 0.5;
        view.layer.shadowRadius = 5;
    };
    block(self);
    
    [self addGesture];
    
    [self addSubview:self.titleLabel];
}

#pragma mark - update

- (void)updateTitle:(NSString *)title{
    self.titleLabel.text = title;
}

#pragma mark - gesture

- (void)addGesture{
    UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    [self addGestureRecognizer:panGes];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
    [self addGestureRecognizer:tap];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGesture:)];
    doubleTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTap];
    
    [tap requireGestureRecognizerToFail:doubleTap];
}
- (void)panGesture:(UIPanGestureRecognizer *)panGes{
    UIView *superview = self.superview;
    CGFloat superW = superview.frame.size.width;
    CGFloat superH = superview.frame.size.height;
    
    if (panGes.state == UIGestureRecognizerStateBegan) {
        self.gesStartPoint = [panGes locationInView:superview];
        self.gesStartFrame = self.frame;
    } else if (panGes.state == UIGestureRecognizerStateChanged){

//        CGPoint velocity = [panGes velocityInView:superview];
        CGPoint p = [panGes locationInView:superview];
        CGFloat offsetX = p.x - self.gesStartPoint.x;
        CGFloat offSetY = p.y - self.gesStartPoint.y;
        
        CGFloat W = self.gesStartFrame.size.width;
        CGFloat H = self.gesStartFrame.size.height;
        CGFloat X = self.gesStartFrame.origin.x + offsetX;
        if (X <= 0) X = 0;
        if (X >= superW - W) X = superW - W;
        CGFloat Y = self.gesStartFrame.origin.y + offSetY;
        if (Y <= 0) Y = 0;
        if (Y >= superH - H) X = superH - H;
        
        [ZHDPMg().window updateFloatFrame:CGRectMake(X, Y, W, H)];
        
    } else if (panGes.state == UIGestureRecognizerStateEnded ||
               panGes.state == UIGestureRecognizerStateCancelled ||
               panGes.state == UIGestureRecognizerStateFailed){
        
        CGFloat centerX = self.center.x;
        CGFloat X = self.frame.origin.x;
        CGFloat Y = self.frame.origin.y;
        CGFloat W = self.gesStartFrame.size.width;
        CGFloat H = self.gesStartFrame.size.height;
        
        if (centerX >= superW * 0.5) X = superW - W;
        if (centerX < superW * 0.5) X = 0;
        [UIView animateWithDuration:0.25 animations:^{
            [ZHDPMg().window updateFloatFrame:CGRectMake(X, Y, W, H)];
        }];
    }
}
- (void)tapGesture:(UITapGestureRecognizer *)panGes{
    if (self.tapBlock) {
        self.tapBlock();
    }
}
- (void)doubleTapGesture:(UITapGestureRecognizer *)panGes{
    if (self.doubleTapBlock) {
        self.doubleTapBlock();
    }
}

#pragma mark - getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [ZHDPMg() defaultFont];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 0;
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _titleLabel;
}
@end
