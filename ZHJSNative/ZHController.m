//
//  ZHController.m
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHController.h"
#import "ZHWebView.h"
#import "ZHUtil.h"
#import "ZHJSContext.h"
#import "ZHCustomApiHandler.h"
#import "ZHCustom1ApiHandler.h"
#import "ZhengFile.h"

@interface ZHController ()<ZHWebViewSocketDebugDelegate>
@property (nonatomic, strong) ZHWebView *webView;
@property (nonatomic, strong) ZHJSContext *context;


@property (nonatomic,strong) ZHCustomApiHandler *customApiHandler;
@end

@implementation ZHController

- (void)handlerEmotion{
    
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"EFEmoji" ofType:@"bundle"];
    
    NSString *imagesPath = [[NSBundle bundleWithPath:bundlePath] pathForResource:@"images" ofType:nil];
    NSString *jsonPath = [[NSBundle bundleWithPath:bundlePath] pathForResource:@"ef_emoji" ofType:@"json"];
    
    NSData *data = [NSData dataWithContentsOfFile:jsonPath];
    NSArray *emojiArr = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    //key值转换 @{@"[滴汗]": @"common_ef_emot07.png"}
    NSMutableDictionary *callInfo = [@{} mutableCopy];
    
    for (NSDictionary *emojiInfo in emojiArr) {
        NSString *mean = [emojiInfo valueForKey:@"emojimeaning"];
        NSString *fileName = [emojiInfo valueForKey:@"emojiname"];
        
        //bundle资源
        NSString *imagePath = [imagesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",fileName]]?:@"";
                
        [callInfo setValue:imagePath forKey:[NSString stringWithFormat:@"[%@]", mean]];
    }
    self.customApiHandler.emotionMap = [callInfo copy];
}
- (void)copyBigEmotion{
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"EFEmoji" ofType:@"bundle"];
    NSString *imagesPath = [[NSBundle bundleWithPath:bundlePath] pathForResource:@"BigEmotin" ofType:nil];
    
    NSString *targetEmotionPath = [[ZhengFile getDocumentPath] stringByAppendingPathComponent:@"BigEmotion"];
     
    [ZhengFile copySourceFile:imagesPath toDesPath:targetEmotionPath];
    
    NSData *data = [NSData dataWithContentsOfFile:[targetEmotionPath stringByAppendingPathComponent:@"index.json"]];
    NSArray *emojiArr = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    //key值转换 @{@"[滴汗]": @"common_ef_emot07.png"}
    NSMutableDictionary *callInfo = [@{} mutableCopy];
    
    for (NSDictionary *emojiInfo in emojiArr) {
        NSString *mean = [emojiInfo valueForKey:@"text"];
        NSString *fileName = [emojiInfo valueForKey:@"path"];
        
        //bundle资源
//        NSString *imagePath = [imagesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",fileName]]?:@"";
        
        //沙盒资源
        NSString *imagePath = [targetEmotionPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",fileName]]?:@"";

        [callInfo setValue:imagePath forKey:[NSString stringWithFormat:@"[%@]", mean]];
    }
    
    self.customApiHandler.bigEmotionMap = [callInfo copy];
    
}

- (void)copyHtmlFile{
    [ZhengFile copySourceFile:[[NSBundle bundleWithPath:[ZHUtil bundlePath]] pathForResource:@"release" ofType:nil] toDesPath:[[ZhengFile getDocumentPath] stringByAppendingPathComponent:@"release"]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.customApiHandler = [[ZHCustomApiHandler alloc] init];
    
    //拷贝表情
    [self handlerEmotion];
    [self copyBigEmotion];
    
    //拷贝html文件
    [self copyHtmlFile];
    
    
    [self config:NO];
    
    //运算js
//    self.context = [[ZHJSContext alloc] initWithApiHandlers:@[[[ZHCustomApiHandler alloc] init], [[ZHCustom1ApiHandler alloc] init]]];
//    NSURL *url = [NSURL fileURLWithPath:[ZHUtil jsPath]];
//    url = [NSURL fileURLWithPath:@"/Users/zheng/Desktop/ZHCode/GitHubCode/ZHJSNative/ZHJSNative/TestBundle.bundle/test.js"];
//    [self.context evaluateScript:[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self configWebViewFrame:self.webView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self configNavigaitonBar:animated];
    NSLog(@"----✅viewWillAppear----");
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    NSLog(@"----✅viewDidAppear----");
    [self configGesture];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self.webView loadUrl:[NSURL fileURLWithPath:[ZHUtil htmlPath]] finish:^(BOOL success) {
//            
//        }];
//    });
}

- (void)config:(BOOL)debugReload{
    [self configView];
    [self configWebView:debugReload];
}

- (void)configView{
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor whiteColor];
//    self.view.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255.0)/ 255.0 green:arc4random_uniform(255.0)/ 255.0 blue:arc4random_uniform(255.0)/ 255.0 alpha:1.0];
}

- (void)configNavigaitonBar:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    UINavigationBar *bar = self.navigationController.navigationBar;
    bar.translucent = NO;
}

- (void)configWebView:(BOOL)debugReload{
    
    NSURL *url = [NSURL fileURLWithPath:[ZHUtil htmlPath]];
//    url = [NSURL fileURLWithPath:@"/Users/em/Desktop/My/ZHCode/GitHubCode/ZHJSNative/ZHJSNative/TestBundle.bundle/test.html"];
//    url = [NSURL fileURLWithPath:@"/Users/em/Desktop/My/ZHCode/GitHubCode/ZHJSNative/template/release/index.html"];
//    url = [NSURL URLWithString:@"http://172.31.35.80:8080"];
    url = [NSURL fileURLWithPath:[[[ZhengFile getDocumentPath] stringByAppendingPathComponent:@"release"] stringByAppendingPathComponent:@"index.html"]];
    
    __weak __typeof__(self) __self = self;
    if (debugReload) {
        [self.webView loadUrl:url allowingReadAccessToURL:[NSURL fileURLWithPath:[ZhengFile getDocumentPath]] finish:^(BOOL success) {
            [__self configDebugOption:@"刷新"];
        }];
        return;
    }
    
    ZHWebView *webView = [[ZHWebView alloc] initWithApiHandlers:@[self.customApiHandler, [[ZHCustom1ApiHandler alloc] init]]];
    [webView loadUrl:url allowingReadAccessToURL:[NSURL fileURLWithPath:[ZhengFile getDocumentPath]] finish:^(BOOL success) {
        [__self configDebugOption:@"刷新"];
    }];
    
    [self configWebViewFrame:webView];
    [self.view addSubview:webView];
    self.webView = webView;
    [self configWebViewDelegate:webView target:self];
}
- (void)configWebViewDelegate:(ZHWebView *)webView target:(id)target{
    webView.zh_navigationDelegate = target;
    webView.zh_UIDelegate = target;
    webView.zh_socketDebugDelegate = target;
}

- (void)configWebViewFrame:(WKWebView *)webView{
    if (@available(iOS 11.0, *)) {
        webView.frame = (CGRect){CGPointZero, {self.view.bounds.size.width, self.view.bounds.size.height - self.view.safeAreaInsets.bottom}};
    } else {
        webView.frame = self.view.bounds;
    }
}
- (void)configGesture{
    @try {
        NSArray *internalTargets = [self.navigationController.interactivePopGestureRecognizer valueForKey:@"targets"];
        id internalTarget = [internalTargets.firstObject valueForKey:@"target"];
        UIScreenEdgePanGestureRecognizer *panGes = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:internalTarget action:@selector(handleNavigationTransition:)];
        panGes.edges = UIRectEdgeLeft;
        [self.view addGestureRecognizer:panGes];
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (object == self.webView) {
        if ([keyPath isEqualToString:@"loading"]) {
            return;
        }
        if ([keyPath isEqualToString:@"title"]){
            self.title = self.webView.title;
            return;
        }
        if ([keyPath isEqualToString:@"estimatedProgress"]){
            NSLog(@"%f",self.webView.estimatedProgress);
//            [self.progressView setProgress:self.webView.estimatedProgress animated:YES];
//            if (self.progressView.progress == 1.0) {
//                __weak __typeof__(self) __self = self;
//                [UIView animateWithDuration:0.55 animations:^{
//                    __self.progressView.alpha = 0.0;
//                }];
//            }
            return;
        }
    }
    
    if ([keyPath isEqualToString:@"contentSize"] &&
        object == self.webView.scrollView) {
        if (@available(iOS 9.0, *)) {
            __weak __typeof__(self) __self = self;
            [self.webView evaluateJavaScript:@"document.body.offsetHeight;" completionHandler:^(id _Nullable object, NSError * _Nullable error) {
                if (!error) {
                    // 网页内容高度
                    CGFloat bodyHeight = [object floatValue];
                    CGFloat webViewHeight = __self.webView.frame.size.height;
                    if (fabs(webViewHeight - bodyHeight) > 2) {
//                        NSLog(@"**************body--height = %@", @(bodyHeight));
//                        NSLog(@"**************webView--height = %@", @(webViewHeight));
                        //                    [weakSelf fireEvent:EF_WEB_PAGE_HEIGHT_CHANGE params:@{@"pageHeight": @(bodyHeight/weakSelf.weexInstance.pixelScaleFactor)}];
                    }
                }
            }];
        }else {
            CGFloat webHeight = self.webView.frame.size.height;
            CGFloat newHeight = [change[NSKeyValueChangeNewKey] CGSizeValue].height;
            if (fabs(webHeight - newHeight) > 2 && newHeight > 0) {
                //            [self fireEvent:EF_WEB_PAGE_HEIGHT_CHANGE params:@{@"pageHeight": @(newHeight/self.weexInstance.pixelScaleFactor)}];
            }
//            NSLog(@"changeNew: %@", NSStringFromCGSize(self.webView.scrollView.contentSize));
        }
    }
}

- (void)dealloc{
    NSLog(@"-------%s---------", __func__);
}

#pragma mark - ZHWebViewSocketDebugDelegate

- (void)webViewReadyRefresh:(ZHWebView *)webView{
    [self configDebugOption:@"准备中..."];
}
- (void)webViewRefresh:(ZHWebView *)webView{
    [self refreshWebView];
}

- (void)refreshWebView{
    [self configDebugOption:@"刷新中..."];
    
    /** presented 与dismiss同时进行 会crash */
//    if ([self.presentedViewController isKindOfClass:[UIAlertController class]]) {
//        [self dismissViewControllerAnimated:YES completion:nil];
//    }
    //清除代理
    [self configWebViewDelegate:self.webView target:nil];
    [self config:YES];
}

- (void)configDebugOption:(NSString *)title{
    #ifdef DEBUG
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(refreshWebView)];
    NSMutableArray *rightItems = [NSMutableArray array];
//    if (self.navigationItem.rightBarButtonItems.count > 0) {
//        [rightItems addObject:self.navigationItem.rightBarButtonItems.firstObject];
//    }
    [rightItems addObject:item];
    self.navigationItem.rightBarButtonItems = rightItems;
    #endif
}
@end
