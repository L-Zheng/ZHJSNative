//
//  ZHDPListDetail.h
//  ZHJSNative
//
//  Created by EM on 2021/5/29.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListPop.h"
#import "ZHDPDataTask.h"

@interface ZHDPListDetail : ZHDPListPop
- (void)showWithSecItem:(ZHDPListSecItem *)secItem;
@property (nonatomic,weak) ZHDPListSecItem *secItem;
@end
