//
//  ZHCtxCreateConfig.h
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHCtxBaseConfig.h"
#import "ZHJSApiProtocol.h"

/** 👉JSContext 创建配置 */
@interface ZHCtxCreateConfig : ZHCtxBaseConfig
// JSContext需要注入的api【如：fund API】
@property (nonatomic,retain) NSArray <id <ZHJSApiProtocol>> *apis;
// 是否注入内置默认api  默认YES
@property (nonatomic,assign) BOOL injectInAPI;
@end

