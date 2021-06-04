//
//  ZHDPListCell.h
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZHDPListRow.h"// list row

NS_ASSUME_NONNULL_BEGIN

@interface ZHDPListCell : UITableViewCell

+ (instancetype)cellWithTableView:(UITableView *)tableView;
@property (nonatomic,strong) ZHDPListRow *rowContent;

@end

NS_ASSUME_NONNULL_END
