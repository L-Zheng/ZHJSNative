//
//  ZHDPList.h
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPComponent.h"
@class ZHDPListItem;// list数据
@class ZHDPListSecItem;// 每一组数据
@class ZHDPDataSpaceItem;// 数据存储容量

NS_ASSUME_NONNULL_BEGIN

@interface ZHDPList : ZHDPComponent
@property (nonatomic,strong) ZHDPListItem *item;

@property (nonatomic,retain) NSMutableArray <ZHDPListSecItem *> *items;
@property (nonatomic,strong) UITableView *tableView;

#pragma mark - search

- (void)showSearch;
- (BOOL)isShowSearch;
- (void)hideSearch;
- (void)resignFirstResponder;
- (BOOL)isFirstResponder;

#pragma mark - sub class

- (NSArray <ZHDPListSecItem *> *)fetchAllItems;

#pragma mark - reload

- (void)addSecItem:(ZHDPListSecItem *)item spaceItem:(ZHDPDataSpaceItem *)spaceItem;
- (void)removeSecItems:(NSArray <ZHDPListSecItem *> *)secItems;
- (void)removeSecItem:(ZHDPListSecItem *)secItem;
- (void)clearSecItems;
- (void)reloadListWhenShow;
- (void)reloadList;
- (void)scrollListToBottomCode;
- (void)scrollListToTopCode;
@end

NS_ASSUME_NONNULL_END
