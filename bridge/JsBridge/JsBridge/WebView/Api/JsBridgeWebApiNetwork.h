//
//  JsBridgeWebApiNetwork.h
//  JsBridge
//
//  Created by EM on 2023/7/12.
//

#import <Foundation/Foundation.h>
#import "JsBridgeProtocol.h"
@class JsBridgeWebHandler;

@interface JsBridgeWebApiNetwork : NSObject <JsBridgeApiProtocol>
@property (nonatomic,weak) JsBridgeWebHandler *jsBridge;
@property (nonatomic, copy) void (^handler) (id data);
@end
