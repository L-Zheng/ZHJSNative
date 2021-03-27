//
//  ZHWebBaseConfig.h
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ZHWebView;

@interface ZHWebBaseConfig : NSObject
@property (nonatomic,weak) ZHWebView *webView;
- (NSDictionary *)formatInfo;
@end
