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

+ (NSString *)htmlPath{
    NSString *name = @"test.html";
    NSBundle *bundle = [NSBundle bundleWithPath:[self bundlePath]];
    NSString *destPath = [bundle pathForResource:name.stringByDeletingPathExtension ofType:name.pathExtension];
    return destPath;
}
+ (NSString *)jsPath{
    NSString *name = @"test.js";
    NSBundle *bundle = [NSBundle bundleWithPath:[self bundlePath]];
    NSString *destPath = [bundle pathForResource:name.stringByDeletingPathExtension ofType:name.pathExtension];
    return destPath;
}
+ (NSString *)jsEventPath{
    NSString *name = @"event.js";
    NSBundle *bundle = [NSBundle bundleWithPath:[self bundlePath]];
    NSString *destPath = [bundle pathForResource:name.stringByDeletingPathExtension ofType:name.pathExtension];
    return destPath;
}

#pragma mark - encode

+ (NSString *)encodeObj:(id)data{
    NSString *res = nil;
    if ([data isKindOfClass:[NSString class]]) {
        res = (NSString *)data;
    }else if ([data isKindOfClass:[NSNumber class]]){
        res = [NSString stringWithFormat:@"%@",data];
    }else if ([data isKindOfClass:[NSDictionary class]] ||
              [data isKindOfClass:[NSArray class]]){
        NSError *jsonError;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&jsonError];
        res = jsonError ? jsonError.localizedDescription : [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        if (jsonError) return nil;
        res = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }else if ([data isKindOfClass:[NSObject class]]){
        res = [data description];
    }else{
        //默认obj作为BOOL值处理
        res = [NSString stringWithFormat:@"%d",data];
    }
    return [res stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

/// 本地路径转NSURL，支持带参数（系统的fileURLWithPath会导致参数被编码，webview加载失败）
/// @param path 本地k路径
/// @param isDirectory 是否文件夹
+ (NSURL *)fileURLWithPath:(NSString *)path isDirectory:(BOOL)isDirectory {
    NSArray *components = [path componentsSeparatedByString:@"?"];
    if (components.count < 1) {
        return nil;
    }
    NSString *subPath = components[0];
    NSURL *fileUrl = [NSURL fileURLWithPath:subPath isDirectory:isDirectory];
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:fileUrl resolvingAgainstBaseURL:NO];
    
    if (components.count > 1) {
        NSString *paramStr = components[1];
        NSArray *params = [paramStr componentsSeparatedByString:@"&"];
        NSMutableArray *queryItems = [NSMutableArray new];
        for (NSString *param in params) {
            NSArray *keyValue = [param componentsSeparatedByString:@"="];
            if (keyValue.count > 1) {
                [queryItems addObject:[NSURLQueryItem queryItemWithName:keyValue[0] value:keyValue[1]]];
            }
        }
        [urlComponents setQueryItems:queryItems];
    }
    return urlComponents.URL;
}


/**拷贝文件(文件夹)到temp目录，hierarchy 需要拷贝的目录层级，
 hierarchy = 0表示仅拷贝srcPath
 hierarchy = 1表示拷贝和srcPath同层级的所有文件
 hierarchy = 2表示拷贝和srcPath同层级的所有文件及上一层所有
 hierarchy = 3表示和srcPath同层及其上2层
 一次类推
 */
+ (NSString *)copyToTempWithPath:(NSString *)srcPath hierarchy:(NSInteger)hierarchy {
    
    // 如果有参数先记下来
    NSString *params = @"";
    NSArray *array = [srcPath componentsSeparatedByString:@"?"];
    if (array.count > 1) {
        srcPath = array[0];
        params = array[1];
    }
    
    NSURL *fileURL = [NSURL fileURLWithPath:srcPath];
    NSError *error = nil;
    if (!fileURL.fileURL || ![fileURL checkResourceIsReachableAndReturnError:&error]) {
        return nil;
    }
    // Create "/temp/www" directory
    //    NSFileManager *fileManager= [NSFileManager defaultManager];
    NSString *temDirURL = NSTemporaryDirectory();
    NSString *currentPath = [NSString stringWithString:srcPath];
    NSString *dstPath = @"";
    NSString *lastPath = @"";
    
    if (hierarchy == 0) {
        currentPath = srcPath;
        dstPath = [NSString stringWithFormat:@"%@%@",temDirURL,srcPath.lastPathComponent];
        [self copyItemAtPath:currentPath toPath:dstPath];
    } else {
        //寻找倒数第hierarchy个‘/’
        NSRange range = NSMakeRange(0, srcPath.length);
        NSRegularExpression *regx = [NSRegularExpression regularExpressionWithPattern:@"/" options:NSRegularExpressionCaseInsensitive | NSRegularExpressionIgnoreMetacharacters error:nil];
        NSArray *matches = [regx matchesInString:srcPath options:0 range:range];
        if (matches.count > hierarchy) {
            //需要拷贝的那一层目录
            NSTextCheckingResult *match = matches[matches.count - hierarchy];
            NSRange matchRange = match.range;
            currentPath = [srcPath substringToIndex:matchRange.location];
            lastPath = [srcPath substringFromIndex:matchRange.location + matchRange.length];
            
            //找到上一个/来找到需要拷贝的目录名
            NSTextCheckingResult *matchP = matches[matches.count - hierarchy - 1];
            NSRange matchRangeP = matchP.range;
            NSString *folderName = [srcPath substringWithRange:NSMakeRange(matchRangeP.location + matchRangeP.length, matchRange.location - matchRangeP.location - matchRangeP.length)];
            dstPath = [NSString stringWithFormat:@"%@%@",temDirURL,folderName];
            [self copyItemAtPath:currentPath toPath:dstPath];
            NSString *result = [NSString stringWithFormat:@"%@/%@",dstPath,lastPath];
            dstPath = result;
        } else {
            NSLog(@"错误：拷贝的目录层级超过总层级了");
        }
        
    }
    // 最后再把参数拼上
    if (params.length > 0) {
        dstPath = [NSString stringWithFormat:@"%@?%@", dstPath, params];
    }
    return dstPath;
}

/**创建目录*/
+ (BOOL)creatDirectory:(NSString *)path {
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    //目标路径的目录不存在则创建目录
    if (!(isDir == YES && existed == YES)) {
        return [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    } else {
        return NO;
    }
}

/**拷贝文件(文件夹)*/
+ (BOOL)copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (srcPath.length < 1) {
        return NO;
    }
    BOOL isDir = NO;
    BOOL exist = [fileManager fileExistsAtPath:srcPath isDirectory:&isDir];
    if (!exist) {
        return NO;
    }
    
    NSString *creatPath = dstPath;
    if (!isDir) {
        creatPath = [dstPath stringByDeletingLastPathComponent];
    }
    //如果不存在则创建目录
    [self creatDirectory:creatPath];
    
    NSError *error;
    
    [fileManager removeItemAtPath:creatPath error:&error];
    return [fileManager copyItemAtPath:srcPath toPath:creatPath error:&error];
}


@end
