//
//  ZHWebApiOpConfig.m
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHWebApiOpConfig.h"

@implementation ZHWebApiOpConfig
@synthesize belong_controller = _belong_controller;
@synthesize status_controller = _status_controller;
@synthesize navigationBar = _navigationBar;
@synthesize navigationItem = _navigationItem;
@synthesize router_navigationController = _router_navigationController;
- (void)dealloc{
    NSLog(@"%s", __func__);
}
- (NSDictionary *)formatInfo{
    return @{};
}
@end
