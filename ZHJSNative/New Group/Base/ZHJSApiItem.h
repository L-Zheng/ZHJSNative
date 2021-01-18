//
//  ZHJSApiItem.h
//  ZHJSNative
//
//  Created by Zheng on 2021/1/16.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZHJSApiItem : NSObject

@end

#pragma mark - 注入的api函数

@interface ZHJSApiRegisterItem : NSObject
@property (nonatomic,copy) NSString *jsMethodName;
@property (nonatomic,copy) NSString *nativeMethodName;
@property (nonatomic,assign,getter=isSync) BOOL sync;
@end

#pragma mark - 回调js function后的js处理结果

@interface ZHJSApiCallJsResItem : NSObject
+ (instancetype)item;
+ (instancetype)item:(id)result error:(NSError *)error;
@property (nonatomic,strong) id result;
@property (nonatomic,strong) NSError *error;
@end

#pragma mark - 回调js function后js的处理结果 交给原生 原生的处理结果

@interface ZHJSApiCallJsResNativeResItem : NSObject
+ (instancetype)item;
@end

// 调用js函数（success、fail、complete）的返回值
#define ZHJSApi_CallJsResNativeBlock_Args ZHJSApiCallJsResItem *jsResItem
#define ZHJSApi_CallJsResNativeBlock_Header ZHJSApiCallJsResNativeResItem *(ZHJSApi_CallJsResNativeBlock_Args)
typedef ZHJSApiCallJsResNativeResItem *(^ZHJSApiCallJsResNativeBlock)(ZHJSApi_CallJsResNativeBlock_Args);

#pragma mark - 回调js function参数

@interface ZHJSApiCallJsArgItem : NSObject
+ (instancetype)item;
// 回调数据 success
@property (nonatomic,retain) NSArray *successDatas;
// 回调数据 fail
@property (nonatomic,retain) NSArray *failDatas;
// 回调数据 complete
@property (nonatomic,retain) NSArray *completeDatas;
// 调用js函数（success、fail）
@property (nonatomic,strong) NSError *error;
// 允许多次调用js函数
@property (nonatomic,assign) BOOL alive;
/** 调用js函数（success、fail、complete）的返回值
 ^ZHJSApi_CallJsResNativeBlock_Header{
     NSLog(@"res: %@--%@",jsResItem.result, jsResItem.error);
     return [ZHJSApiCallJsResNativeResItem item];
 },
 */
@property (nonatomic,copy) ZHJSApiCallJsResNativeBlock jsResSuccessBlock;
@property (nonatomic,copy) ZHJSApiCallJsResNativeBlock jsResFailBlock;
@property (nonatomic,copy) ZHJSApiCallJsResNativeBlock jsResCompleteBlock;
@end

#pragma mark - 回调js function后的原生处理结果

@interface ZHJSApiCallJsNativeResItem : NSObject
+ (instancetype)item;
@end

#define ZHJSApi_InCallBlock_Args ZHJSApiCallJsArgItem *argItem
#define ZHJSApi_InCallBlock_Header ZHJSApiCallJsNativeResItem *(ZHJSApi_InCallBlock_Args)
typedef ZHJSApiCallJsNativeResItem * (^ZHJSApiInCallBlock)(ZHJSApi_InCallBlock_Args);

#pragma mark - 用于回调js function

@interface ZHJSApiCallJsItem : NSObject
+ (instancetype)itemWithBlock:(ZHJSApiInCallBlock)callInBlock;
- (ZHJSApiCallJsNativeResItem * (^) (id successData, NSError *error))call;
- (ZHJSApiCallJsNativeResItem * (^) (id successData, NSError *error, BOOL alive))callA;
- (ZHJSApiCallJsNativeResItem * (^) (id successData, id failData, id completeData, NSError *error))callSFC;
- (ZHJSApiCallJsNativeResItem * (^) (id successData, id failData, id completeData, NSError *error, BOOL alive))callSFCA;
- (ZHJSApiCallJsNativeResItem * (^) (ZHJSApiCallJsArgItem *argItem))callArg;
@end

////if (block2) block2(x(@"2222", nil, @(YES), @{}));
//#define x(result, error, ...) \
//result, error, ## __VA_ARGS__, nil

////if (block2) v(block2, @"2222", nil, @(YES), @{});
//#define v(bb, result, error, ...) \
//bb(result, error, ## __VA_ARGS__, nil)

#pragma mark - js调用原生，原生接收的js参数

@interface ZHJSApiArgItem : NSObject
+ (instancetype)item:(id)jsData callItem:(ZHJSApiCallJsItem *)callItem;
@property (nonatomic, strong, readonly) id jsData;
@property (nonatomic, strong, readonly) ZHJSApiCallJsItem *callItem;
- (NSDictionary *)jsonData;
- (NSArray *)arrData;
- (NSNumber *)numberData;
- (NSString *)stringData;
@end
