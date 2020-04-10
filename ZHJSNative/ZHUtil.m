//
//  ZHUtil.m
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHUtil.h"

@implementation ZHUtil

+ (NSString *)bundlePath{
    return [[NSBundle mainBundle] pathForResource:@"TestBundle" ofType:@"bundle"];
}

+ (NSString *)pathWithName:(NSString *)name{
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TestBundle" ofType:@"bundle"]];
    NSString *destPath = [bundle pathForResource:name.stringByDeletingPathExtension ofType:name.pathExtension];
    return destPath;
}

+ (NSString *)htmlPath{
    return [self pathWithName:@"test.html"];
}
+ (NSString *)jsPath{
    return [self pathWithName:@"test.js"];
}




@end
