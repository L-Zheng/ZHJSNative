//
//  ZHJSPageItem.h
//  ZHJSNative
//
//  Created by EM on 2021/1/12.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/** 交互页面数据信息 */
@interface ZHJSPageItem : NSObject
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

@interface ZHWebViewItem : ZHJSPageItem

@end

@interface ZHJSContextItem : ZHJSPageItem

@end


// WebView JSContext页面协议
@protocol ZHJSPageProtocol <NSObject>
@optional
// renderUrl
- (NSURL *)zh_renderURL;
- (NSURL *)zh_runSandBoxURL;
// pageitem
- (ZHJSPageItem *)zh_pageItem;
// controller
- (UIViewController *)zh_controller;
// navigation
- (UINavigationItem *)zh_navigationItem;
- (UINavigationBar *)zh_navigationBar;
- (UINavigationController *)zh_navigationController;
- (UINavigationController *)zh_router_navigationController;
@end
