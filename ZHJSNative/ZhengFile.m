//
//  ZhengFile.m
//  ZhengFile
//
//  Created by 李保征 on 2017/3/21.
//  Copyright © 2017年 李保征. All rights reserved.
//

#import "ZhengFile.h"

@implementation ZhengFile

+ (long long)readFileSize:(NSString *)filePath{
    // 1.文件管理者
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    // 2.判断file是否存在
    BOOL isDirectory = NO;
    BOOL fileExists = [mgr fileExistsAtPath:filePath isDirectory:&isDirectory];
    // 文件\文件夹不存在
    if (fileExists == NO) return 0;
    
    // 3.判断file是否为文件夹
    if (isDirectory) { // 是文件夹
        NSArray *subpaths = [mgr contentsOfDirectoryAtPath:filePath error:nil];
        long long totalSize = 0;
        for (NSString *subpath in subpaths) {
            NSString *fullSubpath = [filePath stringByAppendingPathComponent:subpath];
            totalSize += [self readFileSize:fullSubpath];
        }
        return totalSize;
    } else { // 不是文件夹, 文件
        // 直接计算当前文件的尺寸
        NSDictionary *attr = [mgr attributesOfItemAtPath:filePath error:nil];
        return [attr[NSFileSize] longLongValue];
    }
}

/** 获取文件(夹)信息 */
+ (NSDictionary *)readFileOrFolderInfo:(NSString *)fileOrFolderPath{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL isDirectory = NO;
    BOOL fileExists = [fileManager fileExistsAtPath:fileOrFolderPath isDirectory:&isDirectory];
    
    if (fileExists) {
        NSDictionary *attr = [fileManager attributesOfItemAtPath:fileOrFolderPath error:nil];
        return attr;
        
    } else {
        return nil;
    }
}

+ (BOOL)deleteFileOrFolder:(NSString *)fileOrFolderPath{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:fileOrFolderPath error:nil];
    return YES;
}

+ (void)deleteFileInFolder:(NSString *)folderPath{
    NSFileManager *manager=[NSFileManager defaultManager];
    //判断文件是不是存在，不存在的话直接返回0
    if ([manager fileExistsAtPath:folderPath]) {
        NSArray *array=[manager subpathsAtPath:folderPath];//获取指定目录下的所有子目录
        
        NSEnumerator *childFile=[array objectEnumerator];//将子目录转换成枚举对象
        
        NSString *subpath;
        //一次取枚举中的下一个元素，进行非空判断
        while ((subpath=[childFile nextObject]) != nil) {
            NSString *newPath=[folderPath stringByAppendingPathComponent:subpath];
            [self deleteFileOrFolder:newPath];
        }
    }
}

+ (BOOL)creatFileFolder:(NSString *)fileFolderPath{
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:fileFolderPath isDirectory:&isDir];
    if ( !(isDir == YES && existed == YES) ){
        BOOL isCreatSuccess = [fileManager createDirectoryAtPath:fileFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
        NSLog(@"创建目录成功---%@",fileFolderPath);
        return isCreatSuccess;
    }
    NSLog(@"创建失败");
    return NO;
}

/** 获取 上一层文件目录 */
+ (NSString *)getUpFileFolder:(NSString *)fileFolderPath{
    
    if (fileFolderPath == nil || fileFolderPath.length == 0) return nil;
    if (![fileFolderPath hasPrefix:@"/"]) return nil;
    if ([fileFolderPath hasSuffix:@"/"]) {
        fileFolderPath = [fileFolderPath substringToIndex:fileFolderPath.length - 1];
    }
    
    NSArray *subComStrArr = [fileFolderPath componentsSeparatedByString:@"/"];
    if (subComStrArr == nil || subComStrArr.count == 0) return nil;
    
    NSMutableString *newStr = [NSMutableString stringWithString:@""];
    for (NSInteger i = 0; i < subComStrArr.count; i++) {
        NSString *subComStr = subComStrArr[i];
        if (i == 0) {
            [newStr appendString:subComStr];
        }
        
        if (i < subComStrArr.count - 2) {
            [newStr appendString:@"/"];
            [newStr appendString:subComStrArr[i+1]];
        }
    }
    return newStr;
}

/** 递归创建文件目录 */
+ (void)recursionCreateFileFolder:(NSString *)fileFolderPath{
    
    if (fileFolderPath == nil || fileFolderPath.length == 0) return;
    if (![fileFolderPath hasPrefix:@"/"]) return;
    if ([fileFolderPath hasSuffix:@"/"]) {
//        NSLog(@"%@",fileFolderPath);
        fileFolderPath = [fileFolderPath substringToIndex:fileFolderPath.length - 1];
//        NSLog(@"%@",fileFolderPath);
    }
    
    NSArray *subComStrArr = [fileFolderPath componentsSeparatedByString:@"/"];
    if (subComStrArr == nil || subComStrArr.count == 0) return;
    
//    NSLog(@"%@",subComStrArr);
//    /Users/em/Desktop/未命名文件夹/v0.1
    
    NSMutableString *newStr = [NSMutableString stringWithString:@""];
    for (NSInteger i = 0; i < subComStrArr.count; i++) {
        NSString *subComStr = subComStrArr[i];
        if (i == 0) {
            [newStr appendString:subComStr];
        }
        
        [newStr appendString:@"/"];
        
        if (i < subComStrArr.count - 1) {
            [newStr appendString:subComStrArr[i+1]];
//            NSLog(@"%@",newStr);
            if (![self isExists:newStr]) {
                [self creatFileFolder:newStr];
            }
        }
        
    }
}

+ (BOOL)creatFile:(NSString *)filePath contents:(NSData *)contents{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]){
        BOOL isCreatSuccess = [fileManager createFileAtPath:filePath contents:contents attributes:nil];
        return isCreatSuccess;
    }
    NSLog(@"创建失败");
    return NO;
}

+ (BOOL)isExists:(NSString *)fileOrFolderPath{
    // 1.文件管理者
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    // 2.判断file是否存在
    BOOL isDirectory = NO;
    BOOL fileExists = [mgr fileExistsAtPath:fileOrFolderPath isDirectory:&isDirectory];
    
    return fileExists;
}

+ (NSMutableArray *)readFolderList:(NSString *)folderPath{
    
    NSFileManager *manager=[NSFileManager defaultManager];
    NSMutableArray *fileListArray = [NSMutableArray array];
    //判断文件是不是存在，不存在的话直接返回0
    if ([manager fileExistsAtPath:folderPath]) {
        
        NSArray *array=[manager subpathsAtPath:folderPath];//获取指定目录下的所有子目录
        
        NSEnumerator *childFile=[array objectEnumerator];//将子目录转换成枚举对象
        
        NSString *subpath;
        //一次取枚举中的下一个元素，进行非空判断
        while ((subpath=[childFile nextObject]) != nil) {
            //                        if ([[subpath substringWithRange:NSMakeRange(subpath.length-3, 3)] isEqualToString:@"mp3"]) {
            //                            //将指定路径经与其子目录拼接成新的字符串作为判断路径
            //                            NSString *newPath=[folderPath stringByAppendingPathComponent:subpath];
            //
            //                            long long size = [FileOperate readFileSize:newPath];
            //
            //                            NSString *string = [NSString stringWithFormat:@"%lld",size];
            //
            //                            NSDictionary *dic = @{@"fileName":subpath,@"fileSize":string};
            //
            //                            [fileListArray addObject:dic];
            //                        }
            //将指定路径经与其子目录拼接成新的字符串作为判断路径
            NSString *newPath=[folderPath stringByAppendingPathComponent:subpath];
            
            long long size = [self readFileSize:newPath];
            
            NSString *string = [NSString stringWithFormat:@"%lld",size];
            
            NSDictionary *dic = @{@"fileName":newPath,@"fileSize":string};
            
            [fileListArray addObject:dic];
        }
    }
    return fileListArray;
}

+ (long long)readSystemTotalSpace{
    NSDictionary *fattributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    return [[fattributes objectForKey:NSFileSystemSize] longLongValue];
}

+ (long long)readSystemFreeSpace{
    NSDictionary *fattributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    return [[fattributes objectForKey:NSFileSystemFreeSize] longLongValue];
}


+ (BOOL)copySourceFile:(NSString *)sourcePath toDesPath:(NSString *)desPath{
    if ([self isExists:sourcePath]) {
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        //源文件存在
        if ([self isExists:desPath]) {
            //目标文件存在
            [fileMgr removeItemAtPath:desPath error:nil];
        }else{
            //目标不存在  获取上一层文件目录  递归创建文件夹
            NSString *upPath = [self getUpFileFolder:desPath];
            [self recursionCreateFileFolder:upPath];
        }
        NSError *error = nil;
        BOOL isSuccess = [fileMgr copyItemAtPath:sourcePath toPath:desPath error:&error];
        return isSuccess;
        
    }else{
        return NO;
    }
}

+ (BOOL)moveSourceFile:(NSString *)sourcePath toDesPath:(NSString *)desPath{
    if ([self isExists:sourcePath]) {
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        //源文件存在
        if ([self isExists:desPath]) {
            //目标文件存在
            [fileMgr removeItemAtPath:desPath error:nil];
        }else{
            //目标不存在  获取上一层文件目录  递归创建文件夹
            NSString *upPath = [self getUpFileFolder:desPath];
            [self recursionCreateFileFolder:upPath];
        }
        NSError *error = nil;
        BOOL isSuccess = [fileMgr moveItemAtPath:sourcePath toPath:desPath error:&error];
        return isSuccess;
        
    }else{
        return NO;
    }
}


/** 解压文件 */
+ (BOOL)unZipSourceFile:(NSString *)sourcePath toDesFolderPath:(NSString *)desFolderPath{
    return NO;
}

/** 压缩文件 */
+ (BOOL)zipSourceFolder:(NSString *)sourceFolderPath toDesPath:(NSString *)desPath{
    return YES;
}



// 获取文档目录路径
///var/mobile/Containers/Data/Application/32053764-FAB0-4C1A-A770-E41440D3E175/Documents
+ (NSString *)getDocumentPath{
    NSArray *userPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [userPaths objectAtIndex:0];
}

// 获取cache目录路径
///var/mobile/Containers/Data/Application/32053764-FAB0-4C1A-A770-E41440D3E175/Library/Caches
+ (NSString *)getCachePath{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

// 获取temp目录路径
+ (NSString *)getTemporaryPath{
    return NSTemporaryDirectory();
}

@end
