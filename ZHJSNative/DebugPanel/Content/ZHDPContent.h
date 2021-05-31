//
//  ZHDPContent.h
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPComponent.h"
@class ZHDPList;

NS_ASSUME_NONNULL_BEGIN

@interface ZHDPContent : ZHDPComponent
- (NSArray <ZHDPList *> *)allLists;
@property (nonatomic, strong) ZHDPList *selectList;
- (void)selectList:(ZHDPList *)list;
@end

NS_ASSUME_NONNULL_END
