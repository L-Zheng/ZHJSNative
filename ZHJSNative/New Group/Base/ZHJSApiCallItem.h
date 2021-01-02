//
//  ZHJSApiCallItem.h
//  ZHJSNative
//
//  Created by Zheng on 2021/1/2.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

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
static NSString * const ZHJSApi_RunJsReturnBlockKey_Success = @"ZHJSApi_RunJsReturnBlockKey_Success";
static NSString * const ZHJSApi_RunJsReturnBlockKey_Fail = @"ZHJSApi_RunJsReturnBlockKey_Fail";
static NSString * const ZHJSApi_RunJsReturnBlockKey_Complete = @"ZHJSApi_RunJsReturnBlockKey_Complete";
#define ZHJSApi_RunJsReturnBlock_Args ZHJSApiRunJsReturnItem *jsReturnItem
#define ZHJSApi_RunJsReturnBlock_Header ZHJSApiRuniOSReturnItem *(ZHJSApi_RunJsReturnBlock_Args)
typedef ZHJSApiRuniOSReturnItem *(^ZHJSApiRunJsReturnBlock)(ZHJSApi_RunJsReturnBlock_Args);

#pragma mark - 回调js function参数

@interface ZHJSApiCallArgItem : NSObject
+ (instancetype)item;
// 回调数据
@property (nonatomic,strong) id result;
// 调用js函数（success、fail）
@property (nonatomic,strong) NSError *error;
// 允许多次调用js函数
@property (nonatomic,assign) BOOL alive;
/** 调用js函数（success、fail、complete）的返回值
 @{
     ZHJSApi_RunJsReturnBlockKey_Success: ^ZHJSApi_RunJsReturnBlock_Header{
         // 参数result、error
         NSLog(@"%@--%@",result, error);
         // 获取所有block参数
         NSMutableArray *bArgs = [NSMutableArray array];
         va_list bList; id bArg;
         va_start(bList, error);
         while ((bArg = va_arg(bList, id))) {
             [bArgs addObject:bArg];
         }
         va_end(bList);
         return nil;
     },
     ZHJSApi_RunJsReturnBlockKey_Fail: ^ZHJSApi_RunJsReturnBlock_Header{
         NSLog(@"%@--%@",result, error);
         return nil;
     },
     ZHJSApi_RunJsReturnBlockKey_Complete: ^ZHJSApi_RunJsReturnBlock_Header{
         NSLog(@"%@--%@",result, error);
         return nil;
     }
 }
 */
@property (nonatomic,strong) NSDictionary *jsRunResMap;
- (ZHJSApiRunJsReturnBlock)callSuccess;
- (ZHJSApiRunJsReturnBlock)callFail;
- (ZHJSApiRunJsReturnBlock)callComplete;
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
- (ZHJSApiCallReturnItem * (^) (id result, NSError *error))call;
- (ZHJSApiCallReturnItem * (^) (id result, NSError *error, BOOL alive))callA;
- (ZHJSApiCallReturnItem * (^) (id result, NSError *error, BOOL alive, NSDictionary *jsRunResMap))callAJ;
- (ZHJSApiCallReturnItem * (^) (ZHJSApiCallArgItem *argItem))callArgs;
@end

////if (block2) block2(x(@"2222", nil, @(YES), @{}));
//#define x(result, error, ...) \
//result, error, ## __VA_ARGS__, nil

////if (block2) v(block2, @"2222", nil, @(YES), @{});
//#define v(bb, result, error, ...) \
//bb(result, error, ## __VA_ARGS__, nil)
