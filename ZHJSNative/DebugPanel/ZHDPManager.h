//
//  ZHDPManager.h
//  ZHJSNative
//
//  Created by EM on 2021/5/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZHDPDataTask.h"
#import "ZHDPWindow.h"

typedef NS_ENUM(NSInteger, ZHDPManagerStatus) {
    ZHDPManagerStatus_Unknown     = 0,
    ZHDPManagerStatus_Open      = 1,
    ZHDPManagerStatus_Close      = 2
};

@interface ZHDPManager : NSObject

+ (instancetype)shareManager;
@property (nonatomic,assign) ZHDPManagerStatus status;
@property (nonatomic,strong) ZHDPDataTask *dataTask;
@property (nonatomic,strong) ZHDPWindow *window;

#pragma mark - open close

- (void)open;
- (void)close;

#pragma mark - switch

- (void)switchFloat;
- (void)switchDebugPanel;

#pragma mark - font

- (UIFont *)iconFontWithSize:(CGFloat)fontSize;
- (UIFont *)defaultFont;

#pragma mark - color

- (UIColor *)defaultColor;
- (UIColor *)selectColor;
@end

__attribute__((unused)) static ZHDPManager * ZHDPMg() {
    return [ZHDPManager shareManager];
}
