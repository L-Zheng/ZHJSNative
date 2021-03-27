//
//  ZHWebFetchConfig.h
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHWebBaseConfig.h"

/** 👉web fetch配置 */
@interface ZHWebFetchConfig : ZHWebBaseConfig
// 查找web资源的完整信息
@property (nonatomic,strong) NSDictionary *fullInfo;
// 小程序appId
@property (nonatomic,copy) NSString *appId;
@end
