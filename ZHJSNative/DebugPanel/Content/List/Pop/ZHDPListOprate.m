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

@interface ZHDPListOprateCollectionViewCell()
@property (nonatomic,strong) UIView *selectView;
@property (nonatomic, strong) UILabel *iconLabel;
@property (nonatomic, strong) UILabel *descLabel;
@end

@implementation ZHDPListOprateCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configNormalStyle];
        
        self.selectedBackgroundView = self.selectView;
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

- (void)setSelected:(BOOL)selected{
    [super setSelected:selected];
    (selected ? [self configHighlightStyle] : [self configNormalStyle]);
}
- (void)configNormalStyle{
    self.contentView.backgroundColor = [UIColor clearColor];
//    cell.contentView.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255.0)/255.0 green:arc4random_uniform(255.0)/255.0 blue:arc4random_uniform(255.0)/255.0 alpha:0.5];
}
- (void)configHighlightStyle{
    self.contentView.backgroundColor = [UIColor lightGrayColor];
}

- (UIView *)selectView{
    if (!_selectView) {
        _selectView = [[UIView alloc] initWithFrame:CGRectZero];
        _selectView.clipsToBounds = YES;
    }
    return _selectView;
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


@interface ZHDPListOprate ()<UICollectionViewDataSource,UICollectionViewDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
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

    CGFloat W = ([self minPopW] - [self focusW]) * 0.5;
    CGFloat H = W;
    UICollectionViewLayout *layout = self.collectionView.collectionViewLayout;
    if ([layout isKindOfClass:UICollectionViewFlowLayout.class]) {
        ((UICollectionViewFlowLayout *)layout).itemSize = CGSizeMake(W, H);
    }
    self.collectionView.frame = self.shadowView.frame;
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
    return 100 + [self focusW];
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
    [self.collectionView reloadData];
}

#pragma mark - config

- (void)configData{
    [super configData];
}
- (void)configUI{
    [super configUI];
    [self addSubview:self.collectionView];
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

#pragma mark - UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ZHDPListOprateCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.collectionCellIdentifier forIndexPath:indexPath];
    [cell configItem:self.items[indexPath.row]];
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    void (^block) (void) = self.items[indexPath.row].block;
    if (block) block();
}
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}
- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath{
    ZHDPListOprateCollectionViewCell *cell = (ZHDPListOprateCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell configHighlightStyle];
}
- (void)collectionView:(UICollectionView *)collectionView  didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath{
    ZHDPListOprateCollectionViewCell *cell = (ZHDPListOprateCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell configNormalStyle];
}

#pragma mark - getter

- (UICollectionView *)collectionView{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 0;// 横向间距
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
                
//        [Assert] negative or zero item sizes are not supported in the flow layout
        layout.itemSize = CGSizeMake(1, 1);
        
        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
        
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.showsVerticalScrollIndicator = YES;
        _collectionView.alwaysBounceHorizontal = NO;
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.directionalLockEnabled = YES;
        
        [_collectionView registerClass:[ZHDPListOprateCollectionViewCell class] forCellWithReuseIdentifier:self.collectionCellIdentifier];
    }
    return _collectionView;
}
- (NSString *)collectionCellIdentifier{
    return [NSString stringWithFormat:@"%@_CollectionViewCell", NSStringFromClass(self.class)];
}

@end
