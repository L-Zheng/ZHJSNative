//
//  JsBridgeWebView.m
//  JsBridge
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "JsBridgeWebView.h"

@interface JsBridgeWebView ()
@end

@implementation JsBridgeWebView

#pragma mark - init

// init、initWithFrame:方法都会调用此方法
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration{
    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
        [self configJsBridge];
    }
    return self;
}

#pragma mark - bridge

- (JsBridgeWebHandler *)jsBridge{
    if (!_jsBridge) {
        _jsBridge = [[JsBridgeWebHandler alloc] init];
        _jsBridge.web = self;
    }
    return _jsBridge;
}
- (void)configJsBridge{
    [self setUIDelegate:nil];
    [self runJs:[self.jsBridge jssdk_api_support] cold:YES complete:nil];
    [self.configuration.userContentController addScriptMessageHandler:self.jsBridge name:JsBridgeWebHandlerKey];
}

#pragma mark - js

- (void)runJs:(NSString *)js cold:(BOOL)cold complete:(void (^)(id res, NSError *error))complete{
    if (!js || ![js isKindOfClass:NSString.class] || js.length == 0) {
        if (complete) complete(nil, JBMakeErr(404, JBLCDesc(@"js params is invalid.")));
        return;
    }
    if (!cold) {
        [self runJs_hot:js complete:complete];
        return;
    }
    [self injectJs:js time:WKUserScriptInjectionTimeAtDocumentStart];
    if (complete) complete(nil, nil);
}
- (void)injectJs:(NSString *)js time:(WKUserScriptInjectionTime)time{
    if (!js || ![js isKindOfClass:NSString.class] || js.length == 0) {
        return;
    }
    /* 注入js
     WKUserScriptInjectionTimeAtDocumentStart:
        document创建完成之后，其它任何内容加载之前。此时h5里面只有window、document对象，没有head、body对象
     WKUserScriptInjectionTimeAtDocumentEnd:
        document加载完成之后（html根标签代码执行到末尾），其它任何子资源可能加载完成之前
     js执行顺序：(vue项目打包后会把js插入到body的末尾)
     start脚本 -> header里面的script标签 -> body里面的script标签 ->vue插入到body末尾的script标签 (beforeCreate -> created -> mounted) -> 与body同级的后面的script标签 ->html根标签执行结束 -> end脚本
     */
    WKUserScript *script = [[WKUserScript alloc] initWithSource:js injectionTime:time forMainFrameOnly:YES];
    [self.configuration.userContentController addUserScript:script];
}
/** evaluateJavaScript方法运行js函数的参数：
 尽量包裹一层数据【使用NSDictionary-->转成NSString-->utf-8编码】：js端再解析出来【utf-8解码-->JSON.parse()-->json】
 
 作用：原生传数据可在js正常解析出类型
 不包裹直接传参数：
     @(YES)   js解析为String类型
     @(1111)   js解析为String类型
 包裹：
     result ：@(YES)  @(NO)  js解析为Boolean类型  可直接使用
     result ：@(111)  js解析为Number类型
 */
// 发送js消息
- (void)sendMsgToJs:(NSArray *)functions params:(NSDictionary *)params complete:(void (^)(id res, NSError *error))complete{
    NSMutableArray *newFunctions = [NSMutableArray array];
    for (NSString *function in functions) {
        if (!function || ![function isKindOfClass:NSString.class] || function.length == 0) {
            continue;
        }
        [newFunctions addObject:function];
    }
    if (!newFunctions || ![newFunctions isKindOfClass:NSArray.class] || newFunctions.count == 0) {
        if (complete) complete(nil, [NSError errorWithDomain:@"" code:404 userInfo:@{NSLocalizedDescriptionKey: @"evaluate js's function is null"}]);
        return;
    }
    
    NSMutableString *funcName = [NSMutableString string];
    for (NSUInteger i = 0; i < newFunctions.count; i++) {
        [funcName appendFormat:@"%@%@", functions[i], (i == functions.count - 1 ? @"" : @".")];
    }
    
    NSString *paramsStr = [self.jsBridge parseObjToStr:params];
    NSString *funcJs = paramsStr.length ? [NSString stringWithFormat:@"(%@)(\"%@\");", funcName, paramsStr] : [NSString stringWithFormat:@"(%@)();", funcName];

    // typeof myApi === 'function'
//    NSString *js = [NSString stringWithFormat:@"\
//          (function () {\
//              try {\
//                      if (Object.prototype.toString.call(window.%@) === '[object Function]') {\
//                        return %@\
//                      } else {\
//                        return '%@ is ' + Object.prototype.toString.call(window.%@);\
//                      }\
//                  }\
//              catch (error) {\
//                  return error.toString();\
//              }\
//          })();", funcName, funcJs, funcName, funcName];
    [self runJs_hot:funcJs complete:complete];
}
- (void)runJs_hot:(NSString *)js complete:(void (^)(id res, NSError *error))complete{
    if (@available(iOS 9.0, *)) {
        [self evaluateJavaScript:js completionHandler:complete];
        return;
    }
    /** iOS8 crash问题
         调用evaluateJavaScript函数，如果此时WKWebView退出dealloc，会导致completionHandler block释放，
         此时JS代码还在执行，等待JavaScriptCore执行完毕，准备回调completionHandler，发生野指针错误。
     iOS9，苹果已修复此问题
        https://zhuanlan.zhihu.com/p/24990222
        https://trac.webkit.org/changeset/179160/webkit
        不再提前获取completionHandler，准备回调时再获取completionHandler
     修复：
        completionHandler强引用WKWebView，推迟WKWebView及completionHandler的释放，待completionHandler执行完成后，
        completionHandler会自动销毁，WKWebView释放。
     */
    __strong __typeof__(self) strongSelf = self;
    [self evaluateJavaScript:js completionHandler:^(id res, NSError *error) {
        // 强引用WebView
        [strongSelf configuration];
        if (complete) complete(res, error);
    }];
}

#pragma mark - WKUIDelegate

- (void)setUIDelegate:(id <WKUIDelegate>)UIDelegate{
    self.jsBridge.outUIDelegate = UIDelegate;
    [super setUIDelegate:self.jsBridge];
}

#pragma mark - dealloc

- (void)dealloc{
    @try {
        WKUserContentController *userContent = self.configuration.userContentController;
        [userContent removeAllUserScripts];
        
        [userContent removeScriptMessageHandlerForName:JsBridgeWebHandlerKey];
    } @catch (NSException *exception) {
    } @finally {
    }
}

@end
