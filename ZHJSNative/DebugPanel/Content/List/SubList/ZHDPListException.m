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
- (NSString *)footerTipTitle{
    return [NSString stringWithFormat:@"%@\n将输出js运行异常信息【页面白屏、异常等】", [super footerTipTitle]];
}

@end
