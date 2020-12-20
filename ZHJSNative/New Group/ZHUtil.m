//
//  ZHUtil.m
//  ZHJSNative
//
//  Created by EM on 2020/12/20.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHUtil.h"

@implementation ZHUtil

//解析运行沙盒目录
+ (NSURL *)parseRealRunBoxFolder:(NSURL *)baseURL fileURL:(NSURL *)fileURL{
    if (baseURL) return baseURL;
    
    if (!fileURL || !fileURL.isFileURL) {
        return nil;
    }
    
    //没有传沙盒路径 默认url的上一级目录为沙盒目录
    NSString *superFolder = [self fetchSuperiorFolder:fileURL.path];
    if (!superFolder) {
        return nil;
    }
    NSURL *superURL = [NSURL fileURLWithPath:superFolder];
    if (![[NSFileManager defaultManager] fileExistsAtPath:superURL.path]) {
        return nil;
    }
    return superURL;
}

//获取路径的上级目录
+ (NSString *)fetchSuperiorFolder:(NSString *)path{
    if (!path || ![path isKindOfClass:[NSString class]] || path.length == 0) return nil;

    NSMutableArray *pathComs = [[path pathComponents] mutableCopy];
    if (pathComs.count <= 1) {
        return nil;
    }
    [pathComs removeLastObject];
    return [NSString pathWithComponents:pathComs];
}

@end
