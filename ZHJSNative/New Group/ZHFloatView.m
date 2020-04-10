//
//  ZHFloatView.m
//  ZHFloatWindow
//
//  Created by Zheng on 2020/3/28.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHFloatView.h"

typedef NS_ENUM(NSInteger, ZHFloatLocation) {
    ZHFloatLocationLeft     = 0,
    ZHFloatLocationRight      = 1,
};

@interface ZHFloatView ()<UIGestureRecognizerDelegate>
@property (nonatomic,strong) UIImageView *imageView;
@property (nonatomic,strong) UILabel *titleLabel;
@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, assign) CGRect startFrame;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) CGFloat timerCount;
@end

@implementation ZHFloatView

#pragma mark - init

+ (ZHFloatView *)floatView{
    ZHFloatView *view = [[ZHFloatView alloc] initWithFrame:CGRectZero];
    return view;
}
- (void)showInView:(UIView *)view{
    if (!view) return;
    
    if (!self.superview) {
        [view addSubview:self];
    }else{
        if (![self.superview isEqual:view]) {
            [self removeFromSuperview];
            [view addSubview:self];
        }
    }
    [self updateWhenSuperViewLayout];
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        [self updateUINormal];
        [self addSubview:self.imageView];
        [self addSubview:self.titleLabel];
        
        [self configGesture];
    }
    return self;
}

- (void)updateWhenSuperViewLayout{
    UIView *view = self.superview;
    
    CGFloat superW = view.frame.size.width;
    CGFloat superH = view.frame.size.height;
    CGFloat selfW = 60;
    CGFloat selfH = 60;
    
    self.frame = CGRectMake(superW - selfW, (superH - selfH) * 0.5, selfW, selfH);
    
    if (![self.superview isEqual:view]) {
        [view addSubview:self];
    }
    [self moveToScreenEdge:^(CGRect currentFrame, ZHFloatLocation location) {
        
    }];
}

- (void)updateTitle:(NSString *)title{
    self.titleLabel.text = title;
}

#pragma mark - config

- (void)configGesture{
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureChanged:)];
    panGesture.delegate = self;
    [self addGestureRecognizer:panGesture];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureClick:)];
    tapGesture.delegate = self;
    [self addGestureRecognizer:tapGesture];
}

#pragma mark - UI

- (void)updateUIHigh{
    self.backgroundColor = [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1.0];
}

- (void)updateUINormal{
    self.backgroundColor = [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1.0];
}

- (void)moveToScreenEdge:(void (^) (CGRect currentFrame, ZHFloatLocation location))finishBlock {
    //移动到屏幕边缘
    UIView *superview = self.superview;
    CGFloat superW = superview.frame.size.width;
    
    CGFloat leftCenterX = (self.frame.size.width * 0.5 + 0);
    CGFloat rightCenterX = superW - (self.frame.size.width * 0.5 + 0);
    CGFloat centerX = (self.center.x >= superW * 0.5) ? rightCenterX : leftCenterX;
    CGPoint targetCenter = CGPointMake(centerX, self.center.y);
    
    ZHFloatLocation location = (self.center.x >= superW * 0.5) ? ZHFloatLocationRight : ZHFloatLocationLeft;
    
    if (CGPointEqualToPoint(targetCenter, self.center)) {
        if (finishBlock) finishBlock(self.frame, location);
        [self updateUIWhenAnimateEnd:location];
        return;
    }
    __weak __typeof__(self) weakSelf = self;
    [UIView animateWithDuration:0.25 animations:^{
        weakSelf.center = targetCenter;
        if (finishBlock) finishBlock(weakSelf.frame, location);
    } completion:^(BOOL finished) {
        [weakSelf updateUIWhenAnimateEnd:location];
    }];
}

- (void)updateUIWhenPanGesBegan{
    CGFloat selfW = self.frame.size.width;
    CGFloat radius = self.frame.size.height * 0.5;
    
    UIBezierPath *maskPath = [UIBezierPath bezierPath];
    [maskPath moveToPoint:CGPointMake(selfW - radius, 0)];
    [maskPath addArcWithCenter:CGPointMake(selfW - radius, radius) radius:radius startAngle:M_PI + M_PI_2 endAngle:M_PI_2 clockwise:YES];
    [maskPath addArcWithCenter:CGPointMake(selfW - radius, radius) radius:radius startAngle:M_PI_2 endAngle:M_PI + M_PI_2 clockwise:YES];
    [maskPath addLineToPoint:CGPointMake(selfW - radius, 0)];
    [maskPath closePath];
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc]init];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    self.layer.mask = maskLayer;
}

- (void)updateUIWhenAnimateEnd:(ZHFloatLocation)location{
    CGFloat selfW = self.frame.size.width;
    CGFloat selfH = self.frame.size.height;
    CGFloat radius = self.frame.size.height * 0.5;
    
    UIBezierPath *maskPath = [UIBezierPath bezierPath];
    
    if (location == ZHFloatLocationLeft) {
        [maskPath moveToPoint:CGPointMake(0, 0)];
        [maskPath addLineToPoint:CGPointMake(selfW - radius, 0)];
        [maskPath addArcWithCenter:CGPointMake(selfW - radius, radius) radius:radius startAngle:M_PI + M_PI_2 endAngle:M_PI_2 clockwise:YES];
        [maskPath addLineToPoint:CGPointMake(0, selfH)];
        [maskPath addLineToPoint:CGPointMake(0, 0)];
    }else{
        [maskPath moveToPoint:CGPointMake(selfW, 0)];
        [maskPath addLineToPoint:CGPointMake(selfW, selfH)];
        [maskPath addLineToPoint:CGPointMake(selfW - radius, selfH)];
        [maskPath addArcWithCenter:CGPointMake(radius, radius) radius:radius startAngle:M_PI_2 endAngle:M_PI + M_PI_2 clockwise:YES];
        [maskPath addLineToPoint:CGPointMake(selfW, 0)];
    }
    [maskPath closePath];
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc]init];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    self.layer.mask = maskLayer;
    
    CGFloat imageViewW = 40;
    CGFloat imageViewH = 40;
    CGFloat margin = 10;
    self.imageView.layer.cornerRadius = imageViewW * 0.5;
    self.imageView.frame = CGRectMake((location == ZHFloatLocationRight ? margin : selfW - imageViewW - margin), (selfH - imageViewH) * 0.5, imageViewW, imageViewH);
    
    CGFloat labelW = 50;
    CGFloat labelH = 50;
    margin = 5;
    self.titleLabel.frame = CGRectMake((location == ZHFloatLocationRight ? margin : selfW - labelW - margin), (selfH - labelH) * 0.5, labelW, labelH);
}
#pragma mark - action

- (void)tapGestureClick:(UITapGestureRecognizer *)gesture {
    [self handleTapGestureClick];
}

- (void)panGestureChanged:(UIPanGestureRecognizer *)gesture {
    
    UIView *superview = self.superview;
    CGFloat superW = superview.frame.size.width;
    CGFloat superH = superview.frame.size.height;
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self removeTimer];
        self.startPoint = [gesture locationInView:superview];
        self.startFrame = self.frame;
        [self handlePanGestureBegan];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        
        CGPoint p = [gesture locationInView:superview];
        CGFloat offsetX = p.x - self.startPoint.x;
        CGFloat offSetY = p.y - self.startPoint.y;
        
        CGFloat width = self.frame.size.width;
        CGFloat height = self.frame.size.height;
        //限制拖动范围
        CGFloat X = self.startFrame.origin.x + offsetX;
        if (X <= 0) X = 0;
        if (X >= superW - width) X = superW - width;
        
        CGFloat Y = self.startFrame.origin.y + offSetY;
        if (Y <= 0) Y = 0;
        if (Y >= superH - height) Y = superH - height;
        
        self.frame = (CGRect){{X, Y}, self.frame.size};
        
        //检查是否进入删除区域
        [self handlePanGestureChanged:self.frame];
        
    } else if (gesture.state == UIGestureRecognizerStateEnded ||
              gesture.state == UIGestureRecognizerStateCancelled ||
              gesture.state == UIGestureRecognizerStateFailed) {
        [self handlePanGestureEnd];
    }
}

- (void)handleTapGestureClick{
    [self moveToScreenEdge:^(CGRect currentFrame, ZHFloatLocation location) {
        
    }];
    [self updateUIHigh];
    [self performSelector:@selector(updateUINormal) withObject:nil afterDelay:0.25];
//    NSLog(@"-------%s---------", __func__);
    if (self.tapClickBlock) self.tapClickBlock();
}

- (void)handlePanGestureBegan{
    [self updateUIWhenPanGesBegan];
//    NSLog(@"-------%s---------", __func__);
    if (self.panGestureBegan) self.panGestureBegan();
}

- (void)handlePanGestureChanged:(CGRect)frame{
//    NSLog(@"-------%s---------", __func__);
    if (self.panGestureChanged) self.panGestureChanged(self.frame);
}

- (void)handlePanGestureEnd{
//    NSLog(@"-------%s---------", __func__);
    if (self.panGestureEnd) self.panGestureEnd();
    [self moveToScreenEdge:^(CGRect currentFrame, ZHFloatLocation location) {
        
    }];
}

#pragma mark - timer

- (void)addTimer {
    if (self.timer) return;
    self.timerCount = 0;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerResponded) userInfo:nil repeats:YES];
}

- (void)removeTimer {
    if (!self.timer) return;
    [self.timer invalidate];
    self.timer = nil;
    self.timerCount = 0;
}

- (void)timerResponded {
    self.timerCount += 0.1;
    if (self.timerCount >= 0.5) {
        [self removeTimer];
        [self handlePanGestureBegan];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    NSLog(@"-------%s---------", __func__);
    [super touchesBegan:touches withEvent:event];
    [self addTimer];
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    NSLog(@"-------%s---------", __func__);
    [super touchesEnded:touches withEvent:event];
    [self removeTimer];
    [self handlePanGestureEnd];
}

//可能被tap or 拖拽手势中断
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    NSLog(@"-------%s---------", __func__);
    [super touchesCancelled:touches withEvent:event];
    [self removeTimer];
}

#pragma mark - getter

- (UIImageView *)imageView{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.backgroundColor = [UIColor clearColor];
        _imageView.image = [UIImage imageNamed:@"applet-icon"];
    }
    return _imageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:12];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 0;
        _titleLabel.textColor = [UIColor blueColor];
        _titleLabel.backgroundColor = [UIColor clearColor];
    }
    return _titleLabel;
}
@end
