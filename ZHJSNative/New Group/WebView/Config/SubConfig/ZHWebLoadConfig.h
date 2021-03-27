//
//  ZHWebLoadConfig.h
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHWebBaseConfig.h"

/** 👉web load配置 */
@interface ZHWebLoadConfig : ZHWebBaseConfig
// 缓存策略@(NSURLRequestCachePolicy)  默认nil
@property (nonatomic,strong) NSNumber *cachePolicy;
// 超时时间 默认nil
@property (nonatomic,strong) NSNumber *timeoutInterval;
/** web可访问的资源目录【如：表情资源，一般传document目录】
 如果传nil，sdk内部会修改为 fileUrl的上级目录 */
@property (nonatomic,strong) NSURL *readAccessURL;
@end

