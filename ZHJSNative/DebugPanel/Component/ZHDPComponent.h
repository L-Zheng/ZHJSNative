//
//  ZHDPComponent.h
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ZHDebugPanel;// 调试面板

NS_ASSUME_NONNULL_BEGIN

@interface ZHDPComponent : UIView
@property (nonatomic,weak) ZHDebugPanel *debugPanel;
@end

NS_ASSUME_NONNULL_END
