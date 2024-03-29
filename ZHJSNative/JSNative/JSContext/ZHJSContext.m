//
//  ZHJSContext.m
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHJSContext.h"
#import "ZHJSHandler.h"
#import "ZHJSInCtxFundApi.h"
#import "NSError+ZH.h"
#import "ZHUtil.h"

@interface ZHJSContext ()
@property (nonatomic,strong) ZHJSHandler *handler;
@property (nonatomic,strong) NSLock *lock;
@property (nonatomic,retain) NSMutableDictionary <NSString *, JSValue *> *consoleMap;
//运行的沙盒目录
@property (nonatomic, copy) NSURL *runSandBoxURL;
@end

@implementation ZHJSContext

- (instancetype)initWithGlobalConfig:(ZHCtxConfig *)globalConfig{
    self.globalConfig = globalConfig;
    globalConfig.jsContext = self;
    
    ZHCtxMpConfig *mpConfig = globalConfig.mpConfig;
    mpConfig.jsContext = self;
    self.mpConfig = mpConfig;
    
    self.contextItem = [ZHJSContextItem createByInfo:@{
        @"appId": mpConfig.appId?:@"",
        @"envVersion": mpConfig.envVersion?:@"",
        @"url": mpConfig.loadFileName?:@"",
        @"params": @{}
    }];
    
    return [self initWithCreateConfig:globalConfig.createConfig];
}
- (instancetype)initWithCreateConfig:(ZHCtxCreateConfig *)createConfig{
    // 初始化配置
    self.createConfig = createConfig;
    createConfig.jsContext = self;
    NSArray <id <ZHJSApiProtocol>> *apis = createConfig.apis;
    
    //创建虚拟机
    JSVirtualMachine *vm = [[JSVirtualMachine alloc] init];
    self = [self initWithVirtualMachine:vm];
    if (self) {
        self.lock = [[NSLock alloc] init];
        
        // debug配置
        ZHCtxDebugItem *debugItem = [ZHCtxDebugItem item:self];
        self.debugItem = debugItem;
        
        // 内置api
        NSMutableArray *inApis = [NSMutableArray array];
        if (createConfig.injectInAPI) {
            ZHJSInCtxFundApi *fund = [[ZHJSInCtxFundApi alloc] init];
            fund.jsContext = self;
            [inApis addObject:fund];
        }
        
        // api处理配置
        ZHJSHandler *handler = [[ZHJSHandler alloc] init];
        handler.apiHandler = [[ZHJSApiHandler alloc] initWithApis:inApis apis:apis?:@[]];
        handler.jsPage = self;
        handler.jsContext = self;
        self.handler = handler;
        
        //注入api
        [self registerException];
        if (debugItem.logOutputXcodeEnable) {
            [self registerLogAPI];
        }
        [self registerAPI];
        
        //运算js
//            [self evaluateScript:[NSString stringWithContentsOfURL:[NSURL fileURLWithPath:[ZHPath jsPath]] encoding:NSUTF8StringEncoding error:nil]];
        
    }
    return self;
}

- (NSArray<id<ZHJSApiProtocol>> *)apis{
    return [self.handler apis];
}

//添加移除api
- (void)addApis:(NSArray <id <ZHJSApiProtocol>> *)apis completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApis, NSArray<id<ZHJSApiProtocol>> *failApis, id res, NSError *error))completion{
    __weak __typeof__(self) __self = self;
    [self.handler addApis:apis completion:^(NSArray<id<ZHJSApiProtocol>> *successApis, NSArray<id<ZHJSApiProtocol>> *failApis, NSString *jsCode, NSError *error) {
        if (error) {
            if (completion) completion(successApis, failApis, nil, error?:[NSError errorWithDomain:@"" code:404 userInfo:@{NSLocalizedDescriptionKey: @"api注入失败"}]);
            return;
        }
        //直接添加  会覆盖掉先前定义的
        [__self registerAPI];
        if (completion) completion(successApis, failApis, @{}, nil);
    }];
}
- (void)removeApis:(NSArray <id <ZHJSApiProtocol>> *)apis completion:(void (^) (NSArray<id<ZHJSApiProtocol>> *successApis, NSArray<id<ZHJSApiProtocol>> *failApis, id res, NSError *error))completion{
    __weak __typeof__(self) __self = self;
    
    //先重置掉原来定义的所有api
    [self removeAPI];
    
    [self.handler removeApis:apis completion:^(NSArray<id<ZHJSApiProtocol>> *successApis, NSArray<id<ZHJSApiProtocol>> *failApis, NSString *jsCode, NSError *error) {
        if (error) {
            if (completion) completion(successApis, failApis, nil, error?:[NSError errorWithDomain:@"" code:404 userInfo:@{NSLocalizedDescriptionKey: @"api移除失败"}]);
            return;
        }
        //添加新的api
        [__self registerAPI];
        if (completion) completion(successApis, failApis, @{}, nil);
    }];
}

- (void)registerException{
    /** 异常回调
     没有try cach方法 js直接报错   会回调
     有try cach方法 catch方法抛出异常throw error;   会回调
     有try cach方法 catch方法没有抛出异常throw error;   不会回调
     */
    __weak __typeof__(self) __self = self;
    [self setExceptionHandler:^(JSContext *context, JSValue *exception){
        NSLog(@"❌JSContext异常");
        NSMutableDictionary *res = [[exception toDictionary] mutableCopy];
        [res setValue:[exception toString]?:@"" forKey:@"message"];
        NSLog(@"%@", res);
        [__self.handler showJSContextException:[res copy]];
    }];
}
//注入console.log
- (void)registerLogAPI{
    __weak __typeof__(self) __self = self;
    [self.handler fetchJSContextConsoleApi:^(NSString *apiPrefix, NSDictionary *apiBlockMap) {
        if (!apiPrefix || ![apiPrefix isKindOfClass:NSString.class] || apiPrefix.length == 0 ||
            !apiBlockMap || ![apiBlockMap isKindOfClass:NSDictionary.class] || apiBlockMap.allKeys.count == 0) {
            return;
        }
        [__self setObject:apiBlockMap forKeyedSubscript:apiPrefix];
    }];
}
- (void)registerAPI{
    [self oprateAPIWithReset:NO];
}
- (void)removeAPI{
    [self oprateAPIWithReset:YES];
}
- (void)oprateAPIWithReset:(BOOL)isReset{
    __weak __typeof__(self) __self = self;
    [self.handler fetchJSContextApi:^(NSString *apiPrefix, NSDictionary *apiBlockMap) {
        if (!apiPrefix || ![apiPrefix isKindOfClass:[NSString class]] || apiPrefix.length == 0) return;
        if (isReset) {
            //因为要移除api  apiMap设定写死传@{}
            [__self setObject:@{} forKeyedSubscript:apiPrefix];
            return;
        }
        if (!apiBlockMap || ![apiBlockMap isKindOfClass:[NSDictionary class]] || apiBlockMap.allKeys.count == 0) return;
        [__self setObject:apiBlockMap forKeyedSubscript:apiPrefix];
    }];
}

#pragma mark - render

/// 加载js
/// @param url 加载的url路径
/// @param baseURL 【JSContext运行所需的资源根目录，如果为nil，默认为url的上级目录】
/// @param loadConfig loadConfig
/// @param loadStartBlock  回调
/// @param loadFinishBlock  回调
- (void)renderWithUrl:(NSURL *)url
              baseURL:(NSURL *)baseURL
           loadConfig:(ZHCtxLoadConfig *)loadConfig
       loadStartBlock:(void (^) (NSURL *runSandBoxURL))loadStartBlock
      loadFinishBlock:(void (^) (NSDictionary *info, NSError *error))loadFinishBlock{
    
    self.loadConfig = loadConfig;
    loadConfig.jsContext = self;
    
    void (^callBack)(NSDictionary *, NSError *) = ^(NSDictionary *info, NSError *error){
        if (loadFinishBlock) loadFinishBlock(info, error);
    };
    
    NSString *extraErrorDesc = [NSString stringWithFormat:@"file path is %@. url is %@. baseURL is %@. loadConfig is %@.", url.path, url, baseURL, [loadConfig formatInfo]];
    
    if (!url) {
        callBack(nil, ZHInlineError(404, ZHLCInlineString(@"jscontext load url is null. %@", extraErrorDesc)));
        return;
    }
    
    //远程Url
    if (!url.isFileURL) {
        [self callStartLoad:nil renderURL:url block:loadStartBlock];
        
        __weak __typeof__(self) __self = self;
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    callBack(nil, ZHInlineError(error.code, ZHLCInlineString(@"%@", error.zh_localizedDescription)));
                    return;
                }
                if (!data || data.length == 0) {
                    callBack(nil, ZHInlineError(error.code, ZHLCInlineString(@"url(%@) response data is null.", url)));
                    return;
                }
                NSString *loadStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (!loadStr || loadStr.length == 0) {
                    callBack(nil, ZHInlineError(error.code, ZHLCInlineString(@"url(%@) response string(%@) data is null.", url, loadStr)));
                    return;
                }
                
                JSValue *res = [__self evaluateScript:loadStr withSourceURL:url];
                callBack([res toObject], nil);
            });
        }];
        [dataTask resume];
        return;
    }
    
    self.runSandBoxURL = [ZHUtil parseRealRunBoxFolder:baseURL fileURL:url];
    [self callStartLoad:self.runSandBoxURL renderURL:url block:loadStartBlock];
    NSError *readErr = nil;
    NSString *loadStr = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&readErr];
    if (readErr) {
        callBack(nil, ZHInlineError(readErr.code, ZHLCInlineString(@"%@", readErr.zh_localizedDescription)));
        return;
    }
    if (!loadStr || loadStr.length == 0) {
        callBack(nil, ZHInlineError(404, ZHLCInlineString(@"url(%@) read string(%@) data is null.", url, loadStr)));
        return;
    }
    /*
     若JSContext运行两次，后者的代码不会覆盖前者的代码，仍可执行js里面的aa函数
     [JSContext evaluateScript:@"var aa = function(){console.log('1111111111')}"];
     [JSContext evaluateScript:@"var bb = function(){console.log('22222222')}"];
     
     JSValue *parseFunc = [self.context objectForKeyedSubscript:@"aa"];
     [parseFunc callWithArguments:@[]];  // 输出1111111111
     */
    JSValue *res = [self evaluateScript:loadStr withSourceURL:url];
    callBack([res toObject], nil);
}

//配置渲染回调
- (void)callStartLoad:(NSURL *)runSandBoxURL renderURL:(NSURL *)renderURL block:(void (^) (NSURL *runSandBoxURL))block{
    self.renderURL = renderURL;
    if (!block) return;
    block(runSandBoxURL);
}

- (JSValue *)runJsFunc:(NSString *)funcName arguments:(NSArray *)arguments{
    if (funcName.length == 0) {
        return nil;
    }
    /**objectForKeyedSubscript 只能获取js代码中的 function 与 var 变量  let 与 const 变量不能获取
     如：var test = {}  function test(params) {}
     */
    JSValue *func = [self objectForKeyedSubscript:funcName];
    if (!func.isObject) {
        return nil;
    }
    return [func callWithArguments:arguments];
}

#pragma mark - console

- (void)setConsole:(JSValue *)jsValue forKey:(NSString *)key{
    if (!key || ![key isKindOfClass:NSString.class] || key.length == 0 ||
        !jsValue || ![jsValue isKindOfClass:jsValue.class]) {
        return;
    }
    [self.lock lock];
    if (!self.consoleMap) {
        self.consoleMap = [NSMutableDictionary dictionary];
    }
    [self.consoleMap setObject:jsValue forKey:key];
    [self.lock unlock];
}
- (JSValue *)getConsoleForKey:(NSString *)key{
    JSValue *res = nil;
    [self.lock lock];
    res = [self.consoleMap objectForKey:key];
    [self.lock unlock];
    return res;
}
- (void)destroyContext{
    // 解除循环引用
    [self.lock lock];
    [self.consoleMap removeAllObjects];
    [self.lock unlock];
}

#pragma mark - ZHJSPageProtocol

// renderUrl
- (NSURL *)zh_renderURL{
    return self.renderURL;
}
- (NSURL *)zh_runSandBoxURL{
    return self.runSandBoxURL;
}
// pageitem
- (ZHJSPageItem *)zh_pageItem{
    return self.contextItem;
}
// pageId
- (NSString *)zh_pageApplicationId{
    NSString *appId = self.contextItem.appId;
    if (!appId || ![appId isKindOfClass:NSString.class] || appId.length == 0) {
        return [NSString stringWithFormat:@"%p", self];
    }
    return appId;
}
// api
- (id <ZHJSPageApiOpProtocol>)zh_apiOp{
    return self.globalConfig.apiOpConfig;
}

- (void)dealloc{
    NSLog(@"%s", __func__);
}

@end
