//
//  ZHDPNetworkTask.h
//  ZHJSNative
//
//  Created by EM on 2021/6/3.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZHDPNetworkTaskProtocol : NSURLProtocol
@end

@interface ZHDPNetworkTask : NSObject
@property (nonatomic, assign) BOOL interceptEnable;

- (void)interceptNetwork;
- (void)cancelNetwork;
@end
