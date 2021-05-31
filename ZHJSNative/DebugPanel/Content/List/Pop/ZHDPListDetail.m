//
//  ZHDPListDetail.m
//  ZHJSNative
//
//  Created by EM on 2021/5/29.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListDetail.h"
#import "ZHDPList.h"
#import "ZHDPManager.h"

@interface ZHDPListDetail ()<UICollectionViewDataSource,UICollectionViewDelegate>
@property (nonatomic, retain) NSArray <ZHDPListDetailItem *> *items;
@property (nonatomic,strong) UIView *contentView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic,strong) UIView *line;
@property (nonatomic,strong) UITextView *textView;
@end

@implementation ZHDPListDetail

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

    self.contentView.frame = self.shadowView.frame;
    
    CGFloat X = 0;
    CGFloat W = self.contentView.frame.size.width - X;
    CGFloat H = 30;
    CGFloat Y = 0;
    UICollectionViewLayout *layout = self.collectionView.collectionViewLayout;
    if ([layout isKindOfClass:UICollectionViewFlowLayout.class]) {
        ((UICollectionViewFlowLayout *)layout).itemSize = CGSizeMake(70, H);
    }
    self.collectionView.frame = CGRectMake(X, Y, W, H);
    
    X = 0;
    W = self.contentView.frame.size.width;
    H = 0.5;
    Y = CGRectGetMaxY(self.collectionView.frame);
    self.line.frame = CGRectMake(X, Y, W, H);
    
    X = 0;
    W = self.contentView.frame.size.width;
    Y = CGRectGetMaxY(self.line.frame);
    H = self.contentView.frame.size.height - Y;
    self.textView.frame = CGRectMake(X, Y, W, H);
    
    [self reloadListFrequently];
}
- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
}
- (void)didMoveToSuperview{
    [super didMoveToSuperview];
}
- (CGFloat)focusW{
    return 30.0;
}
- (CGFloat)minRevealW{
    return 0;
}
- (CGFloat)defaultPopW{
    return 300;
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
- (void)showWithSecItem:(ZHDPListSecItem *)secItem{
    if ([self isShow]) {
        if (![self.secItem isEqual:secItem]) {
            [self reloadWithSecItem:secItem];
        }
        return;
    }
    
    CGFloat superW = self.list.bounds.size.width;
    CGFloat superH = self.list.bounds.size.height;
    
    CGFloat W = superW * 0.8;
    CGFloat X = superW;
    CGFloat H = superH;
    CGFloat Y = (superH - H) * 0.5;
    CGRect startFrame = CGRectMake(X, Y, W, H);
    self.frame = startFrame;
    [self.list addSubview:self];
    [self reloadWithSecItem:secItem];
    
    [super show];
    [self doAnimation:^{
        [self updateFrame];
    } completion:^(BOOL finished) {
    }];
}
- (void)hide{
    if (![self isShow]) return;
    
    [super hide];
    [self doAnimation:^{
        [self updateFrame];
    } completion:^(BOOL finished) {
        self.secItem = nil;
        [self removeFromSuperview];
    }];
}
- (BOOL)allowMaskWhenShow{
    return NO;
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
    [self addSubview:self.contentView];
    [self.contentView addSubview:self.collectionView];
    [self.contentView addSubview:self.line];
    [self.contentView addSubview:self.textView];
}

#pragma mark - relaod

- (void)reloadWithSecItem:(ZHDPListSecItem *)secItem{
    self.secItem = secItem;
    NSArray <ZHDPListDetailItem *> *items = secItem.detailItems;
    if (!items || ![items isKindOfClass:NSArray.class] || items.count == 0) {
        return;
    }
    for (id item in items) {
        if (![item isKindOfClass:ZHDPListDetailItem.class]) {
            return;
        }
    }
    self.items = items.copy;
    
    [self selectItem:items.firstObject];
}

#pragma mark - select

- (void)selectItem:(ZHDPListDetailItem *)item{
    if (![self.items containsObject:item]) return;
    NSUInteger idx = [self.items indexOfObject:item];
    [self selectIndexPath:[NSIndexPath indexPathForItem:idx inSection:0]];
}
- (void)selectIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.item >= self.items.count) return;
    
    for (NSUInteger i = 0; i < self.items.count; i++) {
        self.items[i].selected = (indexPath.item == i ? YES : NO);
    }
    [self reloadListFrequently];
    self.textView.text = self.items[indexPath.item].content;
}

#pragma mark - UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.collectionCellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    UILabel *label = [cell viewWithTag:999];
    if (!label) {
        label = [[UILabel alloc] initWithFrame:cell.bounds];
        label.tag = 999;
        label.textAlignment = NSTextAlignmentCenter;
        label.adjustsFontSizeToFitWidth = YES;
        [cell addSubview:label];
    }
    ZHDPListDetailItem *item = self.items[indexPath.item];
    label.text = [NSString stringWithFormat:@"%@", item.title];
    label.textColor = item.isSelected ? [ZHDPMg() selectColor] : [ZHDPMg() defaultColor];
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    [self selectIndexPath:indexPath];
}

#pragma mark - getter

- (UICollectionView *)collectionView{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 5;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
                
//        [Assert] negative or zero item sizes are not supported in the flow layout
        layout.itemSize = CGSizeMake(1, 1);
        
        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
        
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        
        _collectionView.showsHorizontalScrollIndicator = YES;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.alwaysBounceHorizontal = YES;
        _collectionView.directionalLockEnabled = YES;
        
        [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:self.collectionCellIdentifier];
    }
    return _collectionView;
}
- (NSString *)collectionCellIdentifier{
    return [NSString stringWithFormat:@"%@_CollectionViewCell", NSStringFromClass(self.class)];
}
- (UIView *)contentView{
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectZero];
        _contentView.backgroundColor = [UIColor whiteColor];
        _contentView.clipsToBounds = YES;
    }
    return _contentView;
}
- (UIView *)line{
    if (!_line) {
        _line = [[UIView alloc] initWithFrame:CGRectZero];
        _line.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
    }
    return _line;
}
- (UITextView *)textView{
    if (!_textView) {
        _textView = [[UITextView alloc] initWithFrame:CGRectZero];
        _textView.font = [UIFont systemFontOfSize:13];
        _textView.editable = NO;
    }
    return _textView;
}

@end
