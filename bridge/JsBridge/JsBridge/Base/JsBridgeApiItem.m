//
//  JsBridgeApiItem.m
//  JsBridge
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "JsBridgeApiItem.h"

@implementation JsBridgeApiItem
@end

@interface JsBridgeApiRegisterItem ()
@end
@implementation JsBridgeApiRegisterItem
- (void)dealloc{
}
@end

@implementation JsBridgeApiCallJsResItem
+ (instancetype)item{
    return [[JsBridgeApiCallJsResItem alloc] init];
}
+ (instancetype)item:(id)result error:(NSError *)error{
    JsBridgeApiCallJsResItem *item = [self item];
    item.result = ((!result || [result isEqual:[NSNull null]]) ? nil : result);
    item.error = error;
    return item;
}
@end

@implementation JsBridgeApiCallJsResNativeResItem
+ (instancetype)item{
    return [[JsBridgeApiCallJsResNativeResItem alloc] init];
}
@end

@implementation JsBridgeApiCallJsArgItem
+ (instancetype)item{
    return [[JsBridgeApiCallJsArgItem alloc] init];
}
@end

@implementation JsBridgeApiCallJsNativeResItem
+ (instancetype)item{
    return [[JsBridgeApiCallJsNativeResItem alloc] init];
}
@end

@interface JsBridgeApiCallJsItem ()
@property (nonatomic,copy) JsBridgeApiInCallBlock callInSFCBlock;
@property (nonatomic,copy) JsBridgeApiInCallBlock callInJsFuncArgBlock;
@end

@implementation JsBridgeApiCallJsItem

+ (instancetype)itemWithSFCBlock:(JsBridgeApiInCallBlock)SFCBlock jsFuncArgBlock:(JsBridgeApiInCallBlock)jsFuncArgBlock{
    JsBridgeApiCallJsItem *item = [[JsBridgeApiCallJsItem alloc] init];
    item.callInSFCBlock = SFCBlock;
    item.callInJsFuncArgBlock = jsFuncArgBlock;
    return item;
}

// 单参数回调 success/fail/complete
- (JsBridgeApiCallJsNativeResItem * (^) (id successData, NSError *error))call{
    __weak __typeof__(self) weakSelf = self;
    return ^JsBridgeApiCallJsNativeResItem *(id successData, NSError *error){
        return weakSelf.callSFCA(successData, nil, nil, error, NO);
    };
}
- (JsBridgeApiCallJsNativeResItem * (^) (id successData, NSError *error, BOOL alive))callA{
    __weak __typeof__(self) weakSelf = self;
    return ^JsBridgeApiCallJsNativeResItem *(id successData, NSError *error, BOOL alive){
        return weakSelf.callSFCA(successData, nil, nil, error, alive);
    };
}
- (JsBridgeApiCallJsNativeResItem * (^) (id successData, id failData, id completeData, NSError *error))callSFC{
    __weak __typeof__(self) weakSelf = self;
    return ^JsBridgeApiCallJsNativeResItem *(id successData, id failData, id completeData, NSError *error){
        return weakSelf.callSFCA(successData, failData, completeData, error, NO);
    };
}
- (JsBridgeApiCallJsNativeResItem * (^) (id successData, id failData, id completeData, NSError *error, BOOL alive))callSFCA{
    __weak __typeof__(self) weakSelf = self;
    return ^JsBridgeApiCallJsNativeResItem *(id successData, id failData, id completeData, NSError *error, BOOL alive){
        return weakSelf.m_callSFCA(successData ? @[successData] : @[], failData ? @[failData] : @[], completeData ? @[completeData] : @[], error, alive);
    };
}
// 多参数回调 success/fail/complete
- (JsBridgeApiCallJsNativeResItem * (^) (NSArray *successDatas, NSError *error))m_call{
    __weak __typeof__(self) weakSelf = self;
    return ^JsBridgeApiCallJsNativeResItem *(NSArray *successDatas, NSError *error){
        return weakSelf.m_callSFCA(successDatas, nil, nil, error, NO);
    };
}
- (JsBridgeApiCallJsNativeResItem * (^) (NSArray *successDatas, NSError *error, BOOL alive))m_callA{
    __weak __typeof__(self) weakSelf = self;
    return ^JsBridgeApiCallJsNativeResItem *(NSArray *successDatas, NSError *error, BOOL alive){
        return weakSelf.m_callSFCA(successDatas, nil, nil, error, alive);
    };
}
- (JsBridgeApiCallJsNativeResItem * (^) (NSArray *successDatas, NSArray *failDatas, NSArray *completeDatas, NSError *error))m_callSFC{
    __weak __typeof__(self) weakSelf = self;
    return ^JsBridgeApiCallJsNativeResItem *(NSArray *successDatas, NSArray *failDatas, NSArray *completeDatas, NSError *error){
        return weakSelf.m_callSFCA(successDatas, failDatas, completeDatas, error, NO);
    };
}
- (JsBridgeApiCallJsNativeResItem * (^) (NSArray *successDatas, NSArray *failDatas, NSArray *completeDatas, NSError *error, BOOL alive))m_callSFCA{
    __weak __typeof__(self) weakSelf = self;
    return ^JsBridgeApiCallJsNativeResItem *(NSArray *successDatas, NSArray *failDatas, NSArray *completeDatas, NSError *error, BOOL alive){
        JsBridgeApiCallJsArgItem *caItem = [JsBridgeApiCallJsArgItem item];
        caItem.successDatas = (successDatas && [successDatas isKindOfClass:NSArray.class]) ? successDatas : @[];
        caItem.failDatas = (failDatas && [failDatas isKindOfClass:NSArray.class]) ? failDatas : @[];
        caItem.completeDatas = (completeDatas && [completeDatas isKindOfClass:NSArray.class]) ? completeDatas : @[];
        caItem.error = error;
        caItem.alive = alive;
        return weakSelf.callArg(caItem);
    };
}
// 自定义回调
- (JsBridgeApiCallJsNativeResItem * (^) (JsBridgeApiCallJsArgItem *argItem))callArg{
    __weak __typeof__(self) weakSelf = self;
    return ^JsBridgeApiCallJsNativeResItem *(JsBridgeApiCallJsArgItem *argItem){
        if (weakSelf.callInSFCBlock) {
            return weakSelf.callInSFCBlock(argItem);
        }
        return [JsBridgeApiCallJsNativeResItem item];
    };
    
    
//    JsBridgeApiCallBlock block = ^JsBridgeApiCallBlockHeader{
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
//        JsBridgeApiCallJsArgItem *callArgItem = [JsBridgeApiCallJsArgItem item];
//        callArgItem.result = result;
//        callArgItem.error = error;
//        callArgItem.alive = alive;
//        callArgItem.jsRunResMap = runResMap;
//
//    };
//    return block;
}




// 回调 js 直接传递的 function
- (JsBridgeApiCallJsNativeResItem * (^) (id data))jsFuncArg_call{
    __weak __typeof__(self) weakSelf = self;
    return ^JsBridgeApiCallJsNativeResItem *(id data){
        return weakSelf.jsFuncArg_m_callA(data ? @[data] : @[], NO);
    };
}
- (JsBridgeApiCallJsNativeResItem * (^) (id data, BOOL alive))jsFuncArg_callA{
    __weak __typeof__(self) weakSelf = self;
    return ^JsBridgeApiCallJsNativeResItem *(id data, BOOL alive){
        return weakSelf.jsFuncArg_m_callA(data ? @[data] : @[], alive);
    };
}
- (JsBridgeApiCallJsNativeResItem * (^) (NSArray *args))jsFuncArg_m_call{
    __weak __typeof__(self) weakSelf = self;
    return ^JsBridgeApiCallJsNativeResItem *(NSArray *args){
        return weakSelf.jsFuncArg_m_callA(args, NO);
    };
}
- (JsBridgeApiCallJsNativeResItem * (^) (NSArray *args, BOOL alive))jsFuncArg_m_callA{
    __weak __typeof__(self) weakSelf = self;
    return ^JsBridgeApiCallJsNativeResItem *(NSArray *args, BOOL alive){
        JsBridgeApiCallJsArgItem *caItem = [JsBridgeApiCallJsArgItem item];
        caItem.alive = alive;
        caItem.jsFuncArgDatas = (args && [args isKindOfClass:NSArray.class]) ? args : @[];
        return weakSelf.jsFuncArg_callArg(caItem);
    };
}
// 自定义回调
- (JsBridgeApiCallJsNativeResItem * (^) (JsBridgeApiCallJsArgItem *argItem))jsFuncArg_callArg{
    __weak __typeof__(self) weakSelf = self;
    return ^JsBridgeApiCallJsNativeResItem *(JsBridgeApiCallJsArgItem *argItem){
        if (weakSelf.callInJsFuncArgBlock) {
            return weakSelf.callInJsFuncArgBlock(argItem);
        }
        return [JsBridgeApiCallJsNativeResItem item];
    };
}

@end

@interface JsBridgeApiArgItem ()
@property (nonatomic, weak) id jsPage;
@property (nonatomic, strong) id jsData;
@property (nonatomic, strong) JsBridgeApiCallJsItem *callItem;
@end
@implementation JsBridgeApiArgItem : NSObject
+ (instancetype)item:(id)jsPage jsData:(id)jsData callItem:(JsBridgeApiCallJsItem *)callItem{
    JsBridgeApiArgItem *item = [[JsBridgeApiArgItem alloc] init];
    item.jsPage = jsPage;
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
