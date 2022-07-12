//
//  JsBridgeCtxHandler.h
//  JsBridge
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "JsBridgeHandler.h"
#import <JavaScriptCore/JavaScriptCore.h>

@interface JsBridgeCtxHandler : JsBridgeHandler

@property (nonatomic,weak) JSContext *jsCtx;

#pragma mark - api

- (void)addApis:(NSArray *)apis;
- (void)removeApis:(NSArray *)apis;

#pragma mark - exception

- (void)captureException:(void (^) (id exception))handler;

#pragma mark - console

- (void)captureConsole:(void (^) (NSString *flag, NSArray *args))handler;
@end
