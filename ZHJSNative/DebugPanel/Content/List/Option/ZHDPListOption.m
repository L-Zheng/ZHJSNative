//
//  ZHDPListOption.m
//  ZHJSNative
//
//  Created by EM on 2021/6/17.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListOption.h"
#import "ZHDPManager.h"// 调试面板管理

@interface ZHDPListOption ()<UICollectionViewDataSource,UICollectionViewDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic,retain) NSArray <ZHDPListOprateItem *> *items;
@end

@implementation ZHDPListOption

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
    
    CGFloat W = self.bounds.size.width * 1.0 / 7.0;
    CGFloat H = self.bounds.size.height;
    UICollectionViewLayout *layout = self.collectionView.collectionViewLayout;
    if ([layout isKindOfClass:UICollectionViewFlowLayout.class]) {
        ((UICollectionViewFlowLayout *)layout).itemSize = CGSizeMake(W, H);
    }
    self.collectionView.frame = self.bounds;
    [self reloadCollectionViewFrequently];
}
- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
//    BOOL show = self.superview;
}
- (void)didMoveToSuperview{
    [super didMoveToSuperview];
}

#pragma mark - config

- (void)configData{
}
- (void)configUI{
    self.backgroundColor = [ZHDPMg() bgColor];
    [self addSubview:self.collectionView];
}

#pragma mark - reload

- (void)reloadCollectionViewFrequently{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadCollectionView) object:nil];
    [self performSelector:@selector(reloadCollectionView) withObject:nil afterDelay:0.3];
}
- (void)reloadCollectionView{
    [self.collectionView reloadData];
}
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
    [self reloadCollectionViewFrequently];
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
    [cell configTitleHideEnable:YES];
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
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
                
//        [Assert] negative or zero item sizes are not supported in the flow layout
        layout.itemSize = CGSizeMake(1, 1);
        
        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
        
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.alwaysBounceHorizontal = YES;
        _collectionView.alwaysBounceVertical = NO;
        _collectionView.directionalLockEnabled = YES;
        _collectionView.pagingEnabled = YES;
        
        [_collectionView registerClass:[ZHDPListOprateCollectionViewCell class] forCellWithReuseIdentifier:self.collectionCellIdentifier];
    }
    return _collectionView;
}
- (NSString *)collectionCellIdentifier{
    return [NSString stringWithFormat:@"%@_CollectionViewCell", NSStringFromClass(self.class)];
}
@end
