//
//  ZHDebugPanelOption.h
//  ZHJSNative
//
//  Created by Zheng on 2021/4/17.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ZHDebugPanelContent;
@class ZHDebugPanel;

NS_ASSUME_NONNULL_BEGIN

@interface ZHDebugPanelOption : UIView

@property (nonatomic,weak) ZHDebugPanel *debugPanel;

- (void)reloadWithItems:(NSArray *)items;

- (void)selectContent:(ZHDebugPanelContent *)content;
- (void)selectIndexPath:(NSIndexPath *)indexPath;
@property (nonatomic,copy) void (^selectBlock) (ZHDebugPanelContent *content);

@end

NS_ASSUME_NONNULL_END
