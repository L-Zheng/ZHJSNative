//
//  ZhengFile.h
//  ZhengFile
//
//  Created by 李保征 on 2017/3/21.
//  Copyright © 2017年 李保征. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZhengFile : NSObject

/** 获取文件(夹)大小  字节数 */
+ (long long)readFileSize:(NSString *)filePath;

/** 获取文件(夹)信息 */
+ (NSDictionary *)readFileOrFolderInfo:(NSString *)fileOrFolderPath;

/** 删除文件(夹) 包含文件夹本身 */
+ (BOOL)deleteFileOrFolder:(NSString *)fileOrFolderPath;

/** 删除文件夹下的所有文件 不包含文件夹本身 */
+ (void)deleteFileInFolder:(NSString *)folderPath;

/** 创建文件夹 */
+ (BOOL)creatFileFolder:(NSString *)fileFolderPath;

/** 获取 上一层文件目录 */
+ (NSString *)getUpFileFolder:(NSString *)fileFolderPath;

/** 递归创建文件目录 */
+ (void)recursionCreateFileFolder:(NSString *)fileFolderPath;

/** 创建文件 */
+ (BOOL)creatFile:(NSString *)filePath contents:(NSData *)contents;

/** 文件(夹)是否存在 */
+ (BOOL)isExists:(NSString *)fileOrFolderPath;

/** 给定文件夹 返回文件目录及大小 数组里面装着包含目录及大小的字典 */
+ (NSMutableArray *)readFolderList:(NSString *)folderPath;

/** 获取手机全部存储空间 */
+ (long long)readSystemTotalSpace;

/** 获取手机全部存储空间 */
+ (long long)readSystemFreeSpace;


/** 拷贝文件(夹)  有bug  不能递归创建文件夹 */
+ (BOOL)copySourceFile:(NSString *)sourcePath toDesPath:(NSString *)desPath;

/** 移动文件(夹) */
+ (BOOL)moveSourceFile:(NSString *)sourcePath toDesPath:(NSString *)desPath;


/** 解压文件  大文件放到子线程 */
+ (BOOL)unZipSourceFile:(NSString *)sourcePath toDesFolderPath:(NSString *)desFolderPath;

/** 压缩文件  大文件放到子线程 */
+ (BOOL)zipSourceFolder:(NSString *)sourceFolderPath toDesPath:(NSString *)desPath;


/** 获取Doc目录路径 */
+ (NSString *)getDocumentPath;

/** 获取cache目录路径 */
+ (NSString *)getCachePath;

/** 获取temp目录路径 */
+ (NSString *)getTemporaryPath;

@end
