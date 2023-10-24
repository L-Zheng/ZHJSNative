//
//  JsBridgeHandler.h
//  JsBridge
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JsBridgeProtocol.h"

@interface JsBridgeHandler : NSObject

@property (nonatomic,weak) id jsPage;

- (void)captureApiCall:(void (^) (NSString *apiName, NSString *moduleName, NSString *methodName, NSArray *args, id ret))handler;

@end

// LocationCode
#define JBLCDesc(fmt, ...) [NSString stringWithFormat:(@"function：%s.\nline：%d.\nreason：" fmt), __func__, __LINE__, ##__VA_ARGS__]
__attribute__((unused)) static NSError * JBMakeErr(NSInteger code, NSString *desc) {
    return [NSError errorWithDomain:@"com.WKWebiew.JsBridge" code:code userInfo:@{NSLocalizedDescriptionKey: desc}];
}
