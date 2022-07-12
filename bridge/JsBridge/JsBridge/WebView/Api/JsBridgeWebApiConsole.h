//
//  JsBridgeWebApiConsole.h
//  JsBridge
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JsBridgeProtocol.h"
@class JsBridgeWebHandler;

@interface JsBridgeWebApiConsole : NSObject <JsBridgeApiProtocol>
@property (nonatomic,weak) JsBridgeWebHandler *jsBridge;
@property (nonatomic, copy) void (^handler) (NSString *flag, NSArray *args);
@end
