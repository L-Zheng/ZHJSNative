//
//  ZHContextMpConfig.h
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHContextBaseConfig.h"

/** 👉JSContext 绑定的小程序配置 */
@interface ZHContextMpConfig : ZHContextBaseConfig
// 小程序appId
@property (nonatomic,copy) NSString *appId;
@property (nonatomic,copy) NSString *envVersion;
// 加载的html文件【如：index.html】
@property (nonatomic,copy) NSString *loadFileName;
/** 内置的模板：当本地没有缓存，使用app包内置的模板，传nil则等待下载模板 */
// 文件夹目录路径 与 presetFilePath属性 传一个即可
//@property (nonatomic,copy) NSString *presetFolderPath;
// 文件zip路径
@property (nonatomic,copy) NSString *presetFilePath;
@property (nonatomic,strong) NSDictionary *presetFileInfo;
@end

