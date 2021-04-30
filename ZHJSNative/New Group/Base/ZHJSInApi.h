//
//  ZHJSInApi.h
//  ZHJSNative
//
//  Created by EM on 2020/12/20.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZHJSApiProtocol.h"
#import "ZHJSPageItem.h"

/** 内部api  ZHJSInternalApi */
@interface ZHJSInApi : NSObject<ZHJSApiProtocol>
@property (nonatomic,weak) id <ZHJSPageProtocol> webView;
@property (nonatomic,weak) id <ZHJSPageProtocol> jsContext;

@end

