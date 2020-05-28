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

- (ZHWebView *)createWebView:(CGRect)frame apiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers{
    return [[ZHWebView alloc] initWithFrame:frame apiHandlers:apiHandlers];
}

- (void)preReadyWebView:(NSString *)key frame:(CGRect)frame loadFileName:(NSString *)loadFileName presetFolder:(NSString *)presetFolder allowingReadAccessToURL:(NSURL *)readAccessURL apiHandlers:(NSArray <id <ZHJSApiProtocol>> *)apiHandlers finish:(void (^) (BOOL success))finish{
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
    
    ZHWebView *newWebView = [self createWebView:frame apiHandlers:apiHandlers];
    
    [self opMap:self.loadingWebsMap key:key webView:newWebView add:YES];
    
    __weak __typeof__(self) weakSelf = self;
    [self loadWebView:newWebView key:key loadFileName:loadFileName presetFolder:presetFolder allowingReadAccessToURL:readAccessURL finish:^(BOOL success) {
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

#ifdef DEBUG
- (void)loadOnlineDebugWebView:(ZHWebView *)webView key:(NSString *)key url:(NSURL *)url finish:(void (^) (BOOL success))finish{
    if (!webView || !url) {
        if (finish) finish(NO);return;
    }
    [webView loadUrl:url baseURL:nil allowingReadAccessToURL:[NSURL fileURLWithPath:[ZHWebView getDocumentFolder]] finish:finish];
}

- (void)loadLocalDebugWebView:(ZHWebView *)webView key:(NSString *)key loadFolder:(NSString *)loadFolder loadFileName:(NSString *)loadFileName allowingReadAccessToURL:(NSURL *)readAccessURL finish:(void (^) (BOOL success))finish{
    
    __weak __typeof__(self) __self = self;
    //加载模板 拷贝到沙盒
    [self copyTemplateFolderToSandBox:webView templateFolder:loadFolder error:nil callBack:^(NSString *newLoadFolder, NSError *error) {
        //检查
        if (![ZHWebView checkString:newLoadFolder] || error) {
            if (finish) finish(NO);
            return;
        }
        [__self loadWebView:webView key:key loadFolder:newLoadFolder loadFileName:loadFileName allowingReadAccessToURL:readAccessURL finish:finish];
    }];
}
#endif

- (void)loadWebView:(ZHWebView *)webView key:(NSString *)key loadFileName:(NSString *)loadFileName presetFolder:(NSString *)presetFolder allowingReadAccessToURL:(NSURL *)readAccessURL finish:(void (^) (BOOL success))finish{
    
    if (!webView || ![webView isKindOfClass:[ZHWebView class]] ||
        ![ZHWebView checkString:loadFileName]) {
        if (finish) finish(NO);
        return;
    }
    
    __weak __typeof__(self) __self = self;
    //加载模板 不存在会下载
    [self.class localReleaseTemplateFolder:key presetFolder:presetFolder callBack:^(NSString *templateFolder, NSError *error) {
        [__self copyTemplateFolderToSandBox:webView templateFolder:templateFolder error:error callBack:^(NSString *loadFolder, NSError *error) {
            //检查
            if (![ZHWebView checkString:loadFolder] || error) {
                if (finish) finish(NO);
                return;
            }
            [__self loadWebView:webView key:key loadFolder:loadFolder loadFileName:loadFileName allowingReadAccessToURL:readAccessURL finish:finish];
        }];
    }];
}

- (void)loadWebView:(ZHWebView *)webView key:(NSString *)key loadFolder:(NSString *)loadFolder loadFileName:(NSString *)loadFileName allowingReadAccessToURL:(NSURL *)readAccessURL finish:(void (^) (BOOL success))finish{
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
    NSURL *accessURL = readAccessURL?:[NSURL fileURLWithPath:loadFolder];
    NSURL *url = [NSURL fileURLWithPath:htmlPath];
    
    [webView loadUrl:url baseURL:[NSURL fileURLWithPath:superFolder isDirectory:YES] allowingReadAccessToURL:accessURL finish:finish];
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
+ (void)localReleaseTemplateFolder:(NSString *)key presetFolder:(NSString *)presetFolder callBack:(void (^) (NSString *templateFolder, NSError *error))callBack{

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

#pragma mark - cache

//清理WebView加载缓存
- (void)cleanWebViewLoadCache{
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

#pragma mark - share

- (instancetype)init{
    if (self = [super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
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
