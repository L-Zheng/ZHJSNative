//
//  ZHDPList.m
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPList.h"
#import "ZHDPListCell.h"
#import "ZHDPListHeader.h"
#import "ZHDPManager.h"
#import "ZHDPListOprate.h"
#import "ZHDPListSearch.h"
#import "ZHDPListApps.h"
#import "ZHDPListDetail.h"

typedef NS_ENUM(NSInteger, ZHDPScrollStatus) {
    ZHDPScrollStatus_Idle      = 0,//闲置
    ZHDPScrollStatus_Dragging      = 1,//拖拽中
    ZHDPScrollStatus_DraggingDecelerate      = 2,//拖拽后减速
};

@interface ZHDPList () <UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,retain) NSMutableArray <ZHDPListSecItem *> *items;
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
        return;
    }
    if (listContentH < listH) {
        self.allowScrollAuto = YES;
        return;
    }
    if (listOffSetY >= listContentH - listH - 5) {
        self.allowScrollAuto = YES;
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
    NSArray <ZHDPListColItem *> *colItems = secItem.colItems.copy;
    for (ZHDPListColItem *colItem in colItems) {
        if ([colItem.title.lowercaseString containsString:keyword.lowercaseString]) {
            return YES;
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
        self.searchH = 30;
        [self updateSearchFrame];
    }];
}
- (void)hideSearch{
    if (self.search.frame.size.height <= 0) {
        return;
    }
    self.searchH = 0;
    [UIView animateWithDuration:0.25 animations:^{
        [self updateSearchFrame];
    } completion:^(BOOL finished) {
        [self reloadListWhenShow];
    }];
}

#pragma mark - oprate

- (NSArray <ZHDPListOprateItem *> *)fetchOprateItems{
    NSMutableArray *res = [NSMutableArray array];
    
    __weak __typeof__(self) weakSelf = self;
    NSArray *icons = @[@"\ue68b", @"\ue609", @"\ue630", @"\ue691", @"\ue60a"];
    NSArray *descs = @[@"筛选", @"查找", @"顶部", @"底部", @"隐藏"];
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
             [weakSelf scrollListToTopCode];
         },
         ^{
             [weakSelf.oprate hide];
             [weakSelf scrollListToBottomCode];
         },
         ^{
             [ZHDPMg() switchFloat];
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
- (void)reloadListWhenSelectApp{
    [self reloadListWhenShow];
}
- (void)reloadListWhenSearch{
    [self reloadListWhenShow];
}
- (void)reloadListWhenShow{
    NSArray <ZHDPListSecItem *> *items = [self fetchAllItems]?:@[];
    self.items = [[self filterItems:items.copy]?:@[] mutableCopy];
    [self reloadList];
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
    [self scrollListToBottom];
}
- (void)scrollListToBottomCode{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollListToBottomAutoInternal) object:nil];
    [self scrollListToBottom];
}
- (void)scrollListToBottom{
    if (self.items.count <= 0) return;

    ZHDPListSecItem *secItem = self.items.lastObject;
    NSInteger row = (secItem.isOpen ? (secItem.rowItems.count > 0 ? secItem.rowItems.count - 1 : 0) : 0);
    NSInteger sec = self.items.count - 1;
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:sec] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.items.count;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    ZHDPListHeader *header = [ZHDPListHeader sctionHeaderWithTableView:tableView];
    __weak __typeof__(self) weakSelf = self;
    header.tapClickBlock = ^(BOOL open, ZHDPListSecItem *item) {
        [weakSelf.detail showWithSecItem:item];
//        [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
    };
    [header configItem:self.items[section]];
    return header;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    ZHDPListSecItem *secItem = self.items[section];
    return secItem.headerH;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    ZHDPListSecItem *secItem = self.items[section];
    NSInteger rows = secItem.isOpen ? secItem.rowItems.count : 0;
    return (rows > 0 ? rows : 1);
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    ZHDPListSecItem *secItem = self.items[indexPath.section];
    NSInteger rows = secItem.isOpen ? secItem.rowItems.count : 0;
    return (rows > 0 ? secItem.rowItems[indexPath.row].rowH : 0);
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ZHDPListSecItem *secItem = self.items[indexPath.section];
    NSInteger rows = secItem.isOpen ? secItem.rowItems.count : 0;
    NSArray <ZHDPListColItem *> *colItems = (rows > 0 ? secItem.rowItems[indexPath.row].colItems : nil);
    
    ZHDPListCell *cell = [ZHDPListCell cellWithTableView:tableView];
    [cell.rowContent configItem:colItems];
    return cell;
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
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
