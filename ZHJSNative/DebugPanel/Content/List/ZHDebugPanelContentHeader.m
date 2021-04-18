//
//  ZHDebugPanelContentHeader.m
//  ZHJSNative
//
//  Created by Zheng on 2021/4/17.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDebugPanelContentHeader.h"

@interface ZHDebugPanelContentHeader ()
@property (nonatomic,strong) NSMutableDictionary *item;
@property (nonatomic,retain) NSMutableArray *labels;
@property (nonatomic,strong) UIView *line;
@end

@implementation ZHDebugPanelContentHeader

#pragma mark - init

+ (instancetype)sctionHeaderWithTableView:(UITableView *)tableView{
    NSString *headerID = NSStringFromClass(self);
    ZHDebugPanelContentHeader *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headerID];
    if (!headerView) {
        headerView = [[ZHDebugPanelContentHeader alloc] initWithReuseIdentifier:headerID];
    }
    return headerView;
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        self.clipsToBounds = YES;
        self.contentView.backgroundColor = [UIColor clearColor];
        //[self.contentView addSubview:view];
        
        [self addGesture];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.backgroundView.backgroundColor = [UIColor clearColor];
    self.line.frame = CGRectMake(0, self.contentView.bounds.size.height - 0.5, self.contentView.bounds.size.width, 0.5);
}

- (void)addGesture{
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClickGes:)];
    [self addGestureRecognizer:gesture];
}

- (void)tapClickGes:(UITapGestureRecognizer *)tapGes{
    if (!self.item || ![self.item isKindOfClass:NSDictionary.class] || self.item.allKeys.count == 0) {
        return;
    }
    BOOL open = [(NSNumber *)[self.item objectForKey:@"open"] boolValue];
    [self.item setObject:@(!open) forKey:@"open"];
    if (self.tapClickBlock) {
        self.tapClickBlock(!open);
    }
}

- (void)configItem:(NSMutableDictionary *)item{
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
