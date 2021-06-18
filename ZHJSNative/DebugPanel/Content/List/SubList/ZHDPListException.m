//
//  ZHDPListException.m
//  ZHJSNative
//
//  Created by EM on 2021/6/18.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListException.h"
#import "ZHDPManager.h"// 调试面板管理

@implementation ZHDPListException

#pragma mark - data

- (NSArray <ZHDPListSecItem *> *)fetchAllItems{
    return [ZHDPMg() fetchAllAppDataItems:self.class];
}

@end
