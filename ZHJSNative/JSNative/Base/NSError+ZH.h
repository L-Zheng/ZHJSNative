//
//  NSError+ZH.h
//  ZHJSNative
//
//  Created by EM on 2020/12/20.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

// 定位代码位置  ZHLocationCodeString
#define ZHLCString(fmt, ...) [NSString stringWithFormat:(@"\n  function：%s\n  line：%d\n  reason：" fmt @"\n  stack：%@"), __func__, __LINE__, ##__VA_ARGS__, [NSThread callStackSymbols]]
#define ZHLCInlineString(fmt, ...) [NSString stringWithFormat:(@"  function：%s.\n  line：%d.\n  reason：" fmt), __func__, __LINE__, ##__VA_ARGS__]

@interface NSError (ZH)
@property (nonatomic,copy,readonly) NSString *zh_localizedDescription;
@end

__attribute__((unused)) static NSError * ZHInlineError(NSInteger code, NSString *desc) {
    return [NSError errorWithDomain:@"com.zh.webview" code:code userInfo:@{NSLocalizedDescriptionKey:desc}];
}
__attribute__((unused)) static NSString * ZHErrorDesc(NSError *error) {
    if (!error) return @"";
    return [NSString stringWithFormat:@"[inline-error >>\n  domain: %@.  \n  code: %ld.  \n%@.]", error.domain, error.code, error.zh_localizedDescription];
}
