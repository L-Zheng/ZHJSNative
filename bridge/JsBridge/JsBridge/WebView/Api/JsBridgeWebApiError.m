//
//  JsBridgeWebApiError.m
//  JsBridge
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "JsBridgeWebApiError.h"

@implementation JsBridgeWebApiError

- (void)js_sendNative:(JsBridgeApiArgItem *)arg{
    if (self.handler) self.handler(arg.jsData);
}

- (NSString *)jsBridge_jsApiPrefix{
    return @"My_JsBridge_Error";
}
- (NSString *)jsBridge_iosApiPrefix{
    return @"js_";
}
@end
