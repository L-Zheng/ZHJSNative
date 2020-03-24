//
//  ZHJSInternalApiHandler.h
//  ZHJSNative
//
//  Created by EM on 2020/3/24.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZHJSApiProtocol.h"
@class ZHJSApiHandler;

//NS_ASSUME_NONNULL_BEGIN

@interface ZHJSInternalApiHandler : NSObject <ZHJSApiProtocol>
@property (nonatomic,weak) ZHJSApiHandler *apiHandler;
@end

//NS_ASSUME_NONNULL_END
