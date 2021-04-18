//
//  ZHDebugPanelSearch.h
//  ZHJSNative
//
//  Created by Zheng on 2021/4/18.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZHDebugPanelSearch : UIView

@property (nonatomic,copy) void (^textFieldChangeBlock) (NSString *text);

@end

NS_ASSUME_NONNULL_END
