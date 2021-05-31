//
//  ZHDPOption.m
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPOption.h"
#import "ZHDebugPanel.h"
#import "ZHDPManager.h"

@implementation ZHDPOptionItem

@end

@interface ZHDPOption ()<UICollectionViewDataSource,UICollectionViewDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) UIPanGestureRecognizer *panGes;
@property (nonatomic, assign) CGPoint gesStartPoint;
@property (nonatomic, assign) CGRect gesStartFrame;
@end

@implementation ZHDPOption

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
    
    UICollectionViewLayout *layout = self.collectionView.collectionViewLayout;
    if ([layout isKindOfClass:UICollectionViewFlowLayout.class]) {
        ((UICollectionViewFlowLayout *)layout).itemSize = CGSizeMake(70, self.bounds.size.height);
    }
    self.collectionView.frame = self.bounds;
    
    [self reloadCollectionViewFrequently];
}

#pragma mark - config

- (void)configData{
}
- (void)configUI{
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor clearColor];
    [self addGesture];
    
    [self addSubview:self.collectionView];
}

#pragma mark - gesture

- (void)addGesture{
    self.panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    [self addGestureRecognizer:self.panGes];
}
- (void)panGesture:(UIPanGestureRecognizer *)panGes{
    UIView *superview = self.debugPanel.superview;
    CGFloat superW = superview.frame.size.width;
    CGFloat superH = superview.frame.size.height;
    
    if (panGes.state == UIGestureRecognizerStateBegan) {
        self.gesStartPoint = [panGes locationInView:superview];
        self.gesStartFrame = self.debugPanel.frame;
    } else if (panGes.state == UIGestureRecognizerStateChanged){

//        CGPoint velocity = [panGes velocityInView:superview];
        CGPoint p = [panGes locationInView:superview];
//        CGFloat offsetX = p.x - self.gesStartPoint.x;
        CGFloat offSetY = p.y - self.gesStartPoint.y;
        
        CGFloat X = self.gesStartFrame.origin.x;
        CGFloat Y = self.gesStartFrame.origin.y + offSetY;
        CGFloat W = self.gesStartFrame.size.width;
        CGFloat H = self.gesStartFrame.size.height - offSetY;
        
        [ZHDPMg().window updateDebugPanelFrame:CGRectMake(X, Y, W, H)];
        
    } else if (panGes.state == UIGestureRecognizerStateEnded ||
               panGes.state == UIGestureRecognizerStateCancelled ||
               panGes.state == UIGestureRecognizerStateFailed){
    }
}

#pragma mark - relaod

- (void)reloadCollectionViewFrequently{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadCollectionView) object:nil];
    [self performSelector:@selector(reloadCollectionView) withObject:nil afterDelay:0.3];
}
- (void)reloadCollectionView{
    [self.collectionView reloadData];
}
- (void)reloadWithItems:(NSArray <ZHDPOptionItem *> *)items{
    if (!items || ![items isKindOfClass:NSArray.class] || items.count == 0) {
        return;
    }
    for (id item in items) {
        if (![item isKindOfClass:ZHDPOptionItem.class]) {
            return;
        }
    }
    self.items = items.copy;
    [self reloadCollectionView];
}

#pragma mark - select

- (void)selectItem:(ZHDPOptionItem *)item{
    if (![self.items containsObject:item]) return;
    NSUInteger idx = [self.items indexOfObject:item];
    [self selectIndexPath:[NSIndexPath indexPathForItem:idx inSection:0]];
}
- (void)selectIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.item >= self.items.count) return;
    
    for (NSUInteger i = 0; i < self.items.count; i++) {
        self.items[i].selected = (indexPath.item == i ? YES : NO);
    }
    self.selectItem = self.items[indexPath.item];
    if (self.selectBlock) self.selectBlock(indexPath, self.selectItem);
    [self reloadCollectionView];
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
    cell.contentView.backgroundColor = [UIColor clearColor];
//    cell.contentView.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255.0)/255.0 green:arc4random_uniform(255.0)/255.0 blue:arc4random_uniform(255.0)/255.0 alpha:0.5];
    UILabel *label = [cell viewWithTag:999];
    if (!label) {
        label = [[UILabel alloc] initWithFrame:cell.bounds];
        label.tag = 999;
        label.textAlignment = NSTextAlignmentCenter;
        label.adjustsFontSizeToFitWidth = YES;
        [cell addSubview:label];
    }
    ZHDPOptionItem *item = self.items[indexPath.item];
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
        layout.minimumLineSpacing = 0;// 横向间距
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

@end
