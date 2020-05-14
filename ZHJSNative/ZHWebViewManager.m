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
#import "ZhengFile.h"

@interface ZHWebViewManager ()
//初始化配置资源
@property (nonatomic, strong) NSMutableArray <ZHWebView *> *webs;
@property (nonatomic, strong) NSMutableArray <ZHWebView *> *loadingWebs;
@property (nonatomic,strong) NSLock *lock;
@end

@implementation ZHWebViewManager

- (NSArray *)apiHandlers{
    return @[[[ZHCustomApiHandler alloc] init], [[ZHCustom1ApiHandler alloc] init]];
}

#pragma mark - config

+ (void)install{
//    [ZhengFile deleteFileOrFolder:[[self getDocumentPath] stringByAppendingPathComponent:@"ZHHtml"]];
    
    if ([self isUsePreWebView]) {
        [[ZHWebViewManager shareManager] install];
    }
}

- (void)install{
    if (self.webs.count >= 1) return;
    if (self.loadingWebs.count >= 1) return;
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

- (void)recycleWebView:(ZHWebView *)webView{
    if (webView) webView = nil;
    
    if (self.webs.count >= 3) return;
    
    __weak __typeof__(self) weakSelf = self;
    ZHWebView *newWebView = [self createWebView];
    [self loadWebView:newWebView finish:^(BOOL success) {
        [weakSelf.lock lock];
        if (success) [weakSelf.webs addObject:newWebView];
        [weakSelf.lock unlock];
    }];
}

- (ZHWebView *)createWebView{
    return [[ZHWebView alloc] initWithFrame:[UIScreen mainScreen].bounds apiHandlers:[self apiHandlers]];
}
- (void)loadWebView:(ZHWebView *)webView finish:(void (^) (BOOL success))finish{
    
    NSURL *accessURL = (![ZHWebViewManager isUsePreWebView] ? nil : [NSURL fileURLWithPath:[ZHWebViewManager getDocumentPath]]);
    NSURL *url = [ZHWebViewManager sourceTemplate];
    
    
    [webView loadUrl:url allowingReadAccessToURL:accessURL finish:finish];
}

#pragma mark - path

+ (NSString *)getDocumentPath{
    NSArray *userPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [userPaths objectAtIndex:0];
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

#pragma mark - other
//是否使用预先加载的webview
+ (BOOL)isUsePreWebView{
    if (TARGET_OS_SIMULATOR) {
        return NO;
    }
    return YES;
    NSDictionary *res = [self readLocalConfig];
    if (!res) return YES;
    return [(NSNumber *)[res valueForKey:@"isUsePreWebView"] boolValue];
}

+ (NSDictionary *)readLocalConfig{
    NSString *path = [NSString stringWithFormat:@"%@/%@",[self localPath], @"FW_RunConfig_Temp.json"];
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

+ (NSString *)localPath{
    NSString *macUserName = <#MacUserName#>;
    return [NSString stringWithFormat:@"/Users/%@/Desktop/My/ZHCode/GitHubCode/ZHJSNative/template", macUserName];
}
+ (NSString *)bundlePathName{
    return @"TestBundle";
}
//载入test.html文件
+ (NSURL *)loadBundleTestHtml{
    NSString *name = @"test.html";
    
    BOOL isLocal = YES;
    NSString *destPath = nil;
    if (isLocal) {
        destPath = [[[self localPath] stringByAppendingPathComponent:@"../ZHJSNative/TestBundle.bundle"] stringByAppendingPathComponent:name];
    }else{
        destPath = [[NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TestBundle" ofType:@"bundle"]] pathForResource:name.stringByDeletingPathExtension ofType:name.pathExtension];
    }
    return [NSURL fileURLWithPath:destPath];
}
//模板资源文件
+ (NSURL *)sourceTemplate{
    NSString *name = @"release/index.html";
    if (![ZHWebViewManager isUsePreWebView]) {
        
//        return [self loadBundleTestHtml];
        
        //检查本地调试信息
        NSDictionary *res = [self readLocalConfig];
        BOOL isSocket = [(NSNumber *)[res valueForKey:@"isSocket"] boolValue];
        if (isSocket) {
            NSString *socketUrl = res ? [res valueForKey:@"socketDebugUrl"] : nil;
            socketUrl = socketUrl?:@"http://172.31.35.80:8080";
            return [NSURL URLWithString:socketUrl];
        }
        
        NSFileManager *fileMg = [NSFileManager defaultManager];
        if ([fileMg fileExistsAtPath:[self localPath]]) {
            return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",[self localPath], name]];
        }
    }
    
    NSString *path = nil;
    //拷贝bundle文件
    path = [[NSBundle mainBundle] pathForResource:[self bundlePathName] ofType:@"bundle"];
    path = [path stringByAppendingPathComponent:@"release"];
    NSString *targetPath = [[self getDocumentPath] stringByAppendingPathComponent:@"ZHHtml"];
    targetPath = [NSString stringWithFormat:@"%@/template_%u", targetPath, arc4random_uniform(10)];
    [ZhengFile copySourceFile:path toDesPath:targetPath];
    return [NSURL fileURLWithPath:[targetPath stringByAppendingPathComponent:@"index.html"]];
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
