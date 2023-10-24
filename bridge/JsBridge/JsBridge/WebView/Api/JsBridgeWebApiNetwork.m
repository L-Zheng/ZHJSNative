//
//  JsBridgeWebApiNetwork.m
//  JsBridge
//
//  Created by EM on 2023/7/12.
//

#import "JsBridgeWebApiNetwork.h"

@implementation JsBridgeWebApiNetwork

- (void)js_sendNative:(JsBridgeApiArgItem *)arg1{
    if (self.handler) self.handler(arg1.jsData);
}

- (NSString *)jsBridge_jsApiPrefix{
    return @"JsBridge_Network";
}
- (NSString *)jsBridge_iosApiPrefix{
    return @"js_";
}
- (BOOL)jsBridge_privateApi{
    return YES;
}

@end
