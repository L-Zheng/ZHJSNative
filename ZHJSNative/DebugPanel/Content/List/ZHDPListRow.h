//
//  ZHDPListRow.h
//  ZHJSNative
//
//  Created by EM on 2021/5/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZHDPDataTask.h"// 数据管理

NS_ASSUME_NONNULL_BEGIN

@interface ZHDPListRow : UIView

- (void)configItem:(NSArray <ZHDPListColItem *> *)items;

@end

NS_ASSUME_NONNULL_END
