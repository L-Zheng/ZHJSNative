//
//  ZHCtxDebugManager.m
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHCtxDebugManager.h"

NSString * const ZHCtxDebugEnableKey = @"ZHCtxDebugEnableKey";

@interface ZHCtxDebugManager ()
@property (nonatomic,strong) NSNumber *debugEnable_memory;
@property (nonatomic,strong) NSMutableDictionary *itemMap;
@end

@implementation ZHCtxDebugManager

- (void)config{
#ifdef DEBUG
    [self setDebugEnableWhenNoStore:YES];
#else
#endif
}

- (void)setDebugEnable:(BOOL)enable{
    if ([self getDebugEnable] == enable) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setObject:@(enable) forKey:ZHCtxDebugEnableKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.debugEnable_memory = @(enable);
}
- (void)setDebugEnableWhenNoStore:(BOOL)enable{
    NSNumber *res = [[NSUserDefaults standardUserDefaults] objectForKey:ZHCtxDebugEnableKey];
    if (res) return;
    [self setDebugEnable:enable];
}
- (BOOL)getDebugEnable{
    if (self.debugEnable_memory) {
        return self.debugEnable_memory.boolValue;
    }
    NSNumber *res = [[NSUserDefaults standardUserDefaults] objectForKey:ZHCtxDebugEnableKey];
    BOOL enable = res ? res.boolValue : NO;
    self.debugEnable_memory = @(enable);
    return enable;
}

- (ZHCtxDebugItem *)getConfigItem:(NSString *)key{
    if (!key || ![key isKindOfClass:NSString.class] || key.length == 0) {
        return nil;
    }
    if (!self.itemMap) {
        self.itemMap = [NSMutableDictionary dictionary];
    }
    ZHCtxDebugItem *item = [self.itemMap objectForKey:key];
    if (!item) {
        item = [[ZHCtxDebugItem alloc] init];
        [self.itemMap setObject:item forKey:key];
    }
    return item;
}

- (BOOL)availableIOS11{
    if ([self getDebugEnable]) {
        if (@available(iOS 11.0, *)) {
            return YES;
        }
        return NO;
    }
    if (@available(iOS 11.0, *)) {
        return YES;
    }
    return NO;
}
- (BOOL)availableIOS10{
    if ([self getDebugEnable]) {
        if (@available(iOS 10.0, *)) {
            return YES;
        }
        return NO;
    }
    if (@available(iOS 10.0, *)) {
        return YES;
    }
    return NO;
}
- (BOOL)availableIOS9{
    if ([self getDebugEnable]) {
        if (@available(iOS 9.0, *)) {
            return YES;
        }
        return NO;
    }
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
