//
//  ZHDPListApps.h
//  ZHJSNative
//
//  Created by EM on 2021/5/28.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListPop.h"
#import "ZHDPDataTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZHDPListApps : ZHDPListPop
@property (nonatomic,weak) ZHDPAppItem *selectItem;
@property (nonatomic,copy) void (^selectBlock) (ZHDPAppItem *item);
@end

NS_ASSUME_NONNULL_END
