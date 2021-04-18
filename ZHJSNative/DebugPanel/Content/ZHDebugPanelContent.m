//
//  ZHDebugPanelContent.m
//  ZHJSNative
//
//  Created by Zheng on 2021/4/17.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDebugPanelContent.h"
#import "ZHDebugPanelSearch.h"
#import "ZHDebugPanelOprate.h"
#import "ZHDebugPanel.h"
#import "ZHDebugPanelContentHeader.h"
#import "ZHDebugPanelContentCell.h"

@interface ZHDebugPanelContent ()<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic,retain) NSMutableArray *items;
@property (nonatomic,strong) ZHDebugPanelSearch *searchView;
@property (nonatomic,strong) ZHDebugPanelOprate *oprateView;
@end

@implementation ZHDebugPanelContent

#pragma mark - init

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configData];
        [self configUI];
    }
    return self;
}

- (void)dealloc{
}

#pragma mark - config

- (void)configData{
}

- (void)configUI{
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor cyanColor];
    
}

- (NSString *)titleName{
    return @"父类";
}

#pragma mark - layout

- (void)didMoveToSuperview{
    if (!self.superview) {
        return;
    }
    
    NSArray *views = @[self.searchView, self.oprateView, self.tableView];
    for (UIView *view in views) {
        if (view.superview != self) {
            [view removeFromSuperview];
            [self addSubview:view];
        }
    }
}

//FOUNDATION_EXPORT
CGFloat searchMarginTop = 5;
CGFloat searchH = 30;
CGFloat oprateMarginTop = 5;
CGFloat oprateMarginBottom = 5;
CGFloat oprateH = 30;
CGFloat listMarginTop = 5;

- (void)layoutSubviews{
    [super layoutSubviews];
    
    self.searchView.frame = CGRectMake(0, searchMarginTop, self.bounds.size.width, searchH);
    self.oprateView.frame = CGRectMake(0, self.bounds.size.height - oprateH - oprateMarginBottom, self.bounds.size.width, oprateH);
    
    CGFloat listY = CGRectGetMaxY(self.searchView.frame) + listMarginTop;
    CGFloat listH = self.bounds.size.height - (listY + self.oprateView.frame.size.height + oprateMarginBottom + oprateMarginTop);

    self.tableView.frame = CGRectMake(0, listY, self.bounds.size.width, listH);
    
    [self reloadListWhenContentFrameChange];
}

#pragma mark - reload

- (BOOL)canRefreshList{
    if (self.debugPanel.status != ZHDebugPanelStatus_Show) {
        return NO;
    }
    if (![self.debugPanel.selectContent isEqual:self]) {
        return NO;
    }
    return YES;
}
- (BOOL)canScrollList{
    if (![self canRefreshList]) {
        return NO;
    }
    CGPoint offSet = self.tableView.contentOffset;
    CGSize contentSize = self.tableView.contentSize;
    CGFloat listH = self.tableView.frame.size.height;
    if (contentSize.height <= listH) {
        return YES;
    }
    if (offSet.y + listH >= contentSize.height) {
        return YES;
    }
    return NO;
}
- (void)refreshListUI:(void (^) (void))block{
    if (!block || [self canRefreshList]) return;
    block();
}
- (void)reloadAllItems{
    self.items = [[self fetchDataAll:nil] mutableCopy];
    [self.tableView reloadData];
}
- (void)reloadAddItem:(NSUInteger)section{
    self.items = [[self fetchDataAll:nil] mutableCopy];
    [self.tableView insertSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
}
- (void)reloadListWhenContentFrameChange{
    BOOL needReload = NO;
    
    NSDictionary *map = self.dataMap.copy;
    for (NSString *key in map) {
        NSArray *items = map[key];
        NSUInteger totalCount = items.count;
        for (NSUInteger i = 0; i < totalCount; i++) {
            NSDictionary *item = items[i];
            NSNumber *headerW = item[@"headerW"];
            if (headerW.floatValue == self.bounds.size.width) {
                continue;
            }
            needReload = YES;
            [self updateData:key index:i];
        }
    }
    if (needReload) {
        self.items = [[self fetchDataAll:nil] mutableCopy];
        [self.tableView reloadData];
    }
}

#pragma mark - data

- (NSMutableArray *)filterData:(NSMutableArray *)datas filtStr:(NSString *)filtStr{
    if (!filtStr || filtStr.length == 0) {
        return datas;
    }
    NSArray *searchArr = datas.copy;
    
    NSMutableArray *res = [NSMutableArray array];
    for (NSDictionary *tData in searchArr) {
        NSArray *titles = tData[@"titles"];
        for (NSDictionary *ttData in titles) {
            NSString *text = ttData[@"text"];
            if ([text containsString:filtStr]) {
                [res addObject:tData];
                break;
            }
        }
        if ([res containsObject:tData]) {
            continue;
        }
        NSArray *values = tData[@"values"];
        for (NSDictionary *value in values) {
            NSArray *titles = value[@"titles"];
            for (NSDictionary *ttData in titles) {
                NSString *text = ttData[@"text"];
                if ([text containsString:filtStr]) {
                    [res addObject:tData];
                    break;
                }
            }
            if ([res containsObject:tData]) {
                break;
            }
        }
    }
    return res;
}

- (NSArray *)fetchDataAll:(NSString *)filtStr{
    NSMutableArray *res = [NSMutableArray array];
    NSDictionary *map = self.dataMap.copy;
    for (NSString *key in map) {
        [res addObjectsFromArray:map[key]];
    }
    [res sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        double time1 =  [(NSNumber *)obj1[self.enterMemoryTime] doubleValue];
        double time2 =  [(NSNumber *)obj2[self.enterMemoryTime] doubleValue];
        if (time1 < time2) {
            return NSOrderedAscending;
        }
        if (time1 > time2) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    return [self filterData:res filtStr:filtStr];
}
- (NSArray *)fetchDataByAppId:(NSString *)appId filtStr:(NSString *)filtStr{
    NSDictionary *map = self.dataMap.copy;
    return [self filterData:map[appId] filtStr:filtStr];
}

- (void)updateData:(NSString *)appId index:(NSUInteger)index{
    NSMutableDictionary *map = self.dataMap;
    if (!map || ![map isKindOfClass:NSDictionary.class]) {
        return;
    }
    if (!appId || ![appId isKindOfClass:NSString.class] || appId.length == 0) {
        return;
    }
    NSMutableArray *originDatas = [map objectForKey:appId];
    if (!originDatas || index >= originDatas.count) {
        return;
    }
    NSDictionary *item = originDatas[index];
    NSNumber *enterMemoryTime = item[self.enterMemoryTime];
    NSNumber *open = item[@"open"];
    
    NSMutableArray *headerTitles = [NSMutableArray array];
    NSMutableArray *headerPercents = [NSMutableArray array];
    NSMutableArray *cells = [NSMutableArray array];
    NSMutableArray *cellTitles = [NSMutableArray array];
    NSMutableArray *cellPercents = [NSMutableArray array];
    
    NSArray *titles = [item objectForKey:@"titles"];
    for (NSDictionary *tItem in titles) {
        [headerTitles addObject:tItem[@"text"]];
        [headerPercents addObject:tItem[@"percent"]];
    }
    
    NSArray *values = [item objectForKey:@"values"];
    for (NSDictionary *tItem in values) {
        NSArray *tTitles = [tItem objectForKey:@"titles"];
        for (NSDictionary *ttItem in tTitles) {
            [cellTitles addObject:ttItem[@"text"]];
            [cellPercents addObject:ttItem[@"percent"]];
        }
        [cells addObject:@{
            @"cellTitles": cellTitles,
            @"cellPercents": cellPercents
        }];
    }
    NSDictionary *params = @{
        @"headerTitles":headerTitles,
        @"headerPercents": headerPercents,
        @"cells": cells
    };
    NSMutableDictionary *res = [self calculateSectionData:params];
    [res addEntriesFromDictionary:@{
        self.enterMemoryTime: enterMemoryTime,
        @"open": open
    }];
    
    [originDatas replaceObjectAtIndex:index withObject:res];
}
- (void)addData:(NSString *)appId convertParams:(NSDictionary *)convertParams limit:(NSUInteger)limit{
    NSMutableDictionary *map = self.dataMap;
    if (!map || ![map isKindOfClass:NSDictionary.class]) {
        return;
    }
    if (!appId || ![appId isKindOfClass:NSString.class] || appId.length == 0) {
        return;
    }
    NSMutableArray *originDatas = [map objectForKey:appId];
    if (!originDatas) {
        originDatas = [NSMutableArray array];
        [map setObject:originDatas forKey:appId];
    }
    NSMutableDictionary *res = [self calculateSectionData:convertParams];
    if (!res) return;
    
    if (originDatas.count > limit) {
        [originDatas removeObjectsInRange:NSMakeRange(0, ceilf(limit * 0.5))];
    }
    [originDatas addObject:res];
    [self reloadAddItem:originDatas.count - 1];
}
- (void)addData:(NSString *)appId originParams:(NSDictionary *)originParams limit:(NSUInteger)limit{
    if (!self.dataMap) self.dataMap = [NSMutableDictionary dictionary];
    [self addData:appId convertParams:@{
        @"headerTitles":@[@"1", @"2", @"3", @"4"],
        @"headerPercents": @[@(0.25), @(0.25), @(0.25), @(0.25)],
        @"cells": @[
                @{
                        @"cellTitles": @[@"w", @"q", @"r", @"t"],
                        @"cellPercents": @[@(0.25), @(0.25), @(0.25), @(0.25)]
                },
                
                @{
                        @"cellTitles": @[@"w", @"q", @"r", @"t"],
                        @"cellPercents": @[@(0.25), @(0.25), @(0.25), @(0.25)]
                }
        ]
    } limit:limit];
}
- (void)addDataTest{
    [self addData:@"xxx" originParams:@{} limit:100];
}

- (NSMutableDictionary *)calculateSectionData:(NSDictionary *)params{
    if (!params || ![params isKindOfClass:NSDictionary.class] || params.allKeys.count == 0) {
        return nil;
    }
    CGFloat headerW = self.bounds.size.width;
    NSArray *headerArr = [self calculateRowData:headerW titles:params[@"headerTitles"] percents:params[@"headerPercents"] attributes:@{NSFontAttributeName: [ZHDebugPanelContentHeader textFont]}];
    CGFloat headerH = headerArr.count > 0 ? [(NSValue *)headerArr.lastObject[@"textFrame"] CGRectValue].size.height : 0;
    
    NSArray *cells = params[@"cells"];
    NSMutableArray *cellArr = [NSMutableArray array];
    for (NSDictionary *item in cells) {
        CGFloat cellW = self.bounds.size.width;
        NSArray *cellDatas = [self calculateRowData:headerW titles:item[@"cellTitles"] percents:item[@"cellPercents"] attributes:@{NSFontAttributeName: [ZHDebugPanelContentCell textFont]}];
        CGFloat cellH = cellDatas.count > 0 ? [(NSValue *)cellDatas.lastObject[@"textFrame"] CGRectValue].size.height : 0;
        
        [cellArr addObject:@{
            @"cellW": @(cellW),
            @"cellH": @(cellH),
            @"titles": cellDatas
        }];
    }
    return @{
        [self enterMemoryTime]: @([[NSDate date] timeIntervalSince1970]),
        @"open": @(NO),
        @"headerW": @(headerW),
        @"headerH": @(headerH),
        @"titles": headerArr,
        @"values": cellArr
    }.mutableCopy;
}
- (NSArray *)calculateRowData:(CGFloat)rowW titles:(NSArray *)titles percents:(NSArray *)percents attributes:(NSDictionary *)attributes{
    NSUInteger totalCount = MAX(titles.count, percents.count);
    CGFloat rowH = 0;
    NSMutableArray *resArr = [NSMutableArray array];
    for (NSUInteger i = 0; i < totalCount; i++) {
        NSString *title = i < titles.count ? titles[i] : @"";
        NSNumber *percent = i < percents.count ? percents[i] : @(0);
        CGFloat textW = rowW * percent.floatValue;
        CGFloat textH = [title boundingRectWithSize:CGSizeMake(textW, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil].size.height;
        textH += 5;
        CGFloat textX = resArr.count > 0 ? CGRectGetMaxX([(NSValue *)resArr.lastObject[@"textFrame"] CGRectValue]) : 0;
        
        [resArr addObject:@{
            @"text": title,
            @"percent": percent,
            @"textW": @(textW),
            @"textH": @(textH),
            @"textFrame": [NSValue valueWithCGRect:CGRectMake(textX, 0, textW, 0)]
        }.mutableCopy];
        
        if (textH > rowH) rowH = textH;
    }
    for (NSMutableDictionary *item in resArr) {
        CGRect rect = [(NSValue *)item[@"textFrame"] CGRectValue];
        rect.size.height = rowH;
        [item setObject:[NSValue valueWithCGRect:rect] forKey:@"textFrame"];
    }
    return resArr.copy;
}
- (NSString *)enterMemoryTime{
    return @"ios-enter-memory-time";
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.items.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    __weak __typeof__(self) weakSelf = self;
    ZHDebugPanelContentHeader *header = [ZHDebugPanelContentHeader sctionHeaderWithTableView:tableView];
    header.tapClickBlock = ^(BOOL open) {
        [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
    };
    [header configItem:self.items[section]];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    NSDictionary *item = self.items[section];
    return [(NSNumber *)item[@"headerH"] floatValue];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSDictionary *item = self.items[section];
    BOOL open = [(NSNumber *)[item objectForKey:@"open"] boolValue];
    if (!open) return 0;
    
    NSArray *subItems = item[@"values"];
    return subItems.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSDictionary *item = self.items[indexPath.section];
    NSArray *subItems = item[@"values"];
    NSDictionary *subItem = subItems[indexPath.row];
    return [(NSNumber *)subItem[@"cellH"] floatValue];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSDictionary *item = self.items[indexPath.section];
    NSArray *subItems = item[@"values"];
    NSDictionary *subItem = subItems[indexPath.row];
    
    ZHDebugPanelContentCell *cell = [ZHDebugPanelContentCell cellWithTableView:tableView];
    [cell configItem:subItem];
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - getter

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
- (ZHDebugPanelSearch *)searchView{
    if (!_searchView) {
        _searchView = [[ZHDebugPanelSearch alloc] initWithFrame:CGRectZero];
        _searchView.textFieldChangeBlock = ^(NSString *text) {
            
        };
    }
    return _searchView;
}
- (ZHDebugPanelOprate *)oprateView{
    if (!_oprateView) {
        _oprateView = [[ZHDebugPanelOprate alloc] initWithFrame:CGRectZero];
    }
    return _oprateView;
}

@end
