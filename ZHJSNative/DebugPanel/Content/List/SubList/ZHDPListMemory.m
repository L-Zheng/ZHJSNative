//
//  ZHDPListMemory.m
//  ZHJSNative
//
//  Created by EM on 2021/6/16.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListMemory.h"
#import "ZHDPManager.h"// 调试面板管理

@implementation ZHDPListMemory

#pragma mark - data

- (NSArray <ZHDPListSecItem *> *)fetchAllItems{
    return [ZHDPMg() fetchAllAppDataItems:self.class];
}

#pragma mark - reload

- (void)reloadListWhenSelectApp{
    [ZHDPMg() zh_test_reloadMemory];
    [super reloadListWhenShow];
}
- (void)reloadListWhenSearch{
    [super reloadListWhenShow];
}
- (void)reloadListWhenCloseSearch{
    [super reloadListWhenShow];
}
- (void)reloadListWhenRefresh{
    [ZHDPMg() zh_test_reloadMemory];
    [super reloadListWhenShow];
}
- (void)reloadListWhenShow{
//    NSArray <ZHDPListSecItem *> *items = [self fetchAllItems]?:@[];
//    if (items.count == 0) {
        [ZHDPMg() zh_test_reloadMemory];
//    }
    [super reloadListWhenShow];
}

@end
