//
//  ZHJSInApi.h
//  ZHJSNative
//
//  Created by EM on 2020/12/20.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZHJSApiProtocol.h"
@class ZHJSApiHandler;
@class ZHWebView;
@class ZHJSContext;

/** 内部api  ZHJSInternalApi */
@interface ZHJSInApi : NSObject<ZHJSApiProtocol>
@property (nonatomic,weak) ZHJSApiHandler *apiHandler;
- (ZHWebView *)webView;
- (ZHJSContext *)jsContext;

@end

