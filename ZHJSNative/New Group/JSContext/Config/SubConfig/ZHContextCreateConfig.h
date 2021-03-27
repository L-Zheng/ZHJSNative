//
//  ZHContextCreateConfig.h
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHContextBaseConfig.h"
#import "ZHJSApiProtocol.h"

/** 👉JSContext 创建配置 */
@interface ZHContextCreateConfig : ZHContextBaseConfig
// JSContext需要注入的api【如：fund API】
@property (nonatomic,retain) NSArray <id <ZHJSApiProtocol>> *apiHandlers;
@end

