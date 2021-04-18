//
//  ZHDebugPanelContentCell.h
//  ZHJSNative
//
//  Created by Zheng on 2021/4/17.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZHDebugPanelContentCell : UITableViewCell

+ (instancetype)cellWithTableView:(UITableView *)tableView;

- (void)configItem:(NSDictionary *)item;
+ (UIFont *)textFont;
@end

NS_ASSUME_NONNULL_END
