//
//  ZHJSApiCallItem.m
//  ZHJSNative
//
//  Created by Zheng on 2021/1/2.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHJSApiCallItem.h"

@implementation ZHJSApiRunJsReturnItem
+ (instancetype)item{
    return [[ZHJSApiRunJsReturnItem alloc] init];
}
+ (instancetype)item:(id)result error:(NSError *)error{
    ZHJSApiRunJsReturnItem *item = [self item];
    item.result = result;
    item.error = error;
    return item;
}
@end

@implementation ZHJSApiRuniOSReturnItem
+ (instancetype)item{
    return [[ZHJSApiRuniOSReturnItem alloc] init];
}
@end

@implementation ZHJSApiCallArgItem
+ (instancetype)item{
    return [[ZHJSApiCallArgItem alloc] init];
}
- (ZHJSApiRunJsReturnBlock)callSuccess{
    return [self callJsRunRes:ZHJSApi_RunJsReturnBlockKey_Success];
}
- (ZHJSApiRunJsReturnBlock)callFail{
    return [self callJsRunRes:ZHJSApi_RunJsReturnBlockKey_Fail];
}
- (ZHJSApiRunJsReturnBlock)callComplete{
    return [self callJsRunRes:ZHJSApi_RunJsReturnBlockKey_Complete];
}
- (ZHJSApiRunJsReturnBlock)callJsRunRes:(NSString *)key{
    ZHJSApiRunJsReturnBlock block = self.jsRunResMap[key];
    if (block) return block;
    block = ^ZHJSApi_RunJsReturnBlock_Header{
        return [ZHJSApiRuniOSReturnItem item];
    };
    return block;
}
@end

@implementation ZHJSApiCallReturnItem
+ (instancetype)item{
    return [[ZHJSApiCallReturnItem alloc] init];
}
@end

@interface ZHJSApiCallItem ()
@property (nonatomic,copy) ZHJSApiInCallBlock callInBlock;
@end

@implementation ZHJSApiCallItem
+ (instancetype)itemWithBlock:(ZHJSApiInCallBlock)callInBlock{
    ZHJSApiCallItem *item = [[ZHJSApiCallItem alloc] init];
    item.callInBlock = callInBlock;
    return item;
}
- (ZHJSApiCallReturnItem * (^) (id result, NSError *error))call{
    __weak __typeof__(self) __self = self;
    ZHJSApiCallReturnItem * (^block) (id, NSError *) = ^ZHJSApiCallReturnItem *(id result, NSError *error){
        return __self.callAJ(result, error, NO, nil);
    };
    return block;
}
- (ZHJSApiCallReturnItem * (^) (id result, NSError *error, BOOL alive))callA{
    __weak __typeof__(self) __self = self;
    ZHJSApiCallReturnItem * (^block) (id, NSError *, BOOL) = ^ZHJSApiCallReturnItem *(id result, NSError *error, BOOL alive){
        return __self.callAJ(result, error, alive, nil);
    };
    return block;
}
- (ZHJSApiCallReturnItem * (^) (id result, NSError *error, BOOL alive, NSDictionary *jsRunResMap))callAJ{
    __weak __typeof__(self) __self = self;
    ZHJSApiCallReturnItem * (^block) (id, NSError *, BOOL, NSDictionary*) = ^ZHJSApiCallReturnItem *(id result, NSError *error, BOOL alive, NSDictionary *jsRunResMap){
        ZHJSApiCallArgItem *caItem = [ZHJSApiCallArgItem item];
        caItem.result = result;
        caItem.error = error;
        caItem.alive = alive;
        caItem.jsRunResMap = jsRunResMap;
        return __self.callArgs(caItem);
    };
    return block;
}
- (ZHJSApiCallReturnItem * (^) (ZHJSApiCallArgItem *argItem))callArgs{
    __weak __typeof__(self) __self = self;
    ZHJSApiCallReturnItem * (^block) (ZHJSApiCallArgItem *) = ^ZHJSApiCallReturnItem *(ZHJSApiCallArgItem *argItem){
        if (__self.callInBlock) {
            return __self.callInBlock(argItem);
        }
        return [ZHJSApiCallReturnItem item];
    };
    return block;
    
    
//    ZHJSApiCallBlock block = ^ZHJSApiCallBlockHeader{
//        // 获取所有block参数
//        NSMutableArray *bArgs = [NSMutableArray array];
//        va_list bList; id bArg;
//        va_start(bList, error);
//        //依次获取参数值，直到遇见nil【参数format必须以nil结尾 否则崩溃】
//        while ((bArg = va_arg(bList, id))) {
//            [bArgs addObject:bArg];
//        }
//        va_end(bList);
//
//        BOOL alive = ((bArgs.count > 0 && [bArgs[0] isKindOfClass:[NSNumber class]]) ? [(NSNumber *)bArgs[0] boolValue] : NO);
//        NSDictionary *runResMap = ((bArgs.count > 1 && [bArgs[1] isKindOfClass:[NSDictionary class]]) ? (NSDictionary *)bArgs[1] : @{});
//
//        ZHJSApiCallArgItem *callArgItem = [ZHJSApiCallArgItem item];
//        callArgItem.result = result;
//        callArgItem.error = error;
//        callArgItem.alive = alive;
//        callArgItem.jsRunResMap = runResMap;
//
//    };
//    return block;
}

@end
