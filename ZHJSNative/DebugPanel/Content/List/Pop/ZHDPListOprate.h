//
//  ZHDPListOprate.h
//  ZHJSNative
//
//  Created by EM on 2021/5/28.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListPop.h"
#import "ZHDPDataTask.h"

@interface ZHDPListOprateCell : UITableViewCell
+ (instancetype)cellWithTableView:(UITableView *)tableView;
- (void)configItem:(ZHDPListOprateItem *)item;
@end


@interface ZHDPListOprate : ZHDPListPop
- (void)reloadWithItems:(NSArray <ZHDPListOprateItem *> *)items;
@end
