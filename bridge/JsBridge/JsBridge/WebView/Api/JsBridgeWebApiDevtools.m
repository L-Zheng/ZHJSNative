//
//  JsBridgeWebApiDevtools.m
//  JsBridge
//
//  Created by EM on 2024/4/7.
//

#import "JsBridgeWebApiDevtools.h"

@implementation JsBridgeWebApiDevtools

- (void)js_open:(JsBridgeApiArgItem *)arg1{
    if (self.handler && arg1.callItem && arg1.callItem.jsFuncArg_call) {
        self.handler(^(NSDictionary *info) {
            arg1.callItem.jsFuncArg_call(info);
        });
    }
}

- (NSString *)jsBridge_jsApiPrefix{
    return @"JsBridge_Devtools";
}
- (NSString *)jsBridge_iosApiPrefix{
    return @"js_";
}
- (BOOL)jsBridge_privateApi{
    return YES;
}


@end
