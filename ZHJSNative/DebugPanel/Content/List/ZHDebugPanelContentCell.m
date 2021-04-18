//
//  ZHDebugPanelContentCell.m
//  ZHJSNative
//
//  Created by Zheng on 2021/4/17.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDebugPanelContentCell.h"

@interface ZHDebugPanelContentCell ()
@property (nonatomic,strong) NSDictionary *item;
@property (nonatomic,retain) NSMutableArray *labels;
@property (nonatomic,strong) UIView *line;
@end

@implementation ZHDebugPanelContentCell

+ (instancetype)cellWithTableView:(UITableView *)tableView{
    NSString *cellID = NSStringFromClass(self);
    ZHDebugPanelContentCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[ZHDebugPanelContentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
//        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
        //        self.selectedBackgroundView = [UIView new];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.line.frame = CGRectMake(0, self.contentView.bounds.size.height - 0.5, self.contentView.bounds.size.width, 0.5);
}

- (void)configItem:(NSDictionary *)item{
    self.item = item;
    
    NSArray *titles = item[@"titles"];
    for (NSUInteger i = 0; i < titles.count; i++) {
        NSDictionary *titleItem = titles[i];
        UILabel *label = i < self.labels.count ? self.labels[i] : nil;
        if (!label) {
            label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.font = [self.class textFont];
            label.numberOfLines = 0;
            [self.labels addObject:label];
        }
        
        label.text = titleItem[@"text"];
        label.frame = [(NSValue *)titleItem[@"textFrame"] CGRectValue];
        if (label.superview != self.contentView) {
            [label removeFromSuperview];
            [self.contentView addSubview:label];
        }
    }
    if (!self.line) {
        self.line = [[UIView alloc] initWithFrame:CGRectZero];
        self.line.backgroundColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.25];
    }
    if (self.line.superview != self.contentView) {
        [self.line removeFromSuperview];
        [self.contentView addSubview:self.line];
    }
}

+ (UIFont *)textFont{
    return [UIFont systemFontOfSize:17];
}

- (NSMutableArray *)labels{
    if (!_labels) {
        _labels = [NSMutableArray array];
    }
    return _labels;
}

@end
