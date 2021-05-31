//
//  ZHDebugPanel.h
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ZHDPOption;
@class ZHDPContent;

typedef NS_ENUM(NSInteger, ZHDebugPanelStatusNew) {
    ZHDebugPanelStatusNew_Unknown     = 0,
    ZHDebugPanelStatusNew_Show      = 1,
    ZHDebugPanelStatusNew_Hide      = 2,
};

@interface ZHDebugPanel : UIView
@property (nonatomic,assign) ZHDebugPanelStatusNew status;

@property (nonatomic,strong) ZHDPOption *option;
@property (nonatomic,strong) ZHDPContent *content;
@end
