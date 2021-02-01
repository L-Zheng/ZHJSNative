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

// WebView JSContext页面api协议
@protocol ZHJSPageApiProtocol <NSObject>
// controller
@property (nonatomic,weak) UIViewController *belong_controller;
// status
@property (nonatomic,weak) UIViewController *status_controller;
// api navigation
@property (nonatomic,weak) UINavigationItem *navigationItem;
@property (nonatomic,weak) UINavigationBar *navigationBar;
// api router
@property (nonatomic,weak) UINavigationController *router_navigationController;
@end


// WebView JSContext页面协议
@protocol ZHJSPageProtocol <NSObject>
@optional
// renderUrl
- (NSURL *)zh_renderURL;
- (NSURL *)zh_runSandBoxURL;
// pageitem
- (ZHJSPageItem *)zh_pageItem;
// api
- (id <ZHJSPageApiProtocol>)zh_api;
@end
