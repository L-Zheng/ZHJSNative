//
//  ZHDPListLog.m
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListLog.h"
#import "ZHDPManager.h"

@implementation ZHDPListLog

#pragma mark - data

- (NSArray <ZHDPListSecItem *> *)fetchAllItems{
    return [ZHDPMg().dataTask fetchAllAppDataItems_log];
}

@end
