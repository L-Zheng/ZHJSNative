//
//  ZHJSNativeItem.h
//  ZHJSNative
//
//  Created by EM on 2020/12/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

/** 交互页面数据信息 */
@interface ZHJSNativeItem : NSObject
@property (nonatomic,strong) NSDictionary *downLoadInfo;
@property (nonatomic,strong) NSDictionary *receiveInfo;

@property (nonatomic,copy) NSString *appId;
@property (nonatomic,copy) NSString *envVersion;
@property (nonatomic,copy) NSString *appName;

@property (nonatomic,assign) BOOL fromAssistant;

+ (instancetype)createByInfo:(NSDictionary *)info;

// 版本浮窗信息
@property (nonatomic,copy,readonly) NSString *floatVersionDesc;
@end

@interface ZHWebViewItem : ZHJSNativeItem

@end

@interface ZHJSContextItem : ZHJSNativeItem

@end
