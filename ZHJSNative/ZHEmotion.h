//
//  ZHEmotion.h
//  ZHJSNative
//
//  Created by EM on 2020/4/10.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZHEmotion : NSObject
+ (instancetype)shareManager;
@property (nonatomic,strong) NSDictionary *emotionMap;
@property (nonatomic,strong) NSDictionary *bigEmotionMap;
@end

NS_ASSUME_NONNULL_END
