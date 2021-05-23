//
//  ZHJSInWebSocketApi.h
//  ZHJSNative
//
//  Created by EM on 2020/12/20.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZHJSApiProtocol.h"
#import "ZHJSPageProtocol.h"
@class ZHWebView;

NS_ASSUME_NONNULL_BEGIN

@interface ZHJSInWebSocketApi : NSObject<ZHJSApiProtocol>
@property (nonatomic,weak) ZHWebView <ZHJSPageProtocol> *webView;
@end

NS_ASSUME_NONNULL_END
