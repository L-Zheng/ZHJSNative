//
//  ZHDPListRow.m
//  ZHJSNative
//
//  Created by EM on 2021/5/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListRow.h"

@interface ZHDPListRow ()
@property (nonatomic,strong) NSArray <ZHDPListColItem *> *items;
@property (nonatomic,retain) NSMutableArray *labels;
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
    
    self.line.frame = CGRectMake(0, self.bounds.size.height - 0.5, self.bounds.size.width, 0.5);
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
        
        label.font = colItem.font;
        label.text = colItem.title;
        label.frame = [colItem.rectValue CGRectValue];
        if (label.superview != self) {
            [label removeFromSuperview];
            [self addSubview:label];
        }
    }
    if (!self.line) {
        self.line = [[UIView alloc] initWithFrame:CGRectZero];
        self.line.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
    }
    if (self.line.superview != self) {
        [self.line removeFromSuperview];
        [self addSubview:self.line];
    }
}

- (NSMutableArray *)labels{
    if (!_labels) {
        _labels = [NSMutableArray array];
    }
    return _labels;
}

@end
