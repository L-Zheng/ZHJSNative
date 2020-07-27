//
//  ZHWebViewManager.m
//  ZHJSNative
//
//  Created by EM on 2020/4/10.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHWebViewManager.h"
#import "ZHWebView.h"

NSInteger const ZHWebViewPreLoadMaxCount = 3;
NSInteger const ZHWebViewPreLoadingMaxCount = 1;

@interface ZHWebViewManager ()
//初始化配置资源
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSArray <ZHWebView *> *> *websMap;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSArray <ZHWebView *> *> *loadingWebsMap;
@property (nonatomic,strong) NSLock *lock;
/** 打开的webview页面 */
@property (nonatomic, retain) NSMapTable *openedWebViewMapTable;
// 正在加载的webview
@property (nonatomic, retain) NSMapTable *loadingWebViewMapTable;
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
                 finish:(void (^) (BOOL success))finish{
    
    ZHWebViewAppletConfiguration *appletConfig = config.appletConfig;
    NSString *key = appletConfig.appId;
    
    if (![ZHWebView checkString:key]) {
        if (finish) finish(NO);
        return;
    }
    
    NSMutableArray *webs = [self fetchMap:self.websMap key:key];
    NSMutableArray *loadingWebs = [self fetchMap:self.loadingWebsMap key:key];
    
    if (webs.count >= ZHWebViewPreLoadMaxCount ||
        loadingWebs.count >= ZHWebViewPreLoadingMaxCount) {
        if (finish) finish(NO);
        return;
    }
    
    ZHWebView *newWebView = [[ZHWebView alloc] initWithGlobalConfig:config];
    
    [self opMap:self.loadingWebsMap key:key webView:newWebView add:YES];
    
    __weak __typeof__(self) weakSelf = self;
    [self loadWebView:newWebView config:config finish:^(BOOL success) {
        [weakSelf opMap:weakSelf.loadingWebsMap key:key webView:newWebView add:NO];
        if (success) {
            [weakSelf opMap:weakSelf.websMap key:key webView:newWebView add:YES];
        }
        if (finish) finish(success);
    }];
}

- (ZHWebView *)fetchWebView:(NSString *)key{
    NSMutableArray *webs = [self fetchMap:self.websMap key:key];
    if (webs.count) {
        ZHWebView *web = webs.firstObject;
        [self opMap:self.websMap key:key webView:web add:NO];
        return web;
    }
    return nil;
}

#pragma mark - load

- (void)loadOnlineDebugWebView:(ZHWebView *)webView
                           url:(NSURL *)url
                        config:(ZHWebViewConfiguration *)config
                        finish:(void (^) (BOOL success))finish{
    if (!webView || !url || url.isFileURL) {
        if (finish) finish(NO);return;
    }
    [webView loadWithUrl:url baseURL:nil loadConfig:config.loadConfig startLoadBlock:^(NSURL *runSandBoxURL) {
        
    } finish:finish];
}
- (void)loadLocalDebugWebView:(ZHWebView *)webView
                   templateFolder:(NSString *)templateFolder
                       config:(ZHWebViewConfiguration *)config
                       finish:(void (^) (BOOL success))finish{
    __weak __typeof__(self) __self = self;
    //加载模板 拷贝到沙盒
    [self copyTemplateFolderToSandBox:webView templateFolder:templateFolder error:nil callBack:^(NSString *loadFolder, NSError *error) {
        //检查
        if (error) {
            if (finish) finish(NO);
            return;
        }
        [__self realLoadWebView:webView loadFolder:loadFolder config:config finish:finish];
    }];
}

- (void)loadWebView:(ZHWebView *)webView
             config:(ZHWebViewConfiguration *)config
             finish:(void (^) (BOOL success))finish{
    if (!webView ||
        ![webView isKindOfClass:[ZHWebView class]]) {
        if (finish) finish(NO);
        return;
    }
        
    __weak __typeof__(self) __self = self;
    //加载模板 不存在会下载
    [self.class localReleaseTemplateFolder:config.appletConfig
                                   webView:webView
                                  callBack:^(NSString *templateFolder, NSError *error) {
        [__self copyTemplateFolderToSandBox:webView templateFolder:templateFolder error:error callBack:^(NSString *loadFolder, NSError *error) {
            //检查
            if (error) {
                if (finish) finish(NO);
                return;
            }
            [__self realLoadWebView:webView loadFolder:loadFolder config:config finish:finish];
        }];
    }];
}

- (void)realLoadWebView:(ZHWebView *)webView
             loadFolder:(NSString *)loadFolder
                 config:(ZHWebViewConfiguration *)config
                 finish:(void (^) (BOOL success))finish{
    ZHWebViewAppletConfiguration *appletConfig = config.appletConfig;
    ZHWebViewLoadConfiguration *loadConfig = config.loadConfig;
    NSString *loadFileName = appletConfig.loadFileName;
    
    //检查
    if (![ZHWebView checkString:loadFolder] ||
        ![ZHWebView checkString:loadFileName]) {
        if (finish) finish(NO);
        return;
    }
    NSString *htmlPath = [loadFolder stringByAppendingPathComponent:loadFileName];
    if (![self.fm fileExistsAtPath:htmlPath]) {
        if (finish) finish(NO);
        return;
    }
    //获取上级目录
    NSString *superFolder = [ZHWebView fetchSuperiorFolder:htmlPath];
    if (!superFolder) {
        if (finish) finish(NO);
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
                  finish:^(BOOL success) {
        // 移除loading表
        [__self opLoadingWebView:webView isAdd:NO];
        // 加入finish表
        [__self opLoadFinishWebView:webView isAdd:YES];
        if (finish) finish(success);
    }];
}

#pragma mark - file

- (NSFileManager *)fm{
    return [NSFileManager defaultManager];
}

#pragma mark - path

//拷贝模板资源到沙盒
- (void)copyTemplateFolderToSandBox:(ZHWebView *)webView templateFolder:(NSString *)templateFolder error:(NSError *)error callBack:(void (^) (NSString *loadFolder, NSError *error))callBack{
    if (!templateFolder || error) {
        if (callBack) callBack(nil, error?:[NSError new]);
        return;
    }
    
    //目标路径
    NSString *resFolder = [webView fetchReadyRunSandBox];
    if (!resFolder) {
        if (callBack) callBack(nil, [NSError new]);
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
            if (callBack) callBack(nil, fileError?:[NSError new]);
            return;
        }
    }else{
        //创建上级目录 否则拷贝失败
        NSString *superFolder = [ZHWebView fetchSuperiorFolder:resFolder];
        if (!superFolder) {
            [self.lock unlock];
            if (callBack) callBack(nil, [NSError new]);
            return;
        }
        if (![self.fm fileExistsAtPath:superFolder]) {
            result = [self.fm createDirectoryAtPath:superFolder withIntermediateDirectories:YES attributes:nil error:&fileError];
            if (!result || fileError) {
                [self.lock unlock];
                if (callBack) callBack(nil, fileError?:[NSError new]);
                return;
            }
        }
    }
    
    //拷贝模板文件
    result = [self.fm copyItemAtPath:templateFolder toPath:resFolder error:&fileError];
    if (!result || fileError) {
        [self.lock unlock];
        if (callBack) callBack(nil, fileError?:[NSError new]);
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
                          callBack:(void (^) (NSString *templateFolder, NSError *error))callBack{
    NSString *key = appletConfig.appId;
    NSString *presetFolder = appletConfig.presetFolderPath;
    
    //检查本地缓存
    NSString *latestFolder = nil;
    if ([ZHWebView checkString:latestFolder] &&
        [[NSFileManager defaultManager] fileExistsAtPath:latestFolder]) {
        if (callBack) callBack(latestFolder, nil);
        [[self shareManager] updateTemplate:key];
        return;
    }
    
    //存在预置资源
    if ([ZHWebView checkString:presetFolder] && [[NSFileManager defaultManager] fileExistsAtPath:presetFolder]) {
        if (callBack) callBack(presetFolder, nil);
        [[self shareManager] updateTemplate:key];
        return;
    }
    
    //等待下载
    [[self shareManager] downLoadTemplate:key callback:^(NSDictionary *resultInfo, NSError *error) {
        NSString *downFolder = nil;
        if (downFolder && !error) {
            if (callBack) callBack(downFolder, nil);
        }else{
            if (callBack) callBack(nil, error ? error : [NSError new]);
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

- (void)opLoadingWebView:(ZHWebView *)webView isAdd:(BOOL)isAdd{
    self.loadingWebViewMapTable = [self opWebViewMapTable:self.loadingWebViewMapTable webView:webView isAdd:isAdd];
}
- (void)opLoadFinishWebView:(ZHWebView *)webView isAdd:(BOOL)isAdd{
    self.openedWebViewMapTable = [self opWebViewMapTable:self.openedWebViewMapTable webView:webView isAdd:isAdd];
}
- (NSMapTable *)opWebViewMapTable:(NSMapTable *)mapTable webView:(ZHWebView *)webView isAdd:(BOOL)isAdd{
    if (!webView || ![webView isKindOfClass:[ZHWebView class]]) {
        return mapTable;
    }
        
    [self.lock lock];
    //创建表
    if (!mapTable) {
        mapTable = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsCopyIn valueOptions:NSPointerFunctionsStrongMemory];
    }
    //生成key
    NSString *key = webView.runSandBoxURL.path;
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
