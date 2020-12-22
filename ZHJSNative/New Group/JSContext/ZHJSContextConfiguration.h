//
//  ZHJSContextConfiguration.h
//  ZHJSNative
//
//  Created by EM on 2020/12/19.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZHJSApiProtocol.h"
@class ZHJSContext;


@interface ZHJSContextModuleConfiguration : NSObject
@property (nonatomic,weak) ZHJSContext *jsContext;
- (NSDictionary *)formatInfo;
@end


/** 👉JSContext 绑定的小程序配置 */
@interface ZHJSContextAppletConfiguration : ZHJSContextModuleConfiguration
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


/** 👉JSContext 创建配置 */
@interface ZHJSContextCreateConfiguration : ZHJSContextModuleConfiguration
// JSContext需要注入的api【如：fund API】
@property (nonatomic,retain) NSArray <id <ZHJSApiProtocol>> *apiHandlers;
@end


/** 👉JSContext load配置 */
@interface ZHJSContextLoadConfiguration : ZHJSContextModuleConfiguration
@end


/** 👉JSContext 配置 */
@interface ZHJSContextConfiguration : ZHJSContextModuleConfiguration
@property (nonatomic,strong) ZHJSContextAppletConfiguration *appletConfig;
@property (nonatomic,strong) ZHJSContextCreateConfiguration *createConfig;
@property (nonatomic,strong) ZHJSContextLoadConfiguration *loadConfig;
@end


/** 👉JSContext 调试配置 */
@interface ZHJSContextDebugConfiguration : NSObject

#pragma mark - init
+ (instancetype)configuration:(ZHJSContext *)jsContext;
@property (nonatomic,weak) ZHJSContext *jsContext;

#pragma mark - enable
    
// 长连接调试【切换调试模式】 浮窗
@property (nonatomic,assign,readonly) BOOL debugModelEnable;
// console.log 输出到 Xcode调试控制台
@property (nonatomic,assign,readonly) BOOL logOutputXcodeEnable;
// 弹窗显示 JSContext异常
@property (nonatomic,assign,readonly) BOOL alertJsContextErrorEnable;
@end

