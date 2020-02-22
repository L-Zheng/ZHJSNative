//
//  ZHWebViewDelegate.h
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
@class ZHWebView;

NS_ASSUME_NONNULL_BEGIN

@interface ZHWebViewDelegate : NSObject<WKNavigationDelegate,WKUIDelegate, UIScrollViewDelegate>

@property (nonatomic,weak) ZHWebView *webView;

@end

NS_ASSUME_NONNULL_END
