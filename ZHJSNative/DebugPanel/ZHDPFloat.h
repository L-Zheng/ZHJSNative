//
//  ZHDPFloat.h
//  ZHJSNative
//
//  Created by EM on 2021/5/31.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZHDPFloat : UIView
@property (nonatomic,copy) void (^tapBlock) (void);
@property (nonatomic,copy) void (^doubleTapBlock) (void);

- (void)updateTitle:(NSString *)title;
@end

NS_ASSUME_NONNULL_END
