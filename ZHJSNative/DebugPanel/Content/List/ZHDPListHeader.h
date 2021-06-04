//
//  ZHDPListHeader.h
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZHDPListRow.h"// list row

NS_ASSUME_NONNULL_BEGIN

@interface ZHDPListHeader : UITableViewHeaderFooterView

+ (instancetype)sctionHeaderWithTableView:(UITableView *)tableView;

@property (nonatomic,copy) void (^tapGesBlock) (BOOL open, ZHDPListSecItem *item);
@property (nonatomic,copy) void (^longPressGesBlock) (BOOL open, ZHDPListSecItem *item);
- (void)configItem:(ZHDPListSecItem *)item;
@end

NS_ASSUME_NONNULL_END
