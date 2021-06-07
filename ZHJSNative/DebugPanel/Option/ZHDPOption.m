//
//  ZHDPOption.m
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPOption.h"
#import "ZHDebugPanel.h"// 调试面板
#import "ZHDPManager.h"// 调试面板管理

@implementation ZHDPOptionItem

@end

@interface ZHDPOptionCollectionViewCell()
@property (nonatomic, strong) UILabel *label;
@property (nonatomic,strong) UIView *line;
@end
@implementation ZHDPOptionCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
    //    cell.contentView.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255.0)/255.0 green:arc4random_uniform(255.0)/255.0 blue:arc4random_uniform(255.0)/255.0 alpha:0.5];
        
        [self.contentView addSubview:self.label];
        [self.contentView addSubview:self.line];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.label.frame = self.contentView.bounds;
    
    CGFloat W = 1.0 / UIScreen.mainScreen.scale;
    CGFloat H = self.bounds.size.height;
    CGFloat X = self.bounds.size.width - W;
    CGFloat Y = 0;
    self.line.frame = CGRectMake(X, Y, W, H);
}

- (void)configItem:(ZHDPOptionItem *)item{
    self.label.text = [NSString stringWithFormat:@"%@", item.title];
    self.label.textColor = item.isSelected ? [ZHDPMg() selectColor] : [ZHDPMg() defaultColor];
    self.label.backgroundColor = item.isSelected ? [UIColor whiteColor] : [UIColor clearColor];
}

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.textAlignment = NSTextAlignmentCenter;
    }
    return _label;
}
- (UIView *)line{
    if (!_line) {
        _line = [[UIView alloc] initWithFrame:CGRectZero];
        _line.backgroundColor = [ZHDPMg() defaultLineColor];
    }
    return _line;
}

@end

@interface ZHDPOption ()<UICollectionViewDataSource,UICollectionViewDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic,strong) UIView *line;

@property (nonatomic,strong) UIButton *hideBtn;

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
    
    CGFloat W = 30;
    CGFloat H = self.bounds.size.height;
    CGFloat Y = 0;
    CGFloat X = self.bounds.size.width - W;
    self.hideBtn.frame = CGRectMake(X, Y, W, H);
    
    X = 0;
    Y = 0;
    W = self.hideBtn.frame.origin.x - X;
    H = self.bounds.size.height;
    UICollectionViewLayout *layout = self.collectionView.collectionViewLayout;
    if ([layout isKindOfClass:UICollectionViewFlowLayout.class]) {
        ((UICollectionViewFlowLayout *)layout).itemSize = CGSizeMake(80, H);
    }
    self.collectionView.frame = CGRectMake(X, Y, W, H);
    
    X = 0;
    W = self.bounds.size.width;
    H = [ZHDPMg() defaultLineW];
    Y = self.bounds.size.height - H;
    self.line.frame = CGRectMake(X, Y, W, H);

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
    [self addSubview:self.line];
    [self addSubview:self.hideBtn];
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

#pragma mark - click

- (void)hideBtnClick:(UIButton *)btn{
    [ZHDPMg() switchFloat];
}

#pragma mark - UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ZHDPOptionCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.collectionCellIdentifier forIndexPath:indexPath];
    ZHDPOptionItem *item = self.items[indexPath.item];
    [cell configItem:item];
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
        
        [_collectionView registerClass:[ZHDPOptionCollectionViewCell class] forCellWithReuseIdentifier:self.collectionCellIdentifier];
    }
    return _collectionView;
}
- (NSString *)collectionCellIdentifier{
    return [NSString stringWithFormat:@"%@_CollectionViewCell", NSStringFromClass(self.class)];
}
- (UIView *)line{
    if (!_line) {
        _line = [[UIView alloc] initWithFrame:CGRectZero];
        _line.backgroundColor = [ZHDPMg() defaultLineColor];
    }
    return _line;
}
- (UIButton *)hideBtn{
    if (!_hideBtn) {
        _hideBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        _hideBtn.titleLabel.font = [ZHDPMg() iconFontWithSize:20];
        
        [_hideBtn setTitle:@"\ue60a" forState:UIControlStateNormal];
        [_hideBtn setTitleColor:[ZHDPMg() defaultColor] forState:UIControlStateNormal];
        
        [_hideBtn addTarget:self action:@selector(hideBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _hideBtn;
}

@end
