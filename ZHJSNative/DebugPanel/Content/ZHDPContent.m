//
//  ZHDPContent.m
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPContent.h"
#import "ZHDPDataTask.h"// 数据管理
#import "ZHDPListLog.h"// log列表
#import "ZHDPListNetwork.h"// network列表
#import "ZHDPListStorage.h"// storage列表
#import "ZHDPListIM.h"// im列表

@interface ZHDPContent ()
@property (nonatomic, strong) ZHDPListLog *logList;
@property (nonatomic, strong) ZHDPListNetwork *networkList;
@property (nonatomic, strong) ZHDPListIM *imList;
@property (nonatomic, strong) ZHDPListStorage *storageList;
@end

@implementation ZHDPContent

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
    
    self.selectList.frame = self.bounds;
}

#pragma mark - config

- (void)configData{
}
- (void)configUI{
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor whiteColor];
}

#pragma mark - lists

- (NSArray <ZHDPList *> *)allLists{
    return @[self.logList, self.networkList, self.storageList, self.imList];
}
- (void)selectList:(ZHDPList *)list{
    if (!list || [self.selectList isEqual:list]) return;
    
    ZHDPList *originList = self.selectList;
    if ([originList isFirstResponder]) {
        if ([list isShowSearch]) {
            [originList resignFirstResponder];
//            [list becomeFirstResponder];
        }else{
            [originList resignFirstResponder];
        }
    }
    self.selectList = list;
    
    [originList removeFromSuperview];
    [self addSubview:self.selectList];
    self.selectList.frame = self.bounds;
}

#pragma mark - getter

- (ZHDPListLog *)logList{
    if (!_logList) {
        _logList = [[ZHDPListLog alloc] initWithFrame:CGRectZero];
        _logList.item = [ZHDPListItem itemWithTitle:@"Log"];
    }
    return _logList;
}
- (ZHDPListNetwork *)networkList{
    if (!_networkList) {
        _networkList = [[ZHDPListNetwork alloc] initWithFrame:CGRectZero];
        _networkList.item = [ZHDPListItem itemWithTitle:@"Network"];
    }
    return _networkList;
}
- (ZHDPListIM *)imList{
    if (!_imList) {
        _imList = [[ZHDPListIM alloc] initWithFrame:CGRectZero];
        _imList.item = [ZHDPListItem itemWithTitle:@"IM"];
    }
    return _imList;
}
- (ZHDPListStorage *)storageList{
    if (!_storageList) {
        _storageList = [[ZHDPListStorage alloc] initWithFrame:CGRectZero];
        _storageList.item = [ZHDPListItem itemWithTitle:@"Storage"];
    }
    return _storageList;
}

@end
