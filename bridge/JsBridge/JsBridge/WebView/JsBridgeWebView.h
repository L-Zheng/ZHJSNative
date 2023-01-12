//
//  JsBridgeWebView.h
//  JsBridge
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JsBridgeWebHandler.h"

@interface JsBridgeWebView : WKWebView

@property (nonatomic, strong) JsBridgeWebHandler *jsBridge;

- (void)runJs:(NSString *)js cold:(BOOL)cold complete:(void (^)(id res, NSError *error))complete;
- (void)injectJs:(NSString *)js time:(WKUserScriptInjectionTime)time complete:(void (^)(id res, NSError *error))complete;
- (void)sendMsgToJs:(NSArray *)functions params:(NSDictionary *)params complete:(void (^)(id res, NSError *error))complete;

@end
