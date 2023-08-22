//
//  JsBridgeWebHandler.m
//  JsBridge
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "JsBridgeWebHandler.h"
#import "JsBridgeHandler_Private.h"
#import "JsBridgeWebView.h"
#import "JsBridgeWebApiError.h"
#import "JsBridgeWebApiConsole.h"
#import "JsBridgeWebApiNetwork.h"
#import "JsBridgeWebApiSocket.h"

@interface JsBridgeWebHandler ()
@property (nonatomic, strong) JsBridgeWebApiError <JsBridgeApiProtocol> *api_error;
@property (nonatomic, strong) JsBridgeWebApiConsole <JsBridgeApiProtocol> *api_console;
@property (nonatomic, strong) JsBridgeWebApiNetwork <JsBridgeApiProtocol> *api_network;
@property (nonatomic, strong) JsBridgeWebApiSocket <JsBridgeApiProtocol> *api_socket;
@end

@implementation JsBridgeWebHandler

- (id)jsPage{
    return self.web;
}

#pragma mark - api

- (void)addApis:(NSArray *)apis cold:(BOOL)cold complete:(void (^)(id res, NSError *error))complete{
    NSMutableArray *oriPrefix = [[self fetchJsApiPrefixAll]?:@[] mutableCopy];
    [super addApis:apis];
    NSMutableArray *newPrefix = [[self fetchJsApiPrefixAll]?:@[] mutableCopy];
    [newPrefix removeObjectsInArray:oriPrefix];
    
    // 直接添加, 会覆盖掉先前定义的
    NSMutableString *js = [self jsapi_makeAll:NO].mutableCopy;
    NSString *jsFinish = [self jsapi_makeFinish:newPrefix];
    if (jsFinish.length > 0) {
        [js appendString:jsFinish];
    }
    [self.web runJs:js cold:cold complete:complete];
}
- (void)removeApis:(NSArray *)apis cold:(BOOL)cold complete:(void (^)(id res, NSError *error))complete{
    // 先重置掉原来定义的所有api
    NSString *clearJs = [self jsapi_makeAll:YES];
    // 添加
    [super removeApis:apis];
    // 添加新的api
    NSString *js = [NSString stringWithFormat:@"%@%@", clearJs?:@"", [self jsapi_makeAll:NO]];
    [self.web runJs:js cold:cold complete:complete];
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:JsBridgeWebMessageHandlerName]) {
        [self handlerJsMsg:message.body];
    }
}

#pragma mark - js message

- (BOOL)canHandlerJsMsg:(NSDictionary *)jsInfo{
    // js同步、异步函数标识
    NSString *bridgeIdentifier = [jsInfo valueForKey:@"bridgeIdentifier"];
    if (!bridgeIdentifier || ![bridgeIdentifier isKindOfClass:NSString.class] || bridgeIdentifier.length == 0) {
        return NO;
    }
    if ([bridgeIdentifier isEqualToString:[self jskey_bridgeSyncIdentifier]] ||
        [bridgeIdentifier isEqualToString:[self jskey_bridgeAsyncIdentifier]]) {
        return YES;
    }
    return NO;
}
- (id)handlerJsMsg:(NSDictionary *)jsInfo{
    if (!jsInfo || ![jsInfo isKindOfClass:[NSDictionary class]]) return nil;
    // 检查是否允许处理此消息
    if (![self canHandlerJsMsg:jsInfo]) {
        return nil;
    }
    // 解析消息
    NSString *jsMethodName = [jsInfo valueForKey:@"methodName"];
    NSString *jsModuleName = [jsInfo valueForKey:@"moduleName"];
    NSString *apiPrefix = [jsInfo valueForKey:@"apiPrefix"];
    NSArray *jsArgs = [jsInfo valueForKey:@"args"];
    if (!jsArgs || ![jsArgs isKindOfClass:NSArray.class] || jsArgs.count == 0) {
        return [self runNativeFunc:jsMethodName apiPrefix:apiPrefix jsModuleName:jsModuleName arguments:@[]];
    }
    /**  WebView中：js类型-->原生类型 对应关系
     Date：         params=[NSString class]，Date经JSON.stringify转换为string，@"2020-12-29T05:06:55.383Z"
     function：    params=[NSNull null]，function经JSON.stringify转换为null，原生接受为NSNull
     null：           params=[NSNull null]，null经JSON.stringify转换为null，原生接受为NSNull
     undefined： params=[NSNull null]，undefined经JSON.stringify转换为null，原生接受为NSNull
     boolean：    params=@(YES) or @(NO)  [NSNumber class]
     number：    params= [NSNumber class]
     string：        params= [NSString class]
     array：         params= [NSArray class]
     json：          params= [NSDictionary class]
     */
     __weak __typeof__(self) weakSelf = self;
    //处理参数
    NSMutableArray *resArgs = [NSMutableArray array];
    for (NSUInteger idx = 0; idx < jsArgs.count; idx++) {
        id jsArg = jsArgs[idx];
        if (![jsArg isKindOfClass:[NSDictionary class]]) {
            [resArgs addObject:[JsBridgeApiArgItem item:self.jsPage jsData:jsArg callItem:nil]];
            continue;
        }
        NSDictionary *newParams = (NSDictionary *)jsArg;
        //获取回调方法
        NSString *successId = [newParams valueForKey:[self jskey_callSuccess]];
        NSString *failId = [newParams valueForKey:[self jskey_callFail]];
        NSString *completeId = [newParams valueForKey:[self jskey_callComplete]];
        NSString *jsFuncArgId = [newParams valueForKey:[self jskey_callJsFuncArg]];
        BOOL hasCallFunction = (successId.length || failId.length || completeId.length || jsFuncArgId.length);
        //不需要回调方法
        if (!hasCallFunction) {
            [resArgs addObject:[JsBridgeApiArgItem item:self.jsPage jsData:jsArg callItem:nil]];
            continue;
        }
        //js function 参数回调
        if (jsFuncArgId.length) {
            JsBridgeApiInCallBlock block = ^JsBridgeApi_InCallBlock_Header{
                if (!weakSelf) {
                    return [JsBridgeApiCallJsNativeResItem item];
                }
                NSArray *jsFuncArgDatas = argItem.jsFuncArgDatas;
                BOOL alive = argItem.alive;
                
                [weakSelf callJsFunc:jsFuncArgId datas:jsFuncArgDatas alive:alive callBack:^(id jsRes, NSError *jsError) {
                    if (argItem.jsFuncArgResBlock) {
                        argItem.jsFuncArgResBlock([JsBridgeApiCallJsResItem item:jsRes error:jsError]);
                    }
                }];
                return [JsBridgeApiCallJsNativeResItem item];
            };
            [resArgs addObject:[JsBridgeApiArgItem item:self.jsPage jsData:jsArg callItem:[JsBridgeApiCallJsItem itemWithSFCBlock:nil jsFuncArgBlock:block]]];
        }else{
            //js success/fail/complete 回调
            JsBridgeApiInCallBlock block = ^JsBridgeApi_InCallBlock_Header{
                if (!weakSelf) {
                    return [JsBridgeApiCallJsNativeResItem item];
                }
                NSArray *successDatas = argItem.successDatas;
                NSArray *failDatas = argItem.failDatas;
                NSArray *completeDatas = argItem.completeDatas;
                NSError *error = argItem.error;
                BOOL alive = argItem.alive;
                
                if (!error && successId.length) {
                    [weakSelf callJsFunc:successId datas:successDatas alive:alive callBack:^(id jsRes, NSError *jsError) {
                        if (argItem.jsResSuccessBlock) {
                            argItem.jsResSuccessBlock([JsBridgeApiCallJsResItem item:jsRes error:jsError]);
                        }
                    }];
                }
                if (error && failId.length) {
                    [weakSelf callJsFunc:failId datas:failDatas alive:alive callBack:^(id jsRes, NSError *jsError) {
                        if (argItem.jsResFailBlock) {
                            argItem.jsResFailBlock([JsBridgeApiCallJsResItem item:jsRes error:jsError]);
                        }
                    }];
                }
                if (completeId.length) {
                    [weakSelf callJsFunc:completeId datas:completeDatas alive:alive callBack:^(id jsRes, NSError *jsError) {
                        if (argItem.jsResCompleteBlock) {
                            argItem.jsResCompleteBlock([JsBridgeApiCallJsResItem item:jsRes error:jsError]);
                        }
                    }];
                }
                return [JsBridgeApiCallJsNativeResItem item];
            };
            [resArgs addObject:[JsBridgeApiArgItem item:self.jsPage jsData:jsArg callItem:[JsBridgeApiCallJsItem itemWithSFCBlock:block jsFuncArgBlock:nil]]];
        }
    }
    return [self runNativeFunc:jsMethodName apiPrefix:apiPrefix jsModuleName:jsModuleName arguments:resArgs.copy];
}
- (void)callJsFunc:(NSString *)funcId datas:(NSArray *)datas alive:(BOOL)alive callBack:(void (^) (id jsRes, NSError *jsError))callBack{
    if (funcId.length == 0) return;
    NSDictionary *sendParams = @{@"funcId": funcId, @"data": ((datas && [datas isKindOfClass:NSArray.class]) ? datas : @[]), @"alive": @(alive)};
    [self.web sendMsgToJs:@[self.jskey_receviceNativeCall] params:sendParams complete:^(id res, NSError *error) {
        if (callBack) callBack(res, error);
    }];
}

#pragma mark - WKUIDelegate

// 页面是弹出窗口 _blank 处理
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    id <WKUIDelegate> de = self.outUIDelegate;
    // 不可使用 SEL sel = _cmd, 如果方法被交换, _cmd代表的交换后的方法名
    SEL sel = @selector(webView:createWebViewWithConfiguration:forNavigationAction:windowFeatures:);
    if ([de respondsToSelector:sel]) {
        return [de webView:webView createWebViewWithConfiguration:configuration forNavigationAction:navigationAction windowFeatures:windowFeatures];
    }
    return nil;
}
- (void)webViewDidClose:(WKWebView *)webView{
    id <WKUIDelegate> de = self.outUIDelegate;
    SEL sel = @selector(webViewDidClose:);
    if ([de respondsToSelector:sel]) {
        if (@available(iOS 9.0, *)) {
            [de webViewDidClose:webView];
        }
    }
}
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    id <WKUIDelegate> de = self.outUIDelegate;
    SEL sel = @selector(webView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:);
    if ([de respondsToSelector:sel]) {
        return [de webView:webView runJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    }
    
    // 默认实现
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (completionHandler) completionHandler();
    }]];
    [[self fetchController] presentViewController:alert animated:YES completion:nil];
}
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler{
    id <WKUIDelegate> de = self.outUIDelegate;
    SEL sel = @selector(webView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:);
    if ([de respondsToSelector:sel]) {
        return [de webView:webView runJavaScriptConfirmPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    }
    
    // 默认实现
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (completionHandler) completionHandler(YES);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        if (completionHandler) completionHandler(NO);
    }]];
    
    [[self fetchController] presentViewController:alert animated:YES completion:nil];
}
// 处理js的同步消息
-(void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler{
    __weak __typeof__(self) weakSelf = self;
    
    void (^block) (void) = ^(void){
        id <WKUIDelegate> de = weakSelf.outUIDelegate;
        SEL sel = @selector(webView:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:);
        if ([de respondsToSelector:sel]) {
           [de webView:webView runJavaScriptTextInputPanelWithPrompt:prompt defaultText:defaultText initiatedByFrame:frame completionHandler:completionHandler];
           return;
        }
        
        // 默认实现
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:prompt preferredStyle:UIAlertControllerStyleAlert];
        __weak __typeof__(alert) weakAlert = alert;
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            if (completionHandler) completionHandler(weakAlert.textFields[0].text);
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
            if (completionHandler) completionHandler(nil);
        }]];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * textField) {
            textField.text = defaultText;
        }];
        [[weakSelf fetchController] presentViewController:alert animated:YES completion:nil];
    };
    
    if (!prompt || ![prompt isKindOfClass:NSString.class] || prompt.length == 0) {
        block();
        return;
    }
    
    NSData *promptData = [prompt dataUsingEncoding:NSUTF8StringEncoding];
    if (!promptData || ![promptData isKindOfClass:NSData.class] || promptData.length == 0) {
        block();
        return;
    }
    
    NSError *error;
    NSDictionary *receiveInfo;
    @try {
        receiveInfo = [NSJSONSerialization JSONObjectWithData:promptData options:NSJSONReadingAllowFragments error:&error];
        if (error) receiveInfo = nil;
    } @catch (NSException *exception) {
        receiveInfo = nil;
    } @finally {
    }
    
    if (!receiveInfo || ![receiveInfo isKindOfClass:NSDictionary.class] || receiveInfo.allKeys.count == 0) {
        block();
        return;
    }
    
    // 检查是否允许处理此消息
    if (![self canHandlerJsMsg:receiveInfo]) {
        block();
        return;
    }
    
    // 说明此函数是api调用过来的
    id result = [self handlerJsMsg:receiveInfo];
    if (!result) {
        if (completionHandler) completionHandler(nil);
        return;
    }
    /** 包裹一层数据：js端再解析出来
     作用：原生传数据可在js正常解析出类型
     不包裹：
         completionHandler回调@(YES)   js解析为Number类型
         completionHandler回调@(1111)   js解析为Number类型
     包裹：
         result ：@(YES)  @(NO)  js解析为Boolean类型  可直接使用
         result ：@(111)  js解析为Number类型
     */
    result = @{@"data": result};
    NSData *data = nil;
    @try {
        data = [NSJSONSerialization dataWithJSONObject:result options:kNilOptions error:nil];
    } @catch (NSException *exception) {
    } @finally {
    }
    if (!data) {
        if (completionHandler) completionHandler(nil);
        return;
    }
    if (completionHandler) completionHandler([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

#pragma mark - controller

- (UIViewController *)fetchController{
    UIResponder *res = self.web.nextResponder;
    while (res && ![res isKindOfClass:UIViewController.class]) {
        res = res.nextResponder;
    }
    return res ? (UIViewController *)res : nil;
}

#pragma mark - js api

- (NSString *)jsapi_makeAll:(BOOL)clear{
    NSMutableString *res = [NSMutableString string];
    [self enumRegsiterApiMap:^(NSString *apiPrefix, NSDictionary <NSString *, JsBridgeApiRegisterItem *> *apiMap, NSDictionary *apiModuleMap) {
        // 因为要移除api, apiMap设定写死传@{}
        if (clear) {
            NSString *jsCode = [self jsapi_makeApi:apiPrefix apiMap:@{}];
            if (jsCode) [res appendString:jsCode];
        }else{
            NSString *jsCode = [self jsapi_makeApi:apiPrefix apiMap:apiMap];
            if (jsCode) [res appendString:jsCode];
            jsCode = [self jsapi_makeModule:apiPrefix apiModuleMap:apiModuleMap];
            if (jsCode) [res appendString:jsCode];
        }
    }];
    return [res copy];
}
- (NSString *)jsapi_makeApi:(NSString *)apiPrefix apiMap:(NSDictionary <NSString *,JsBridgeApiRegisterItem *> *)apiMap {
    if (![apiPrefix isKindOfClass:[NSString class]] || apiPrefix.length == 0) return nil;
    
    NSMutableDictionary *codeMap = [NSMutableDictionary dictionary];
    [apiMap enumerateKeysAndObjectsUsingBlock:^(NSString *jsMethod, JsBridgeApiRegisterItem *item, BOOL *stop) {
        [codeMap setObject:@{@"sync": @(item.isSync)} forKey:jsMethod];
    }];
    NSString *code = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:codeMap options:NSJSONWritingFragmentsAllowed error:nil] encoding:NSUTF8StringEncoding];
    
    return [NSString stringWithFormat:@"var %@=%@('%@',undefined,%@);",apiPrefix, self.jskey_makeApi, apiPrefix, code];
}
- (NSString *)jsapi_makeModule:(NSString *)apiPrefix apiModuleMap:(NSDictionary *)apiModuleMap{
    if (![apiPrefix isKindOfClass:[NSString class]] || apiPrefix.length == 0 || !apiModuleMap) return nil;
    
    NSMutableDictionary *codeMap = [NSMutableDictionary dictionary];
    [apiModuleMap enumerateKeysAndObjectsUsingBlock:^(NSString *jsModuleName, NSDictionary *moduleMap, BOOL *stop) {
        NSMutableDictionary *codeMap_module = [NSMutableDictionary dictionary];
        [moduleMap enumerateKeysAndObjectsUsingBlock:^(NSString *jsMethod, JsBridgeApiRegisterItem *item, BOOL *stop) {
            [codeMap_module setObject:@{@"sync": @(item.isSync)} forKey:jsMethod];
        }];
        [codeMap setObject:codeMap_module.copy forKey:jsModuleName];
    }];
    NSString *code = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:codeMap options:NSJSONWritingFragmentsAllowed error:nil] encoding:NSUTF8StringEncoding];
    
    return [NSString stringWithFormat:@"var %@=%@('%@',%@,%@);", apiPrefix, self.jskey_makeModuleApi, apiPrefix, apiPrefix, code];
}
- (NSString *)jsapi_makeFinish:(NSArray *)filterApiPrefix{
    /* h5监听api注入完成通知
     @"window.addEventListener('JsBridgeMyApiReady', () => {});"
     事件名称: JsBridgeMyApiReady
     */
    __block NSMutableString *resCode = [NSMutableString string];
    [self enumRegsiterApiInjectFinishEventNameMap:^(NSString *apiPrefix, NSString *apiInjectFinishEventName) {
        if ([filterApiPrefix containsObject:apiPrefix]) {
            [resCode appendFormat:@"var JsBridge_ApiInjectFinish_%@ = document.createEvent('Event');JsBridge_ApiInjectFinish_%@.initEvent('%@');window.dispatchEvent(JsBridge_ApiInjectFinish_%@);", apiPrefix, apiPrefix, apiInjectFinishEventName, apiPrefix];
        }
    }];
    return resCode.copy;
}

#pragma mark - js sdk

- (NSString *)jssdk_api_support{
    // 以下代码由event.js压缩而成
    NSString *fmt = JsBridge_resource_event.length ? JsBridge_resource_event : [self readJsFmt:@"event-min.js"];
    return [NSString stringWithFormat:fmt,
    JsBridgeWebMessageHandlerName,
     self.jskey_bridgeSyncIdentifier,
     self.jskey_bridgeAsyncIdentifier,
     self.jskey_callSuccess,
     self.jskey_callFail,
     self.jskey_callComplete,
     self.jskey_callJsFuncArg,
     self.jskey_receviceNativeCall,
     self.jskey_makeApi,
     self.jskey_makeModuleApi];
}
- (NSString *)jskey_bridgeSyncIdentifier{
    return @"JsBridge_Key_SyncIdentifier";
}
- (NSString *)jskey_bridgeAsyncIdentifier{
    return @"JsBridge_Key_AsyncIdentifier";
}
- (NSString *)jskey_callSuccess{
    return @"JsBridge_Key_CallSuccess";
}
- (NSString *)jskey_callFail{
    return @"JsBridge_Key_CallFail";
}
- (NSString *)jskey_callComplete{
    return @"JsBridge_Key_CallComplete";
}
- (NSString *)jskey_callJsFuncArg{
    return @"JsBridge_Key_CallJsFuncArg";
}
- (NSString *)jskey_receviceNativeCall{
    return @"My_JsBridge_ReceviceNativeCall";
}
- (NSString *)jskey_makeApi{
    return @"My_JsBridge_MakeApi";
}
- (NSString *)jskey_makeModuleApi{
    return @"My_JsBridge_MakeModuleApi";
}

#pragma mark - js fmt

- (NSString *)readJsFmt:(NSString *)name{
    NSString *path = [[NSBundle mainBundle] pathForResource:name.stringByDeletingPathExtension ofType:name.pathExtension];
//    [[NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TestBundle" ofType:@"bundle"]] pathForResource:name.stringByDeletingPathExtension ofType:name.pathExtension]
    BOOL dir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir] || dir) {
        return nil;
    }
    NSString *res = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (!res || ![res isKindOfClass:NSString.class] || res.length == 0) {
        return nil;
    }
    return res;
}

#pragma mark - error

// 运行 -[WKWebView evaluateJavaScript:completionHandler:] 方法导致的异常也会被捕获到
- (void)captureException:(BOOL)cold handler:(void (^) (id exception))handler{
    __weak __typeof__(self) weakSelf = self;
    void (^block) (id exception) = ^(id exception){
        if (!handler) return;
        handler([weakSelf parseException:exception]);
    };
    
    if (self.api_error) {
        self.api_error.handler = block;
        return;
    }
    
    self.api_error = [[JsBridgeWebApiError alloc] init];
    self.api_error.jsBridge = self;
    self.api_error.handler = block;
    [self addApis:@[self.api_error] cold:cold complete:^(id res1, NSError *error1) {
        if (error1) return;
        NSString *js = [weakSelf jssdk_api_error:[weakSelf.api_error jsBridge_jsApiPrefix]];
        [weakSelf.web runJs:js cold:cold complete:^(id res2, NSError *error2) {
        }];
    }];
}
- (NSString *)jssdk_api_error:(NSString *)apiJsName{
    // 以下代码由error.js压缩而成
    NSString *fmt = JsBridge_resource_error.length ? JsBridge_resource_error : [self readJsFmt:@"error-min.js"];
    return [NSString stringWithFormat:fmt, apiJsName, apiJsName];
}

#pragma mark - console

- (void)captureConsole:(BOOL)cold handler:(void (^) (NSString *flag, NSArray *args))handler{
    __weak __typeof__(self) weakSelf = self;
    void (^block) (NSString *flag, NSArray *args) = ^(NSString *flag, NSArray *args){
        if (!handler) return;
        handler(flag, args);
    };
    
    if (self.api_console) {
        self.api_console.handler = block;
        return;
    }
    
    self.api_console = [[JsBridgeWebApiConsole alloc] init];
    self.api_console.jsBridge = self;
    self.api_console.handler = block;
    [self addApis:@[self.api_console] cold:cold complete:^(id res1, NSError *error1) {
        if (error1) return;
        NSString *js = [weakSelf jssdk_api_console:[weakSelf.api_console jsBridge_jsApiPrefix]];
        [weakSelf.web runJs:js cold:cold complete:^(id res2, NSError *error2) {
        }];
    }];
}
- (NSString *)jssdk_api_console:(NSString *)apiJsName{
    // 以下代码由console.js压缩而成
    NSString *fmt = JsBridge_resource_console.length ? JsBridge_resource_console : [self readJsFmt:@"console-min.js"];
    return [NSString stringWithFormat:fmt, apiJsName];
}
- (void)captureVConsole:(BOOL)cold complete:(void (^) (id res, NSError *error))complete{
    NSString *js = [self jssdk_api_vconsole];
    if (cold) {
        [self.web injectJs:js time:WKUserScriptInjectionTimeAtDocumentEnd complete:complete];
    }else{
        [self.web runJs:js cold:NO complete:complete];
    }
}
- (NSString *)jssdk_api_vconsole{
    NSString *js = [self readJsFmt:@"vconsole.min.js"];
    if (!js) return nil;
    return [NSString stringWithFormat:@"%@; var vConsole = new VConsole(); (function() { var timer = null; timer = setInterval(function() { var wrap = document ? document.getElementById('__vconsole') : null; var dom = (typeof wrap === 'object' && typeof wrap.children === 'object' && wrap.children.length > 0) ? wrap.children[0] : null; if (!dom) return; dom.style.width = '60px'; clearInterval(timer); timer = null; }, 1000); })();", js];
}

#pragma mark - network

- (void)captureNetwork:(BOOL)cold handler:(void (^) (id data))handler{
    __weak __typeof__(self) weakSelf = self;
    void (^block) (id data) = ^(id data){
        if (!handler) return;
        handler(data);
    };
    
    if (self.api_network) {
        self.api_network.handler = block;
        return;
    }
    
    self.api_network = [[JsBridgeWebApiNetwork alloc] init];
    self.api_network.jsBridge = self;
    self.api_network.handler = block;
    [self addApis:@[self.api_network] cold:cold complete:^(id res1, NSError *error1) {
        if (error1) return;
        NSString *js = [weakSelf jssdk_api_network:[weakSelf.api_network jsBridge_jsApiPrefix]];
        [weakSelf.web runJs:js cold:cold complete:^(id res2, NSError *error2) {
        }];
    }];
}
- (NSString *)jssdk_api_network:(NSString *)apiJsName{
    // 以下代码由console.js压缩而成
    NSString *fmt = JsBridge_resource_network.length ? JsBridge_resource_network : [self readJsFmt:@"network-min.js"];
    return [NSString stringWithFormat:fmt, apiJsName];
}

#pragma mark - socket

- (void)captureSocket:(BOOL)cold complete:(void (^) (id res, NSError *error))complete{
    if (self.api_socket) {
        if (complete) complete(nil, nil);
        return;
    }
    __weak __typeof__(self) weakSelf = self;
    self.api_socket = [[JsBridgeWebApiSocket alloc] init];
    self.api_socket.jsBridge = self;
    [self addApis:@[self.api_socket] cold:cold complete:^(id res1, NSError *error1) {
        if (error1) {
            if (complete) complete(res1, error1);
            return;
        }
        NSString *js = [weakSelf jssdk_api_socket:[weakSelf.api_socket jsBridge_jsApiPrefix]];
        [weakSelf.web runJs:js cold:cold complete:^(id res2, NSError *error2) {
            if (complete) complete(res2, error2);
        }];
    }];
}
- (NSString *)jssdk_api_socket:(NSString *)apiJsName{
    // 以下代码由socket.js压缩而成
    NSString *fmt = JsBridge_resource_socket.length ? JsBridge_resource_socket : [self readJsFmt:@"socket-min.js"];
    return [NSString stringWithFormat:fmt, apiJsName];
}

#pragma mark - parse

- (NSString *)parseObjToStr:(id)data{
    if (!data) return nil;
    
    NSString *res = nil;
    if ([data isKindOfClass:[NSString class]]) {
        res = (NSString *)data;
    }else if ([data isKindOfClass:[NSNumber class]]){
        res = [NSString stringWithFormat:@"%@",data];
    }else if ([data isKindOfClass:[NSDictionary class]] || [data isKindOfClass:[NSArray class]]){
        NSError *jsonError;
        NSData *jsonData = nil;
        @try {
            // 当原生传来的json中包含有NSObject对象，数据解析异常导致crash
            jsonData = [NSJSONSerialization dataWithJSONObject:data options:kNilOptions error:&jsonError];
        } @catch (NSException *exception) {
        } @finally {
        }
        if (jsonError || !jsonData) return nil;
        res = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }else{
        res = [data description];
    }
    
    NSString *(^block)(NSString *) = ^NSString *(NSString *str){
        return [str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    };
    if (@available(iOS 8.3, *)) {
        return block(res);
    }
    /** iOS8.2以下对于 较长的中文字符串 编码存在内存问题，导致crash
     https://stackoverflow.com/questions/44309415/stack-overflow-in-nsstringnsurlutilities-stringbyaddingpercentencodingwithal
     https://github.com/Alamofire/Alamofire/issues/206
     将字符串分割操作
     */
    if (res.length < 400) {
        return block(res);
    }
    NSMutableString *newRes = [NSMutableString string];
    NSInteger totalCount = res.length;
    NSInteger batchSize = 100;
    for (NSUInteger i = 0; i < totalCount; i += batchSize) {
        NSInteger rangeLength = i + batchSize > totalCount ? totalCount - i : batchSize;
        [newRes appendString:block([res substringWithRange:NSMakeRange(i, rangeLength)])];
    }
    return newRes.copy;
}

@end
