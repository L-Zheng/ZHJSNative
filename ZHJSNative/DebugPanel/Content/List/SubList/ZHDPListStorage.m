//
//  ZHDPListStorage.m
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListStorage.h"
#import "ZHDPManager.h"// 调试面板管理

@implementation ZHDPListStorage

#pragma mark - data

- (NSArray <ZHDPListSecItem *> *)fetchAllItems{
    return [ZHDPMg() fetchAllAppDataItems:self.class];
}

#pragma mark - reload

- (void)reloadListWhenSelectApp{
    [ZHDPMg() zh_test_reloadStorage];
    [super reloadListWhenShow];
}
- (void)reloadListWhenSearch{
    [super reloadListWhenShow];
}
- (void)reloadListWhenCloseSearch{
    [super reloadListWhenShow];
}
- (void)reloadListWhenRefresh{
    [ZHDPMg() zh_test_reloadStorage];
    [super reloadListWhenShow];
}
- (void)reloadListWhenShow{
//    NSArray <ZHDPListSecItem *> *items = [self fetchAllItems]?:@[];
//    if (items.count == 0) {
        [ZHDPMg() zh_test_reloadStorage];
//    }
    [super reloadListWhenShow];
}

@end
