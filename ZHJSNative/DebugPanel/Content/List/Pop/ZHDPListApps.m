//
//  ZHDPListApps.m
//  ZHJSNative
//
//  Created by EM on 2021/5/28.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListApps.h"
#import "ZHDPManager.h"// 调试面板管理
#import "ZHDPList.h"// 列表

@interface ZHDPListApps ()<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic,strong) UILabel *topTipLabel;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,retain) NSArray <ZHDPAppItem *> *items;
@property (nonatomic,strong) UILabel *tipLabel;
@property (nonatomic,strong) UIButton *selectAllBtn;
@end

@implementation ZHDPListApps

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
    
    CGFloat X = self.shadowView.frame.origin.x;
    CGFloat Y = 0;
    CGFloat W = self.shadowView.frame.size.width;
    CGFloat H = 44;
    self.topTipLabel.frame = CGRectMake(X, Y, W, H);
    
    X = self.shadowView.frame.origin.x;
    H = 44;
    Y = self.shadowView.frame.size.height - H;
    W = self.shadowView.frame.size.width;
    self.selectAllBtn.frame = CGRectMake(X, Y, W, H);
    
    X = self.shadowView.frame.origin.x;
    Y = CGRectGetMaxY(self.topTipLabel.frame);
    W = self.shadowView.frame.size.width;
    H = self.selectAllBtn.frame.origin.y - Y;
    self.tableView.frame = CGRectMake(X, Y, W, H);
    
    self.tipLabel.frame = CGRectMake(0, 0, self.shadowView.frame.size.width, 44);
    
    [self reloadListFrequently];
}
- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
}
- (void)didMoveToSuperview{
    [super didMoveToSuperview];
//    BOOL show = self.superview;
//    if (!show) return;
}

- (CGFloat)focusW{
    return 30.0;
}
- (CGFloat)minRevealW{
    return 0;
}
- (CGFloat)defaultPopW{
    return 200;
}
- (CGFloat)minPopW{
    return 0;
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
    CGFloat H = superH * 1.0;
    CGFloat Y = (superH - H) * 0.5;
    self.frame = CGRectMake(X, Y, W, H);
}
- (void)show{
    [ZHDPMg().window enableDebugPanel:NO];
    if ([self isShow]) {
        [ZHDPMg().window enableDebugPanel:YES];
        return;
    }
    
    CGFloat superW = self.list.bounds.size.width;
    CGFloat superH = self.list.bounds.size.height;
    
    CGFloat W = self.realW;
    CGFloat X = superW;
    CGFloat H = superH;
    CGFloat Y = (superH - H) * 0.5;
    CGRect startFrame = CGRectMake(X, Y, W, H);
    
    self.frame = startFrame;
    [self.list addSubview:self];
    [self reloadSecItems];
    
    [super show];
    [ZHDPMg() doAnimation:^{
        [self updateFrame];
    } completion:^(BOOL finished) {
        [ZHDPMg().window enableDebugPanel:YES];
    }];
}
- (void)hide{
    [ZHDPMg().window enableDebugPanel:NO];
    if (![self isShow]) {
        [ZHDPMg().window enableDebugPanel:YES];
        return;
    }
    
    [super hide];
    [ZHDPMg() doAnimation:^{
        [self updateFrame];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        [ZHDPMg().window enableDebugPanel:YES];
    }];
}
- (BOOL)allowMaskWhenShow{
    return YES;
}
- (void)reloadList{
    self.tableView.tableFooterView = (self.items.count <= 0 ? self.tipLabel : [UIView new]);
    [self.tableView reloadData];
}

#pragma mark - config

- (void)configData{
    [super configData];
}
- (void)configUI{
    [super configUI];
    [self addSubview:self.topTipLabel];
    [self addSubview:self.tableView];
    [self addSubview:self.selectAllBtn];
}

#pragma mark - data

- (void)reloadSecItems{
    NSArray <ZHDPListSecItem *> *secItems = [self.list fetchAllItems]?:@[];
    ZHDPAppItem *fundCliItem = nil;
    NSMutableArray *appIds = [NSMutableArray array];
    NSMutableArray *items = [NSMutableArray array];
    for (ZHDPListSecItem *secItem in secItems) {
        ZHDPAppItem *appItem = secItem.appDataItem.appItem;
        NSString *appId = appItem.appId;
        if (!appId || ![appId isKindOfClass:NSString.class] || appId.length == 0) {
            continue;
        }
        if ([appIds containsObject:appId]) continue;
        [appIds addObject:appId];
        if (appItem.isFundCli) {
            fundCliItem = appItem;
        }else{
            [items addObject:appItem];
        }
    }
    if (fundCliItem) {
        [items insertObject:fundCliItem atIndex:0];
    }
    // 修改了self.items要立即刷新
    self.items = items.copy;
    [self reloadListInstant];
}

#pragma mark - select

- (void)selectAppItem:(ZHDPAppItem *)item{
    self.selectItem = item;
    if (self.selectBlock) self.selectBlock(self.selectItem);
}

#pragma mark - click

- (void)selectAllBtnClick:(UIButton *)btn{
    [self selectAppItem:nil];
}

#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.items.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellID = [NSString stringWithFormat:@"%@_UITableViewCell", NSStringFromClass(self.class)];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        cell.clipsToBounds = YES;
        cell.backgroundColor = [UIColor clearColor];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.backgroundView = [UIView new];
        
        cell.textLabel.font = [ZHDPMg() defaultFont];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
    }
    ZHDPAppItem *appItem = self.items[indexPath.row];
    cell.textLabel.text = appItem.appName;
    
    NSString *appId = self.selectItem.appId;
    cell.textLabel.textColor = [appId isEqualToString:appItem.appId] ? [ZHDPMg() selectColor] : [ZHDPMg() defaultColor];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self selectAppItem:self.items[indexPath.row]];
}

#pragma mark - getter

- (UILabel *)topTipLabel {
    if (!_topTipLabel) {
        _topTipLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _topTipLabel.font = [ZHDPMg() defaultBoldFont];
        _topTipLabel.textAlignment = NSTextAlignmentCenter;
        _topTipLabel.text = @"筛选";
        _topTipLabel.textColor = [UIColor blackColor];
        _topTipLabel.backgroundColor = [UIColor clearColor];
        _topTipLabel.adjustsFontSizeToFitWidth = NO;
    }
    return _topTipLabel;
}
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        
        _tableView.directionalLockEnabled = YES;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        
        _tableView.layer.borderColor = [ZHDPMg() defaultLineColor].CGColor;
        _tableView.layer.borderWidth = [ZHDPMg() defaultLineW];
        
        _tableView.separatorInset = UIEdgeInsetsZero;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    return _tableView;
}
- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _tipLabel.font = [ZHDPMg() defaultFont];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.text = @"内容为空";
        _tipLabel.numberOfLines = 0;
        _tipLabel.textColor = [UIColor blackColor];
        _tipLabel.backgroundColor = [UIColor clearColor];
        _tipLabel.adjustsFontSizeToFitWidth = NO;
    }
    return _tipLabel;
}
- (UIButton *)selectAllBtn{
    if (!_selectAllBtn) {
        _selectAllBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        _selectAllBtn.backgroundColor = [UIColor clearColor];
        _selectAllBtn.titleLabel.font = [ZHDPMg() defaultBoldFont];
        _selectAllBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
        
        [_selectAllBtn setTitle:@"选择全部" forState:UIControlStateNormal];
        [_selectAllBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        [_selectAllBtn addTarget:self action:@selector(selectAllBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _selectAllBtn;
}

@end
