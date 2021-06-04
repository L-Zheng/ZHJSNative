//
//  ZHDPListCell.m
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListCell.h"

@interface ZHDPListCell ()
@end

@implementation ZHDPListCell

+ (instancetype)cellWithTableView:(UITableView *)tableView{
    NSString *cellID = NSStringFromClass(self);
    ZHDPListCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[ZHDPListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.clipsToBounds = YES;
        //        ⚠️[TableView] Changing the background color of UITableViewHeaderFooterView is not supported. Use the background view configuration instead.
        //        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundView = [UIView new];
        //        self.selectedBackgroundView = [UIView new];
        
        [self.contentView addSubview:self.rowContent];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.rowContent.frame = self.contentView.bounds;
}

- (ZHDPListRow *)rowContent{
    if (!_rowContent) {
        _rowContent = [[ZHDPListRow alloc] initWithFrame:CGRectZero];
    }
    return _rowContent;
}

@end
