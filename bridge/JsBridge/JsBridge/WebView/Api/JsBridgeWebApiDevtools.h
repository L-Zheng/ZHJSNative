//
//  JsBridgeWebApiDevtools.h
//  JsBridge
//
//  Created by EM on 2024/4/7.
//

#import <Foundation/Foundation.h>
#import "JsBridgeProtocol.h"
@class JsBridgeWebHandler;


@interface JsBridgeWebApiDevtoolsSocket : NSObject <JsBridgeApiProtocol>
@property (nonatomic,weak) JsBridgeWebHandler *jsBridge;
@property (nonatomic,copy) void (^connect) (NSDictionary *info);
@property (nonatomic,copy) void (^onOpen) (void (^) (id msg));
@property (nonatomic,copy) void (^onMessage) (void (^) (id msg));
@property (nonatomic,copy) void (^send) (id msg);
@end


@interface JsBridgeWebApiDevtools : NSObject <JsBridgeApiProtocol>
@property (nonatomic,weak) JsBridgeWebHandler *jsBridge;

@property (nonatomic, copy) void (^open) (void (^callback) (NSDictionary *info));

@end

