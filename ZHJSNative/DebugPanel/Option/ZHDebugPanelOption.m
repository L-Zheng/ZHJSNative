//
//  ZHDebugPanelOption.m
//  ZHJSNative
//
//  Created by Zheng on 2021/4/17.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDebugPanelOption.h"
#import "ZHDebugPanelContent.h"

@interface ZHDebugPanelOption ()<UICollectionViewDataSource,UICollectionViewDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic,retain) NSMutableArray *items;
@end

@implementation ZHDebugPanelOption

#pragma mark - init

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configData];
        [self configUI];
    }
    return self;
}

#pragma mark - config

- (void)reloadWithItems:(NSArray *)items{
    if (self.items) return;
    
    self.items = [NSMutableArray array];
    
    __weak __typeof__(self) weakSelf = self;
    for (NSUInteger i = 0; i < items.count; i++) {
        ZHDebugPanelContent *content = items[i];
        [self.items addObject:@{
            @"title": [content titleName]?:@"",
            @"select": i == 0 ? @(YES) : @(NO),
            @"content": content,
            @"block": ^(ZHDebugPanelContent *content){
                if (weakSelf.selectBlock) {
                    weakSelf.selectBlock(content);
                }
            }
        }.mutableCopy];
    }
    
    [self.collectionView reloadData];
}


- (void)selectContent:(ZHDebugPanelContent *)content{
    NSInteger findIndex = NSNotFound;
    for (NSUInteger i = 0; i < self.items.count; i++) {
        NSMutableDictionary *item = self.items[i];
        if ([item[@"content"] isEqual:content]) {
            findIndex = i;
            break;
        }
    }
    if (findIndex == NSNotFound) {
        return;
    }
    [self selectIndexPath:[NSIndexPath indexPathForItem:findIndex inSection:0]];
}

- (void)selectIndexPath:(NSIndexPath *)indexPath{
    for (NSUInteger i = 0; i < self.items.count; i++) {
        NSMutableDictionary *item = self.items[i];
        BOOL select = (indexPath.item == i ? YES : NO);
        [item setObject:@(select) forKey:@"select"];
    }
    NSDictionary *selectItem = self.items[indexPath.item];
    void (^block) (ZHDebugPanelContent *content) = [selectItem objectForKey:@"block"];
    if (block) block(selectItem[@"content"]);
    
    [self.collectionView reloadData];
}

- (void)configData{
}

- (void)configUI{
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor orangeColor];
    
    [self addSubview:self.collectionView];
}

#pragma mark - layout

- (void)layoutSubviews{
    [super layoutSubviews];
    
    UICollectionViewLayout *layout = self.collectionView.collectionViewLayout;
    if ([layout isKindOfClass:UICollectionViewFlowLayout.class]) {
        ((UICollectionViewFlowLayout *)layout).itemSize = CGSizeMake(70, self.bounds.size.height);
    }
    self.collectionView.frame = self.bounds;
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[NSString stringWithFormat:@"%@_CollectionViewCell", NSStringFromClass(self.class)] forIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255.0)/255.0 green:arc4random_uniform(255.0)/255.0 blue:arc4random_uniform(255.0)/255.0 alpha:0.5];
    UILabel *label = [cell viewWithTag:999];
    if (!label) {
        label = [[UILabel alloc] initWithFrame:cell.bounds];
        label.tag = 999;
        label.textAlignment = NSTextAlignmentCenter;
        label.adjustsFontSizeToFitWidth = YES;
        [cell addSubview:label];
    }
    NSDictionary *item = self.items[indexPath.item];
    label.text = [NSString stringWithFormat:@"%@_%ld", [item objectForKey:@"title"], indexPath.item];
    label.backgroundColor = [(NSNumber *)item[@"select"] boolValue] ? [UIColor blueColor] : [UIColor clearColor];
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
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
        
        [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:[NSString stringWithFormat:@"%@_CollectionViewCell", NSStringFromClass(self.class)]];
    }
    return _collectionView;
}

@end
