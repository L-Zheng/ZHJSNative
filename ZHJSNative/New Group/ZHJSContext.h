//
//  ZHJSContext.h
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "ZHJSApiProtocol.h"

//NS_ASSUME_NONNULL_BEGIN

@interface ZHJSContext : JSContext

- (instancetype)initWithApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers;
@property (nonatomic,strong,readonly) NSArray <id <ZHJSApiProtocol>> *apiHandlers;

- (JSValue *)runJsFunc:(NSString *)funcName arguments:(NSArray *)arguments;

@end

//NS_ASSUME_NONNULL_END
