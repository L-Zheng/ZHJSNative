//
//  ZHUtil.h
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZHUtil : NSObject

+ (NSString *)bundlePath;
+ (NSString *)pathWithName:(NSString *)name;
+ (NSString *)htmlPath;
+ (NSString *)jsPath;
+ (NSString *)jsEventPath;
+ (NSString *)jsLogEventPath;
+ (NSString *)jsErrorEventPath;
+ (NSString *)jsSocketEventPath;

//编码
+ (NSString *)encodeObj:(id)data;

/// 本地路径转NSURL，支持带参数（系统的fileURLWithPath会导致参数被编码，webview加载失败）
/// @param path 本地k路径
/// @param isDirectory 是否文件夹
+ (NSURL *)fileURLWithPath:(NSString *)path isDirectory:(BOOL)isDirectory;


/**拷贝文件(文件夹)到temp目录，hierarchy 需要拷贝的目录层级，
 hierarchy = 0表示仅拷贝srcPath
 hierarchy = 1表示拷贝和srcPath同层级的所有文件
 hierarchy = 2表示拷贝和srcPath同层级的所有文件及上一层所有
 hierarchy = 3表示和srcPath同层及其上2层
 一次类推
 */
+ (NSString *)copyToTempWithPath:(NSString *)srcPath hierarchy:(NSInteger)hierarchy;

@end

NS_ASSUME_NONNULL_END
