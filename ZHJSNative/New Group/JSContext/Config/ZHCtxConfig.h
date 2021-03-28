//
//  ZHCtxConfig.h
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHCtxBaseConfig.h"
#import "ZHCtxCreateConfig.h"
#import "ZHCtxLoadConfig.h"
#import "ZHCtxApiOpConfig.h"
#import "ZHCtxMpConfig.h"

/** 👉JSContext 配置 */
@interface ZHCtxConfig : ZHCtxBaseConfig
@property (nonatomic,strong) ZHCtxMpConfig *mpConfig;
@property (nonatomic,strong) ZHCtxCreateConfig *createConfig;
@property (nonatomic,strong) ZHCtxLoadConfig *loadConfig;
@property (nonatomic,strong) ZHCtxApiOpConfig <ZHJSPageApiOpProtocol> *apiOpConfig;
@end
