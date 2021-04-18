//
//  ZHDebugPanelContent.h
//  ZHJSNative
//
//  Created by Zheng on 2021/4/17.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ZHDebugPanel;

NS_ASSUME_NONNULL_BEGIN

@interface ZHDebugPanelContent : UIView

@property (nonatomic,weak) ZHDebugPanel *debugPanel;
/*
 @{
    @"appId": @[
                @{
                   @"ios-enter-memory-time": @(0),
                   @"open": @(0),
                   @"headerW": @(0),
                   @"headerH": @(0),
                   @"titles": @[
                                   @{
                                       @"text": @"1",
                                       @"percent": @(0.5),
                                       @"textW": @(44),
                                       @"textH": @(44),
                                       @"textFrame": [NSValue val]
                                    }
                               ],
                   @"values": @[
                                @{
                                   @"cellW": @(0),
                                   @"cellH": @(0),
                                   @"titles": @[
                                                   @{
                                                       @"text": @"1",
                                                       @"percent": @(0.5),
                                                       @"textW": @(44),
                                                       @"textH": @(44),
                                                       @"textFrame": [NSValue val]
                                                    }
                                               ]
                                 }
                               ]
                 }
            ]
  }
 */
@property (nonatomic,strong) NSMutableDictionary *dataMap;

@property (nonatomic,strong) UITableView *tableView;

//- (void)updateData:(NSString *)appId index:(NSUInteger)index;
//- (void)addData:(NSString *)appId convertParams:(NSDictionary *)convertParams;
//- (void)addData:(NSString *)appId originParams:(NSDictionary *)originParams;
- (void)addDataTest;

- (NSString *)titleName;
@end

NS_ASSUME_NONNULL_END
