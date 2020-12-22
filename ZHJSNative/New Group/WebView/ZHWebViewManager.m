//
//  ZHWebViewManager.m
//  ZHJSNative
//
//  Created by EM on 2020/4/10.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHWebViewManager.h"
#import "ZHWebView.h"
#import "NSError+ZH.h"
#import "ZHUtil.h"
#import "ZHJSNativeItem.h" // WebView/JSContext页面信息数据

NSInteger const ZHWebViewPreLoadMaxCount = 3;
NSInteger const ZHWebViewPreLoadingMaxCount = 1;

@interface ZHWebViewManager ()
//初始化配置资源：用于预加载
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSArray <ZHWebView *> *> *websMap;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSArray <ZHWebView *> *> *loadingWebsMap;
@property (nonatomic,strong) NSLock *lock;
/** 打开的webview页面 、 正在加载的webview：用于清理沙盒 */
@property (nonatomic, retain) NSMapTable *openedWebViewMapTable;
@property (nonatomic, retain) NSMapTable *loadingWebViewMapTable;

// 外部正在使用的webview：用于外部获取
@property (nonatomic, retain) NSMapTable *outsideUsedWebViewMapTable;
@end

@implementation ZHWebViewManager

#pragma mark - config

#pragma mark - map

- (NSMutableArray *)fetchMap:(NSMutableDictionary *)map key:(NSString *)key{
    [self.lock lock];
    
    if (![ZHWebView checkString:key]) return 0;
    NSMutableArray *arr = [map objectForKey:key];
    
    [self.lock unlock];
    
    return arr ?: [@[] mutableCopy];
}

- (void)opMap:(NSMutableDictionary *)map key:(NSString *)key webView:(ZHWebView *)webView add:(BOOL)add{
    if (![ZHWebView checkString:key]) return;
    
    [self.lock lock];
    
    NSMutableArray *arr = [map objectForKey:key]?:[@[] mutableCopy];
    if (add) {
        if (![arr containsObject:webView]) {
            [arr addObject:webView];
        }
    }else{
        if ([arr containsObject:webView]) {
            [arr removeObject:webView];
        }
    }
    [map setObject:arr forKey:key];
    
    [self.lock unlock];
}

#pragma mark - webview

- (void)preReadyWebView:(ZHWebViewConfiguration *)config
                 finish:(void (^) (NSDictionary *info, NSError *error))finish{
    
    ZHWebViewAppletConfiguration *appletConfig = config.appletConfig;
    NSString *key = appletConfig.appId;
    
    if (![ZHWebView checkString:key]) {
        if (finish) finish(nil, ZHInlineError(404, ZHLCInlineString(@"key(%@) is invalid", key)));
        return;
    }
    
    NSMutableArray *webs = [self fetchMap:self.websMap key:key];
    NSMutableArray *loadingWebs = [self fetchMap:self.loadingWebsMap key:key];
    
    if (webs.count >= ZHWebViewPreLoadMaxCount) {
        if (finish) finish(nil, ZHInlineError(-999, ZHLCInlineString(@"load finish webview count is beyond max(%ld)", ZHWebViewPreLoadMaxCount)));
        return;
    }
    if (loadingWebs.count >= ZHWebViewPreLoadingMaxCount) {
        if (finish) finish(nil, ZHInlineError(-999, ZHLCInlineString(@"loading webview count is beyond max(%ld)", ZHWebViewPreLoadingMaxCount)));
        return;
    }
    
    ZHWebView *newWebView = [[ZHWebView alloc] initWithGlobalConfig:config];
    
    [self opMap:self.loadingWebsMap key:key webView:newWebView add:YES];
    
    __weak __typeof__(self) weakSelf = self;
    [self loadWebView:newWebView config:config finish:^(NSDictionary *info, NSError *error) {
        [weakSelf opMap:weakSelf.loadingWebsMap key:key webView:newWebView add:NO];
        if (!error) {
            [weakSelf opMap:weakSelf.websMap key:key webView:newWebView add:YES];
        }
        if (finish) finish(error ? nil : info, error ? ZHInlineError(error.code, ZHLCInlineString(@"%@", ZHErrorDesc(error))) : nil);
    }];
}

- (ZHWebView *)fetchWebView:(NSString *)key{
    NSMutableArray *webs = [self fetchMap:self.websMap key:key];
    if (webs.count) {
        ZHWebView *web = webs.firstObject;
        [self opMap:self.websMap key:key webView:web add:NO];

        ZHWebViewDebugModel cMode = web.debugConfig.debugModel;
        ZHWebViewDebugModel gMode = [[ZHWebViewDebugGlobalConfiguration shareConfiguration] fetchConfigurationItem:web.globalConfig.appletConfig.appId].debugModel;
        return (cMode == gMode ? web : nil);
    }
    return nil;
}
// 操作所有加载的webview
- (void)opAllWebViewUsingBlock:(void (^) (ZHWebView *webView))block{
    if (!block) return;
    NSArray <ZHWebView *> *webs = [self fetchAllWebViews];
    if (!webs || webs.count == 0) return;
    for (ZHWebView *webView in webs) {
        block(webView);
    }
}
// 获取所有加载的webview
- (NSArray <ZHWebView *> *)fetchAllWebViews{
    [self.lock lock];
    NSMutableArray <ZHWebView *> *allWebViews = [@[] mutableCopy];
    //遍历key
    NSEnumerator *enumerator = self.outsideUsedWebViewMapTable ? [self.outsideUsedWebViewMapTable keyEnumerator] : nil;
    if (enumerator) {
        id key;
        while (key = [enumerator nextObject]) {
            NSPointerArray *arr = [self.outsideUsedWebViewMapTable objectForKey:key];
            if (!arr) {
                continue;
            }
            //清除空对象
            [arr addPointer:NULL];
            [arr compact];
            if (arr.count == 0 || arr.allObjects.count == 0) {
                continue;
            }
            [allWebViews addObjectsFromArray:arr.allObjects];
        }
    }
    [self.lock unlock];
    
    return allWebViews.copy;
}

#pragma mark - load

- (void)loadOnlineDebugWebView:(ZHWebView *)webView
                           url:(NSURL *)url
                        config:(ZHWebViewConfiguration *)config
                        finish:(void (^) (NSDictionary *info, NSError *error))finish{
    if (!webView || !url || url.isFileURL) {
        NSError *error = ZHInlineError(404, ZHLCInlineString(@"webView is null / url is null / url is not filr URL.  URL is %@.", url));
        if (finish) finish(nil, error);
        return;
    }
    __weak __typeof__(self) __self = self;
    [webView loadWithUrl:url baseURL:nil loadConfig:config.loadConfig startLoadBlock:^(NSURL *runSandBoxURL) {
        
    } finish:^(NSDictionary *info, NSError *error) {
        if (!error) {
            [__self opOutsideUsedWebView:webView isAdd:YES];
        }
        if (finish) finish(info, error);
    }];
}
- (void)loadLocalDebugWebView:(ZHWebView *)webView
                   templateFolder:(NSString *)templateFolder
                       config:(ZHWebViewConfiguration *)config
                       finish:(void (^) (NSDictionary *info, NSError *error))finish{
    __weak __typeof__(self) __self = self;
    //加载模板 拷贝到沙盒
    [self copyTemplateFolderToSandBox:webView templateFolder:templateFolder callBack:^(NSString *loadFolder, NSError *error) {
        //检查
        if (error) {
            if (finish) finish(nil, ZHInlineError(error.code, ZHLCInlineString(@"%@", ZHErrorDesc(error))));
            return;
        }
        [__self realLoadWebView:webView loadFolder:loadFolder config:config finish:^(NSDictionary *info, NSError *error) {
            if (finish) finish(error ? nil : info, error ? ZHInlineError(error.code, ZHLCInlineString(@"%@", ZHErrorDesc(error))) : nil);
        }];
    }];
}

- (void)loadWebView:(ZHWebView *)webView
             config:(ZHWebViewConfiguration *)config
             finish:(void (^) (NSDictionary *info, NSError *error))finish{
    if (!webView ||
        ![webView isKindOfClass:[ZHWebView class]]) {
        if (finish) finish(nil, ZHInlineError(404, ZHLCInlineString(@"webview is invalid")));
        return;
    }
    
    ZHWebViewDebugModel debugModel = webView.debugConfig.debugModel;
    if (debugModel == ZHWebViewDebugModelLocal) {
        NSString *templateFolder = [webView.debugConfig.localDebugUrlStr stringByAppendingPathComponent:@"release"];
        [self loadLocalDebugWebView:webView
                     templateFolder:templateFolder
                             config:webView.globalConfig
                             finish:finish];
        return;
    }
    if (debugModel == ZHWebViewDebugModelOnline) {
        [self loadOnlineDebugWebView:webView
                                 url:[NSURL URLWithString:webView.debugConfig.socketDebugUrlStr]
                              config:webView.globalConfig
                              finish:finish];
        return;
    }
        
    __weak __typeof__(self) __self = self;
    //加载模板 不存在会下载
    [self.class localReleaseTemplateFolder:config.appletConfig
                                   webView:webView
                                  callBack:^(NSString *templateFolder, NSDictionary *resultInfo, NSError *error) {
        if (error) {
            if (finish) finish(nil, ZHInlineError(error.code, ZHLCInlineString(@"%@", ZHErrorDesc(error))));
            return;
        }
        [__self copyTemplateFolderToSandBox:webView templateFolder:templateFolder callBack:^(NSString *loadFolder, NSError *error) {
            //检查
            if (error) {
                if (finish) finish(nil, ZHInlineError(error.code, ZHLCInlineString(@"%@", ZHErrorDesc(error))));
                return;
            }
            webView.webItem.downLoadInfo = [resultInfo copy];
            [__self realLoadWebView:webView loadFolder:loadFolder config:config finish:^(NSDictionary *info, NSError *error) {
                if (finish) finish(error ? nil : info, error ? ZHInlineError(error.code, ZHLCInlineString(@"%@", ZHErrorDesc(error))) : nil);
            }];
        }];
    }];
}

/// 重新下载模板文件加载webView
- (void)retryLoadWebView:(ZHWebView *)webView
                  config:(ZHWebViewConfiguration *)config
           downLoadStart:(void (^) (void))downLoadStart
          downLoadFinish:(void (^) (NSDictionary *info ,NSError *error))downLoadFinish
                  finish:(void (^) (NSDictionary *info ,NSError *error))finish{
    if (!webView ||
        ![webView isKindOfClass:[ZHWebView class]]) {
        if (finish) finish(nil, ZHInlineError(404, ZHLCInlineString(@"webview is invalid")));
        return;
    }
    
    NSString *key = config.appletConfig.appId;
    if (![ZHWebView checkString:key]) {
        if (finish) finish(nil, ZHInlineError(404, ZHLCInlineString(@"key(%@) is invalid", key)));
        return;
    }
    
    __weak __typeof__(self) __self = self;
    //下载
    if (downLoadStart) downLoadStart();
    [self.class waitDownLoadTemplate:key callBack:^(NSString *templateFolder, NSDictionary *resultInfo, NSError *error) {
        if (downLoadFinish) downLoadFinish(error ? nil : resultInfo, error);
        if (error) {
            if (finish) finish(nil, ZHInlineError(error.code, ZHLCInlineString(@"%@", ZHErrorDesc(error))));
            return;
        }
        
        // 拷贝到沙盒
        [__self copyTemplateFolderToSandBox:webView templateFolder:templateFolder callBack:^(NSString *loadFolder, NSError *error) {
            //检查
            if (error) {
                if (finish) finish(nil, ZHInlineError(error.code, ZHLCInlineString(@"%@", ZHErrorDesc(error))));
                return;
            }
            webView.webItem.downLoadInfo = [resultInfo copy];
            [__self realLoadWebView:webView loadFolder:loadFolder config:config finish:finish];
        }];
    }];
}

- (void)realLoadWebView:(ZHWebView *)webView
             loadFolder:(NSString *)loadFolder
                 config:(ZHWebViewConfiguration *)config
                 finish:(void (^) (NSDictionary *info, NSError *error))finish{
    ZHWebViewAppletConfiguration *appletConfig = config.appletConfig;
    ZHWebViewLoadConfiguration *loadConfig = config.loadConfig;
    NSString *loadFileName = appletConfig.loadFileName;
    
    NSString *extraErrorDesc = [NSString stringWithFormat:@"config is %@.", [config formatInfo]];
    
    //检查
    if (![ZHWebView checkString:loadFolder]) {
        if (finish) finish(nil, ZHInlineError(404, ZHLCInlineString(@"loadFolder is null. %@", extraErrorDesc)));
        return;
    }
    if (![ZHWebView checkString:loadFileName]) {
        if (finish) finish(nil, ZHInlineError(404, ZHLCInlineString(@"loadFileName is invaild: %@. %@", loadFileName, extraErrorDesc)));
        return;
    }
    NSString *htmlPath = [loadFolder stringByAppendingPathComponent:loadFileName];
    if (![self.fm fileExistsAtPath:htmlPath]) {
        if (finish) finish(nil, ZHInlineError(404, ZHLCInlineString(@"htmlPath(%@) is not exists. %@", htmlPath, extraErrorDesc)));
        return;
    }
    //获取上级目录
    NSString *superFolder = [ZHUtil fetchSuperiorFolder:htmlPath];
    if (!superFolder) {
        if (finish) finish(nil, ZHInlineError(404, ZHLCInlineString(@"fetch superFolder is failed. htmlPath is (%@). %@", htmlPath, extraErrorDesc)));
        return;
    }
    
    //加载
    loadConfig.readAccessURL = loadConfig.readAccessURL?:[NSURL fileURLWithPath:loadFolder];
    NSURL *url = [NSURL fileURLWithPath:htmlPath];
    NSURL *baseURL = [NSURL fileURLWithPath:superFolder isDirectory:YES];
    
    __weak __typeof__(self) __self = self;
    [webView loadWithUrl:url
                 baseURL:baseURL
              loadConfig:loadConfig
          startLoadBlock:^(NSURL *runSandBoxURL) {
        // 加入loading表
        [__self opLoadingWebView:webView isAdd:YES];
    }
                  finish:^(NSDictionary *info, NSError *error) {
        // 移除loading表
        [__self opLoadingWebView:webView isAdd:NO];
        // 加入finish表
        [__self opLoadFinishWebView:webView isAdd:YES];
        // 加入外部使用表
        if (!error) {
            [__self opOutsideUsedWebView:webView isAdd:YES];
        }
        if (finish) finish(error ? nil : info, error ? ZHInlineError(error.code, ZHLCInlineString(@"%@", ZHErrorDesc(error))) : nil);
    }];
}

#pragma mark - file

- (NSFileManager *)fm{
    return [NSFileManager defaultManager];
}

#pragma mark - path

//拷贝模板资源到沙盒
- (void)copyTemplateFolderToSandBox:(ZHWebView *)webView templateFolder:(NSString *)templateFolder callBack:(void (^) (NSString *loadFolder, NSError *error))callBack{
    if (!templateFolder) {
        if (callBack) callBack(nil, ZHInlineError(404, ZHLCInlineString(@"templateFolder is null")));
        return;
    }
    
    //目标路径
    NSString *resFolder = [webView fetchReadyRunSandBox];
    if (!resFolder) {
        if (callBack) callBack(nil, ZHInlineError(404, ZHLCInlineString(@"fetch Ready Run SandBox is failed")));
        return;
    }
    
    BOOL result = NO;
    NSError *fileError = nil;
    
    [self.lock lock];
    
    //删除目录
    if ([self.fm fileExistsAtPath:resFolder]) {
        result = [self.fm removeItemAtPath:resFolder error:&fileError];
        
        if (!result || fileError) {
            [self.lock unlock];
            if (callBack) callBack(nil, ZHInlineError(-999, ZHLCInlineString(@"remove file(%@) failed. fileError :%@ .", resFolder, ZHErrorDesc(fileError))));
            return;
        }
    }else{
        //创建上级目录 否则拷贝失败
        NSString *superFolder = [ZHUtil fetchSuperiorFolder:resFolder];
        if (!superFolder) {
            [self.lock unlock];
            if (callBack) callBack(nil, ZHInlineError(404, ZHLCInlineString(@"fetch superFolder is failed by folder(%@).", resFolder)));
            return;
        }
        if (![self.fm fileExistsAtPath:superFolder]) {
            result = [self.fm createDirectoryAtPath:superFolder withIntermediateDirectories:YES attributes:nil error:&fileError];
            if (!result || fileError) {
                [self.lock unlock];
                if (callBack) callBack(nil, ZHInlineError(-999, ZHLCInlineString(@"create folder(%@) failed. fileError :%@ .", superFolder, ZHErrorDesc(fileError))));
                return;
            }
        }
    }
    
    //拷贝模板文件
    result = [self.fm copyItemAtPath:templateFolder toPath:resFolder error:&fileError];
    if (!result || fileError) {
        [self.lock unlock];
        if (callBack) callBack(nil, ZHInlineError(-999, ZHLCInlineString(@"copy sourceFolder(%@) targetFolder(%@) failed. fileError :%@ .", templateFolder, resFolder, ZHErrorDesc(fileError))));
        return;
    }
    
    [self.lock unlock];
    if (callBack) callBack(resFolder, nil);
}

#pragma mark - template

- (void)downLoadTemplate:(NSString *)key callback:(void(^)(NSDictionary *resultInfo, NSError *error))callback progressBlock:(void (^)(NSProgress *progress))progressBlock{
}
- (void)updateTemplate:(NSString *)key{
//    if (callBack) callBack(@"", nil);
}

#pragma mark - debug

//加载线上资源
+ (void)localReleaseTemplateFolder:(ZHWebViewAppletConfiguration *)appletConfig
                           webView:(ZHWebView *)webView
                          callBack:(void (^) (NSString *templateFolder, NSDictionary *resultInfo, NSError *error))callBack{
    NSString *key = appletConfig.appId;
    NSString *presetFolder = appletConfig.presetFilePath;
    NSDictionary *presetFileInfo = appletConfig.presetFileInfo;
    NSString *loadFileName = appletConfig.loadFileName;
    
    //检查本地缓存
    NSString *latestFolder = nil;
    if ([ZHWebView checkString:latestFolder] &&
        [[NSFileManager defaultManager] fileExistsAtPath:latestFolder]) {
        NSString *htmlPath = [latestFolder stringByAppendingPathComponent:loadFileName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:htmlPath]) {
            if (callBack) callBack(latestFolder, @{@"description": @"此模板为本地缓存资源"}, nil);
            [[self shareManager] updateTemplate:key];
        }else{
            //文件有缺失：等待下载
            [self waitDownLoadTemplate:key callBack:callBack];
        }
        return;
    }
    
    //存在预置资源
    if ([ZHWebView checkString:presetFolder] && [[NSFileManager defaultManager] fileExistsAtPath:presetFolder]) {
        if (callBack) callBack(presetFolder, presetFileInfo, nil);
        [[self shareManager] updateTemplate:key];
        return;
    }
    
    //等待下载
    [self waitDownLoadTemplate:key callBack:callBack];
}

+ (void)waitDownLoadTemplate:(NSString *)key callBack:(void (^) (NSString *templateFolder, NSDictionary *resultInfo, NSError *error))callBack{
    [[self shareManager] downLoadTemplate:key callback:^(NSDictionary *resultInfo, NSError *error) {
        NSString *downFolder = nil;
        if (downFolder && !error) {
            if (callBack) callBack(downFolder, resultInfo, nil);
        }else{
            if (callBack) callBack(nil, nil, error ? error : [NSError new]);
        }
    } progressBlock:^(NSProgress *progress) {
        
    }];
}

#pragma mark - getter

- (NSLock *)lock{
    if (!_lock) {
        _lock = [[NSLock alloc] init];
    }
    return _lock;
}

- (NSMutableDictionary<NSString *,NSArray<ZHWebView *> *> *)websMap{
    if (!_websMap) {
        _websMap = [@{} mutableCopy];
    }
    return _websMap;
}

- (NSMutableDictionary<NSString *,NSArray<ZHWebView *> *> *)loadingWebsMap{
    if (!_loadingWebsMap) {
        _loadingWebsMap = [@{} mutableCopy];
    }
    return _loadingWebsMap;
}

#pragma mark - notification

- (void)addNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)applicationDidEnterBackground:(NSNotification *)note{
    [self cleanWebViewLoadCache];
}

#pragma mark - cache

//清理WebView加载缓存
- (void)cleanWebViewLoadCache{
    if ([ZHWebViewDebugConfiguration availableIOS9]) {
        [self cleanWebViewLoadCache:ZHWebViewFolder()];
        return;
    }
    [self cleanWebViewLoadCache:ZHWebViewTmpFolder()];
}
- (void)cleanWebViewLoadCache:(NSString *)webviewFolder{
    [self.lock lock];

    NSMutableArray *usedKeys = [@[] mutableCopy];
    NSMutableArray *cleanKeys = [@[] mutableCopy];
    //遍历key
    NSEnumerator *enumerator = self.openedWebViewMapTable ? [self.openedWebViewMapTable keyEnumerator] : nil;
    if (enumerator) {
        id key;
        while (key = [enumerator nextObject]) {
            NSPointerArray *arr = [self.openedWebViewMapTable objectForKey:key];
            if (!arr) {
                [cleanKeys addObject:key];
                continue;
            }
            //清除空对象
            [arr addPointer:NULL];
            [arr compact];
            if (arr.count == 0 || arr.allObjects.count == 0) {
                [cleanKeys addObject:key];
                continue;
            }
            [usedKeys addObject:key];
        }
    }
    enumerator = self.loadingWebViewMapTable ? [self.loadingWebViewMapTable keyEnumerator] : nil;
    if (enumerator) {
        id key;
        while (key = [enumerator nextObject]) {
            [usedKeys addObject:key];
        }
    }
    
    //遍历子目录
    NSArray *subFolders = [self.fm subpathsAtPath:webviewFolder];
    NSEnumerator *childFile = [subFolders objectEnumerator];
    NSString *subPath;
    while ((subPath = [childFile nextObject]) != nil) {
        if (subPath.length == 0) continue;
        NSArray *pathComs = subPath.pathComponents;
        //只获取一级目录
        if (pathComs.count != 1) continue;
        NSString *firstCom = pathComs.firstObject;
        
        NSURL *newSubURLPath = [NSURL fileURLWithPath:[webviewFolder stringByAppendingPathComponent:firstCom]];
        if ([self.fm fileExistsAtPath:newSubURLPath.path] &&
            ![usedKeys containsObject:newSubURLPath.path]) {
            [cleanKeys addObject:newSubURLPath.path];
        }
    }
    //清理
    for (NSString *cleanKey in cleanKeys) {
        [self.openedWebViewMapTable removeObjectForKey:cleanKey];
        
        if (![self.fm fileExistsAtPath:cleanKey]) continue;
        [self.fm removeItemAtPath:cleanKey error:nil];
    }
    
    [self.lock unlock];
}
- (void)cleanWebViewAllLoadCache{
    __weak __typeof__(self) __self = self;
    void (^block) (NSString *) = ^(NSString *folder){
        if (![__self.fm fileExistsAtPath:folder]) {
            return;
        }
        [__self.lock lock];
        [__self.fm removeItemAtPath:folder error:nil];
        [__self.lock unlock];
    };
    
    block(ZHWebViewFolder());
    block(ZHWebViewTmpFolder());
}

- (void)opOutsideUsedWebView:(ZHWebView *)webView isAdd:(BOOL)isAdd{
    self.outsideUsedWebViewMapTable = [self opWebViewMapTable:self.outsideUsedWebViewMapTable webView:webView isAdd:isAdd keyBlock:^NSString *(ZHWebView *web) {
        return [NSString stringWithFormat:@"%p", web];
    }];
}
- (void)opLoadingWebView:(ZHWebView *)webView isAdd:(BOOL)isAdd{
    self.loadingWebViewMapTable = [self opWebViewMapTable:self.loadingWebViewMapTable webView:webView isAdd:isAdd keyBlock:^NSString *(ZHWebView *web) {
        return web.runSandBoxURL.path;
    }];
}
- (void)opLoadFinishWebView:(ZHWebView *)webView isAdd:(BOOL)isAdd{
    self.openedWebViewMapTable = [self opWebViewMapTable:self.openedWebViewMapTable webView:webView isAdd:isAdd keyBlock:^NSString *(ZHWebView *web) {
        return web.runSandBoxURL.path;
    }];
}
- (NSMapTable *)opWebViewMapTable:(NSMapTable *)mapTable webView:(ZHWebView *)webView isAdd:(BOOL)isAdd keyBlock:(NSString * (^) (ZHWebView *web))keyBlock{
    if (!webView || ![webView isKindOfClass:[ZHWebView class]]) {
        return mapTable;
    }
        
    [self.lock lock];
    //创建表
    if (!mapTable) {
        mapTable = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsCopyIn valueOptions:NSPointerFunctionsStrongMemory];
    }
    //生成key
    NSString *key = keyBlock ? keyBlock(webView) : nil;
    if (![ZHWebView checkString:key]) {
        [self.lock unlock];
        return mapTable;
    }
    //创建PointerArray
    NSPointerArray *arr = [mapTable objectForKey:key];
    if (!arr) {
        arr = [NSPointerArray weakObjectsPointerArray];
    }
    
    // 清除空对象
    [arr addPointer:NULL];
    [arr compact];
    
    if (isAdd) {
        //添加
        if (![arr.allObjects containsObject:webView]) {
            [arr addPointer:(__bridge void * _Nullable)(webView)];
            [mapTable setObject:arr forKey:key];
        }
        [self.lock unlock];
        return mapTable;
    }
    if ([arr.allObjects containsObject:webView]) {
        __block NSUInteger removeIndex = NSNotFound;
        NSArray *allObjects = arr.allObjects;
        [allObjects enumerateObjectsUsingBlock:^(ZHWebView *obj, NSUInteger idx, BOOL *stop) {
            if ([webView isEqual:obj]) {
                removeIndex = idx;
                *stop = YES;
            }
        }];
        //移除
        if (removeIndex != NSNotFound) {
            [arr removePointerAtIndex:removeIndex];
        }
        if (arr.count == 0) {
            [mapTable removeObjectForKey:key];
        }else{
            [mapTable setObject:arr forKey:key];
        }
    }
    
    [self.lock unlock];
    return mapTable;
}

#pragma mark - dealloc

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"%s", __func__);
}

#pragma mark - share

- (instancetype)init{
    if (self = [super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self addNotification];
            // 初始化 清理缓存 仅执行一次
            [self cleanWebViewAllLoadCache];
        });
    }
    return self;
}

static id _instance;

+ (instancetype)shareManager{
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
