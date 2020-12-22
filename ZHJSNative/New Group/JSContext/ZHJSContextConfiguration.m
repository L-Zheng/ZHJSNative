//
//  ZHJSContextConfiguration.m
//  ZHJSNative
//
//  Created by EM on 2020/12/19.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHJSContextConfiguration.h"
#import "ZHJSNativeItem.h" // WebView/JSContext页面信息数据

@implementation ZHJSContextModuleConfiguration
- (NSDictionary *)formatInfo{
    return @{};
}
- (void)dealloc{
    NSLog(@"%s", __func__);
}
@end


/** 👉JSContext 绑定的小程序配置 */
@implementation ZHJSContextAppletConfiguration
- (NSDictionary *)formatInfo{
    return @{
        @"appId": self.appId?:@"",
        @"loadFileName": self.loadFileName?:@"",
        @"presetFilePath": self.presetFilePath?:@""
    };
}
- (void)dealloc{
    NSLog(@"%s", __func__);
}
@end


/** 👉JSContext 创建配置 */
@implementation ZHJSContextCreateConfiguration
- (void)dealloc{
    NSLog(@"%s", __func__);
}
@end


/** 👉JSContext load配置 */
@implementation ZHJSContextLoadConfiguration
- (NSDictionary *)formatInfo{
    return @{};
}
- (void)dealloc{
    NSLog(@"%s", __func__);
}
@end


/** 👉JSContext 配置 */
@implementation ZHJSContextConfiguration
- (NSDictionary *)formatInfo{
    return @{
        @"appletConfig": [self.appletConfig formatInfo],
        @"createConfig": [self.createConfig formatInfo],
        @"loadConfig": [self.loadConfig formatInfo]
    };
}
- (void)dealloc{
    NSLog(@"%s", __func__);
}
@end


/** 👉JSContext 调试配置 */
@interface ZHJSContextDebugConfiguration ()
// 总调试开关
@property (nonatomic,assign) BOOL debugEnable;

@end
@implementation ZHJSContextDebugConfiguration : NSObject

+ (instancetype)configuration:(ZHJSContext *)jsContext{
    ZHJSContextDebugConfiguration *config = [[ZHJSContextDebugConfiguration alloc] init];
    config.jsContext = jsContext;
    [config configProperty];
    return config;
}

// 配置属性
- (void)configProperty{
    self.debugEnable = [self.class readEnable];
}
+ (BOOL)readEnable{
#ifdef DEBUG
    return YES;
#else
    return NO;
#endif
}

- (BOOL)logOutputXcodeEnable{
    return self.debugEnable;
}
- (BOOL)alertJsContextErrorEnable{
    return self.debugEnable;
}

@end
