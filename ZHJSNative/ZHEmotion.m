//
//  ZHEmotion.m
//  ZHJSNative
//
//  Created by EM on 2020/4/10.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHEmotion.h"
#import "ZhengFile.h"

@implementation ZHEmotion

- (void)install{
    self.emotionMap = [self handlerEmotion];
    self.bigEmotionMap = [self copyBigEmotion];
}

- (NSDictionary *)handlerEmotion{
    
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"EFEmoji" ofType:@"bundle"];
    
    NSString *imagesPath = [[NSBundle bundleWithPath:bundlePath] pathForResource:@"images" ofType:nil];
    NSString *jsonPath = [[NSBundle bundleWithPath:bundlePath] pathForResource:@"ef_emoji" ofType:@"json"];
    
    NSData *data = [NSData dataWithContentsOfFile:jsonPath];
    NSArray *emojiArr = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    //key值转换 @{@"[滴汗]": @"common_ef_emot07.png"}
    NSMutableDictionary *callInfo = [@{} mutableCopy];
    
    for (NSDictionary *emojiInfo in emojiArr) {
        NSString *mean = [emojiInfo valueForKey:@"emojimeaning"];
        NSString *fileName = [emojiInfo valueForKey:@"emojiname"];
        
        //bundle资源
        NSString *imagePath = [imagesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",fileName]]?:@"";
                
        [callInfo setValue:imagePath forKey:[NSString stringWithFormat:@"[%@]", mean]];
    }
    return [callInfo copy];
}
- (NSDictionary *)copyBigEmotion{
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"EFEmoji" ofType:@"bundle"];
    NSString *imagesPath = [[NSBundle bundleWithPath:bundlePath] pathForResource:@"BigEmotin" ofType:nil];
    
    NSString *targetEmotionPath = [[ZhengFile getDocumentPath] stringByAppendingPathComponent:@"BigEmotion"];
     
    [ZhengFile copySourceFile:imagesPath toDesPath:targetEmotionPath];
    
    NSData *data = [NSData dataWithContentsOfFile:[targetEmotionPath stringByAppendingPathComponent:@"index.json"]];
    NSArray *emojiArr = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    //key值转换 @{@"[滴汗]": @"common_ef_emot07.png"}
    NSMutableDictionary *callInfo = [@{} mutableCopy];
    
    for (NSDictionary *emojiInfo in emojiArr) {
        NSString *mean = [emojiInfo valueForKey:@"text"];
        NSString *fileName = [emojiInfo valueForKey:@"path"];
        
        //bundle资源
//        NSString *imagePath = [imagesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",fileName]]?:@"";
        
        //沙盒资源
        NSString *imagePath = [targetEmotionPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",fileName]]?:@"";

        [callInfo setValue:imagePath forKey:[NSString stringWithFormat:@"[%@]", mean]];
    }
    
    return [callInfo copy];
}

- (instancetype)init{
    if (self = [super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self install];
        });
    }
    return self;
}

static id _instance;

+ (instancetype)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

@end
