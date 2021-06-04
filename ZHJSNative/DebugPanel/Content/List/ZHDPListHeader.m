//
//  ZHDPListHeader.m
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListHeader.h"

@interface ZHDPListHeader ()
@property (nonatomic,strong) ZHDPListSecItem *item;
@property (nonatomic,strong) ZHDPListRow *rowContent;
@end

@implementation ZHDPListHeader

#pragma mark - init

+ (instancetype)sctionHeaderWithTableView:(UITableView *)tableView{
    NSString *headerID = NSStringFromClass(self);
    ZHDPListHeader *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headerID];
    if (!headerView) {
        headerView = [[ZHDPListHeader alloc] initWithReuseIdentifier:headerID];
    }
    return headerView;
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        self.clipsToBounds = YES;
//        ⚠️[TableView] Changing the background color of UITableViewHeaderFooterView is not supported. Use the background view configuration instead.
//        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundView = [UIView new];
        
        [self.contentView addSubview:self.rowContent];
        
        [self addGesture];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.rowContent.frame = self.contentView.bounds;
}

- (void)addGesture{
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGes:)];
    [self addGestureRecognizer:gesture];
    
    UILongPressGestureRecognizer *longPressGes = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGes:)];
    [self addGestureRecognizer:longPressGes];
}

- (void)longPressGes:(UILongPressGestureRecognizer *)ges{
    if (ges.state == UIGestureRecognizerStateBegan) {
        if (self.longPressGesBlock) {
            self.longPressGesBlock(self.item.open, self.item);
        }
    }
}
- (void)tapGes:(UITapGestureRecognizer *)ges{
    if (!self.item) {
        return;
    }
//    self.item.open = !self.item.isOpen;
    if (self.tapGesBlock) {
        self.tapGesBlock(self.item.open, self.item);
    }
}

- (void)configItem:(ZHDPListSecItem *)item{
    self.item = item;
    
    [self.rowContent configItem:item.colItems];
}

- (ZHDPListRow *)rowContent{
    if (!_rowContent) {
        _rowContent = [[ZHDPListRow alloc] initWithFrame:CGRectZero];
    }
    return _rowContent;
}
@end
