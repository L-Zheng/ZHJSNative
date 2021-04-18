//
//  ZHDebugPanel.h
//  ZHJSNative
//
//  Created by Zheng on 2021/4/17.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ZHDebugPanelOption;
@class ZHDebugPanelContent;
@class ZHDebugPanelContentLog;
@class ZHDebugPanelContentNetwork;
@class ZHDebugPanelContentStorage;
@class ZHDebugPanelContentIM;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZHDebugPanelStatus) {
    ZHDebugPanelStatus_Unknown     = 0,
    ZHDebugPanelStatus_Show      = 1,
    ZHDebugPanelStatus_Hide      = 2,
};

@interface ZHDebugPanel : UIView
@property (nonatomic,assign) ZHDebugPanelStatus status;

@property (nonatomic,strong) ZHDebugPanelOption *optionView;

@property (nonatomic,strong) ZHDebugPanelContentLog *logContent;
@property (nonatomic,strong) ZHDebugPanelContentNetwork *networkContent;
@property (nonatomic,strong) ZHDebugPanelContentStorage *storageContent;
@property (nonatomic,strong) ZHDebugPanelContentIM *imContent;
@property (nonatomic,strong) ZHDebugPanelContent *selectContent;
@end

NS_ASSUME_NONNULL_END
