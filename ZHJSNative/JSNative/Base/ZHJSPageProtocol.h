//
//  ZHJSPageProtocol.h
//  ZHJSNative
//
//  Created by EM on 2021/5/14.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class ZHJSPageItem;

// WebView JSContext页面api操作的原生控件协议
@protocol ZHJSPageApiOpProtocol <NSObject>
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
// pageId
- (NSString *)zh_pageApplicationId;
// api
- (id <ZHJSPageApiOpProtocol>)zh_apiOp;
@end

