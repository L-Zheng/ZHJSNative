//
//  ZHDebugPanel.m
//  ZHJSNative
//
//  Created by Zheng on 2021/4/17.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDebugPanel.h"
#import "ZHDebugPanelOption.h"

#import "ZHDebugPanelContentLog.h"
#import "ZHDebugPanelContentNetwork.h"
#import "ZHDebugPanelContentStorage.h"
#import "ZHDebugPanelContentIM.h"

@interface ZHDebugPanel ()
@end

@implementation ZHDebugPanel

#pragma mark - init

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configData];
        [self configUI];
    }
    return self;
}

#pragma mark - config

- (void)configData{
}

- (void)configUI{
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor grayColor];
}

#pragma mark - event

- (void)selectOption:(ZHDebugPanelContent *)content{
    for (UIView *view in self.allContents) {
        [view removeFromSuperview];
    }
    self.selectContent = content;
    [self addSubview:content];
    
    [content setNeedsLayout];
    [content layoutIfNeeded];
    
    
    
    [content addDataTest];
    [content addDataTest];
    [content addDataTest];
    [content addDataTest];
    [content addDataTest];
    [content addDataTest];
}

- (NSArray *)allContents{
    return @[self.logContent, self.networkContent, self.storageContent, self.imContent];
}

#pragma mark - layout

- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
    // 添加到父视图
    if (newSuperview) {
        return;
    }
}
- (void)didMoveToSuperview{
    self.status = self.superview ? ZHDebugPanelStatus_Show : ZHDebugPanelStatus_Hide;
    if (!self.superview) {
        return;
    }
    
    if (self.optionView.superview != self) {
        [self.optionView removeFromSuperview];
        [self addSubview:self.optionView];
        [self.optionView reloadWithItems:[self allContents]];
    }
    
    
    
    
    
    [self.optionView selectContent:self.logContent];

}

//FOUNDATION_EXPORT
CGFloat optionMarginTop = 5;
CGFloat optionH = 30;
CGFloat contentMarginTop = 5;

- (void)layoutSubviews{
    [super layoutSubviews];
    
    self.optionView.frame = CGRectMake(0, optionMarginTop, self.bounds.size.width, optionH);
    
    CGFloat contentY = CGRectGetMaxY(self.optionView.frame) + contentMarginTop;
    CGFloat contentH = self.bounds.size.height - contentY;
    self.selectContent.frame = CGRectMake(0, contentY, self.bounds.size.width, contentH);
}

#pragma mark - getter

- (ZHDebugPanelOption *)optionView{
    if (!_optionView) {
        __weak __typeof__(self) weakSelf = self;
        _optionView = [[ZHDebugPanelOption alloc] initWithFrame:CGRectZero];
        _optionView.selectBlock = ^(ZHDebugPanelContent *content) {
            [weakSelf selectOption:content];
        };
        _optionView.debugPanel = self;
    }
    return _optionView;
}

- (ZHDebugPanelContentLog *)logContent{
    if (!_logContent) {
        _logContent = [[ZHDebugPanelContentLog alloc] initWithFrame:CGRectZero];
        _logContent.debugPanel = self;
    }
    return _logContent;
}
- (ZHDebugPanelContentNetwork *)networkContent{
    if (!_networkContent) {
        _networkContent = [[ZHDebugPanelContentNetwork alloc] initWithFrame:CGRectZero];
        _networkContent.debugPanel = self;
    }
    return _networkContent;
}
- (ZHDebugPanelContentStorage *)storageContent{
    if (!_storageContent) {
        _storageContent = [[ZHDebugPanelContentStorage alloc] initWithFrame:CGRectZero];
        _storageContent.debugPanel = self;
    }
    return _storageContent;
}
- (ZHDebugPanelContentIM *)imContent{
    if (!_imContent) {
        _imContent = [[ZHDebugPanelContentIM alloc] initWithFrame:CGRectZero];
        _imContent.debugPanel = self;
    }
    return _imContent;
}


@end
