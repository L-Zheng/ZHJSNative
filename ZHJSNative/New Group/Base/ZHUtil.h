//
//  ZHUtil.h
//  ZHJSNative
//
//  Created by EM on 2020/12/20.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZHUtil : NSObject

//解析运行沙盒目录
+ (NSURL *)parseRealRunBoxFolder:(NSURL *)baseURL fileURL:(NSURL *)fileURL;

//获取路径的上级目录
+ (NSString *)fetchSuperiorFolder:(NSString *)path;

@end
