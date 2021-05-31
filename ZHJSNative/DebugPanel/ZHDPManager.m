//
//  ZHDPManager.m
//  ZHJSNative
//
//  Created by EM on 2021/5/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPManager.h"
#import "ZHDPContent.h"
#import "ZHDPListLog.h"
#import <CoreText/CoreText.h>

@interface ZHDPManager (){
    CFURLRef _originFontUrl;//注册字体Url
    CTFontDescriptorRef _descriptor;//注册字体Descriptor
}
@property (nonatomic,strong) NSTimer *timer;
@end

@implementation ZHDPManager

#pragma mark - data

- (CGFloat)basicW{
    return UIScreen.mainScreen.bounds.size.width;
}

- (void)addlog{
    if (self.status != ZHDPManagerStatus_Open) {
        return;
    }
    // 哪个应用的数据
    ZHDPAppItem *appItem = [[ZHDPAppItem alloc] init];
    appItem.appId = [NSString stringWithFormat:@"%u", arc4random_uniform(10)];
    appItem.appName = appItem.appId;
    
    // 内容
    CGFloat basicW = self.basicW;
    NSInteger count = 2;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    
    NSMutableArray <ZHDPListColItem *> *colItems = [NSMutableArray array];
    for (NSUInteger i = 0; i < count; i++) {
        ZHDPListColItem *colItem = [[ZHDPListColItem alloc] init];
        colItem.font = [UIFont systemFontOfSize:13];
        colItem.title = [NSString stringWithFormat:@"%@_%@", [dateFormatter stringFromDate:[NSDate date]], appItem.appId];
        colItem.percent = 0.5;
        CGFloat width = basicW * colItem.percent;
        CGFloat X = colItems.count > 0 ? CGRectGetMaxX(colItems.lastObject.rectValue.CGRectValue) : 0;
        CGSize fitSize = [colItem.title boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: colItem.font} context:nil].size;
        colItem.rectValue = [NSValue valueWithCGRect:CGRectMake(X, 0, width, fitSize.height + 2 * 5)];
        
        [colItems addObject:colItem];
    }
    
    ZHDPListRowItem *rowItem = [[ZHDPListRowItem alloc] init];
    rowItem.colItems = @[];
    
    NSMutableArray *detailItems = [NSMutableArray array];
    ZHDPListDetailItem *item = [[ZHDPListDetailItem alloc] init];
    item.title = @"概要";
    item.content = [NSString stringWithFormat:@"%@_%@", item.title, colItems.firstObject.title];
    [detailItems addObject:item];
    
    item = [[ZHDPListDetailItem alloc] init];
    item.title = @"hhh";
    item.content = [NSString stringWithFormat:@"%@_%@", item.title, colItems.firstObject.title];
    [detailItems addObject:item];
    
    ZHDPListSecItem *secItem = [[ZHDPListSecItem alloc] init];
    secItem.enterMemoryTime = [[NSDate date] timeIntervalSince1970];
    secItem.open = NO;
    secItem.colItems = colItems.copy;
    secItem.rowItems = @[];
    secItem.detailItems = detailItems.copy;
    
    // 追加到全局数据管理
    ZHDPAppDataItem *appDataItem = [self.dataTask fetchAppDataItem:appItem];
    secItem.appDataItem = appDataItem;
    [self.dataTask addAndCleanItems:appDataItem.logItems item:secItem spaceItem:appDataItem.logSpaceItem];
    
    // 不可用 self.window  window一旦创建就会自动显示在屏幕上
    // 如果当前列表正在显示，刷新列表
    if (_window && self.window.debugPanel.status == ZHDebugPanelStatus_Show) {
        ZHDPList *list = self.window.debugPanel.content.selectList;
        if ([list isKindOfClass:ZHDPListLog.class]) {
            [list addSecItem:secItem spaceItem:appDataItem.logSpaceItem];
        }
    }
}

#pragma mark - open close

- (void)open{
    if (self.status == ZHDPManagerStatus_Open) {
        return;
    }
    self.status = ZHDPManagerStatus_Open;
    [self.window showFloat];
    [self.window hideDebugPanel];
}
- (void)close{
    if (self.status != ZHDPManagerStatus_Open) {
        return;
    }
    self.status = ZHDPManagerStatus_Close;
    self.window.hidden = YES;
    self.window = nil;
}

#pragma mark - switch

- (void)switchFloat{
    if (!_window) return;
    [self.window showFloat];
    [self.window hideDebugPanel];
}
- (void)switchDebugPanel{
    if (!_window) return;
    [self.window hideFloat];
    [self.window showDebugPanel];
}

#pragma mark - timer

- (void)timeResponse{
    [self addlog];
}

- (void)addTimer:(NSTimeInterval)space{
    if (self.timer != nil) return;
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:space target:self selector:@selector(timeResponse) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    self.timer = timer;
}

- (void)removeTimer{
    if (self.timer == nil) return;
    [self.timer invalidate];
    self.timer = nil;
}

#pragma mark - getter

- (ZHDPDataTask *)dataTask{
    if (!_dataTask) {
        _dataTask = [[ZHDPDataTask alloc] init];
        _dataTask.dpManager = self;
    }
    return _dataTask;
}
- (ZHDPWindow *)window{
    if (!_window) {
        _window = [ZHDPWindow window];
    }
    return _window;
}

#pragma mark - font

- (UIFont *)iconFontWithSize:(CGFloat)fontSize{
    NSString *fontSrc = [[NSBundle mainBundle] pathForResource:@"iconfont" ofType:@"ttf"];
    fontSize = (fontSize > 0 ? fontSize : 17);
    if (fontSrc.length == 0) {
        return [UIFont systemFontOfSize:fontSize];
    }
    NSURL *originFontURL = (__bridge NSURL *)_originFontUrl;
    BOOL isRegistered = (_originFontUrl && _descriptor);
    
    //已经注册同样的字体文件
    if (isRegistered && [originFontURL.path isEqualToString:fontSrc]) {
        return [UIFont fontWithDescriptor:(__bridge UIFontDescriptor *)_descriptor size:fontSize];
    }
    
    //取消注册先前的文件
    if (isRegistered) {
        CTFontManagerUnregisterFontsForURL(_originFontUrl, kCTFontManagerScopeNone, NULL);
        _originFontUrl = nil;
        _descriptor = nil;
    }
    
    //注册新字体文件
    CFURLRef newFontURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)fontSrc, kCFURLPOSIXPathStyle, false);
    CTFontManagerRegisterFontsForURL(newFontURL, kCTFontManagerScopeNone, NULL);
    _originFontUrl = newFontURL;
    CFArrayRef descriptors = CTFontManagerCreateFontDescriptorsFromURL(newFontURL);
    NSInteger count = CFArrayGetCount(descriptors);
    _descriptor = (count >= 1 ? CFArrayGetValueAtIndex(descriptors, 0) : nil);
    if (_originFontUrl && _descriptor) {
        return [UIFont fontWithDescriptor:(__bridge UIFontDescriptor *)_descriptor size:fontSize];
    }else{
        return [UIFont systemFontOfSize:fontSize];
    }
}
- (UIFont *)defaultFont{
    return [UIFont systemFontOfSize:13];
}

#pragma mark - color

- (UIColor *)defaultColor{
    return [UIColor blackColor];
}
- (UIColor *)selectColor{
    return [UIColor colorWithRed:12.0/255.0 green:200.0/255.0 blue:46.0/255.0 alpha:1];
}

#pragma mark - share

- (instancetype)init{
    if (self = [super init]) {
        // 只加载一次的资源
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self addTimer:1];
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

@end
