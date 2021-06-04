//
//  ZHDPListOprate.m
//  ZHJSNative
//
//  Created by EM on 2021/5/28.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListOprate.h"
#import "ZHDPList.h"// 列表
#import "ZHDPManager.h"// 调试面板管理
#import "ZHDPListApps.h"// pop app列表

@interface ZHDPListOprateCell ()
@property (nonatomic, strong) UILabel *iconLabel;
@property (nonatomic, strong) UILabel *descLabel;
@end

@implementation ZHDPListOprateCell

+ (instancetype)cellWithTableView:(UITableView *)tableView{
    NSString *cellID = NSStringFromClass(self);
    ZHDPListOprateCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[ZHDPListOprateCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
//        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.clipsToBounds = YES;
        //        ⚠️[TableView] Changing the background color of UITableViewHeaderFooterView is not supported. Use the background view configuration instead.
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundView = [UIView new];
        //        self.selectedBackgroundView = [UIView new];
        
        [self.contentView addSubview:self.iconLabel];
        [self.contentView addSubview:self.descLabel];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    CGFloat X = 0;
    CGFloat Y = 0;
    CGFloat W = self.bounds.size.width;
    CGFloat H = 30;
    self.iconLabel.frame = CGRectMake(X, Y, W, H);
//    self.iconLabel.backgroundColor = [UIColor cyanColor];
    
    X = 0;
    W = self.bounds.size.width;
    H = 25;
    Y = self.bounds.size.height - H;
    self.descLabel.frame = CGRectMake(X, Y, W, H);
//    self.descLabel.backgroundColor = [UIColor orangeColor];
}

- (void)configItem:(ZHDPListOprateItem *)item{
    self.iconLabel.text = item.icon;
    self.descLabel.text = item.desc;
    self.iconLabel.textColor = item.textColor;
    self.descLabel.textColor = item.textColor;
}

- (UILabel *)iconLabel {
    if (!_iconLabel) {
        _iconLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _iconLabel.font = [ZHDPMg() iconFontWithSize:20];
        _iconLabel.textAlignment = NSTextAlignmentCenter;
//        _iconLabel.numberOfLines = 0;
        _iconLabel.backgroundColor = [UIColor clearColor];
        _iconLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _iconLabel;
}
- (UILabel *)descLabel {
    if (!_descLabel) {
        _descLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _descLabel.font = [ZHDPMg() defaultFont];
        _descLabel.textAlignment = NSTextAlignmentCenter;
//        _descLabel.numberOfLines = 0;
        _descLabel.backgroundColor = [UIColor clearColor];
        _descLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _descLabel;
}

@end


@interface ZHDPListOprate ()<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,retain) NSArray <ZHDPListOprateItem *> *items;
@end

@implementation ZHDPListOprate

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

    self.tableView.frame = self.shadowView.frame;
    [self reloadListFrequently];
}
- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
//    BOOL show = self.superview;
}
- (void)didMoveToSuperview{
    [super didMoveToSuperview];
}
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
    [super updateFrame];
    CGFloat superW = self.list.bounds.size.width;
    CGFloat superH = self.list.bounds.size.height;
    
    CGFloat W = self.realW;
    CGFloat X = superW - self.realRevealW;
    CGFloat H = superH * 0.85;
    CGFloat Y = (superH - H) * 0.5;
    self.frame = CGRectMake(X, Y, W, H);
}
- (void)show{
    [super show];
    [self doAnimation:^{
        [self updateFrame];
    } completion:^(BOOL finished) {
        
    }];
}
- (void)hide{    
    [super hide];
    [self doAnimation:^{
        [self updateFrame];
    } completion:^(BOOL finished) {
    }];
}
- (BOOL)allowMaskWhenShow{
    return YES;
}
- (void)reloadList{
    self.tableView.tableFooterView = [UIView new];
    [self.tableView reloadData];
}

#pragma mark - config

- (void)configData{
    [super configData];
}
- (void)configUI{
    [super configUI];
    [self addSubview:self.tableView];
}

#pragma mark - reload

- (void)reloadWithItems:(NSArray <ZHDPListOprateItem *> *)items{
    if (!items || ![items isKindOfClass:NSArray.class] || items.count == 0) {
        return;
    }
    for (id item in items) {
        if (![item isKindOfClass:ZHDPListOprateItem.class]) {
            return;
        }
    }
    self.items = items.copy;
    [self reloadListFrequently];
}

#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.items.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    ZHDPListOprateCell *cell = [ZHDPListOprateCell cellWithTableView:tableView];
    [cell configItem:self.items[indexPath.row]];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    void (^block) (void) = self.items[indexPath.row].block;
    if (block) block();
}

#pragma mark - getter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        
        _tableView.directionalLockEnabled = YES;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.showsVerticalScrollIndicator = NO;
        
        _tableView.separatorInset = UIEdgeInsetsZero;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        
        _tableView.clipsToBounds = YES;
    }
    return _tableView;
}

@end
