//
//  ZHWebCreateConfig.h
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHWebBaseConfig.h"
#import <WebKit/WebKit.h>
#import "ZHJSApiProtocol.h"

/** 👉web 创建配置 */
@interface ZHWebCreateConfig : ZHWebBaseConfig
// 初始化frame
@property (nonatomic,strong) NSValue *frameValue;
/** 内容进程池
 传nil：会自动创建一个新的processPool，不同的web的processPool不同，内容数据不能共享。
 如要共享内容数据（如： localstorage数据）可自行创建processPool单例，不同的web共用此单例
 */
@property (nonatomic,strong) WKProcessPool *processPool;
// web需要注入的api【如：fund API】
@property (nonatomic,retain) NSArray <id <ZHJSApiProtocol>> *apiHandlers;
// web初始化附加脚本：document start时注入
@property (nonatomic,copy) NSString *extraScriptStart;
// web初始化附加脚本：document end时注入
@property (nonatomic,copy) NSString *extraScriptEnd;
@end
