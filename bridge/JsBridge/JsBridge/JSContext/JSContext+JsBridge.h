//
//  JSContext+JsBridge.h
//  JsBridge
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>
#import "JsBridgeCtxHandler.h"

@interface JSContext (JsBridge)
@property (nonatomic, strong) JsBridgeCtxHandler *jsBridge;
@end
