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
@property (nonatomic,copy) NSString *nativeMethodInClassName;
@property (nonatomic,weak) id nativeInstance;
@property (nonatomic,assign,getter=isSync) BOOL sync;
@property (nonatomic,copy) NSString *supportVersion;
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

// 允许多次调用js函数
@property (nonatomic,assign) BOOL alive;


// 回调数据 success
@property (nonatomic,retain) NSArray *successDatas;
// 回调数据 fail
@property (nonatomic,retain) NSArray *failDatas;
// 回调数据 complete
@property (nonatomic,retain) NSArray *completeDatas;
// 调用js函数（success、fail）
@property (nonatomic,strong) NSError *error;
/** 调用js函数（success、fail、complete）的返回值
 ^ZHJSApi_CallJsResNativeBlock_Header{
     NSLog(@"res: %@--%@",jsResItem.result, jsResItem.error);
     return [ZHJSApiCallJsResNativeResItem item];
 },
 */
@property (nonatomic,copy) ZHJSApiCallJsResNativeBlock jsResSuccessBlock;
@property (nonatomic,copy) ZHJSApiCallJsResNativeBlock jsResFailBlock;
@property (nonatomic,copy) ZHJSApiCallJsResNativeBlock jsResCompleteBlock;

//回调 js 直接传递的 function  的  参数
@property (nonatomic,retain) NSArray *jsFuncArgDatas;
//回调 js 直接传递的 function  的  返回值
@property (nonatomic,copy) ZHJSApiCallJsResNativeBlock jsFuncArgResBlock;
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

+ (instancetype)itemWithSFCBlock:(ZHJSApiInCallBlock)SFCBlock jsFuncArgBlock:(ZHJSApiInCallBlock)jsFuncArgBlock;

// 单参数回调 success/fail/complete
- (ZHJSApiCallJsNativeResItem * (^) (id successData, NSError *error))call;
- (ZHJSApiCallJsNativeResItem * (^) (id successData, NSError *error, BOOL alive))callA;
- (ZHJSApiCallJsNativeResItem * (^) (id successData, id failData, id completeData, NSError *error))callSFC;
- (ZHJSApiCallJsNativeResItem * (^) (id successData, id failData, id completeData, NSError *error, BOOL alive))callSFCA;
// 多参数回调 success/fail/complete
- (ZHJSApiCallJsNativeResItem * (^) (NSArray *successDatas, NSError *error))m_call;
- (ZHJSApiCallJsNativeResItem * (^) (NSArray *successDatas, NSError *error, BOOL alive))m_callA;
- (ZHJSApiCallJsNativeResItem * (^) (NSArray *successDatas, NSArray *failDatas, NSArray *completeDatas, NSError *error))m_callSFC;
- (ZHJSApiCallJsNativeResItem * (^) (NSArray *successDatas, NSArray *failDatas, NSArray *completeDatas, NSError *error, BOOL alive))m_callSFCA;
// 自定义回调
- (ZHJSApiCallJsNativeResItem * (^) (ZHJSApiCallJsArgItem *argItem))callArg;


// 回调 js 直接传递的 function
- (ZHJSApiCallJsNativeResItem * (^) (id data))jsFuncArg_call;
- (ZHJSApiCallJsNativeResItem * (^) (id data, BOOL alive))jsFuncArg_callA;
- (ZHJSApiCallJsNativeResItem * (^) (NSArray *args))jsFuncArg_m_call;
- (ZHJSApiCallJsNativeResItem * (^) (NSArray *args, BOOL alive))jsFuncArg_m_callA;
// 自定义回调
- (ZHJSApiCallJsNativeResItem * (^) (ZHJSApiCallJsArgItem *argItem))jsFuncArg_callArg;


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
