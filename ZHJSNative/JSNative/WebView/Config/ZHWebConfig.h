//
//  ZHWebConfig.h
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHWebBaseConfig.h"
#import "ZHWebCreateConfig.h"
#import "ZHWebLoadConfig.h"
#import "ZHWebApiOpConfig.h"
#import "ZHWebMpConfig.h"

/** 👉web 配置 */
@interface ZHWebConfig : ZHWebBaseConfig
@property (nonatomic,strong) ZHWebCreateConfig *createConfig;
@property (nonatomic,strong) ZHWebLoadConfig *loadConfig;
@property (nonatomic,strong) ZHWebApiOpConfig <ZHJSPageApiOpProtocol> *apiOpConfig;
@property (nonatomic,strong) ZHWebMpConfig *mpConfig;
@end
