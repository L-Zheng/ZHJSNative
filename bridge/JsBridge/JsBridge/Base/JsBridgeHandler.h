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

@end

// LocationCode
#define JBLCDesc(fmt, ...) [NSString stringWithFormat:(@"function：%s.\nline：%d.\nreason：" fmt), __func__, __LINE__, ##__VA_ARGS__]
__attribute__((unused)) static NSError * JBMakeErr(NSInteger code, NSString *desc) {
    return [NSError errorWithDomain:@"com.WKWebiew.JsBridge" code:code userInfo:@{NSLocalizedDescriptionKey: desc}];
}
