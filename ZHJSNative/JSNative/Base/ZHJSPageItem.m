//
//  ZHJSPageItem.m
//  ZHJSNative
//
//  Created by EM on 2021/1/12.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHJSPageItem.h"

@implementation ZHJSPageItem

- (void)updateProperty:(NSDictionary *)info{
    if (!info) return;
    [self setObjProperty:info key:@"appName"];
}

- (void)setObjProperty:(NSDictionary *)info key:(NSString *)key{
    [self setObjProperty:info dataKey:key propertyKey:key];
}

- (void)setObjProperty:(NSDictionary *)info dataKey:(NSString *)dataKey propertyKey:(NSString *)propertyKey{
    if (!info || ![info isKindOfClass:[NSDictionary class]] || info.allKeys.count == 0) return;
    if (dataKey.length == 0 || propertyKey.length == 0) return;
    
    NSArray *allKeys = info.allKeys;
    if (![allKeys containsObject:dataKey]) return;
    
    id value = info[dataKey];
    if (!value || value == [NSNull null]) return;
    
    if ([value isKindOfClass:[NSString class]]) {
        [self setValue:[NSString stringWithFormat:@"%@",value] forKey:propertyKey];
    }else{
        [self setValue:value forKey:propertyKey];
    }
}

- (void)setDownLoadInfo:(NSDictionary *)downLoadInfo{
    _downLoadInfo = downLoadInfo;
    [self updateProperty:downLoadInfo];
}

+ (instancetype)createByInfo:(NSDictionary *)info{
    return nil;
}
- (instancetype)configByInfo:(NSDictionary *)info{
    if (!info || ![info isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    BOOL (^checkBlock)(NSString *) = ^BOOL(NSString *str){
        return !(!str || ![str isKindOfClass:NSString.class] || str.length == 0);
    };
    NSString *appId = [info valueForKey:@"appId"];
    NSString *envVersion = [info valueForKey:@"envVersion"];
    if (!checkBlock(appId)) {
        return nil;
    }
    self.appId = appId;
    self.envVersion = checkBlock(envVersion) ? envVersion : @"release";
    self.receiveInfo = info;
    return self;
}
@end

@implementation ZHWebViewItem

+ (instancetype)createByInfo:(NSDictionary *)info{
    return [[[ZHWebViewItem alloc] init] configByInfo:info];
}

@end

@implementation ZHJSContextItem

+ (instancetype)createByInfo:(NSDictionary *)info{
    return [[[ZHJSContextItem alloc] init] configByInfo:info];
}

@end
