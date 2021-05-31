//
//  ZHDPOption.h
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPComponent.h"
@class ZHDPList;

@interface ZHDPOptionItem : NSObject
@property (nonatomic,copy) NSString *title;
@property (nonatomic,assign,getter=isSelected) BOOL selected;
@property (nonatomic,weak) ZHDPList *list;
@end

@interface ZHDPOption : ZHDPComponent
@property (nonatomic,copy) void (^selectBlock) (NSIndexPath *indexPath, ZHDPOptionItem *item);

@property (nonatomic,strong) ZHDPOptionItem *selectItem;
@property (nonatomic, retain) NSArray <ZHDPOptionItem *> *items;
- (void)reloadWithItems:(NSArray <ZHDPOptionItem *> *)items;
- (void)selectIndexPath:(NSIndexPath *)indexPath;
@end
