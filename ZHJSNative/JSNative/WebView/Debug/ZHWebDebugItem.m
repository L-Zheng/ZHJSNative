//
//  ZHWebDebugItem.m
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHWebDebugItem.h"
#import "ZHJSDebugManager.h"
#import "ZHWebView.h"
#import "ZHJSApiListController.h"
#import "ZHJSHandler.h"
#import <ZHFloatWindow/ZHFloatView.h>

@interface ZHWebDebugItem ()
// 浮窗
@property (nonatomic,strong) ZHFloatView *refreshFloatView;
@property (nonatomic,strong) ZHFloatView *debugModeFloatView;
@end

@implementation ZHWebDebugItem

+ (instancetype)defaultItem{
    ZHWebDebugItem *item = [[ZHWebDebugItem alloc] init];
    [item configProperty:nil];
    return item;
}
+ (instancetype)item:(ZHWebView *)webView{
    ZHWebDebugItem *item = [ZHJSDebugMg() getWebDebugGlobalItem:webView.globalConfig.mpConfig.appId];
    
    ZHWebDebugItem *resItem = [item sameItem];
    resItem.webView = webView;
    return resItem;
}
- (ZHWebDebugItem *)sameItem{
    ZHWebDebugItem *resItem = [[ZHWebDebugItem alloc] init];
    [resItem configProperty:self];
    return resItem;
}
- (void)configProperty:(ZHWebDebugItem *)item{
    self.debugMode = item ? item.debugMode : ZHWebDebugMode_Release;
    self.socketUrlStr = item ? item.socketUrlStr : nil;
    self.localUrlStr = item ? item.localUrlStr : nil;
    self.webView = item ? item.webView : nil;
    
    BOOL globalDebugEnable = [ZHJSDebugMg() getWebDebugGlobalEnable];
    
    self.debugModeEnable = item ? item.debugModeEnable : globalDebugEnable;
    self.refreshEnable = item ? item.refreshEnable : globalDebugEnable;
    self.logOutputWebEnable = item ? item.logOutputWebEnable : globalDebugEnable;
    self.logOutputXcodeEnable = item ? item.logOutputXcodeEnable : globalDebugEnable;
    self.alertWebErrorEnable = item ? item.alertWebErrorEnable : [ZHJSDebugMg() getWebDebugAlertErrorEnable];
    self.touchCalloutEnable = item ? item.touchCalloutEnable : globalDebugEnable;
}

#pragma mark - alert

//切换模式
- (void)doSwitchDebugMode:(ZHWebDebugMode)debugMode{
    [self updateDebugModeFloatViewTitle:ZHWebDebugDescByMode(debugMode)];
    [self webViewCallReadyRefresh];
    [self webViewCallStartRefresh:nil];
}
//socket debug调试弹窗
- (void)alertDebugModeOnline:(UIAlertAction *)action debugMode:(ZHWebDebugMode)debugMode{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:action.title message:@"该模式将会监听代码改动，同步刷新页面UI。\n在Web项目目录下运行 yarn serve，将http地址填在此处【如：http://192.168.2.21:8080】。" preferredStyle:UIAlertControllerStyleAlert];
    
    __weak __typeof__(self) __self = self;
    UIAlertAction *ac1 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull actionT){
    }];
    UIAlertAction *ac2 = [UIAlertAction actionWithTitle:@"仅设置当前页面" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actionT) {
        NSString *urlStr = [alert.textFields.firstObject text];
        if (urlStr.length == 0) return;
            
        __self.socketUrlStr = urlStr;
        __self.debugMode = debugMode;
        
        [ZHJSDebugMg() readWebDebugObj:[ZHJSDebugMg() webDebugSocketUrlKey]];
        
        [__self doSwitchDebugMode:debugMode];
    }];
    UIAlertAction *ac3 = [UIAlertAction actionWithTitle:@"App全局设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actionT) {
        NSString *urlStr = [alert.textFields.firstObject text];
        if (urlStr.length == 0) return;
        
        ZHWebDebugItem *item = [ZHJSDebugMg() getWebDebugGlobalItem:__self.webView.globalConfig.mpConfig.appId];
        item.socketUrlStr = urlStr;
        item.debugMode = debugMode;
        
        __self.socketUrlStr = urlStr;
        __self.debugMode = debugMode;
        
        [ZHJSDebugMg() readWebDebugObj:[ZHJSDebugMg() webDebugSocketUrlKey]];
        
        [__self doSwitchDebugMode:debugMode];
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"输入socket调试地址";
        textField.clearButtonMode = UITextFieldViewModeAlways;
        NSString *cacheUrl = __self.socketUrlStr?:[ZHJSDebugMg() readWebDebugObj:[ZHJSDebugMg() webDebugSocketUrlKey]];
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
- (void)alertDebugModeLocal:(UIAlertAction *)action debugMode:(ZHWebDebugMode)debugMode{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:action.title message:@"该模式将会运行本机Web项目目录下的内容。\n【如：/Users/em/Desktop/EMCode/fund-projects/fund-details/release】\n在你改动代码后，运行yarn build，点击浮窗刷新。" preferredStyle:UIAlertControllerStyleAlert];
    
    __weak __typeof__(self) __self = self;
    UIAlertAction *ac1 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull actionT){
    }];
    UIAlertAction *ac2 = [UIAlertAction actionWithTitle:@"仅设置当前页面" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actionT) {
        NSString *urlStr = [alert.textFields.firstObject text];
        if (urlStr.length == 0) return;
        
        __self.localUrlStr = urlStr;
        __self.debugMode = debugMode;
        
        [ZHJSDebugMg() storeWebDebugObj:[ZHJSDebugMg() webDebugLocalUrlKey] value:urlStr];
        
        [__self doSwitchDebugMode:debugMode];
    }];
    UIAlertAction *ac3 = [UIAlertAction actionWithTitle:@"App全局设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actionT) {
        NSString *urlStr = [alert.textFields.firstObject text];
        if (urlStr.length == 0) return;
        
        ZHWebDebugItem *item = [ZHJSDebugMg() getWebDebugGlobalItem:__self.webView.globalConfig.mpConfig.appId];
        item.localUrlStr = urlStr;
        item.debugMode = debugMode;
        
        __self.localUrlStr = urlStr;
        __self.debugMode = debugMode;
        
        [ZHJSDebugMg() storeWebDebugObj:[ZHJSDebugMg() webDebugLocalUrlKey] value:urlStr];
        
        [__self doSwitchDebugMode:debugMode];
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"输入本机Web项目目录地址";
        textField.clearButtonMode = UITextFieldViewModeAlways;
        
        NSString *cacheUrl = __self.localUrlStr?:[ZHJSDebugMg() readWebDebugObj:[ZHJSDebugMg() webDebugLocalUrlKey]];
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
- (void)alertDebugModeRelease:(UIAlertAction *)action debugMode:(ZHWebDebugMode)debugMode{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:action.title message:@"切换为release线上模式" preferredStyle:UIAlertControllerStyleAlert];
    __weak __typeof__(self) __self = self;
    UIAlertAction *ac1 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull actionT){
    }];
    UIAlertAction *ac2 = [UIAlertAction actionWithTitle:@"仅设置当前页面" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actionT) {
        
        __self.debugMode = debugMode;
        
        [__self doSwitchDebugMode:debugMode];
    }];
    UIAlertAction *ac3 = [UIAlertAction actionWithTitle:@"App全局设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull actionT) {
        
        ZHWebDebugItem *item = [ZHJSDebugMg() getWebDebugGlobalItem:__self.webView.globalConfig.mpConfig.appId];
        item.debugMode = debugMode;
        
        __self.debugMode = debugMode;
        
        [__self doSwitchDebugMode:debugMode];
    }];
    [alert addAction:ac2];
    [alert addAction:ac3];
    [alert addAction:ac1];
    [[self fetchActivityCtrl] presentViewController:alert animated:YES completion:nil];
}
//sheet 弹窗选择
- (void)alertSheetSelected:(UIAlertAction *)action debugMode:(ZHWebDebugMode)debugMode{
    if (debugMode == ZHWebDebugMode_Release) {
        [self alertDebugModeRelease:action debugMode:debugMode];
    }else if (debugMode == ZHWebDebugMode_Local){
        [self alertDebugModeLocal:action debugMode:debugMode];
    }else if (debugMode == ZHWebDebugMode_Online){
        [self alertDebugModeOnline:action debugMode:debugMode];
    }
}
//sheet 弹窗
- (void)alertDebugModeSheet{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"切换调试模式" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    __weak __typeof__(self) __self = self;
    
    [alert addAction:[UIAlertAction actionWithTitle:@"查看App注入的API" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        ZHJSApiListController *list = [[ZHJSApiListController alloc] initWithApiHandler:__self.webView.handler.apiHandler];
        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:list];
        navi.modalPresentationStyle = UIModalPresentationFullScreen;
        [[__self fetchActivityCtrl] presentViewController:navi animated:YES completion:nil];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:ZHWebDebugDescByMode(ZHWebDebugMode_Release) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [__self alertSheetSelected:action debugMode:ZHWebDebugMode_Release];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:ZHWebDebugDescByMode(ZHWebDebugMode_Online) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [__self alertSheetSelected:action debugMode:ZHWebDebugMode_Online];
    }]];
    if (TARGET_OS_SIMULATOR) [alert addAction:[UIAlertAction actionWithTitle:ZHWebDebugDescByMode(ZHWebDebugMode_Local) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [__self alertSheetSelected:action debugMode:ZHWebDebugMode_Local];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }]];    
    UIViewController *ctrl = [self fetchActivityCtrl];
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
        UIPopoverPresentationController *popover = alert.popoverPresentationController;
        popover.sourceView = ctrl.view;
        popover.sourceRect = CGRectMake(ctrl.view.center.x - 1, ctrl.view.frame.size.height - 1, 2, 1);
        popover.permittedArrowDirections = UIPopoverArrowDirectionDown;
    }
    [ctrl presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Call ZHWebViewDebugSocketDelegate

- (void)webViewCallReadyRefresh{
    [self updateRefreshFloatViewTitle:@"准备中..."];
    if (ZHCheckDelegate(self.webView.zh_debugSocketDelegate, @selector(zh_webViewReadyRefresh:))) {
        [self.webView.zh_debugSocketDelegate zh_webViewReadyRefresh:self.webView];
    }
}
- (void)webViewCallStartRefresh:(NSDictionary *)info{
    [self updateRefreshFloatViewTitle:@"刷新中..."];
        
        /** presented 与dismiss同时进行 会crash */
    //    if ([self.presentedViewController isKindOfClass:[UIAlertController class]]) {
    //        [self dismissViewControllerAnimated:YES completion:nil];
    //    }
    
    //获取代理
    id <ZHWebViewDebugSocketDelegate> socketDebugDelegate = self.webView.zh_debugSocketDelegate;
    //清除代理
    self.webView.zh_navigationDelegate = nil;
    self.webView.zh_UIDelegate = nil;
    self.webView.zh_debugSocketDelegate = nil;
    //清除缓存【否则ios11以上不会实时刷新最新的改动】
    [self.webView clearWebViewSystemCache];
    //回调
    if (ZHCheckDelegate(socketDebugDelegate, @selector(zh_webViewStartRefresh:))) {
        [socketDebugDelegate zh_webViewStartRefresh:self.webView];
    }
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

#pragma mark - float view

- (void)showFloatView{
    if (self.refreshEnable) {
        [self.refreshFloatView showInView:self.webView location:ZHFloatLocationRight locationScale:0.4];
    }
    if (self.debugModeEnable) {
        [self.debugModeFloatView showInView:self.webView location:ZHFloatLocationRight locationScale:0.6];
        [self updateDebugModeFloatViewTitle:ZHWebDebugDescByMode(self.debugMode)];
    }
}
- (void)updateRefreshFloatViewTitle:(NSString *)title{
    if (self.refreshEnable) {
        [self.refreshFloatView updateTitle:title];
    }
}
- (void)updateDebugModeFloatViewTitle:(NSString *)title{
    if (self.debugModeEnable) {
        [self.debugModeFloatView updateTitle:title];
    }
}
- (void)updateFloatViewLocation{
    if (self.refreshEnable) {
        [self.refreshFloatView updateWhenSuperViewLayout];
    }
    if (self.debugModeEnable) {
        [self.debugModeFloatView updateWhenSuperViewLayout];
    }
}

#pragma mark - getter

- (ZHFloatView *)refreshFloatView{
    if (!_refreshFloatView) {
        _refreshFloatView = [ZHFloatView floatViewWithItems:nil];
        __weak __typeof__(self) __self = self;
        _refreshFloatView.tapClickBlock = ^{
            [__self webViewCallStartRefresh:nil];
        };
    }
    return _refreshFloatView;
}
- (ZHFloatView *)debugModeFloatView{
    if (!_debugModeFloatView) {
        _debugModeFloatView = [ZHFloatView floatViewWithItems:nil];
        __weak __typeof__(self) __self = self;
        _debugModeFloatView.tapClickBlock = ^{
            [__self alertDebugModeSheet];
        };
    }
    return _debugModeFloatView;
}

- (void)dealloc{
    NSLog(@"%s", __func__);
}

@end
