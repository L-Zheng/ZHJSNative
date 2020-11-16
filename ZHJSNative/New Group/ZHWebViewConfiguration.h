//
//  ZHWebViewConfiguration.h
//  ZHJSNative
//
//  Created by EM on 2020/7/10.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "ZHJSApiProtocol.h"
@class ZHWebViewAppletConfiguration;
@class ZHWebViewCreateConfiguration;
@class ZHWebViewLoadConfiguration;
@class ZHWebView;


@interface ZHWebViewModuleConfiguration : NSObject
@property (nonatomic,weak) ZHWebView *webView;
- (NSDictionary *)formatInfo;
@end


/** 👉webview 绑定的小程序配置 */
@interface ZHWebViewAppletConfiguration : ZHWebViewModuleConfiguration
// 小程序appId
@property (nonatomic,copy) NSString *appId;
// 加载的html文件【如：index.html】
@property (nonatomic,copy) NSString *loadFileName;
/** 内置的模板：当本地没有缓存，使用app包内置的模板，传nil则等待下载模板 */
// 文件夹目录路径 与 presetFilePath属性 传一个即可
@property (nonatomic,copy) NSString *presetFolderPath;
// 文件zip路径
@property (nonatomic,copy) NSString *presetFilePath;
@end


/** 👉webview 创建配置 */
@interface ZHWebViewCreateConfiguration : ZHWebViewModuleConfiguration
// 初始化frame
@property (nonatomic,strong) NSValue *frameValue;
/** 内容进程池
 传nil：会自动创建一个新的processPool，不同的WebView的processPool不同，内容数据不能共享。
 如要共享内容数据（如： localstorage数据）可自行创建processPool单例，不同的WebView共用此单例
 */
@property (nonatomic,strong) WKProcessPool *processPool;
// WebView需要注入的api【如：fund API】
@property (nonatomic,retain) NSArray <id <ZHJSApiProtocol>> *apiHandlers;
@end


/** 👉webview load配置 */
@interface ZHWebViewLoadConfiguration : ZHWebViewModuleConfiguration
// 缓存策略@(NSURLRequestCachePolicy)  默认nil
@property (nonatomic,strong) NSNumber *cachePolicy;
// 超时时间 默认nil
@property (nonatomic,strong) NSNumber *timeoutInterval;
/** WebView可访问的资源目录【如：表情资源，一般传document目录】
 如果传nil，sdk内部会修改为 fileUrl的上级目录 */
@property (nonatomic,strong) NSURL *readAccessURL;
@end


/** 👉webview 配置 */
@interface ZHWebViewConfiguration : NSObject
@property (nonatomic,strong) ZHWebViewAppletConfiguration *appletConfig;
@property (nonatomic,strong) ZHWebViewCreateConfiguration *createConfig;
@property (nonatomic,strong) ZHWebViewLoadConfiguration *loadConfig;
@property (nonatomic,weak) ZHWebView *webView;
- (NSDictionary *)formatInfo;
@end



/** 👉webview 调试配置 */
FOUNDATION_EXPORT NSString * const ZHWebViewSocketDebugUrlKey;
FOUNDATION_EXPORT NSString * const ZHWebViewLocalDebugUrlKey;

typedef NS_ENUM(NSInteger, ZHWebViewDebugModel) {
    ZHWebViewDebugModelNo     = 0, //release模式
    ZHWebViewDebugModelLocal      = 1, //本地拷贝js调试
    ZHWebViewDebugModelOnline      = 2, //链接线上地址调试
};
@interface ZHWebViewDebugConfiguration : NSObject
#pragma mark - init

+ (instancetype)configuration;
@property (nonatomic,weak) ZHWebView *webView;
+ (void)setupDebugEnable:(BOOL)enable;
+ (BOOL)fetchDebugEnable;

// 调试模式
@property (nonatomic, assign, readonly) ZHWebViewDebugModel debugModel;

#pragma mark - float view

- (void)showFlowView;
- (void)updateFloatViewTitle:(NSString *)title;
- (void)updateFloatViewLocation;

#pragma mark - enable
    
// 长连接调试【切换调试模式】 浮窗
@property (nonatomic,assign,readonly) BOOL debugModelEnable;
// 手动刷新 浮窗
@property (nonatomic,assign,readonly) BOOL refreshEnable;
// webview 中添加 log调试控制台
@property (nonatomic,assign,readonly) BOOL logOutputWebviewEnable;
// console.log 输出到 Xcode调试控制台
@property (nonatomic,assign,readonly) BOOL logOutputXcodeEnable;
// 弹窗显示 webview异常  window.onerror
@property (nonatomic,assign,readonly) BOOL alertWebViewErrorEnable;
// 弹窗显示 JSContext异常
@property (nonatomic,assign,readonly) BOOL alertJsContextErrorEnable;
// 禁用webview长按弹出菜单
@property (nonatomic,assign,readonly) BOOL touchCalloutEnable;
// 版本 运行iOS8模式
+ (BOOL)availableIOS11;
+ (BOOL)availableIOS10;
+ (BOOL)availableIOS9;
@end
