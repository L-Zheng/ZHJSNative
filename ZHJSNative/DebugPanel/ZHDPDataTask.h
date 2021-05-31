//
//  ZHDPDataTask.h
//  ZHJSNative
//
//  Created by EM on 2021/5/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class ZHDPManager;
@class ZHDPAppDataItem;

// list操作栏数据
@interface ZHDPListOprateItem : NSObject
@property (nonatomic,copy) NSString *icon;
@property (nonatomic,copy) NSString *desc;
@property (nonatomic,strong) UIColor *textColor;
@property (nonatomic,copy) void (^block) (void);
@end

// 描述list的信息
@interface ZHDPListItem : NSObject
+ (instancetype)itemWithTitle:(NSString *)title;
@property (nonatomic,copy) NSString *title;
@end

// list中每一行中每一分段的信息
@interface ZHDPListColItem : NSObject
@property (nonatomic,strong) UIFont *font;
@property (nonatomic,copy) NSString *title;
@property (nonatomic,assign) CGFloat percent;
@property (nonatomic,strong) NSValue *rectValue;
@end

// list中每一行的信息
@interface ZHDPListRowItem : NSObject
@property (nonatomic,retain) NSArray <ZHDPListColItem *> *colItems;
@property (nonatomic,assign) CGFloat rowH;
@end

// list选中某一组显示的详细信息
@interface ZHDPListDetailItem : NSObject
@property (nonatomic,copy) NSString *title;
@property (nonatomic,copy) NSString *content;
@property (nonatomic,assign,getter=isSelected) BOOL selected;
@end

// list中每一组的信息
@interface ZHDPListSecItem : NSObject
@property (nonatomic,weak) ZHDPAppDataItem *appDataItem;

@property (nonatomic,assign) NSTimeInterval enterMemoryTime;
@property (nonatomic,assign,getter=isOpen) BOOL open;
@property (nonatomic,retain) NSArray <ZHDPListColItem *> *colItems;
@property (nonatomic,assign) CGFloat headerH;
@property (nonatomic,retain) NSArray <ZHDPListRowItem *> *rowItems;

@property (nonatomic,retain) NSArray <ZHDPListDetailItem *> *detailItems;
@end

// 某种类型数据的存储最大容量
@interface ZHDPDataSpaceItem : NSObject
@property (nonatomic,assign) NSInteger count;
@property (nonatomic,assign) CGFloat removePercent;
@end

// 某个应用的简要信息
@interface ZHDPAppItem : NSObject
@property (nonatomic,copy) NSString *appName;
@property (nonatomic,copy) NSString *appId;
@end

// 某个应用的数据
@interface ZHDPAppDataItem : NSObject

@property (nonatomic,strong) ZHDPAppItem *appItem;

@property (nonatomic,strong) ZHDPDataSpaceItem *logSpaceItem;
@property (nonatomic,retain) NSMutableArray <ZHDPListSecItem *> *logItems;

@property (nonatomic,strong) ZHDPDataSpaceItem *networkSpaceItem;
@property (nonatomic,retain) NSMutableArray <ZHDPListSecItem *> *networkItems;

@property (nonatomic,strong) ZHDPDataSpaceItem *imSpaceItem;
@property (nonatomic,retain) NSMutableArray <ZHDPListSecItem *> *imItems;

@property (nonatomic,strong) ZHDPDataSpaceItem *storageSpaceItem;
@property (nonatomic,retain) NSMutableArray <ZHDPListSecItem *> *storageItems;
@end


// 数据管理
@interface ZHDPDataTask : NSObject

@property (nonatomic,weak) ZHDPManager *dpManager;
@property (nonatomic,strong) NSMutableDictionary *appDataMap;

// 查找所有应用的数据
- (NSArray <ZHDPAppDataItem *> *)fetchAllAppDataItems;
- (NSArray <ZHDPListSecItem *> *)fetchAllAppDataItems_module:(NSArray * (^) (ZHDPAppDataItem *appDataItem))block;
- (NSArray <ZHDPListSecItem *> *)fetchAllAppDataItems_log;
- (NSArray <ZHDPListSecItem *> *)fetchAllAppDataItems_network;
- (NSArray <ZHDPListSecItem *> *)fetchAllAppDataItems_im;
- (NSArray <ZHDPListSecItem *> *)fetchAllAppDataItems_storage;

// 查找某个应用的数据
- (ZHDPAppDataItem *)fetchAppDataItem:(ZHDPAppItem *)appItem;

// 清理并添加数据
- (void)addAndCleanItems:(NSMutableArray *)items item:(ZHDPListSecItem *)item spaceItem:(ZHDPDataSpaceItem *)spaceItem;
@end


