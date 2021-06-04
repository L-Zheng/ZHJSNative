//
//  ZHDPListRow.m
//  ZHJSNative
//
//  Created by EM on 2021/5/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListRow.h"
#import "ZHDPManager.h"// 调试面板管理

@interface ZHDPListRow ()
@property (nonatomic,strong) NSArray <ZHDPListColItem *> *items;
@property (nonatomic,retain) NSMutableArray *labels;
@property (nonatomic,retain) NSMutableArray *verticalLines;
@property (nonatomic,strong) UIView *line;
@end

@implementation ZHDPListRow

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
    
    for (UIView *line in self.verticalLines) {
        if (line.superview) {
            line.frame = CGRectMake(line.frame.origin.x, 0, line.frame.size.width, self.bounds.size.height);
        }
    }
    
    self.line.frame = CGRectMake(0, self.bounds.size.height - [ZHDPMg() defaultLineW], self.bounds.size.width, [ZHDPMg() defaultLineW]);
}

#pragma mark - config

- (void)configData{
}
- (void)configUI{
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor clearColor];
}

- (void)configItem:(NSArray <ZHDPListColItem *> *)items{
    if (!items || ![items isKindOfClass:NSArray.class] || items.count == 0) {
        return;
    }
    self.items = items;
    
    NSArray *colItems = items.copy;
    for (NSUInteger i = 0; i < colItems.count; i++) {
        ZHDPListColItem *colItem = colItems[i];
        UILabel *label = i < self.labels.count ? self.labels[i] : nil;
        if (!label) {
            label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.backgroundColor = [UIColor clearColor];
            label.numberOfLines = 0;
            label.adjustsFontSizeToFitWidth = YES;
            [self.labels addObject:label];
        }
        
        label.attributedText = colItem.attTitle;
        label.frame = [colItem.rectValue CGRectValue];
        [self addViewToSelf:label];
        
        if (i < colItems.count - 1) {
            UIView *line = i < self.verticalLines.count ? self.verticalLines[i] : nil;
            if (!line) {
                line = [[UIView alloc] initWithFrame:CGRectZero];
                line.backgroundColor = [ZHDPMg() defaultLineColor];
//                line.backgroundColor = [UIColor cyanColor];
                [self.verticalLines addObject:line];
            }
            line.frame = CGRectMake(CGRectGetMaxX(label.frame) + ([ZHDPMg() marginW] - [ZHDPMg() defaultLineW]) * 0.5, label.frame.origin.y, [ZHDPMg() defaultLineW], label.frame.size.height);
            [self addViewToSelf:line];
        }
    }
    if (colItems.count < self.labels.count) {
        for (NSInteger i = colItems.count; i < self.labels.count; i++) {
            UIView *view = self.labels[i];
            [view removeFromSuperview];
        }
    }
    if (colItems.count <= 1) {
        for (NSInteger i = 0; i < self.verticalLines.count; i++) {
            UIView *view = self.verticalLines[i];
            [view removeFromSuperview];
        }
    }else{
        if (colItems.count - 1 < self.verticalLines.count) {
            for (NSInteger i = colItems.count - 1; i < self.verticalLines.count; i++) {
                UIView *view = self.verticalLines[i];
                [view removeFromSuperview];
            }
        }
    }
    
    if (!self.line) {
        self.line = [[UIView alloc] initWithFrame:CGRectZero];
        self.line.backgroundColor = [ZHDPMg() defaultLineColor];
    }
    [self addViewToSelf:self.line];
}
- (void)addViewToSelf:(UIView *)view{
    if (!view) return;
    if (!view.superview) {
        [self addSubview:view];
    }else{
        if (view.superview != self) {
            [view removeFromSuperview];
            [self addSubview:view];
        }
    }
}

- (NSMutableArray *)labels{
    if (!_labels) {
        _labels = [NSMutableArray array];
    }
    return _labels;
}
- (NSMutableArray *)verticalLines{
    if (!_verticalLines) {
        _verticalLines = [NSMutableArray array];
    }
    return _verticalLines;
}

@end
