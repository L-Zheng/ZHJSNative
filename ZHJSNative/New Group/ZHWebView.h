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
@class ZHWebView;

//调试模式
typedef NS_ENUM(NSInteger, ZHWebViewDebugModel) {
    ZHWebViewDebugModelNo     = 0, //release模式
    ZHWebViewDebugModelLocal      = 1, //本地拷贝js调试
    ZHWebViewDebugModelOnline      = 2, //链接线上地址调试
};

FOUNDATION_EXPORT NSString * const ZHWebViewSocketDebugUrlKey;
FOUNDATION_EXPORT NSString * const ZHWebViewLocalDebugUrlKey;


typedef NS_ENUM(NSInteger, ZHWebViewExceptionOperate) {
    ZHWebViewExceptionOperateNothing     = 0,//不做任何操作
    ZHWebViewExceptionOperateReload      = 1,//WebView重新load
    ZHWebViewExceptionOperateNewInit      = 2,//重新初始化新的WebView
};

//NS_ASSUME_NONNULL_BEGIN

/** socket调试代理 */
@protocol ZHWebViewSocketDebugDelegate <NSObject>
@optional
- (void)webViewReadyRefresh:(ZHWebView *)webView;
- (void)webViewRefresh:(ZHWebView *)webView debugModel:(ZHWebViewDebugModel)debugModel info:(NSDictionary *)info;
@end

/** 重写系统代理 */
@protocol ZHWKNavigationDelegate <WKNavigationDelegate>
@end
@protocol ZHWKUIDelegate <WKUIDelegate>
@end
@protocol ZHScrollViewDelegate <UIScrollViewDelegate>
@end


@interface ZHWebView : WKWebView

#pragma mark - load call

@property (nonatomic,copy, readonly) void (^loadFinish) (BOOL success);
@property (nonatomic, assign, readonly) BOOL loadSuccess;
@property (nonatomic, assign, readonly) BOOL loadFail;

#pragma mark - delegate

@property (nonatomic,weak) id <ZHWebViewSocketDebugDelegate> zh_socketDebugDelegate;
@property (nonatomic,weak) id <ZHWKNavigationDelegate> zh_navigationDelegate;
@property (nonatomic,weak) id <ZHWKUIDelegate> zh_UIDelegate;
@property (nonatomic,weak) id <ZHScrollViewDelegate> zh_scrollViewDelegate;

#pragma mark - init
/// 创建
/// @param frame frame
/// @param processPool 内容进程池【传nil：会自动创建一个新的processPool，不同的WebView的processPool不同，内容数据不能共享。如要共享内容数据（如： localstorage数据）可自行创建processPool单例，不同的WebView共用此单例】
/// @param apiHandlers 注入的api 【如： fund api】
- (instancetype)initWithFrame:(CGRect)frame
                  processPool:(WKProcessPool *)processPool
                  apiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers;

//添加移除api
- (void)addJsCode:(NSString *)jsCode completion:(void (^) (id res, NSError *error))completion;
- (void)addApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, id res, NSError *error))completion;
- (void)removeApiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApiHandlers, NSArray<id<ZHJSApiProtocol>> *failApiHandlers, id res, NSError *error))completion;

@property (nonatomic,strong,readonly) NSArray <id <ZHJSApiProtocol>> *apiHandlers;

#pragma mark - Exception

/** 检查WebView异常 ：白屏*/
- (ZHWebViewExceptionOperate)checkException;

#pragma mark - encode

+ (NSString *)encodeObj:(id)data;

#pragma mark - loads

/// 加载h5
/// @param url 加载的url路径
/// @param cachePolicy 【iOS8下 or  加载http地址使用】 缓存策略@(NSURLRequestCachePolicy)  默认nil
/// @param timeoutInterval 【iOS8下 or  加载http地址使用】 超时时间  默认nil
/// @param baseURL 【WebView运行所需的资源根目录，如果为nil，默认为url的上级目录】
/// @param readAccessURL 允许WebView读取的目录
/// @param finish 回调
- (void)loadUrl:(NSURL *)url
    cachePolicy:(NSNumber *)cachePolicy
timeoutInterval:(NSNumber *)timeoutInterval
        baseURL:(NSURL *)baseURL
allowingReadAccessToURL:(NSURL *)readAccessURL
         finish:(void (^) (BOOL success))finish;

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

#pragma mark - debug

@property (nonatomic, assign, readonly) ZHWebViewDebugModel debugModel;

+ (BOOL)isAvailableIOS11;

+ (BOOL)isAvailableIOS9;

#pragma mark - path

+ (NSString *)getDocumentFolder;
+ (NSString *)getCacheFolder;
+ (NSString *)getTemporaryFolder;

//获取webView准备运行沙盒
- (NSString *)fetchReadyRunSandBox;

//获取路径的上级目录
+ (NSString *)fetchSuperiorFolder:(NSString *)path;

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
__attribute__((unused)) static NSString * ZHWebViewDateString() {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    return [dateFormatter stringFromDate:[NSDate date]];
}



//NS_ASSUME_NONNULL_END
