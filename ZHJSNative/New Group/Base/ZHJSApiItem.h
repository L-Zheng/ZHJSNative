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

@interface ZHJSApiRunJsReturnItem : NSObject
+ (instancetype)item;
+ (instancetype)item:(id)result error:(NSError *)error;
@property (nonatomic,strong) id result;
@property (nonatomic,strong) NSError *error;
@end

#pragma mark - 回调js function后js的处理结果 交给原生 原生的处理结果

@interface ZHJSApiRuniOSReturnItem : NSObject
+ (instancetype)item;
@end

// 调用js函数（success、fail、complete）的返回值
#define ZHJSApi_RunJsReturnBlock_Args ZHJSApiRunJsReturnItem *jsReturnItem
#define ZHJSApi_RunJsReturnBlock_Header ZHJSApiRuniOSReturnItem *(ZHJSApi_RunJsReturnBlock_Args)
typedef ZHJSApiRuniOSReturnItem *(^ZHJSApiRunJsReturnBlock)(ZHJSApi_RunJsReturnBlock_Args);

#pragma mark - 回调js function参数

@interface ZHJSApiCallArgItem : NSObject
+ (instancetype)item;
// 回调数据 success
@property (nonatomic,strong) id successData;
// 回调数据 fail
@property (nonatomic,strong) id failData;
// 回调数据 complete
@property (nonatomic,strong) id completeData;
// 调用js函数（success、fail）
@property (nonatomic,strong) NSError *error;
// 允许多次调用js函数
@property (nonatomic,assign) BOOL alive;
/** 调用js函数（success、fail、complete）的返回值
 ^ZHJSApi_RunJsReturnBlock_Header{
     NSLog(@"res: %@--%@",jsReturnItem.result, jsReturnItem.error);
     return [ZHJSApiRuniOSReturnItem item];
 },
 */
@property (nonatomic,copy) ZHJSApiRunJsReturnBlock jsReturnSuccessBlock;
@property (nonatomic,copy) ZHJSApiRunJsReturnBlock jsReturnFailBlock;
@property (nonatomic,copy) ZHJSApiRunJsReturnBlock jsReturnCompleteBlock;
@end

#pragma mark - 回调js function后的原生处理结果

@interface ZHJSApiCallReturnItem : NSObject
+ (instancetype)item;
@end

#define ZHJSApi_InCallBlock_Args ZHJSApiCallArgItem *argItem
#define ZHJSApi_InCallBlock_Header ZHJSApiCallReturnItem *(ZHJSApi_InCallBlock_Args)
typedef ZHJSApiCallReturnItem * (^ZHJSApiInCallBlock)(ZHJSApi_InCallBlock_Args);

#pragma mark - 用于回调js function

/**js传递给原生的参数：（json格式 && 有success、fail、complete函数），
 就会带有此key值ZHJSApiCallItemKey，其value是个ZHJSApiCallItem,可用于回调给js
 */
static NSString * const ZHJSApiCallItemKey = @"ZHJSApiCallItemKey";

@interface ZHJSApiCallItem : NSObject
+ (instancetype)itemWithBlock:(ZHJSApiInCallBlock)callInBlock;
- (ZHJSApiCallReturnItem * (^) (id successData, NSError *error))call;
- (ZHJSApiCallReturnItem * (^) (id successData, NSError *error, BOOL alive))callA;
- (ZHJSApiCallReturnItem * (^) (id successData, id failData, id completeData, NSError *error))callSFC;
- (ZHJSApiCallReturnItem * (^) (id successData, id failData, id completeData, NSError *error, BOOL alive))callSFCA;
- (ZHJSApiCallReturnItem * (^) (ZHJSApiCallArgItem *argItem))callArg;
@end

////if (block2) block2(x(@"2222", nil, @(YES), @{}));
//#define x(result, error, ...) \
//result, error, ## __VA_ARGS__, nil

////if (block2) v(block2, @"2222", nil, @(YES), @{});
//#define v(bb, result, error, ...) \
//bb(result, error, ## __VA_ARGS__, nil)
