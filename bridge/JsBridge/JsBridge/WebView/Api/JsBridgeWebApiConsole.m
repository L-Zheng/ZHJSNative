//
//  JsBridgeWebApiConsole.m
//  JsBridge
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "JsBridgeWebApiConsole.h"

@implementation JsBridgeWebApiConsole

- (void)js_sendNative:(JsBridgeApiArgItem *)arg1 arg2:(JsBridgeApiArgItem *)arg2{
    if (self.handler) self.handler(arg1.jsData, arg2.jsData);
}

- (NSString *)jsBridge_jsApiPrefix{
    return @"JsBridge_Console";
}
- (NSString *)jsBridge_iosApiPrefix{
    return @"js_";
}
- (BOOL)jsBridge_privateApi{
    return YES;
}

@end
