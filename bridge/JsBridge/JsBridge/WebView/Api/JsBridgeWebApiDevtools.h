//
//  JsBridgeWebApiDevtools.h
//  JsBridge
//
//  Created by EM on 2024/4/7.
//

#import <Foundation/Foundation.h>
#import "JsBridgeProtocol.h"
@class JsBridgeWebHandler;

@interface JsBridgeWebApiDevtools : NSObject <JsBridgeApiProtocol>
@property (nonatomic,weak) JsBridgeWebHandler *jsBridge;

@property (nonatomic, copy) void (^handler) (void (^callback) (NSDictionary *info));

@end

