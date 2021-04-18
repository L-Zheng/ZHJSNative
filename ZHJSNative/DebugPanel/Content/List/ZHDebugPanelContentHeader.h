//
//  ZHDebugPanelContentHeader.h
//  ZHJSNative
//
//  Created by Zheng on 2021/4/17.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZHDebugPanelContentHeader : UITableViewHeaderFooterView

+ (instancetype)sctionHeaderWithTableView:(UITableView *)tableView;

@property (nonatomic,copy) void (^tapClickBlock) (BOOL open);
- (void)configItem:(NSMutableDictionary *)item;
+ (UIFont *)textFont;
@end

NS_ASSUME_NONNULL_END
