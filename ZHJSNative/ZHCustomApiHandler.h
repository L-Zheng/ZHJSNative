//
//  ZHCustomApiHandler.h
//  ZHJSNative
//
//  Created by EM on 2020/3/24.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZHJSApiProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZHCustomApiHandler : NSObject <ZHJSApiProtocol>

@property (nonatomic,strong) NSDictionary *emotionMap;
@property (nonatomic,strong) NSDictionary *bigEmotionMap;

@end

NS_ASSUME_NONNULL_END
