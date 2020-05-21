//
//  ZHWebViewManager.m
//  ZHJSNative
//
//  Created by EM on 2020/4/10.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHWebViewManager.h"
#import "ZHWebView.h"
#import "ZHCustomApiHandler.h"
#import "ZHCustom1ApiHandler.h"
#import "ZHCustom2ApiHandler.h"
#import "ZhengFile.h"

NSInteger const ZHWebViewPreLoadMaxCount = 1;

@interface ZHWebViewManager ()
//初始化配置资源
@property (nonatomic, strong) NSMutableArray <ZHWebView *> *webs;
@property (nonatomic, strong) NSMutableArray <ZHWebView *> *loadingWebs;
@property (nonatomic,strong) NSLock *lock;
@end

@implementation ZHWebViewManager

- (NSArray *)apiHandlers{
    return @[[[ZHCustomApiHandler alloc] init], [[ZHCustom1ApiHandler alloc] init], [[ZHCustom2ApiHandler alloc] init]];
}

#pragma mark - config

+ (void)install{
//    [ZhengFile deleteFileOrFolder:[[self getDocumentPath] stringByAppendingPathComponent:@"ZHHtml"]];
    
    if ([self isUsePreLoadWebView]) {
        [[ZHWebViewManager shareManager] install];
    }
}

- (void)install{
    [self.lock lock];
    
    if (self.webs.count >= 1) return;
    if (self.loadingWebs.count >= 1) return;
    
    [self.lock unlock];
    [self preReadyWebView];
}

#pragma mark - webview

- (ZHWebView *)fetchWebView{
    [self.lock lock];
    
    NSMutableArray *arr = [self.webs mutableCopy];
    if (arr.count == 0) {
        [self.lock unlock];
        [self preReadyWebView];
        return nil;
    }
    
    ZHWebView *webView = arr.firstObject;
    [arr removeObjectAtIndex:0];
    
    self.webs = [arr mutableCopy];
    
    [self.lock unlock];
    
    [self preReadyWebView];
    return webView;
}

- (void)preReadyWebView{
    if (self.webs.count >= 3) return;
    if (self.loadingWebs.count >= 3) return;
    
    __weak __typeof__(self) weakSelf = self;
    ZHWebView *newWebView = [self createWebView];
    
    [self.lock lock];
    [self.loadingWebs addObject:newWebView];
    [self.lock unlock];
    
    [self loadWebView:newWebView finish:^(BOOL success) {
        [weakSelf.lock lock];
        [weakSelf.loadingWebs removeObject:newWebView];
        if (success) [weakSelf.webs addObject:newWebView];
        [weakSelf.lock unlock];
    }];
}

- (ZHWebView *)createWebView{
    return [[ZHWebView alloc] initWithFrame:[UIScreen mainScreen].bounds apiHandlers:[self apiHandlers]];
}
- (void)loadWebView:(ZHWebView *)webView finish:(void (^) (BOOL success))finish{
    if ([self.class isDebug] && [self.class isDebugSocket] && ![self.class isUseReleaseWhenSimulator]) {
        NSURL *socketUrl = [self.class socketDebugUrl];
        [webView loadUrl:socketUrl baseURL:nil allowingReadAccessToURL:[NSURL fileURLWithPath:[ZHWebView getDocumentFolder]] finish:finish];
        return;
    }
    
    __weak __typeof__(self) __self = self;
    [self createPreLoadTemplateFolder:webView callBack:^(NSString *loadFolder, NSError *error) {
        //检查
        if (![ZHWebView checkString:loadFolder] || error) {
            if (finish) finish(NO);
            return;
        }
        NSString *htmlPath = [loadFolder stringByAppendingPathComponent:[self.class templateHtmlName]];
        if (![__self.fm fileExistsAtPath:htmlPath]) {
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
        NSURL *accessURL = [NSURL fileURLWithPath:loadFolder];
        NSURL *url = [NSURL fileURLWithPath:htmlPath];
        
        [webView loadUrl:url baseURL:[NSURL fileURLWithPath:superFolder isDirectory:YES] allowingReadAccessToURL:accessURL finish:finish];
    }];
}

#pragma mark - file

- (NSFileManager *)fm{
    return [NSFileManager defaultManager];
}

#pragma mark - check

- (BOOL)checkString:(NSString *)string{
    return !(!string || ![string isKindOfClass:[NSString class]] || string.length == 0);
}

- (BOOL)checkURL:(NSURL *)URL{
    return !(!URL || ![URL isKindOfClass:[NSURL class]] || URL.absoluteString.length == 0);
}

#pragma mark - cache

//清理WebView预加载缓存
- (void)cleanWebViewPreLoadCache{
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

#pragma mark - path

//获取WebView预加载目录
- (void)createPreLoadTemplateFolder:(ZHWebView *)webView callBack:(void (^) (NSString *loadFolder, NSError *error))callBack{
    if (!webView || ![webView isKindOfClass:[ZHWebView class]]) {
        if (callBack) callBack(nil, [NSError new]);
        return;
    }
    
    //获取webView模板文件路径
    __weak __typeof__(self) __self = self;
    [self fetchTemplateFolder:^(NSString *templateFolder, NSError *error) {
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
        
        [__self.lock lock];
        
        //删除目录
        if ([__self.fm fileExistsAtPath:resFolder]) {
            result = [__self.fm removeItemAtPath:resFolder error:&fileError];
            
            if (!result || fileError) {
                [__self.lock unlock];
                if (callBack) callBack(nil, fileError?:[NSError new]);
                return;
            }
        }else{
            //创建上级目录 否则拷贝失败
            NSString *superFolder = [ZHWebView fetchSuperiorFolder:resFolder];
            if (!superFolder) {
                [__self.lock unlock];
                if (callBack) callBack(nil, [NSError new]);
                return;
            }
            if (![__self.fm fileExistsAtPath:superFolder]) {
                result = [__self.fm createDirectoryAtPath:superFolder withIntermediateDirectories:YES attributes:nil error:&fileError];
                if (!result || fileError) {
                    [__self.lock unlock];
                    if (callBack) callBack(nil, fileError?:[NSError new]);
                    return;
                }
            }
        }
        
        //拷贝模板文件
        result = [__self.fm copyItemAtPath:templateFolder toPath:resFolder error:&fileError];
        if (!result || fileError) {
            [__self.lock unlock];
            if (callBack) callBack(nil, fileError?:[NSError new]);
            return;
        }
        
        [__self.lock unlock];
        if (callBack) callBack(resFolder, nil);
    }];
}
//模板文件路径
- (void)fetchTemplateFolder:(void (^) (NSString *templateFolder, NSError *error))callBack{
    //调试配置 使用本地路径文件
    if ([self.class isDebug] && [self.class isSimulator] && ![self.class isUseReleaseWhenSimulator]) {
        NSString *path = [self.class localDebugTemplateFolder];
        if ([self.fm fileExistsAtPath:path]) {
            if (callBack) callBack(path, nil);
            return;
        }
    }
    //获取路径
    [self.class localReleaseTemplateFolder:^(NSString *templateFolder, NSError *error) {
        if (callBack) callBack(templateFolder, error);
    }];
}

#pragma mark - template

+ (NSString *)templateHtmlName{
//    template.html  index.html
    return <#loadHtmlName#>;
}
+ (NSDictionary *)templateInfo{
    return @{@"appId": @"xxxx"};
}

- (void)updateTemplate:(void (^) (NSString *downFolder, NSError *error))callBack{
    if (callBack) callBack(@"", nil);
}


#pragma mark - debug

//加载线上资源
+ (void)localReleaseTemplateFolder:(void (^) (NSString *templateFolder, NSError *error))callBack{
    NSString *folder = nil;
    folder = [[NSBundle mainBundle] pathForResource:[self bundlePathName] ofType:@"bundle"];
    folder = [folder stringByAppendingPathComponent:@"release"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:folder]) {
        if (callBack) callBack(folder, nil);
        [[self shareManager] updateTemplate:nil];
        return;
    }
    [[self shareManager] updateTemplate:^(NSString *downFolder, NSError *error) {
        if (downFolder && !error) {
            if (callBack) callBack(downFolder, nil);
        }else{
            if (callBack) callBack(nil, error ? error : [NSError new]);
        }
    }];
}

+ (NSString *)localDebugTemplateFolder{
    // release  dist
    NSString *packageName = <#packageName#>;
    return [[self localDebugTemplatePrjFolder] stringByAppendingPathComponent:packageName];
}

+ (NSString *)localDebugTemplatePrjFolder{
    // em zheng
    NSString *macName = <#MacName#>;//em zheng
    //Desktop/My/ZHCode/GitHubCode/ZHJSNative/template
    NSString *relativePath = <#prjPath#>;

    return [NSString stringWithFormat:@"/Users/%@/%@", macName, relativePath];
}

+ (NSDictionary *)readLocalDebugConfig{
    if ([self isDebug] && [self isSimulator]) {
        NSString *path = [NSString stringWithFormat:@"%@/%@",[self localDebugTemplatePrjFolder], @"FW_RunConfig_Temp.json"];
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (!data) return nil;
        
        NSError *error = nil;
        id fileData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (!error && [fileData isKindOfClass:[NSDictionary class]]) {
            return fileData;
        }else{
            return nil;
        }
    }
    return nil;
}

//当运行模拟器时是否使用release环境
+ (BOOL)isUseReleaseWhenSimulator{
    if ([self isDebug]) {
        NSDictionary *res = [self readLocalDebugConfig];
        if (!res) return NO;
        return [(NSNumber *)[res valueForKey:@"isUseReleaseWhenSimulator"] boolValue];
    }
    return NO;
}
//是否使用Socket调试
+ (BOOL)isDebugSocket{
    if ([self isDebug]) {
        NSDictionary *res = [self readLocalDebugConfig];
        if (!res) return NO;
        BOOL isSocket = [(NSNumber *)[res valueForKey:@"isSocket"] boolValue];
        return isSocket && [self socketDebugUrl] ? YES : NO;
    }
    return NO;
}
+ (NSURL *)socketDebugUrl{
    if ([self isDebug]) {
        NSDictionary *res = [self readLocalDebugConfig];
        if (!res) return nil;
        NSString *socketUrl = res ? [res valueForKey:@"socketDebugUrl"] : nil;
//        @"http://172.31.35.80:8080"
        return socketUrl ? [NSURL URLWithString:socketUrl] : nil;
    }
    return nil;
}

+ (NSString *)bundlePathName{
    return @"TestBundle";
}

+ (BOOL)isSimulator{
    if ([self isDebug]) {
        return TARGET_OS_SIMULATOR ? YES : NO;
    }
    return NO;
}
+ (BOOL)isDebug{
#ifdef DEBUG
    return YES;
#endif
    return NO;
}
+ (BOOL)isUsePreLoadWebView{
    //❌提交代码注释掉
    //    return YES;
    if (![self isDebug]) {
        return YES;
    }
    if (![self isSimulator]) {
        return YES;
    }
    if ([self isUseReleaseWhenSimulator]) {
        return YES;
    }
    return NO;
}


#pragma mark - getter

- (NSLock *)lock{
    if (!_lock) {
        _lock = [[NSLock alloc] init];
    }
    return _lock;
}
- (NSMutableArray<ZHWebView *> *)webs{
    if (!_webs) {
        _webs = [@[] mutableCopy];
    }
    return _webs;
}

- (NSMutableArray<ZHWebView *> *)loadingWebs{
    if (!_loadingWebs) {
        _loadingWebs = [@[] mutableCopy];
    }
    return _loadingWebs;
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
