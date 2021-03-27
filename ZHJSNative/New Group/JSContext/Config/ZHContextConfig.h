//
//  ZHContextConfig.h
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHContextBaseConfig.h"
#import "ZHContextCreateConfig.h"
#import "ZHContextLoadConfig.h"
#import "ZHContextApiOpConfig.h"
#import "ZHContextMpConfig.h"

/** 👉JSContext 配置 */
@interface ZHContextConfig : ZHContextBaseConfig
@property (nonatomic,strong) ZHContextMpConfig *mpConfig;
@property (nonatomic,strong) ZHContextCreateConfig *createConfig;
@property (nonatomic,strong) ZHContextLoadConfig *loadConfig;
@property (nonatomic,strong) ZHContextApiOpConfig <ZHJSPageApiOpProtocol> *apiOpConfig;
@end
