//
//  ZHDPDataTask.m
//  ZHJSNative
//
//  Created by EM on 2021/5/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPDataTask.h"

// list操作栏数据
@implementation ZHDPListOprateItem
@end

// 描述list的信息
@implementation ZHDPListItem
+ (instancetype)itemWithTitle:(NSString *)title{
    ZHDPListItem *item = [[ZHDPListItem alloc] init];
    item.title = title;
    return item;
}
+ (CGFloat)maxHeightByColItems:(NSArray<ZHDPListColItem *> *)colItems{
    CGFloat res = 0;
    for (ZHDPListColItem *colItem in colItems) {
        CGFloat h = colItem.rectValue.CGRectValue.size.height;
        if (res < h) res = h;
    }
    return res;
}
@end

// list中每一行中每一分段的信息
@implementation ZHDPListColItem
- (UIFont *)font{
    return _font?:[UIFont systemFontOfSize:17];
}
@end

// list中每一行的信息
@implementation ZHDPListRowItem
- (void)setColItems:(NSArray<ZHDPListColItem *> *)colItems{
    _colItems = colItems.copy;
    self.rowH = [ZHDPListItem maxHeightByColItems:_colItems];
}
@end

// list选中某一组显示的详细信息
@implementation ZHDPListDetailItem
@end

// list中每一组的信息
@implementation ZHDPListSecItem
- (void)setColItems:(NSArray<ZHDPListColItem *> *)colItems{
    _colItems = colItems.copy;
    self.headerH = [ZHDPListItem maxHeightByColItems:_colItems];
}
@end

// 某种类型数据的存储最大容量
@implementation ZHDPDataSpaceItem
@end

// 单个应用的简要信息
@implementation ZHDPAppItem

@end

// 单个应用的数据
@implementation ZHDPAppDataItem
- (ZHDPDataSpaceItem *)logSpaceItem{
    if (!_logSpaceItem) {
        ZHDPDataSpaceItem *item = [[ZHDPDataSpaceItem alloc] init];
        item.count = 100;
        item.removePercent = 0.5;
        _logSpaceItem = item;
    }
    return _logSpaceItem;
}
- (NSMutableArray<ZHDPListSecItem *> *)logItems{
    if (!_logItems) _logItems = [NSMutableArray array];
    return _logItems;
}
- (ZHDPDataSpaceItem *)networkSpaceItem{
    if (!_networkSpaceItem) {
        ZHDPDataSpaceItem *item = [[ZHDPDataSpaceItem alloc] init];
        item.count = 100;
        item.removePercent = 0.5;
        _networkSpaceItem = item;
    }
    return _networkSpaceItem;
}
- (NSMutableArray<ZHDPListSecItem *> *)networkItems{
    if (!_networkItems) _networkItems = [NSMutableArray array];
    return _networkItems;
}
- (ZHDPDataSpaceItem *)imSpaceItem{
    if (!_imSpaceItem) {
        ZHDPDataSpaceItem *item = [[ZHDPDataSpaceItem alloc] init];
        item.count = 50;
        item.removePercent = 0.5;
        _imSpaceItem = item;
    }
    return _imSpaceItem;
}
- (NSMutableArray<ZHDPListSecItem *> *)imItems{
    if (!_imItems) _imItems = [NSMutableArray array];
    return _imItems;
}
- (ZHDPDataSpaceItem *)storageSpaceItem{
    if (!_storageSpaceItem) {
        ZHDPDataSpaceItem *item = [[ZHDPDataSpaceItem alloc] init];
        item.count = 100;
        item.removePercent = 0.5;
        _storageSpaceItem = item;
    }
    return _storageSpaceItem;
}
- (NSMutableArray<ZHDPListSecItem *> *)storageItems{
    if (!_storageItems) _storageItems = [NSMutableArray array];
    return _storageItems;
}
@end


// 数据管理
@implementation ZHDPDataTask

// 查找所有应用的数据
- (NSArray <ZHDPAppDataItem *> *)fetchAllAppDataItems{
    return [self.appDataMap allValues].copy;
}
- (NSArray <ZHDPListSecItem *> *)fetchAllAppDataItems_module:(NSArray * (^) (ZHDPAppDataItem *appDataItem))block{
    if (!block) return nil;
    
    NSMutableArray *res = [NSMutableArray array];
    NSArray <ZHDPAppDataItem *> *appDataItems = [self fetchAllAppDataItems];
    for (ZHDPAppDataItem *appDataItem in appDataItems) {
        [res addObjectsFromArray:block(appDataItem)];
    }
    // 按照进入内存的时间 升序排列
    [res sortUsingComparator:^NSComparisonResult(ZHDPListSecItem *obj1, ZHDPListSecItem  *obj2) {
        if (obj1.enterMemoryTime > obj2.enterMemoryTime) {
            return NSOrderedDescending;
        }else if (obj1.enterMemoryTime < obj2.enterMemoryTime){
            return NSOrderedAscending;
        }
        return NSOrderedSame;
    }];
    return res.copy;
}
- (NSArray <ZHDPListSecItem *> *)fetchAllAppDataItems_log{
    return [self fetchAllAppDataItems_module:^NSArray *(ZHDPAppDataItem *appDataItem) {
        return appDataItem.logItems.copy;
    }];
}
- (NSArray <ZHDPListSecItem *> *)fetchAllAppDataItems_network{
    return [self fetchAllAppDataItems_module:^NSArray *(ZHDPAppDataItem *appDataItem) {
        return appDataItem.networkItems.copy;
    }];
}
- (NSArray <ZHDPListSecItem *> *)fetchAllAppDataItems_im{
    return [self fetchAllAppDataItems_module:^NSArray *(ZHDPAppDataItem *appDataItem) {
        return appDataItem.imItems.copy;
    }];
}
- (NSArray <ZHDPListSecItem *> *)fetchAllAppDataItems_storage{
    return [self fetchAllAppDataItems_module:^NSArray *(ZHDPAppDataItem *appDataItem) {
        return appDataItem.storageItems.copy;
    }];
}

// 查找某个应用的数据
- (ZHDPAppDataItem *)fetchAppDataItem:(ZHDPAppItem *)appItem{
    NSString *appId = appItem.appId;
    if (!appId || ![appId isKindOfClass:NSString.class] || appId.length == 0) {
        return nil;
    }
    ZHDPAppDataItem *item = [self.appDataMap objectForKey:appId];
    if (!item) {
        item = [[ZHDPAppDataItem alloc] init];
        item.appItem = appItem;
        [self.appDataMap setObject:item forKey:appId];
    }
    return item;
}


// 清理并添加数据
- (void)cleanItems:(NSMutableArray *)items spaceItem:(ZHDPDataSpaceItem *)spaceItem{
    if (!items) return;
    
    CGFloat limit = spaceItem.count;
    CGFloat removePercent = spaceItem.removePercent;
    
    if (items.count <= limit) return;
    
    NSInteger removeCount = floorf(items.count * removePercent);
    if (removeCount < 0) removeCount = 0;
    
    if (removeCount >= items.count) return;
    
    [items removeObjectsInRange:NSMakeRange(0, removeCount)];
}
- (void)addItem:(NSMutableArray *)items item:(ZHDPListSecItem *)item{
    if (!items || !item) return;
    [items addObject:item];
}
- (void)addAndCleanItems:(NSMutableArray *)items item:(ZHDPListSecItem *)item spaceItem:(ZHDPDataSpaceItem *)spaceItem{
    [self addItem:items item:item];
    [self cleanItems:items spaceItem:spaceItem];
}

// 映射表
- (NSMutableDictionary *)appDataMap{
    if (!_appDataMap) {
        _appDataMap = [NSMutableDictionary dictionary];
    }
    return _appDataMap;
}

@end
