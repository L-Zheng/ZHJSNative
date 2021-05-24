//
//  ZHJSDebugManager.m
//  ZHJSNative
//
//  Created by EM on 2021/5/24.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHJSDebugManager.h"

@interface ZHJSDebugManager ()
@property (nonatomic,strong) NSMutableDictionary *debugWebConfig;
@property (nonatomic,strong) NSMutableDictionary *itemWebMap;

@property (nonatomic,strong) NSMutableDictionary *debugCtxConfig;
@property (nonatomic,strong) NSMutableDictionary *itemCtxMap;
@end

@implementation ZHJSDebugManager

- (void)config{
#ifdef DEBUG
    [self setWebDebugGlobalEnableWhenNoStore:YES];
    [self setCtxDebugGlobalEnableWhenNoStore:YES];
    
    [self setWebDebugAlertErrorEnable:YES];
    [self setCtxDebugAlertErrorEnable:YES];
#else
#endif
}

#pragma mark - debug web

- (NSString *)webDebugAlertErrorKey{
    return @"alertError";
}
- (BOOL)setWebDebugAlertErrorEnable:(BOOL)enable{
    if ([self getWebDebugAlertErrorEnable] == enable) {
        return YES;
    }
    BOOL res = [self storeWebDebugObj:self.webDebugAlertErrorKey value:@(enable)];
    return res;
}
- (BOOL)getWebDebugAlertErrorEnable{
    id obj = [self readWebDebugObj:self.webDebugAlertErrorKey];
    return ((obj && [obj isKindOfClass:[NSNumber class]]) ? [obj boolValue] : NO);
}

- (NSString *)webDebugGlobalKey{
    return @"DebugGlobal";
}
- (BOOL)setWebDebugGlobalEnable:(BOOL)enable{
    if ([self getWebDebugGlobalEnable] == enable) {
        return YES;
    }
    BOOL res = [self storeWebDebugObj:self.webDebugGlobalKey value:@(enable)];
    
    // 调试开关发生改变 移除全局debugItem
    [self removeWebDebugGlobalItem];
    
    return res;
}
- (BOOL)setWebDebugGlobalEnableWhenNoStore:(BOOL)enable{
    id obj = [self readWebDebugObj:self.webDebugGlobalKey];
    if (obj) return YES;
    return [self setWebDebugGlobalEnable:enable];
}
- (BOOL)getWebDebugGlobalEnable{
    id obj = [self readWebDebugObj:self.webDebugGlobalKey];
    return ((obj && [obj isKindOfClass:[NSNumber class]]) ? [obj boolValue] : NO);
}

- (void)removeWebDebugGlobalItem{
    [self.itemWebMap removeAllObjects];
}
- (ZHWebDebugItem *)getWebDebugGlobalItem:(NSString *)key{
    if (!key || ![key isKindOfClass:NSString.class] || key.length == 0) {
        return [ZHWebDebugItem defaultItem];
    }
    if (!self.itemWebMap) {
        self.itemWebMap = [NSMutableDictionary dictionary];
    }
    ZHWebDebugItem *item = [self.itemWebMap objectForKey:key];
    if (!item) {
        item = [ZHWebDebugItem defaultItem];
        [self.itemWebMap setObject:item forKey:key];
    }
    return item;
}

- (NSString *)storeWebDebugFilePath{
    return [[self debugStoreDir] stringByAppendingPathComponent:@"WebConfig.json"];
}
- (BOOL)storeWebDebugObj:(NSString *)debugKey value:(id)value{
    if (!debugKey || ![debugKey isKindOfClass:NSString.class] || debugKey.length == 0 ||
        !value) {
        return NO;
    }
    NSString *filePath = [self storeWebDebugFilePath];
    if (!self.debugWebConfig) self.debugWebConfig = [NSMutableDictionary dictionary];
    [self.debugWebConfig setObject:value forKey:debugKey];
    return [self jsonToFilePath:self.debugWebConfig filePath:filePath];
}
- (id)readWebDebugObj:(NSString *)debugKey{
    if (!debugKey || ![debugKey isKindOfClass:NSString.class] || debugKey.length == 0) {
        return nil;
    }
    NSString *filePath = [self storeWebDebugFilePath];
    if (!self.debugWebConfig) self.debugWebConfig = [self readJsonFromFilePath:filePath];
    return [self.debugWebConfig objectForKey:debugKey];
}

#pragma mark - debug ctx

- (NSString *)ctxDebugAlertErrorKey{
    return @"alertError";
}
- (BOOL)setCtxDebugAlertErrorEnable:(BOOL)enable{
    if ([self getCtxDebugAlertErrorEnable] == enable) {
        return YES;
    }
    BOOL res = [self storeCtxDebugObj:self.ctxDebugAlertErrorKey value:@(enable)];
    return res;
}
- (BOOL)getCtxDebugAlertErrorEnable{
    id obj = [self readCtxDebugObj:self.ctxDebugAlertErrorKey];
    return ((obj && [obj isKindOfClass:[NSNumber class]]) ? [obj boolValue] : NO);
}

- (NSString *)ctxDebugGlobalKey{
    return @"DebugGlobal";
}
- (BOOL)setCtxDebugGlobalEnable:(BOOL)enable{
    if ([self getCtxDebugGlobalEnable] == enable) {
        return YES;
    }
    BOOL res = [self storeCtxDebugObj:self.ctxDebugGlobalKey value:@(enable)];
    
    // 调试开关发生改变 移除全局debugItem
    [self removeCtxDebugGlobalItem];
    
    return res;
}
- (BOOL)setCtxDebugGlobalEnableWhenNoStore:(BOOL)enable{
    id obj = [self readCtxDebugObj:self.ctxDebugGlobalKey];
    if (obj) return YES;
    return [self setCtxDebugGlobalEnable:enable];
}
- (BOOL)getCtxDebugGlobalEnable{
    id obj = [self readCtxDebugObj:self.ctxDebugGlobalKey];
    return ((obj && [obj isKindOfClass:[NSNumber class]]) ? [obj boolValue] : NO);
}

- (void)removeCtxDebugGlobalItem{
    [self.itemCtxMap removeAllObjects];
}
- (ZHCtxDebugItem *)getCtxDebugGlobalItem:(NSString *)key{
    if (!key || ![key isKindOfClass:NSString.class] || key.length == 0) {
        return [ZHCtxDebugItem defaultItem];
    }
    if (!self.itemCtxMap) {
        self.itemCtxMap = [NSMutableDictionary dictionary];
    }
    ZHCtxDebugItem *item = [self.itemCtxMap objectForKey:key];
    if (!item) {
        item = [ZHCtxDebugItem defaultItem];
        [self.itemCtxMap setObject:item forKey:key];
    }
    return item;
}

- (NSString *)storeCtxDebugFilePath{
    return [[self debugStoreDir] stringByAppendingPathComponent:@"CtxConfig.json"];
}
- (BOOL)storeCtxDebugObj:(NSString *)debugKey value:(id)value{
    if (!debugKey || ![debugKey isKindOfClass:NSString.class] || debugKey.length == 0 ||
        !value) {
        return NO;
    }
    NSString *filePath = [self storeCtxDebugFilePath];
    if (!self.debugCtxConfig) self.debugCtxConfig = [NSMutableDictionary dictionary];
    [self.debugCtxConfig setObject:value forKey:debugKey];
    return [self jsonToFilePath:self.debugCtxConfig filePath:filePath];
}
- (id)readCtxDebugObj:(NSString *)debugKey{
    if (!debugKey || ![debugKey isKindOfClass:NSString.class] || debugKey.length == 0) {
        return nil;
    }
    NSString *filePath = [self storeCtxDebugFilePath];
    if (!self.debugCtxConfig) self.debugCtxConfig = [self readJsonFromFilePath:filePath];
    return [self.debugCtxConfig objectForKey:debugKey];
}

#pragma mark - debug store

- (NSString *)debugStoreDir{
    NSString *res = nil;
    
    NSArray *userPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    if (userPaths.count > 0) {
        res = [userPaths firstObject];
    }else{
        userPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        if (userPaths.count > 0) {
            res = [[userPaths lastObject] stringByAppendingPathComponent:@"Caches"];
        }else{
            res = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Caches"];
        }
    }
    return [[[res stringByAppendingPathComponent:@"com.zh.JSNative.SroreDir"] stringByAppendingPathComponent:@"Debug"] stringByAppendingPathComponent:@"DebugEnable"];
}
- (NSMutableDictionary *)readJsonFromFilePath:(NSString *)filePath{
    NSMutableDictionary *emptyRes = [@{} mutableCopy];
    
    if (!filePath || ![filePath isKindOfClass:NSString.class] || filePath.length == 0) {
        return emptyRes;
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    
    BOOL isDirectory = YES;
    BOOL success = [fm fileExistsAtPath:filePath isDirectory:&isDirectory];
    if (!success || isDirectory) {
        return emptyRes;
    }
    NSData *data = [fm contentsAtPath:filePath];
    if (!data) {
        return emptyRes;
    }
    NSError *jsonError = nil;
    id json = nil;
    @try {
        json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
    } @catch (NSException *exception) {
    } @finally {
    }
    if (jsonError || !json || ![json isKindOfClass:NSDictionary.class] || ((NSDictionary *)json).allKeys.count == 0) {
        return emptyRes;
    }
    return [json mutableCopy];
}
- (BOOL)jsonToFilePath:(id)json filePath:(NSString *)filePath{
    if (!json || ![json isKindOfClass:NSDictionary.class] || ((NSDictionary *)json).allKeys.count == 0) {
        return NO;
    }
    
    NSError *jsonError = nil;
    NSData *data = nil;
    @try {
        data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&jsonError];
    } @catch (NSException *exception) {
    } @finally {
    }
    
    if (jsonError || !data) {
        return NO;
    }
    
    NSString *fileDir = [self debugStoreDir];
    if (!fileDir || ![fileDir isKindOfClass:NSString.class] || fileDir.length == 0 ||
        !filePath || ![filePath isKindOfClass:NSString.class] || filePath.length == 0) {
        return NO;
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *fileError = nil;
    BOOL isDirectory = YES;
    BOOL success = [fm fileExistsAtPath:fileDir isDirectory:&isDirectory];
    if (success) {
        if (!isDirectory) {
            success = [fm removeItemAtPath:fileDir error:&fileError];
            if (!success || fileError) return NO;
            
            success = [fm createDirectoryAtPath:fileDir withIntermediateDirectories:YES attributes:nil error:&fileError];
            if (!success || fileError) return NO;
        }
    }else{
        success = [fm createDirectoryAtPath:fileDir withIntermediateDirectories:YES attributes:nil error:&fileError];
        if (!success || fileError) return NO;
    }
    
    
    success = [fm fileExistsAtPath:filePath isDirectory:&isDirectory];
    if (success) {
        NSError *fileError = nil;
        success = [fm removeItemAtPath:filePath error:&fileError];
        if (!success || fileError) return NO;
    }
    success = [fm createFileAtPath:filePath contents:data attributes:nil];
    return success;
}

#pragma mark - available

- (BOOL)availableIOS11{
    if (@available(iOS 11.0, *)) {
        return YES;
    }
    return NO;
}
- (BOOL)availableIOS10{
    if (@available(iOS 10.0, *)) {
        return YES;
    }
    return NO;
}
- (BOOL)availableIOS9{
    if (@available(iOS 9.0, *)) {
        return YES;
    }
    return NO;
}

#pragma mark - share

- (instancetype)init{
    if (self = [super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self config];
        });
    }
    return self;
}

static id _instance;

+ (instancetype)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

@end
