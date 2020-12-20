//
//  NSError+ZH.m
//  ZHJSNative
//
//  Created by EM on 2020/12/20.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "NSError+ZH.h"

@implementation NSError (ZH)
- (NSString *)zh_localizedDescription{
    /**
     [NSError new]，error.domain == null 时，调用error.localizedDescription会崩溃
     error.domain == @"" 或者  error.userInfo的key不服从NSErrorUserInfoKey协议   时，error.localizedDescription = The operation couldn’t be completed. ( error 22.)
     */
    NSErrorDomain domain = self.domain;
    if (!domain) {
        return @"this error is illegality created";
    }
    if ([domain isKindOfClass:NSString.class]) {
        if (domain.length == 0 && [domain isEqualToString:@""]) {
            return [NSString stringWithFormat:@"this error domain length is zero. code is %ld. localizedDescription is %@. userInfo is %@.", self.code, self.localizedDescription, self.userInfo];
        }
        return self.localizedDescription?:@"";
    }
    return self.localizedDescription?:@"";
}
@end
