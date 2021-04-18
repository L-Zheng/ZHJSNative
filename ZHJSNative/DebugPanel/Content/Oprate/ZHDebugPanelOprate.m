//
//  ZHDebugPanelOprate.m
//  ZHJSNative
//
//  Created by Zheng on 2021/4/18.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDebugPanelOprate.h"

@implementation ZHDebugPanelOprate

#pragma mark - init

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configData];
        [self configUI];
    }
    return self;
}

- (void)dealloc{
}

#pragma mark - config

- (void)configData{
}

- (void)configUI{
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor blueColor];
    
}

#pragma mark - layout

- (void)layoutSubviews{
    [super layoutSubviews];
    
}

@end
