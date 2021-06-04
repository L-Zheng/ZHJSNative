//
//  ZHDebugPanel.h
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ZHDPOption;// 操作栏
@class ZHDPContent;// 内容列表容器

typedef NS_ENUM(NSInteger, ZHDebugPanelStatus) {
    ZHDebugPanelStatus_Unknown     = 0,
    ZHDebugPanelStatus_Show      = 1,
    ZHDebugPanelStatus_Hide      = 2,
};

@interface ZHDebugPanel : UIView
@property (nonatomic,assign) ZHDebugPanelStatus status;

@property (nonatomic,strong) ZHDPOption *option;
@property (nonatomic,strong) ZHDPContent *content;
@end
