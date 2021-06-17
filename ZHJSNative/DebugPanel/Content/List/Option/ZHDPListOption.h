//
//  ZHDPListOption.h
//  ZHJSNative
//
//  Created by EM on 2021/6/17.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPComponent.h"
#import "ZHDPListOprate.h"// pop操作栏
@class ZHDPList;

NS_ASSUME_NONNULL_BEGIN

@interface ZHDPListOption : ZHDPComponent
@property (nonatomic,weak) ZHDPList *list;
- (void)reloadWithItems:(NSArray <ZHDPListOprateItem *> *)items;
@end

NS_ASSUME_NONNULL_END
