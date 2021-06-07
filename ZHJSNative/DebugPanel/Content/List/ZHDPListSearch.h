//
//  ZHDPListSearch.h
//  ZHJSNative
//
//  Created by EM on 2021/5/28.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPComponent.h"
@class ZHDPList;// 列表

@interface ZHDPListSearch : ZHDPComponent
@property (nonatomic,weak) ZHDPList *list;
@property (nonatomic,copy) NSString *keyWord;
@property (nonatomic,copy) void (^fieldChangeBlock) (NSString *str);

- (void)becomeFirstResponder;
@end
