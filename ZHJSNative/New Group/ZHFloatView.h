//
//  ZHFloatView.h
//  ZHFloatWindow
//
//  Created by Zheng on 2020/3/28.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZHFloatView : UIView

+ (ZHFloatView *)floatView;
- (void)showInView:(UIView *)view;

- (void)updateWhenSuperViewLayout;
- (void)updateTitle:(NSString *)title;

@property (nonatomic, copy) void (^tapClickBlock) (void);
@property (nonatomic, copy) void (^panGestureBegan) (void);
@property (nonatomic, copy) void (^panGestureChanged) (CGRect currentFrame);
@property (nonatomic, copy) void (^panGestureEnd) (void);

@end

NS_ASSUME_NONNULL_END
