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
    if ([self.class isDebug] && [self.class isDebugSocket]) {
        NSURL *socketUrl = [self.class socketDebugUrl];
        [webView loadUrl:socketUrl baseURL:nil allowingReadAccessToURL:[NSURL fileURLWithPath:[ZHWebView getDocumentFolder]] finish:finish];
        return;
    }
    
    NSString *preLoadFolder = [self createPreLoadTemplateFolder:webView];
    
    if (![ZHWebView checkString:preLoadFolder]) {
        if (finish) finish(NO);
        return;
    }
    NSString *htmlPath = [preLoadFolder stringByAppendingPathComponent:[ZHWebViewManager templateHtmlName]];
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
    
    NSURL *accessURL = [NSURL fileURLWithPath:preLoadFolder];
    NSURL *url = [NSURL fileURLWithPath:htmlPath];
    
    [webView loadUrl:url baseURL:[NSURL fileURLWithPath:superFolder isDirectory:YES] allowingReadAccessToURL:accessURL finish:finish];
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
- (NSString *)createPreLoadTemplateFolder:(ZHWebView *)webView{
    if (!webView || ![webView isKindOfClass:[ZHWebView class]]) {
        return nil;
    }
    
    //获取webView模板文件路径
    NSString *templateFolder = [self fetchTemplateFolder];
    if (!templateFolder) {
        return nil;
    }
    
    //目标路径
    NSString *resFolder = [webView fetchRunSandBox];
    if (!resFolder) {
        return nil;
    }
    
    BOOL result = NO;
    NSError *error = nil;
    
    [self.lock lock];
    
    //删除目录
    if ([self.fm fileExistsAtPath:resFolder]) {
        result = [self.fm removeItemAtPath:resFolder error:&error];
        
        if (!result || error) {
            [self.lock unlock];
            return nil;
        }
    }else{
        //创建上级目录 否则拷贝失败
        NSString *superFolder = [ZHWebView fetchSuperiorFolder:resFolder];
        if (!superFolder) {
            [self.lock unlock];
            return nil;
        }
        if (![self.fm fileExistsAtPath:superFolder]) {
            result = [self.fm createDirectoryAtPath:superFolder withIntermediateDirectories:YES attributes:nil error:&error];
            if (!result || error) {
                [self.lock unlock];
                return nil;
            }
        }
    }
    
    //拷贝模板文件
    result = [self.fm copyItemAtPath:templateFolder toPath:resFolder error:&error];
    if (!result || error) {
        [self.lock unlock];
        return nil;
    }
    
    [self.lock unlock];
    return resFolder;
}
//模板文件路径
- (NSString *)fetchTemplateFolder{
    //调试配置 使用本地路径文件
    if ([self.class isDebug] && [self.class isSimulator]) {
        NSString *path = [self.class localDebugTemplateFolder];
        if ([self.fm fileExistsAtPath:path]) {
            return path;
        }
    }
    //获取路径
    NSString *folder = [self.class localReleaseTemplateFolder];
    if (!folder) {
        [self updateTemplate];
        return nil;
    }
    return folder;
}

#pragma mark - template

+ (NSString *)templateHtmlName{
//    template.html  index.html
    return <#loadHtmlName#>;
}
+ (NSDictionary *)templateInfo{
    return @{@"appId": @"xxxx"};
}

- (void)updateTemplate{
}


#pragma mark - debug

//
+ (NSString *)localReleaseTemplateFolder{
    NSString *folder = nil;
    folder = [[NSBundle mainBundle] pathForResource:[self bundlePathName] ofType:@"bundle"];
    folder = [folder stringByAppendingPathComponent:@"release"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:folder]) {
        return nil;
    }
    return folder;
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

+ (BOOL)isDebugSocket{
    if ([self isDebug]) {
        NSDictionary *res = [self readLocalDebugConfig];
        if (!res) return NO;
        BOOL isSocket = [(NSNumber *)[res valueForKey:@"isSocket"] boolValue];
        return isSocket;
    }
    return NO;
}

+ (NSURL *)socketDebugUrl{
    if ([self isDebug]) {
        NSDictionary *res = [self readLocalDebugConfig];
        if (!res) return nil;
        NSString *socketUrl = res ? [res valueForKey:@"socketDebugUrl"] : nil;
        socketUrl = socketUrl?:@"http://172.31.35.80:8080";
        return [NSURL URLWithString:socketUrl];
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
    if ([self isDebug]) {
        return ![self isSimulator];
    }
    return YES;
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
