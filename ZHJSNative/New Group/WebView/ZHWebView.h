//
//  ZHWebView.h
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "ZHJSApiProtocol.h"
#import "ZHWebConfig.h"
#import "ZHWebDebugManager.h"
#import "ZHJSPageItem.h" // WebView/JSContext页面信息数据
@class ZHWebView;
@class ZHJSHandler;

typedef NS_ENUM(NSInteger, ZHWebViewExceptionOperate) {
    ZHWebViewExceptionOperateNothing     = 0,//不做任何操作
    ZHWebViewExceptionOperateReload      = 1,//WebView重新load
    ZHWebViewExceptionOperateNewInit      = 2,//重新初始化新的WebView
};

//NS_ASSUME_NONNULL_BEGIN

/** socket调试代理 */
@protocol ZHWebViewDebugSocketDelegate <NSObject>
@optional
- (void)zh_webViewReadyRefresh:(ZHWebView *)webView;
- (void)zh_webViewStartRefresh:(ZHWebView *)webView;
@end

/** webview异常代理 */
@protocol ZHWebViewExceptionDelegate <NSObject>
@optional
- (void)zh_webView:(ZHWebView *)webView exception:(NSDictionary *)exception;
@end

/** 重写系统代理 */
@protocol ZHWKNavigationDelegate <WKNavigationDelegate>
@end
@protocol ZHWKUIDelegate <WKUIDelegate>
@end
@protocol ZHScrollViewDelegate <UIScrollViewDelegate>
@end


@interface ZHWebView : WKWebView <ZHJSPageProtocol>

#pragma mark - mp

@property (nonatomic,strong) ZHWebViewItem *webItem;

#pragma mark - load call

@property (nonatomic, assign, readonly) BOOL loadSuccess;
@property (nonatomic, assign, readonly) BOOL loadFail;

#pragma mark - delegate

@property (nonatomic,weak) id <ZHWebViewDebugSocketDelegate> zh_debugSocketDelegate;
@property (nonatomic,weak) id <ZHWebViewExceptionDelegate> zh_exceptionDelegate;
@property (nonatomic,weak) id <ZHWKNavigationDelegate> zh_navigationDelegate;
@property (nonatomic,weak) id <ZHWKUIDelegate> zh_UIDelegate;
@property (nonatomic,weak) id <ZHScrollViewDelegate> zh_scrollViewDelegate;

#pragma mark - config

@property (nonatomic,strong) ZHWebConfig *globalConfig;
@property (nonatomic,strong) ZHWebMpConfig *mpConfig;
@property (nonatomic,strong) ZHWebCreateConfig *createConfig;
@property (nonatomic,strong) ZHWebLoadConfig *loadConfig;
// 调试配置
@property (nonatomic,strong) ZHWebDebugItem *debugItem;

#pragma mark - init

// 创建
- (instancetype)initWithGlobalConfig:(ZHWebConfig *)globalConfig;
- (instancetype)initWithCreateConfig:(ZHWebCreateConfig *)createConfig;
@property (nonatomic, strong) ZHJSHandler *handler;

//添加移除api
- (void)addJsCode:(NSString *)jsCode completion:(void (^) (id res, NSError *error))completion;
- (void)addApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, id res, NSError *error))completion;
- (void)removeApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, id res, NSError *error))completion;

@property (nonatomic,strong,readonly) NSArray <id <ZHJSApiProtocol>> *apiHandlers;

#pragma mark - Exception

/** 检查WebView异常 ：白屏*/
- (ZHWebViewExceptionOperate)checkException;
@property (nonatomic,strong,readonly) NSDictionary *exceptionInfo;
@property (nonatomic,assign,readonly) BOOL didTerminate;

#pragma mark - encode

+ (NSString *)encodeObj:(id)data;

#pragma mark - loads

/// 加载h5
/// @param url 加载的url路径
/// @param baseURL 【WebView运行所需的资源根目录，如果为nil，默认为url的上级目录】
/// @param loadConfig loadConfig
/// @param finish  回调
- (void)loadWithUrl:(NSURL *)url
            baseURL:(NSURL *)baseURL
         loadConfig:(ZHWebLoadConfig *)loadConfig
     startLoadBlock:(void (^) (NSURL *runSandBoxURL))startLoadBlock
             finish:(void (^) (NSDictionary *info, NSError *error))finish;

/// 渲染js页面
/// @param jsSourceBaseURL 渲染该js文件所需的资源【jsSourceBaseURL的目录下包含有jsSourceURL文件】
/// @param jsSourceURL js文件
/// @param completionHandler 回调
- (void)renderLoadPage:(NSURL *)jsSourceBaseURL
           jsSourceURL:(NSURL *)jsSourceURL
     completionHandler:(void (^)(id res, NSError *error))completionHandler;
- (void)render:(NSString *)renderFunctionName
jsSourceBaseURL:(NSURL *)jsSourceBaseURL
   jsSourceURL:(NSURL *)jsSourceURL
completionHandler:(void (^)(id res, NSError *error))completionHandler;


#pragma mark - render url

@property (nonatomic, strong) NSURL *renderURL;
//webView运行的沙盒目录
@property (nonatomic, copy, readonly) NSURL *runSandBoxURL;

/** 发送js消息 */
- (void)postMessageToJs:(NSString *)funcName
                 params:(NSDictionary *)params
      completionHandler:(void (^)(id res, NSError *error))completionHandler;
- (void)evaluateJs:(NSString *)js
 completionHandler:(void (^)(id res, NSError *error))completionHandler;

#pragma mark - clear

- (void)clearWebViewSystemCache;

#pragma mark - path

+ (NSString *)getDocumentFolder;
+ (NSString *)getCacheFolder;
+ (NSString *)getTemporaryFolder;

//获取webView的内置zip资源临时解压目录
- (NSString *)fetchPresetUnzipTmpFolder;
//获取webView准备运行沙盒
- (NSString *)fetchReadyRunSandBox;

#pragma mark - check

+ (BOOL)checkString:(NSString *)string;

+ (BOOL)checkURL:(NSURL *)URL;

@end
//目标路径
__attribute__((unused)) static NSString * ZHWebViewTargetFolder(NSString *home, NSString *name) {
    NSString *envName = YES ? @"SDKRelease" : @"SDKDevelop";
    NSString *grayName = (YES ? @"GrayScale" : @"UnGrayScale");
    return [[[home stringByAppendingPathComponent:name] stringByAppendingPathComponent:envName] stringByAppendingPathComponent:grayName];
}
__attribute__((unused)) static NSString * ZHWebViewFolder() {
    return ZHWebViewTargetFolder([ZHWebView getDocumentFolder], @"ZHWebView");
}
__attribute__((unused)) static NSString * ZHWebViewTmpFolder() {
    return ZHWebViewTargetFolder([ZHWebView getTemporaryFolder], @"ZHWebView");
}
__attribute__((unused)) static NSString * ZHWebViewPresetUnzipTmpFolder() {
    return ZHWebViewTargetFolder([ZHWebView getTemporaryFolder], @"ZHWebViewPresetUnzip");
}
__attribute__((unused)) static BOOL ZHCheckDelegate(id delegate, SEL sel) {
    if (!delegate || !sel) return NO;
    return [delegate respondsToSelector:sel];
}
__attribute__((unused)) static NSString * ZHWebViewDateString() {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    return [dateFormatter stringFromDate:[NSDate date]];
}


//NS_ASSUME_NONNULL_END
