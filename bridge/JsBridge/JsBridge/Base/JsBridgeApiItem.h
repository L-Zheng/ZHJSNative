//
//  JsBridgeApiItem.h
//  JsBridge
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JsBridgeApiItem : NSObject

@end

#pragma mark - 注入的api函数

@interface JsBridgeApiRegisterItem : NSObject
@property (nonatomic,copy) NSString *jsMethodName;
@property (nonatomic,copy) NSString *nativeMethodName;
@property (nonatomic,copy) NSString *nativeMethodInClassName;
@property (nonatomic,weak) id nativeInstance;
@property (nonatomic,assign,getter=isSync) BOOL sync;
@property (nonatomic,copy) NSString *supportVersion;
@end

#pragma mark - 回调js function后的js处理结果

@interface JsBridgeApiCallJsResItem : NSObject
+ (instancetype)item;
+ (instancetype)item:(id)result error:(NSError *)error;
@property (nonatomic,strong) id result;
@property (nonatomic,strong) NSError *error;
@end

#pragma mark - 回调js function后js的处理结果 交给原生 原生的处理结果

@interface JsBridgeApiCallJsResNativeResItem : NSObject
+ (instancetype)item;
@end

// 调用js函数（success、fail、complete）的返回值
#define JsBridgeApi_CallJsResNativeBlock_Args JsBridgeApiCallJsResItem *jsResItem
#define JsBridgeApi_CallJsResNativeBlock_Header JsBridgeApiCallJsResNativeResItem *(JsBridgeApi_CallJsResNativeBlock_Args)
typedef JsBridgeApiCallJsResNativeResItem *(^JsBridgeApiCallJsResNativeBlock)(JsBridgeApi_CallJsResNativeBlock_Args);

#pragma mark - 回调js function参数

@interface JsBridgeApiCallJsArgItem : NSObject
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
 ^JsBridgeApi_CallJsResNativeBlock_Header{
     NSLog(@"res: %@--%@",jsResItem.result, jsResItem.error);
     return [JsBridgeApiCallJsResNativeResItem item];
 },
 */
@property (nonatomic,copy) JsBridgeApiCallJsResNativeBlock jsResSuccessBlock;
@property (nonatomic,copy) JsBridgeApiCallJsResNativeBlock jsResFailBlock;
@property (nonatomic,copy) JsBridgeApiCallJsResNativeBlock jsResCompleteBlock;

//回调 js 直接传递的 function  的  参数
@property (nonatomic,retain) NSArray *jsFuncArgDatas;
//回调 js 直接传递的 function  的  返回值
@property (nonatomic,copy) JsBridgeApiCallJsResNativeBlock jsFuncArgResBlock;
@end

#pragma mark - 回调js function后的原生处理结果

@interface JsBridgeApiCallJsNativeResItem : NSObject
+ (instancetype)item;
@end

#define JsBridgeApi_InCallBlock_Args JsBridgeApiCallJsArgItem *argItem
#define JsBridgeApi_InCallBlock_Header JsBridgeApiCallJsNativeResItem *(JsBridgeApi_InCallBlock_Args)
typedef JsBridgeApiCallJsNativeResItem * (^JsBridgeApiInCallBlock)(JsBridgeApi_InCallBlock_Args);

#pragma mark - 用于回调js function

@interface JsBridgeApiCallJsItem : NSObject

+ (instancetype)itemWithSFCBlock:(JsBridgeApiInCallBlock)SFCBlock jsFuncArgBlock:(JsBridgeApiInCallBlock)jsFuncArgBlock;

// 单参数回调 success/fail/complete
- (JsBridgeApiCallJsNativeResItem * (^) (id successData, NSError *error))call;
- (JsBridgeApiCallJsNativeResItem * (^) (id successData, NSError *error, BOOL alive))callA;
- (JsBridgeApiCallJsNativeResItem * (^) (id successData, id failData, id completeData, NSError *error))callSFC;
- (JsBridgeApiCallJsNativeResItem * (^) (id successData, id failData, id completeData, NSError *error, BOOL alive))callSFCA;
// 多参数回调 success/fail/complete
- (JsBridgeApiCallJsNativeResItem * (^) (NSArray *successDatas, NSError *error))m_call;
- (JsBridgeApiCallJsNativeResItem * (^) (NSArray *successDatas, NSError *error, BOOL alive))m_callA;
- (JsBridgeApiCallJsNativeResItem * (^) (NSArray *successDatas, NSArray *failDatas, NSArray *completeDatas, NSError *error))m_callSFC;
- (JsBridgeApiCallJsNativeResItem * (^) (NSArray *successDatas, NSArray *failDatas, NSArray *completeDatas, NSError *error, BOOL alive))m_callSFCA;
// 自定义回调
- (JsBridgeApiCallJsNativeResItem * (^) (JsBridgeApiCallJsArgItem *argItem))callArg;


// 回调 js 直接传递的 function
- (JsBridgeApiCallJsNativeResItem * (^) (id data))jsFuncArg_call;
- (JsBridgeApiCallJsNativeResItem * (^) (id data, BOOL alive))jsFuncArg_callA;
- (JsBridgeApiCallJsNativeResItem * (^) (NSArray *args))jsFuncArg_m_call;
- (JsBridgeApiCallJsNativeResItem * (^) (NSArray *args, BOOL alive))jsFuncArg_m_callA;
// 自定义回调
- (JsBridgeApiCallJsNativeResItem * (^) (JsBridgeApiCallJsArgItem *argItem))jsFuncArg_callArg;


@end

////if (block2) block2(x(@"2222", nil, @(YES), @{}));
//#define x(result, error, ...) \
//result, error, ## __VA_ARGS__, nil

////if (block2) v(block2, @"2222", nil, @(YES), @{});
//#define v(bb, result, error, ...) \
//bb(result, error, ## __VA_ARGS__, nil)

#pragma mark - js调用原生，原生接收的js参数

@interface JsBridgeApiArgItem : NSObject
+ (instancetype)item:(id)jsPage jsData:(id)jsData callItem:(JsBridgeApiCallJsItem *)callItem;
@property (nonatomic, weak, readonly) id jsPage;
@property (nonatomic, strong, readonly) id jsData;
@property (nonatomic, strong, readonly) JsBridgeApiCallJsItem *callItem;
- (NSDictionary *)jsonData;
- (NSArray *)arrData;
- (NSNumber *)numberData;
- (NSString *)stringData;
@end
