//
//  ZHDPList.h
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPComponent.h"
@class ZHDPListItem;
@class ZHDPListSecItem;
@class ZHDPDataSpaceItem;

NS_ASSUME_NONNULL_BEGIN

@interface ZHDPList : ZHDPComponent
@property (nonatomic,strong) ZHDPListItem *item;

@property (nonatomic,strong) UITableView *tableView;

#pragma mark - search

- (void)showSearch;
- (void)hideSearch;

#pragma mark - sub class

- (NSArray <ZHDPListSecItem *> *)fetchAllItems;

#pragma mark - reload

- (void)addSecItem:(ZHDPListSecItem *)item spaceItem:(ZHDPDataSpaceItem *)spaceItem;
- (void)reloadListWhenShow;
- (void)reloadList;
- (void)scrollListToBottomCode;
- (void)scrollListToTopCode;
@end

NS_ASSUME_NONNULL_END
