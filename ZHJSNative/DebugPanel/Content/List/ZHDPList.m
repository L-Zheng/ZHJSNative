//
//  ZHDPList.m
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPList.h"
#import "ZHDPListCell.h"// list cell
#import "ZHDPListHeader.h"// list header
#import "ZHDPManager.h"// 调试面板管理
#import "ZHDPListOprate.h"// pop操作栏
#import "ZHDPListSearch.h"// 搜索
#import "ZHDPListApps.h"// pop app列表
#import "ZHDPListDetail.h"// pop detail数据

typedef NS_ENUM(NSInteger, ZHDPScrollStatus) {
    ZHDPScrollStatus_Idle      = 0,//闲置
    ZHDPScrollStatus_Dragging      = 1,//拖拽中
    ZHDPScrollStatus_DraggingDecelerate      = 2,//拖拽后减速
};

@interface ZHDPList () <UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,retain) NSMutableArray *items_temp;

@property (nonatomic,assign) ZHDPScrollStatus scrollStatus;
@property (nonatomic,assign) BOOL allowScrollAuto;

@property (nonatomic,strong) ZHDPListSearch *search;
@property (nonatomic,assign) CGFloat searchH;

@property (nonatomic,strong) ZHDPListOprate *oprate;

@property (nonatomic,strong) ZHDPListApps *apps;

@property (nonatomic,strong) ZHDPListDetail *detail;
@end

@implementation ZHDPList

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

    [self updateSearchFrame];
    [self.oprate updateFrame];
    [self.apps updateFrame];
    [self.detail updateFrame];
}
- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
}
- (void)didMoveToSuperview{
    [super didMoveToSuperview];
    BOOL show = self.superview;
    if (!show) return;
    [self reloadListWhenShow];
}

#pragma mark - config

- (void)configData{
    self.allowScrollAuto = YES;
    self.searchH = 0;
}
- (void)configUI{
    self.clipsToBounds = YES;
    
    [self addSubview:self.search];
    
    [self addSubview:self.tableView];
    
    [self addSubview:self.oprate];
    [self relaodOprate];
}
- (void)configScrollAuto{
    CGFloat listH = self.tableView.frame.size.height;
    CGFloat listOffSetY = self.tableView.contentOffset.y;
    CGFloat listContentH = self.tableView.contentSize.height;
    
    if (listContentH <= 0 || listH <= 0) {
        self.allowScrollAuto = YES;
        [self scrollListToBottom:NO];
        return;
    }
    if (listContentH < listH) {
        self.allowScrollAuto = YES;
        [self scrollListToBottom:NO];
        return;
    }
    if (listOffSetY >= listContentH - listH - 10) {
        self.allowScrollAuto = YES;
        [self scrollListToBottom:NO];
        return;
    }
    self.allowScrollAuto = NO;
}

#pragma mark - search

- (void)updateSearchFrame{
    CGFloat h = self.searchH;
    self.search.frame = CGRectMake(0, 0, self.bounds.size.width, h);
    self.tableView.frame = CGRectMake(0, h, self.bounds.size.width, self.bounds.size.height - h);
}
- (BOOL)verifyFilterCondition:(ZHDPListSecItem *)secItem{
    if (!secItem || ![secItem isKindOfClass:ZHDPListSecItem.class]) {
        return NO;
    }
    
    // 筛选appId
    ZHDPAppItem *selectAppItem = self.apps.selectItem;
    ZHDPAppItem *cAppItem = secItem.appDataItem.appItem;
    if (selectAppItem && cAppItem) {
        if (![selectAppItem.appId isEqualToString:cAppItem.appId]) {
            return NO;
        }
    }
    
    // 筛选搜索关键字
    NSString *keyword = self.search.keyWord;
    if (!keyword || ![keyword isKindOfClass:NSString.class] || keyword.length == 0) {
        return YES;
    }
    // 搜索某一组
    NSArray <ZHDPListColItem *> *colItems = secItem.colItems.copy;
    for (ZHDPListColItem *colItem in colItems) {
        if ([colItem.attTitle.string.lowercaseString containsString:keyword.lowercaseString]) {
            return YES;
        }
    }
    // 搜索某一行
    NSArray <ZHDPListRowItem *> *rowItems = secItem.rowItems.copy;
    for (ZHDPListRowItem *rowItem in rowItems) {
        colItems = rowItem.colItems.copy;
        for (ZHDPListColItem *colItem in colItems) {
            if ([colItem.attTitle.string.lowercaseString containsString:keyword.lowercaseString]) {
                return YES;
            }
        }
    }
    
    return NO;
}
- (NSArray <ZHDPListSecItem *> *)filterItems:(NSArray <ZHDPListSecItem *> *)items{
    if (!items || ![items isKindOfClass:NSArray.class] || items.count == 0) {
        return nil;
    }
    
    NSMutableArray <ZHDPListSecItem *> *searchItems = [NSMutableArray array];
    
    NSArray <ZHDPListSecItem *> *newItems = items.copy;
    for (ZHDPListSecItem *secItem in newItems) {
        if (![self verifyFilterCondition:secItem]) continue;
        [searchItems addObject:secItem];
    }
    
    return searchItems.copy;
}
- (void)showSearch{
    if (self.search.frame.size.height > 0) {
        return;
    }
    [UIView animateWithDuration:0.25 animations:^{
        self.searchH = 40;
        [self updateSearchFrame];
    } completion:^(BOOL finished) {
        [self.search becomeFirstResponder];
    }];
}
- (BOOL)isShowSearch{
    return (self.searchH > 0);
}
- (void)hideSearch{
    if (self.search.frame.size.height <= 0) {
        return;
    }
    [self.search resignFirstResponder];
    self.searchH = 0;
    [UIView animateWithDuration:0.25 animations:^{
        [self updateSearchFrame];
    } completion:^(BOOL finished) {
        [self reloadListWhenCloseSearch];
    }];
}
- (void)resignFirstResponder{
    [self.search resignFirstResponder];
}
- (BOOL)isFirstResponder{
    return [self.search isFirstResponder];
}

#pragma mark - oprate

- (NSArray <ZHDPListOprateItem *> *)fetchOprateItems{
    NSMutableArray *res = [NSMutableArray array];
    
    __weak __typeof__(self) weakSelf = self;
    NSArray *icons = @[@"\ue68b", @"\ue609", @"\ue636", @"\ue61d", @"\ue630", @"\ue691", @"\ue60a", @"\ue681"];
    NSArray *descs = @[@"筛选", @"查找", @"刷新", @"删除", @"顶部", @"底部", @"隐藏", @"退出"];
    NSArray *blocks = @[
        ^{
            [weakSelf.apps show];
        },
         ^{
             [weakSelf.oprate hide];
             [weakSelf showSearch];
         },
         ^{
             [weakSelf.oprate hide];
             [weakSelf reloadListWhenRefresh];
         },
         ^{
             [weakSelf.oprate hide];
             [ZHDPMg() removeSecItemsList:weakSelf.class secItems:weakSelf.items.copy];
         },
         ^{
             [weakSelf.oprate hide];
             [weakSelf scrollListToTopCode];
         },
         ^{
             [weakSelf.oprate hide];
             [weakSelf scrollListToBottomCode];
         },
         ^{
             [ZHDPMg() switchFloat];
         },
         ^{
             [ZHDPMg() close];
         }
    ];
    for (NSUInteger i = 0; i < icons.count; i++) {
        ZHDPListOprateItem *item = [[ZHDPListOprateItem alloc] init];
        item.icon = icons[i];
        item.desc = descs[i];
        item.textColor = [ZHDPMg() defaultColor];
        item.block = [blocks[i] copy];
        [res addObject:item];
    }
    return res.copy;
}
- (void)relaodOprate{
    NSArray <ZHDPListOprateItem *> *items = [self fetchOprateItems];
    
    ZHDPAppItem *selectAppItem = self.apps.selectItem;
    if (selectAppItem && items.count > 0) {
        ZHDPListOprateItem *item = items.firstObject;
        item.desc = selectAppItem.appName;
        item.textColor = [ZHDPMg() selectColor];
    }
    
    [self.oprate reloadWithItems:items];
}

#pragma mark - apps

- (void)selectListApps:(ZHDPAppItem *)item{
    [self relaodOprate];
    [self.apps hide];
    [self reloadListWhenSelectApp];
}

#pragma mark - sub class

- (NSArray <ZHDPListSecItem *> *)fetchAllItems{
    return nil;
}

#pragma mark - reload

- (void)setScrollStatus:(ZHDPScrollStatus)scrollStatus{
    _scrollStatus = scrollStatus;
    
    if (scrollStatus != ZHDPScrollStatus_Idle) return;
    
    NSArray *arr = self.items_temp.copy;
    if (arr.count <= 0) return;
    
    [self.items_temp removeAllObjects];
    for (void(^block)(void) in arr) {
        block();
    }
    [self reloadList];
}
- (void)addSecItem:(ZHDPListSecItem *)item spaceItem:(ZHDPDataSpaceItem *)spaceItem{
    if (!item || ![item isKindOfClass:ZHDPListSecItem.class]) return;
    
    __weak __typeof__(self) weakSelf = self;
    
    void (^block) (void) = ^(void){
        if ([weakSelf verifyFilterCondition:item]) {
            [ZHDPMg().dataTask addAndCleanItems:weakSelf.items item:item spaceItem:spaceItem];
        }
    };
    if (self.scrollStatus != ZHDPScrollStatus_Idle) {
        [self.items_temp addObject:block];
        return;
    }
    block();
    [self reloadList];
}
- (void)removeSecItems:(NSArray <ZHDPListSecItem *> *)secItems{
    if (!secItems || ![secItems isKindOfClass:NSArray.class] || secItems.count == 0 || self.items.count == 0) {
        return;
    }
    NSUInteger originCount = self.items.count;
    [self.items removeObjectsInArray:secItems];
    if (self.items.count == originCount) {
        return;
    }
    [self reloadListFrequently];
}
- (void)removeSecItem:(ZHDPListSecItem *)secItem{
    if (!secItem || ![secItem isKindOfClass:ZHDPListSecItem.class] || self.items.count == 0) return;
    if ([self.items containsObject:secItem]) {
        [self.items removeObject:secItem];
        [self reloadListFrequently];
    }
}
- (void)reloadListWhenSelectApp{
    [self reloadListWhenShow];
}
- (void)reloadListWhenSearch{
    [self reloadListWhenShow];
}
- (void)reloadListWhenCloseSearch{
    [self reloadListWhenShow];
}
- (void)reloadListWhenRefresh{
    [self reloadListWhenShow];
}
- (void)reloadListWhenShow{
    NSArray <ZHDPListSecItem *> *items = [self fetchAllItems]?:@[];
    self.items = [[self filterItems:items.copy]?:@[] mutableCopy];
    [self reloadList];
}
- (void)reloadListFrequently{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadList) object:nil];
    [self performSelector:@selector(reloadList) withObject:nil afterDelay:0.25];
}
- (void)reloadList{
    if (!self.allowScrollAuto) {
        [self.tableView reloadData];
        return;
    }
    
    CGFloat listH = self.tableView.frame.size.height;
//    CGFloat listOffSetY = self.tableView.contentOffset.y;
    CGFloat listContentH = self.tableView.contentSize.height;
    
    if (listContentH <= 0 || listH <= 0) {
        [self.tableView reloadData];
        return;
    }
    if (listContentH < listH) {
        [self.tableView reloadData];
        return;
    }
    
    [self.tableView reloadData];
    [self scrollListToBottomAuto];
}

- (void)scrollListToBottomAuto{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollListToBottomAutoInternal) object:nil];
    [self performSelector:@selector(scrollListToBottomAutoInternal) withObject:nil afterDelay:0.3];
}
- (void)scrollListToBottomAutoInternal{
    if (!self.allowScrollAuto) return;
    [self scrollListToBottom:YES];
}
- (void)scrollListToBottomCode{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollListToBottomAutoInternal) object:nil];
    [self scrollListToBottom:YES];
}
- (void)scrollListToBottom:(BOOL)animated{
    if (self.items.count <= 0) return;

    ZHDPListSecItem *secItem = self.items.lastObject;
    NSInteger row = (secItem.isOpen ? (secItem.rowItems.count > 0 ? secItem.rowItems.count - 1 : -1) : -1);
    NSInteger sec = self.items.count - 1;
    if (row >= 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:sec] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }else{
        CGFloat listH = self.tableView.frame.size.height;
        CGFloat listContentH = self.tableView.contentSize.height;
        
        if (listContentH <= listH) {
            return;
        }
        // list 总行数为0  不能调用函数scrollToRowAtIndexPath滚动
        [self.tableView setContentOffset:CGPointMake(0, (listContentH - listH)) animated:animated];
    }
}

- (void)scrollListToTopCode{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollListToBottomAutoInternal) object:nil];
    [self scrollListToTop];
}
- (void)scrollListToTop{
    if (self.items.count <= 0) return;
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

#pragma mark - UITableViewDelegate

// 存在问题  tableView为多组一行(行高为1像素)模式  调用滚动函数scrollToRowAtIndexPath  有可能滚动不到最底部
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.items.count;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    ZHDPListSecItem *secItem = self.items[section];
    if (secItem.headerH <= 0) {
        return nil;
    }
    ZHDPListHeader *header = [ZHDPListHeader sctionHeaderWithTableView:tableView];
    __weak __typeof__(self) weakSelf = self;
    header.tapGesBlock = ^(BOOL open, ZHDPListSecItem *item) {
        [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
    };
    [header configItem:secItem];
    return header;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    ZHDPListSecItem *secItem = self.items[section];
    return secItem.headerH;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    ZHDPListSecItem *secItem = self.items[section];
    NSInteger rows = secItem.isOpen ? secItem.rowItems.count : 0;
    return rows;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    ZHDPListSecItem *secItem = self.items[indexPath.section];
    return secItem.rowItems[indexPath.row].rowH;
    // [ZHDPMg() defaultLineW]  返回一个像素的行高  否则  scrollToRowAtIndexPath滚动时  位置可能不准确
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ZHDPListSecItem *secItem = self.items[indexPath.section];
    ZHDPListRowItem *rowItem = secItem.rowItems[indexPath.row];
    
    ZHDPListCell *cell = [ZHDPListCell cellWithTableView:tableView];
    __weak __typeof__(self) weakSelf = self;
    cell.tapGesBlock = ^(void) {
        [weakSelf.detail showWithSecItem:secItem];
    };
    cell.longPressGesBlock = ^(void) {
        [ZHDPMg() copySecItemToPasteboard:secItem];
    };
    [cell configItem:rowItem];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
// 将要开始拖拽
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    self.scrollStatus = ZHDPScrollStatus_Dragging;
}
// 将要结束拖拽
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    self.scrollStatus = ZHDPScrollStatus_Dragging;
}
// 结束拖拽
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    self.scrollStatus = decelerate ? ZHDPScrollStatus_DraggingDecelerate : ZHDPScrollStatus_Idle;
    if (!decelerate) {
        [self configScrollAuto];
    }
//    NSLog(@"%s",__func__);
}
// 将要开始减速
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView{
    self.scrollStatus = ZHDPScrollStatus_DraggingDecelerate;
//    NSLog(@"%s",__func__);
}
// 完成减速
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self configScrollAuto];
    self.scrollStatus = ZHDPScrollStatus_Idle;
//    NSLog(@"%s",__func__);
}
// called when setContentOffset/scrollRectVisible:animated: finishes. not called if not animating
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    [self configScrollAuto];
//    NSLog(@"%s",__func__);
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
}

#pragma mark - getter

- (NSMutableArray<ZHDPListSecItem *> *)items{
    if (!_items) {
        _items = [NSMutableArray array];
    }
    return _items;
}
- (NSMutableArray<ZHDPListSecItem *> *)items_temp{
    if (!_items_temp) {
        _items_temp = [NSMutableArray array];
    }
    return _items_temp;
}
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        
        _tableView.directionalLockEnabled = YES;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        
        if (@available(iOS 11.0, *)){
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }else{
//            self.automaticallyAdjustsScrollViewInsets = YES;
        }
        
//        _tableView.separatorColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.25];
//        _tableView.separatorInset = UIEdgeInsetsZero;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        _tableView.tableFooterView = [UIView new];
    }
    return _tableView;
}
- (ZHDPListSearch *)search{
    if (!_search) {
        _search = [[ZHDPListSearch alloc] initWithFrame:CGRectZero];
        _search.list = self;
        __weak __typeof__(self) weakSelf = self;
        _search.fieldChangeBlock = ^(NSString *str) {
            [weakSelf reloadListWhenSearch];
        };
    }
    return _search;
}
- (ZHDPListOprate *)oprate{
    if (!_oprate) {
        _oprate = [[ZHDPListOprate alloc] initWithFrame:CGRectZero];
        _oprate.list = self;
    }
    return _oprate;
}
- (ZHDPListApps *)apps{
    if (!_apps) {
        _apps = [[ZHDPListApps alloc] initWithFrame:CGRectZero];
        __weak __typeof__(self) weakSelf = self;
        _apps.selectBlock = ^(ZHDPAppItem * _Nonnull item) {
            [weakSelf selectListApps:item];
        };
        _apps.list = self;
    }
    return _apps;
}
- (ZHDPListDetail *)detail{
    if (!_detail) {
        _detail = [[ZHDPListDetail alloc] initWithFrame:CGRectZero];
        _detail.list = self;
    }
    return _detail;
}

@end
