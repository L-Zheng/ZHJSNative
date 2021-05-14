//
//  ZHJSPageItem.h
//  ZHJSNative
//
//  Created by EM on 2021/1/12.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

/** 交互页面数据信息 */
@interface ZHJSPageItem : NSObject
@property (nonatomic,strong) NSDictionary *downLoadInfo;
@property (nonatomic,strong) NSDictionary *receiveInfo;

@property (nonatomic,copy) NSString *appId;
@property (nonatomic,copy) NSString *envVersion;
@property (nonatomic,copy) NSString *appName;

+ (instancetype)createByInfo:(NSDictionary *)info;
@end

@interface ZHWebViewItem : ZHJSPageItem

@end

@interface ZHJSContextItem : ZHJSPageItem

@end
