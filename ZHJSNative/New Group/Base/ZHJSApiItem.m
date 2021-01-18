//
//  ZHJSApiItem.m
//  ZHJSNative
//
//  Created by Zheng on 2021/1/16.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHJSApiItem.h"

@implementation ZHJSApiItem
@end

@interface ZHJSApiRegisterItem ()
@end
@implementation ZHJSApiRegisterItem
@end

@implementation ZHJSApiCallJsResItem
+ (instancetype)item{
    return [[ZHJSApiCallJsResItem alloc] init];
}
+ (instancetype)item:(id)result error:(NSError *)error{
    ZHJSApiCallJsResItem *item = [self item];
    item.result = result;
    item.error = error;
    return item;
}
@end

@implementation ZHJSApiCallJsResNativeResItem
+ (instancetype)item{
    return [[ZHJSApiCallJsResNativeResItem alloc] init];
}
@end

@implementation ZHJSApiCallJsArgItem
+ (instancetype)item{
    return [[ZHJSApiCallJsArgItem alloc] init];
}
@end

@implementation ZHJSApiCallJsNativeResItem
+ (instancetype)item{
    return [[ZHJSApiCallJsNativeResItem alloc] init];
}
@end

@interface ZHJSApiCallJsItem ()
@property (nonatomic,copy) ZHJSApiInCallBlock callInBlock;
@end

@implementation ZHJSApiCallJsItem
+ (instancetype)itemWithBlock:(ZHJSApiInCallBlock)callInBlock{
    ZHJSApiCallJsItem *item = [[ZHJSApiCallJsItem alloc] init];
    item.callInBlock = callInBlock;
    return item;
}
- (ZHJSApiCallJsNativeResItem * (^) (id successData, NSError *error))call{
    __weak __typeof__(self) __self = self;
    return ^ZHJSApiCallJsNativeResItem *(id successData, NSError *error){
        return __self.callSFCA(successData, nil, nil, error, NO);
    };
}
- (ZHJSApiCallJsNativeResItem * (^) (id successData, NSError *error, BOOL alive))callA{
    __weak __typeof__(self) __self = self;
    return ^ZHJSApiCallJsNativeResItem *(id successData, NSError *error, BOOL alive){
        return __self.callSFCA(successData, nil, nil, error, alive);
    };
}
- (ZHJSApiCallJsNativeResItem * (^) (id successData, id failData, id completeData, NSError *error))callSFC{
    __weak __typeof__(self) __self = self;
    return ^ZHJSApiCallJsNativeResItem *(id successData, id failData, id completeData, NSError *error){
        return __self.callSFCA(successData, failData, completeData, error, NO);
    };
}
- (ZHJSApiCallJsNativeResItem * (^) (id successData, id failData, id completeData, NSError *error, BOOL alive))callSFCA{
    __weak __typeof__(self) __self = self;
    return ^ZHJSApiCallJsNativeResItem *(id successData, id failData, id completeData, NSError *error, BOOL alive){
        ZHJSApiCallJsArgItem *caItem = [ZHJSApiCallJsArgItem item];
        caItem.successDatas = successData ? @[successData] : @[];
        caItem.failDatas = failData ? @[failData] : @[];
        caItem.completeDatas = completeData ? @[completeData] : @[];
        caItem.error = error;
        caItem.alive = alive;
        return __self.callArg(caItem);
    };
}
- (ZHJSApiCallJsNativeResItem * (^) (ZHJSApiCallJsArgItem *argItem))callArg{
    __weak __typeof__(self) __self = self;
    return ^ZHJSApiCallJsNativeResItem *(ZHJSApiCallJsArgItem *argItem){
        if (__self.callInBlock) {
            return __self.callInBlock(argItem);
        }
        return [ZHJSApiCallJsNativeResItem item];
    };
    
    
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
//        ZHJSApiCallJsArgItem *callArgItem = [ZHJSApiCallJsArgItem item];
//        callArgItem.result = result;
//        callArgItem.error = error;
//        callArgItem.alive = alive;
//        callArgItem.jsRunResMap = runResMap;
//
//    };
//    return block;
}

@end

@interface ZHJSApiArgItem ()
@property (nonatomic, strong) id jsData;
@property (nonatomic, strong) ZHJSApiCallJsItem *callItem;
@end
@implementation ZHJSApiArgItem : NSObject
+ (instancetype)item:(id)jsData callItem:(ZHJSApiCallJsItem *)callItem{
    ZHJSApiArgItem *item = [[ZHJSApiArgItem alloc] init];
    item.jsData = ((!jsData || [jsData isEqual:[NSNull null]]) ? nil : jsData);
    item.callItem = callItem;
    return item;
}
- (id)fetchData:(Class)class{
    id data = self.jsData;
    if (!class || !data ||
        [data isEqual:[NSNull null]] ||
        ![data isKindOfClass:class]) {
        return nil;
    }
    return data;
}
- (NSDictionary *)jsonData{
    return [self fetchData:[NSDictionary class]];
}
- (NSArray *)arrData{
    return [self fetchData:[NSArray class]];
}
- (NSNumber *)numberData{
    return [self fetchData:[NSNumber class]];
}
- (NSString *)stringData{
    return [self fetchData:[NSString class]];
}
@end
