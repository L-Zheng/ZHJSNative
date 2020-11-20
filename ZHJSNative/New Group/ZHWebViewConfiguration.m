//
//  ZHWebViewConfiguration.m
//  ZHJSNative
//
//  Created by EM on 2020/7/10.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHWebViewConfiguration.h"
#import "ZHWebView.h"
#import <ZHFloatWindow/ZHFloatView.h>

@implementation ZHWebViewModuleConfiguration
- (NSDictionary *)formatInfo{
    return @{};
}
- (void)dealloc{
    NSLog(@"%s", __func__);
}
@end


@implementation ZHWebViewAppletConfiguration
- (NSDictionary *)formatInfo{
    return @{
        @"appId": self.appId?:@"",
        @"loadFileName": self.loadFileName?:@"",
        @"presetFilePath": self.presetFilePath?:@"",
        @"presetFolderPath": self.presetFolderPath?:@""
    };
}
- (void)dealloc{
    NSLog(@"%s", __func__);
}
@end


@implementation ZHWebViewCreateConfiguration
- (void)dealloc{
    NSLog(@"%s", __func__);
}
@end

@implementation ZHWebViewLoadConfiguration
- (NSDictionary *)formatInfo{
    return @{
        @"cachePolicy": self.cachePolicy?:@"",
        @"timeoutInterval": self.timeoutInterval?:@"",
        @"readAccessURL": self.readAccessURL.absoluteString ?: @""
    };
}
- (void)dealloc{
    NSLog(@"%s", __func__);
}
@end


@implementation ZHWebViewConfiguration
- (NSDictionary *)formatInfo{
    return @{
        @"appletConfig": [self.appletConfig formatInfo],
        @"createConfig": [self.createConfig formatInfo],
        @"loadConfig": [self.loadConfig formatInfo]
    };
}
- (void)dealloc{
    NSLog(@"%s", __func__);
}
@end


NSString * const ZHWebViewSocketDebugUrlKey = @"ZHWebViewSocketDebugUrlKey";
NSString * const ZHWebViewLocalDebugUrlKey = @"ZHWebViewLocalDebugUrlKey";

@implementation ZHWebViewDebugGlobalConfigurationItem : NSObject
@end

@interface ZHWebViewDebugGlobalConfiguration ()
@property (nonatomic,strong) NSMutableDictionary <NSString *, ZHWebViewDebugGlobalConfigurationItem *> *itemMap;
@end
@implementation ZHWebViewDebugGlobalConfiguration

- (ZHWebViewDebugGlobalConfigurationItem *)fetchConfigurationItem:(NSString *)key{
    key = [ZHWebView checkString:key] ? key : @"ZHWebViewGlobalConfigurationKey";
    
    ZHWebViewDebugGlobalConfigurationItem *item = self.itemMap[key];
    if (!item) {
        item = [[ZHWebViewDebugGlobalConfigurationItem alloc] init];
        item.debugModel = ZHWebViewDebugModelNo;
        item.socketDebugUrlStr = nil;
        item.localDebugUrlStr = nil;
        
        [self.itemMap setObject:item forKey:key];
    }
    return item;
}

- (NSMutableDictionary<NSString *,ZHWebViewDebugGlobalConfigurationItem *> *)itemMap{
    if (!_itemMap) {
        _itemMap = @{}.mutableCopy;
    }
    return _itemMap;
}

- (NSString *)fetchModeDesc:(ZHWebViewDebugModel)mode{
    switch (mode) {
        case ZHWebViewDebugModelLocal:
            return @"本机js调试模式";
            break;
        case ZHWebViewDebugModelOnline:
            return @"socket调试模式";
            break;
        default:
            return @"release调试模式";
            break;
    }
}

+ (void)setupDebugEnable:(BOOL)enable{
#ifdef DEBUG
    enable = YES;
#else
#endif
    [[NSUserDefaults standardUserDefaults] setObject:@(enable) forKey:[self storeKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)fetchDebugEnable{
    return [self readEnable];
}

// 读取记录
+ (BOOL)readEnable{
#ifdef DEBUG
    return YES;
#else
#endif
    NSNumber *num = [[NSUserDefaults standardUserDefaults] objectForKey:[self storeKey]];
    return num ? num.boolValue : NO;
}

+ (NSString *)storeKey{
    return [NSString stringWithFormat:@"ZHDebugKey_%@", NSStringFromClass([self class])];
}

static id _instance;
+ (instancetype)shareConfiguration{
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
+ (instancetype)copyWithZone:(struct _NSZone *)zone{
    return _instance;
}
@end




@interface ZHWebViewDebugConfiguration ()
// 浮窗
@property (nonatomic,strong) ZHFloatView *refreshFloatView;
@property (nonatomic,strong) ZHFloatView *debugModelFloatView;

// 总调试开关
@property (nonatomic,assign) BOOL debugEnable;
@end

@implementation ZHWebViewDebugConfiguration

+ (instancetype)configuration:(ZHWebView *)webview{
    ZHWebViewDebugConfiguration *config = [[ZHWebViewDebugConfiguration alloc] init];
    config.webView = webview;
    [config configProperty];
    return config;
}

// 配置属性
- (void)configProperty{
    self.debugEnable = [ZHWebViewDebugGlobalConfiguration readEnable];
    
    self.globalConfig = [ZHWebViewDebugGlobalConfiguration shareConfiguration];
    ZHWebViewDebugGlobalConfigurationItem *item = [self.globalConfig fetchConfigurationItem:self.webView.globalConfig.appletConfig.appId];
    
    self.debugModel = item.debugModel;
    self.socketDebugUrlStr = item.socketDebugUrlStr;
    self.localDebugUrlStr = item.localDebugUrlStr;
}

- (BOOL)debugModelEnable{
    return self.debugEnable;
}
- (BOOL)refreshEnable{
    return self.debugEnable;
}
- (BOOL)logOutputWebviewEnable{
    return self.debugEnable;
}
- (BOOL)logOutputXcodeEnable{
    return self.debugEnable;
}
- (BOOL)alertWebViewErrorEnable{
    return self.debugEnable;
}
- (BOOL)alertJsContextErrorEnable{
    return self.debugEnable;
}
- (BOOL)touchCalloutEnable{
    return self.debugEnable;
}
+ (BOOL)availableIOS11{
    if ([ZHWebViewDebugGlobalConfiguration readEnable]) {
        if (@available(iOS 11.0, *)) {
            return YES;
        }
        return NO;
    }
    if (@available(iOS 11.0, *)) {
        return YES;
    }
    return NO;
}
+ (BOOL)availableIOS10{
    if ([ZHWebViewDebugGlobalConfiguration readEnable]) {
        if (@available(iOS 10.0, *)) {
            return YES;
        }
        return NO;
    }
    if (@available(iOS 10.0, *)) {
        return YES;
    }
    return NO;
}
+ (BOOL)availableIOS9{
    if ([ZHWebViewDebugGlobalConfiguration readEnable]) {
        if (@available(iOS 9.0, *)) {
            return YES;
        }
        return NO;
    }
    if (@available(iOS 9.0, *)) {
        return YES;
    }
    return NO;
}

#pragma mark - getter

- (ZHFloatView *)refreshFloatView{
    if (!_refreshFloatView) {
        _refreshFloatView = [ZHFloatView floatViewWithItems:nil];
        __weak __typeof__(self) __self = self;
        _refreshFloatView.tapClickBlock = ^{
            [__self webViewCallRefresh:nil];
        };
    }
    return _refreshFloatView;
}
- (ZHFloatView *)debugModelFloatView{
    if (!_debugModelFloatView) {
        _debugModelFloatView = [ZHFloatView floatViewWithItems:nil];
        [_debugModelFloatView updateTitle:[self.globalConfig fetchModeDesc:self.debugModel]];
        __weak __typeof__(self) __self = self;
        _debugModelFloatView.tapClickBlock = ^{
            [__self alertDebugModelSheet];
        };
    }
    return _debugModelFloatView;
}

#pragma mark - float view

- (void)showFlowView{
    if (self.refreshEnable) {
        [self.refreshFloatView showInView:self.webView location:ZHFloatLocationRight locationScale:0.4];
    }
    if (self.debugModelEnable) {
        [self.debugModelFloatView showInView:self.webView location:ZHFloatLocationRight locationScale:0.6];
    }
}
- (void)updateFloatViewTitle:(NSString *)title{
    if (self.refreshEnable) {
        [self.refreshFloatView updateTitle:title];
    }
}
- (void)updateFloatViewLocation{
    if (self.refreshEnable) {
        [self.refreshFloatView updateWhenSuperViewLayout];
    }
    if (self.debugModelEnable) {
        [self.debugModelFloatView updateWhenSuperViewLayout];
    }
}

#pragma mark - alert

//切换模式
- (void)doSwitchDebugModel:(ZHWebViewDebugModel)debugModel info:(NSDictionary *)info{
    [self.debugModelFloatView updateTitle:[self.globalConfig fetchModeDesc:debugModel]];
    [self webViewCallReadyRefresh];
    [self webViewCallRefresh:info];
}
//socket debug调试弹窗
- (void)alertDebugModelOnline:(UIAlertAction *)action debugModel:(ZHWebViewDebugModel)debugModel{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:action.title message:@"该模式将会监听代码改动，同步刷新页面UI。\n在WebView项目目录下运行 yarn serve，将http地址填在此处【如：http://192.168.2.21:8080，会自动填充上一次的地址】。" preferredStyle:UIAlertControllerStyleAlert];
    
    NSString *localDebugUrlCacheKey = @"ZHWebViewOnlineDebugUrlCacheKey";
    void (^cacheBlock)(NSString *) = ^(NSString *urlStr){
        [[NSUserDefaults standardUserDefaults] setValue:urlStr forKey:localDebugUrlCacheKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    };
    NSString* (^fetchCacheBlock)(void) = ^NSString *(void){
        return [[NSUserDefaults standardUserDefaults] valueForKey:localDebugUrlCacheKey];
    };
    
    __weak __typeof__(self) __self = self;
    UIAlertAction *ac1 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull actionT){
    }];
    UIAlertAction *ac2 = [UIAlertAction actionWithTitle:@"仅设置当前页面" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actionT) {
        NSString *urlStr = [alert.textFields.firstObject text];
        if (urlStr.length == 0) return;
            
        __self.socketDebugUrlStr = urlStr;
        __self.debugModel = debugModel;
        
        cacheBlock(urlStr);
        
        [__self doSwitchDebugModel:debugModel info:@{ZHWebViewSocketDebugUrlKey: urlStr}];
    }];
    UIAlertAction *ac3 = [UIAlertAction actionWithTitle:@"App全局设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actionT) {
        NSString *urlStr = [alert.textFields.firstObject text];
        if (urlStr.length == 0) return;
        
        ZHWebViewDebugGlobalConfigurationItem *item = [__self.globalConfig fetchConfigurationItem:__self.webView.globalConfig.appletConfig.appId];
        item.socketDebugUrlStr = urlStr;
        item.debugModel = debugModel;
        
        __self.socketDebugUrlStr = urlStr;
        __self.debugModel = debugModel;
        
        cacheBlock(urlStr);
        
        [__self doSwitchDebugModel:debugModel info:@{ZHWebViewSocketDebugUrlKey: urlStr}];
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"输入socket调试地址";
        NSString *cacheUrl = __self.socketDebugUrlStr?:fetchCacheBlock();
        if (cacheUrl && cacheUrl.length > 0) {
            textField.text = cacheUrl;
        }
    }];
    [alert addAction:ac2];
    [alert addAction:ac3];
    [alert addAction:ac1];
    [[self fetchActivityCtrl] presentViewController:alert animated:YES completion:nil];
}
//local debug调试弹窗
- (void)alertDebugModelLocal:(UIAlertAction *)action debugModel:(ZHWebViewDebugModel)debugModel{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:action.title message:@"该模式将会运行本机WebView项目目录release文件下内容。\n将 本机WebView项目目录 填在此处【如：/Users/em/Desktop/EMCode/fund-projects/fund-details，会自动填充上一次的地址】\n在你改动代码后，运行yarn build，点击浮窗刷新。" preferredStyle:UIAlertControllerStyleAlert];
    
    NSString *localDebugUrlCacheKey = @"ZHWebViewLocalDebugUrlCacheKey";
    void (^cacheBlock)(NSString *) = ^(NSString *urlStr){
        [[NSUserDefaults standardUserDefaults] setValue:urlStr forKey:localDebugUrlCacheKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    };
    NSString* (^fetchCacheBlock)(void) = ^NSString *(void){
        return [[NSUserDefaults standardUserDefaults] valueForKey:localDebugUrlCacheKey];
    };
    
    __weak __typeof__(self) __self = self;
    UIAlertAction *ac1 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull actionT){
    }];
    UIAlertAction *ac2 = [UIAlertAction actionWithTitle:@"仅设置当前页面" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actionT) {
        NSString *urlStr = [alert.textFields.firstObject text];
        if (urlStr.length == 0) return;
        
        __self.localDebugUrlStr = urlStr;
        __self.debugModel = debugModel;
        
        cacheBlock(urlStr);
        
        [__self doSwitchDebugModel:debugModel info:@{ZHWebViewLocalDebugUrlKey: urlStr}];
    }];
    UIAlertAction *ac3 = [UIAlertAction actionWithTitle:@"App全局设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actionT) {
        NSString *urlStr = [alert.textFields.firstObject text];
        if (urlStr.length == 0) return;
        
        ZHWebViewDebugGlobalConfigurationItem *item = [__self.globalConfig fetchConfigurationItem:__self.webView.globalConfig.appletConfig.appId];
        item.localDebugUrlStr = urlStr;
        item.debugModel = debugModel;
        
        __self.localDebugUrlStr = urlStr;
        __self.debugModel = debugModel;
        
        cacheBlock(urlStr);
        
        [__self doSwitchDebugModel:debugModel info:@{ZHWebViewLocalDebugUrlKey: urlStr}];
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"输入本机WebView项目目录地址";
        NSString *cacheUrl = __self.localDebugUrlStr?:fetchCacheBlock();
        if (cacheUrl && cacheUrl.length > 0) {
            textField.text = cacheUrl;
        }
    }];
    [alert addAction:ac2];
    [alert addAction:ac3];
    [alert addAction:ac1];
    [[self fetchActivityCtrl] presentViewController:alert animated:YES completion:nil];
}
//release调试弹窗
- (void)alertDebugModelRelease:(UIAlertAction *)action debugModel:(ZHWebViewDebugModel)debugModel{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:action.title message:@"切换为release线上模式" preferredStyle:UIAlertControllerStyleAlert];
    __weak __typeof__(self) __self = self;
    UIAlertAction *ac1 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull actionT){
    }];
    UIAlertAction *ac2 = [UIAlertAction actionWithTitle:@"仅设置当前页面" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actionT) {
        
        __self.debugModel = debugModel;
        
        [__self doSwitchDebugModel:debugModel info:nil];
    }];
    UIAlertAction *ac3 = [UIAlertAction actionWithTitle:@"App全局设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actionT) {
        
        ZHWebViewDebugGlobalConfigurationItem *item = [__self.globalConfig fetchConfigurationItem:__self.webView.globalConfig.appletConfig.appId];
        item.debugModel = debugModel;
        
        __self.debugModel = debugModel;
        
        [__self doSwitchDebugModel:debugModel info:nil];
    }];
    [alert addAction:ac2];
    [alert addAction:ac3];
    [alert addAction:ac1];
    [[self fetchActivityCtrl] presentViewController:alert animated:YES completion:nil];
}
//sheet 弹窗选择
- (void)alertSheetSelected:(UIAlertAction *)action debugModel:(ZHWebViewDebugModel)debugModel{
    if (debugModel == ZHWebViewDebugModelNo) {
        [self alertDebugModelRelease:action debugModel:debugModel];
    }else if (debugModel == ZHWebViewDebugModelLocal){
        [self alertDebugModelLocal:action debugModel:debugModel];
    }else if (debugModel == ZHWebViewDebugModelOnline){
        [self alertDebugModelOnline:action debugModel:debugModel];
    }
}
//sheet 弹窗
- (void)alertDebugModelSheet{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"切换调试模式" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    __weak __typeof__(self) __self = self;
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:[self.globalConfig fetchModeDesc:ZHWebViewDebugModelNo] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [__self alertSheetSelected:action debugModel:ZHWebViewDebugModelNo];
    }];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:[self.globalConfig fetchModeDesc:ZHWebViewDebugModelOnline] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [__self alertSheetSelected:action debugModel:ZHWebViewDebugModelOnline];
    }];
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:[self.globalConfig fetchModeDesc:ZHWebViewDebugModelLocal] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [__self alertSheetSelected:action debugModel:ZHWebViewDebugModelLocal];
    }];
    UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alert addAction:action];
    [alert addAction:action1];
    if (TARGET_OS_SIMULATOR) [alert addAction:action2];
    [alert addAction:action3];
    [[self fetchActivityCtrl] presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Call ZHWebViewSocketDebugDelegate

- (void)webViewCallReadyRefresh{
    [self updateFloatViewTitle:@"准备中..."];
    if (ZHCheckDelegate(self.webView.zh_socketDebugDelegate, @selector(webViewReadyRefresh:))) {
        [self.webView.zh_socketDebugDelegate webViewReadyRefresh:self.webView];
    }
}
- (void)webViewCallRefresh:(NSDictionary *)info{
    [self updateFloatViewTitle:@"刷新中..."];
        
        /** presented 与dismiss同时进行 会crash */
    //    if ([self.presentedViewController isKindOfClass:[UIAlertController class]]) {
    //        [self dismissViewControllerAnimated:YES completion:nil];
    //    }
    
    //获取代理
    id <ZHWebViewSocketDebugDelegate> socketDebugDelegate = self.webView.zh_socketDebugDelegate;
    //清除代理
    self.webView.zh_navigationDelegate = nil;
    self.webView.zh_UIDelegate = nil;
    self.webView.zh_socketDebugDelegate = nil;
    //清除缓存【否则ios11以上不会实时刷新最新的改动】
    [self.webView clearWebViewSystemCache];
    //回调
    if (ZHCheckDelegate(socketDebugDelegate, @selector(webViewRefresh:debugModel:info:))) {
        ZHWebViewDebugModel debugModel = self.debugModel;
        if (debugModel == ZHWebViewDebugModelNo) {
        }else if (debugModel == ZHWebViewDebugModelLocal){
            info = info ?: @{ZHWebViewLocalDebugUrlKey: self.localDebugUrlStr};
        }else if (debugModel == ZHWebViewDebugModelOnline){
            info = info ?: @{ZHWebViewSocketDebugUrlKey: self.socketDebugUrlStr};
        }
        [socketDebugDelegate webViewRefresh:self.webView debugModel:self.debugModel info:info];
    }
}

#pragma mark - socket debug

- (void)socketDidOpen:(NSDictionary *)params{
    
}
- (void)socketDidReceiveMessage:(NSDictionary *)params{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![params isKindOfClass:[NSDictionary class]]) return;
        NSString *type = [params valueForKey:@"type"];
        if (![type isKindOfClass:[NSString class]]) return;
        NSObject *target = self;
        
        if ([type isEqualToString:@"invalid"]) {
            if ([target respondsToSelector:@selector(webViewCallReadyRefresh)]) {
                [target performSelector:@selector(webViewCallReadyRefresh) withObject:nil];
            }
            if ([target respondsToSelector:@selector(webViewCallRefresh:)]) {
                [NSObject cancelPreviousPerformRequestsWithTarget:target selector:@selector(webViewCallRefresh:) object:nil];
            }
            return;
        }
        if ([type isEqualToString:@"hash"]) {
            if ([target respondsToSelector:@selector(webViewCallRefresh:)]) {
                [NSObject cancelPreviousPerformRequestsWithTarget:target selector:@selector(webViewCallRefresh:) object:nil];
            }
            return;
        }
        if ([type isEqualToString:@"ok"] || [type isEqualToString:@"warnings"]) {
            if ([target respondsToSelector:@selector(webViewCallRefresh:)]) {
                [NSObject cancelPreviousPerformRequestsWithTarget:target selector:@selector(webViewCallRefresh:) object:nil];
                [target performSelector:@selector(webViewCallRefresh:) withObject:nil afterDelay:0.3];
            }
            return;
        }
    });
}
- (void)socketDidError:(NSDictionary *)params{
    
}
- (void)socketDidClose:(NSDictionary *)params{
    
}

#pragma mark - activityCtrl

- (UIViewController *)fetchActivityCtrl:(UIViewController *)ctrl{
    UIViewController *topCtrl = ctrl.presentedViewController;
    if (!topCtrl) return ctrl;
    return [self fetchActivityCtrl:topCtrl];
}
- (UIViewController *)fetchActivityCtrl{
    UIViewController *ctrl = [UIApplication sharedApplication].keyWindow.rootViewController;
    return [self fetchActivityCtrl:ctrl];
}

- (void)dealloc{
    NSLog(@"%s", __func__);
}
@end
