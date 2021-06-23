//
//  ZHDPManager.m
//  ZHJSNative
//
//  Created by EM on 2021/5/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPManager.h"
#import <CoreText/CoreText.h>
#import "ZHDPContent.h"// 内容列表容器
#import "ZHDPListLog.h"// log列表
#import "ZHDPListNetwork.h"// network列表
#import "ZHDPListStorage.h"// storage列表
#import "ZHDPListMemory.h"// Memory列表
#import "ZHDPListIM.h"// im列表
#import "ZHDPListException.h"// Exception列表

@interface ZHDPManager (){
    CFURLRef _originFontUrl;//注册字体Url
    CTFontDescriptorRef _descriptor;//注册字体Descriptor
}
@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic,strong) NSDateFormatter *dateFormat;
@end

@implementation ZHDPManager

#pragma mark - config

- (void)config{
}

#pragma mark - basic

- (CGFloat)basicW{
    return UIScreen.mainScreen.bounds.size.width;
}
- (CGFloat)marginW{
    return 5;
}

#pragma mark - date

- (NSDateFormatter *)dateByFormat:(NSString *)formatStr{
//    @"yyyy-MM-dd HH:mm:ss.SSS"
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateStyle:NSDateFormatterMediumStyle];
    [format setTimeStyle:NSDateFormatterShortStyle];
    [format setDateFormat:formatStr];
    return format;
}
- (NSDateFormatter *)dateFormat{
    if (!_dateFormat) {
        _dateFormat = [self dateByFormat:@"HH:mm:ss.SSS"];
    }
    return _dateFormat;
}
- (CGFloat)dateW{
    NSString *str = [self dateFormat].dateFormat;
    str = @"99:99:99.999";
    CGFloat basicW = [self basicW];
    return [str boundingRectWithSize:CGSizeMake(basicW, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [self defaultFont]} context:nil].size.width;
}

#pragma mark - animate

- (void)doAnimation:(void (^)(void))animation completion:(void (^ __nullable)(BOOL finished))completion{
//    BOOL isHaveWindow = (_window ? YES : NO);
//    if (isHaveWindow) {
//        [self.window enableDebugPanel:NO];
//    }
//    __weak __typeof__(self) weakSelf = self;
    [UIView animateWithDuration:0.20 animations:animation completion:^(BOOL finished) {
        if (completion) completion(finished);
//        if (isHaveWindow) {
//            [weakSelf.window enableDebugPanel:YES];
//        }
    }];
}

#pragma mark - open close

- (void)openOnlyFunction{
    if (self.status == ZHDPManagerStatus_Open) {
        return;
    }
    self.status = ZHDPManagerStatus_Open;
}
- (void)open{
    if (self.status == ZHDPManagerStatus_Open) {
        return;
    }
    self.status = ZHDPManagerStatus_Open;
    [self startMonitorMpLog];
    [self.networkTask interceptNetwork];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveImMessage:) name:@"ZHSDKImMessageToConsoleNotification" object:nil];
    
    if ([self fetchKeyWindow]) {
        [self openInternal];
        return;
    }
    
    [self addTimer:0.5];
}
- (void)openInternal{
    if (self.status != ZHDPManagerStatus_Open) {
        return;
    }
    [self.window showFloat:[self fetchFloatTitle]];
    [self.window hideDebugPanel];
}
- (void)close{
    if (self.status != ZHDPManagerStatus_Open) {
        return;
    }
    self.status = ZHDPManagerStatus_Close;
    [self removeTimer];
    [self stopMonitorMpLog];
    if (_networkTask) [self.networkTask cancelNetwork];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ZHSDKImMessageToConsoleNotification" object:nil];
    
    if (!_window) return;
    self.window.hidden = YES;
    self.window = nil;
}

#pragma mark - window

- (UIWindow *)fetchKeyWindow{
    // window必须成为keyWindow  才可创建自定义的window  否则崩溃
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (!keyWindow || keyWindow.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for (UIWindow *window in windows) {
            if (window.windowLevel == UIWindowLevelNormal){
                keyWindow = window;
                break;
            }
        }
    }
    return keyWindow.isKeyWindow ? keyWindow : nil;
}
- (UIEdgeInsets)fetchKeyWindowSafeAreaInsets{
    // 只是获取window的safeAreaInsets  不需要window成为keyWindow
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (keyWindow.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for (UIWindow *window in windows) {
            if (window.windowLevel == UIWindowLevelNormal){
                keyWindow = window;
                break;
            }
        }
    }
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = [keyWindow safeAreaInsets];
    }
    return safeAreaInsets;
}

#pragma mark - float

- (NSString *)fetchFloatTitle{
    return @"调试台";
}
- (void)updateFloatTitle{
    if (!_window) return;
    [self.window.floatView updateTitle:[self fetchFloatTitle]];
}

#pragma mark - switch

- (void)switchFloat{
    if (!_window) return;
    [self.window showFloat:[self fetchFloatTitle]];
    [self.window hideDebugPanel];
}
- (void)switchDebugPanel{
    if (!_window) return;
    [self.window hideFloat];
    [self.window showDebugPanel];
}

#pragma mark - timer

- (void)timeResponse{
    if ([self fetchKeyWindow]) {
        [self removeTimer];
        [self openInternal];
    }
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
    return [UIFont systemFontOfSize:14];
}
- (UIFont *)defaultBoldFont{
    return [UIFont boldSystemFontOfSize:14];
}

#pragma mark - color

- (UIColor *)bgColor{
    return [UIColor colorWithRed:239.0/255.0 green:239.0/255.0 blue:244.0/255.0 alpha:1.0];
}
- (UIColor *)defaultColor{
    return [UIColor blackColor];
}
- (UIColor *)selectColor{
    return [UIColor colorWithRed:12.0/255.0 green:200.0/255.0 blue:46.0/255.0 alpha:1];
}
- (UIColor *)defaultLineColor{
    return [UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1];
    return [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1];
}
- (CGFloat)defaultLineW{
    return 1.0 / UIScreen.mainScreen.scale;
}
- (CGFloat)defaultCornerRadius{
    return 10.0;
}

- (NSDictionary *)outputColorMap{
    return @{
        @(ZHDPOutputColorType_Error): [UIColor colorWithRed:220.0/255.0 green:20.0/255.0 blue:60.0/255.0 alpha:1],
        @(ZHDPOutputColorType_Warning): [UIColor colorWithRed:255.0/255.0 green:215.0/255.0 blue:0.0/255.0 alpha:1],
        @(ZHDPOutputColorType_Default): [UIColor blackColor]
    };
}
- (UIColor *)fetchOutputColor:(ZHDPOutputColorType)type{
    NSDictionary *map = [self outputColorMap];
    UIColor *res = [map objectForKey:@(type)];
    if (!res) {
        res = [map objectForKey:@(ZHDPOutputColorType_Default)];
    }
    return res;
}

#pragma mark - toast

- (void)showToast:(NSString *)title{
    CGSize size = CGSizeMake(150, 30);
    UIView *container = self.window.debugPanel;
    CGFloat X = (container.bounds.size.width - size.width) * 0.5;
    
    CGRect startFrame = (CGRect){{X, -size.height}, size};
    CGRect endFrame = (CGRect){{X, 5}, size};
    
    UILabel *label = [[UILabel alloc] initWithFrame:startFrame];
    
    label.userInteractionEnabled = YES;
    UIGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(skipToWeChatApp)];
    [label addGestureRecognizer:tapGes];
    
    label.text = title;
    label.font = [self defaultFont];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [self selectColor];
//    label.alpha = 0.7;
    label.backgroundColor = [UIColor whiteColor];
    label.layer.masksToBounds = YES;
    label.clipsToBounds = YES;
    label.layer.cornerRadius = size.height * 0.5;
    [container addSubview:label];
    [UIView animateWithDuration:0.25 animations:^{
        label.frame = endFrame;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.25 animations:^{
                label.frame = startFrame;
            } completion:^(BOOL finished) {
                [label removeFromSuperview];
            }];
        });
    }];
}
- (void)skipToWeChatApp{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"weixin://"]];
}

#pragma mark - data

/**JSContext中：js类型-->JSValue类型 对应关系
 Date：[JSValue toDate]=[NSDate class]
 function：[JSValue toObject]=[NSDictionary class]    [jsValue isObject]=YES
 null：[JSValue toObject]=[NSNull null]
 undefined：[JSValue toObject]=nil
 boolean：[JSValue toObject]=@(YES) or @(NO)  [NSNumber class]
 number：[JSValue toObject]= [NSNumber class]
 string：[JSValue toObject]= [NSString class]   [jsValue isObject]=NO
 array：[JSValue toObject]= [NSArray class]    [jsValue isObject]=YES
 json：[JSValue toObject]= [NSDictionary class]    [jsValue isObject]=YES
 */
- (id)jsValueToNative:(JSValue *)jsValue{
    if (!jsValue) return nil;
    if (@available(iOS 9.0, *)) {
        if (jsValue.isDate) {
            return [jsValue toDate];
        }
        if (jsValue.isArray) {
            return [jsValue toArray];
        }
    }
    if (@available(iOS 13.0, *)) {
        if (jsValue.isSymbol) {
            return nil;
        }
    }
    if (jsValue.isNull) {
        return [NSNull null];
    }
    if (jsValue.isUndefined) {
        return @"Undefined";
    }
    if (jsValue.isBoolean){
        return [jsValue toBool] ? @"true" : @"false";
    }
    if (jsValue.isString || jsValue.isNumber){
        return [jsValue toObject];
    }
    if (jsValue.isObject){
        return [jsValue toObject];
    }
    return [jsValue toObject];
}
- (NSString *)jsonToString:(id)json{
    if (!json) {
        return nil;
    }
    if ([json isKindOfClass:NSArray.class] || [json isKindOfClass:NSDictionary.class]) {
        NSString *res = nil;
        @try {
            NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
            res = (data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil);
        } @catch (NSException *exception) {
        } @finally {
        }
        return res;
    }
    return json;
}
- (void)convertToString:(id)title block:(void (^) (NSString *conciseStr, NSString *detailStr))block{
    if (!block) {
        return;
    }
    if (!title) {
        block(nil, nil);
        return;
    }
    if ([title isKindOfClass:NSDate.class]) {
        block([(NSDate *)title description], [(NSDate *)title description]);
        return;
    }
    if ([title isKindOfClass:NSArray.class]) {
        block(@"[Object Array]", [self jsonToString:title] ?: @"[Object Array]");
        return;
    }
    if ([title isKindOfClass:NSNull.class]) {
        block(@"[Object Null]", @"[Object Null]");
        return;
    }
    if ([title isKindOfClass:NSString.class]) {
        block(title, title);
        return;
    }
    if ([title isKindOfClass:NSNumber.class]) {
        block([NSString stringWithFormat:@"%@", title], [NSString stringWithFormat:@"%@", title]);
        return;
    }
    if ([title isKindOfClass:NSDictionary.class]) {
        block(@"[Object Object]", [self jsonToString:title] ?: @"[Object Object]");
        return;
    }
    block([title description], [title description]);
}
- (NSAttributedString *)createDetailAttStr:(NSArray *)titles descs:(NSArray *)descs{
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] init];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = 5;
    for (NSUInteger i = 0; i < titles.count; i++) {
        [attStr appendAttributedString:[[NSAttributedString alloc] initWithString:titles[i] attributes:@{NSFontAttributeName: [ZHDPMg() defaultBoldFont], NSForegroundColorAttributeName: [ZHDPMg() selectColor], NSParagraphStyleAttributeName: style}]];
        if (i < descs.count){
            [attStr appendAttributedString:[[NSAttributedString alloc] initWithString:descs[i] attributes:@{NSFontAttributeName: [ZHDPMg() defaultFont], NSForegroundColorAttributeName: [ZHDPMg() defaultColor], NSParagraphStyleAttributeName: style}]];
        }
    }
    return [[NSAttributedString alloc] initWithAttributedString:attStr];
}
- (ZHDPListColItem *)createColItem:(NSString *)title percent:(CGFloat)percent X:(CGFloat)X colorType:(ZHDPOutputColorType)colorType{

    title = title?:@"";
    NSMutableAttributedString *tAtt = [[NSMutableAttributedString alloc] init];
    
    NSUInteger limit = 200;
    NSUInteger titleLength = title.length;
    if (titleLength < limit) {
        [tAtt appendAttributedString:[[NSAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName: [self defaultFont], NSForegroundColorAttributeName: [self fetchOutputColor:colorType]}]];
    }else{
        title = [title substringToIndex:limit - 1];
        [tAtt appendAttributedString:[[NSAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName: [self defaultFont], NSForegroundColorAttributeName: [self fetchOutputColor:colorType]}]];
        [tAtt appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n...点击展开" attributes:@{NSFontAttributeName: [self defaultFont], NSForegroundColorAttributeName: [self selectColor]}]];
    }
    
    ZHDPListColItem *colItem = [[ZHDPListColItem alloc] init];
    colItem.attTitle = [[NSAttributedString alloc] initWithAttributedString:tAtt];
    colItem.percent = percent;
    CGFloat width = [self basicW] * colItem.percent;
    
    CGSize fitSize = [colItem.attTitle boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
//    CGSize fitSize = [title boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [self defaultFont]} context:nil].size;
    colItem.rectValue = [NSValue valueWithCGRect:CGRectMake(X, 0, width, fitSize.height + 2 * 5)];
    
    return colItem;
}
- (id)parseDataFromRequestBody:(NSData *)data{
    if (!data || ![data isKindOfClass:NSData.class]) {
        return nil;
    }
    id res = nil;
    // 尝试json解析
    @try {
        res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingFragmentsAllowed error:nil];
    } @catch (NSException *exception) {
    } @finally {
    }
    if (res) return res;
    
    // 尝试string解析
    @try {
        res = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } @catch (NSException *exception) {
    } @finally {
    }
    
    if (!res || ![res isKindOfClass:NSString.class] || ((NSString *)res).length == 0) {
        return nil;
    }
    
    // 转json
    NSURLComponents *comp = [[NSURLComponents alloc] init];
    comp.query = res;
    res = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *item in comp.queryItems) {
        if (item.name.length && item.value.length) {
            [res setObject:item.value forKey:item.name];
        }
    }
    if (res && [res isKindOfClass:NSDictionary.class] && ((NSDictionary *)res).allKeys.count > 0) {
        return ((NSDictionary *)res).copy;
    }
    return nil;
}

- (void)copySecItemToPasteboard:(ZHDPListSecItem *)secItem{
    if (secItem.pasteboardBlock) {
        NSString *str = secItem.pasteboardBlock();
        // 去除转义字符
        str = [str stringByReplacingOccurrencesOfString:@"\\" withString:@""];
        [[UIPasteboard generalPasteboard] setString:str];
        [self showToast:@"已复制，点击分享"];
    }
}

- (NSString *)opSecItemsMapKey_items{
    return @"itemsBlock";
}
- (NSString *)opSecItemsMapKey_space{
    return @"spaceBlock";
}
- (NSDictionary *)opSecItemsMap{
    NSString *itemsKey = [self opSecItemsMapKey_items];
    NSString *spaceKey = [self opSecItemsMapKey_space];
    return @{
        NSStringFromClass(ZHDPListLog.class): @{
                itemsKey: ^NSMutableArray *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.logItems;
                },
                spaceKey: ^ZHDPDataSpaceItem *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.logSpaceItem;
                }
        },
        NSStringFromClass(ZHDPListNetwork.class): @{
                itemsKey: ^NSMutableArray *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.networkItems;
                },
                spaceKey: ^ZHDPDataSpaceItem *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.networkSpaceItem;
                }
        },
        NSStringFromClass(ZHDPListStorage.class): @{
                itemsKey: ^NSMutableArray *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.storageItems;
                },
                spaceKey: ^ZHDPDataSpaceItem *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.storageSpaceItem;
                }
        },
        NSStringFromClass(ZHDPListMemory.class): @{
                itemsKey: ^NSMutableArray *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.memoryItems;
                },
                spaceKey: ^ZHDPDataSpaceItem *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.memorySpaceItem;
                }
        },
        NSStringFromClass(ZHDPListIM.class): @{
                itemsKey: ^NSMutableArray *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.imItems;
                },
                spaceKey: ^ZHDPDataSpaceItem *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.imSpaceItem;
                }
        },
        NSStringFromClass(ZHDPListException.class): @{
                itemsKey: ^NSMutableArray *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.exceptionItems;
                },
                spaceKey: ^ZHDPDataSpaceItem *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.exceptionSpaceItem;
                }
        }
    };
}

- (NSArray <ZHDPListSecItem *> *)fetchAllAppDataItems:(Class)listClass{
    ZHDPManager *dpMg = ZHDPMg();
    
    NSDictionary *map = [dpMg opSecItemsMap];
    NSMutableArray * (^itemsBlock) (ZHDPAppDataItem *) = [[map objectForKey:NSStringFromClass(listClass)] objectForKey:[dpMg opSecItemsMapKey_items]];
    
    if (!itemsBlock) return nil;
    
    NSMutableArray *res = [NSMutableArray array];
    NSArray <ZHDPAppDataItem *> *appDataItems = [dpMg.dataTask fetchAllAppDataItems];
    for (ZHDPAppDataItem *appDataItem in appDataItems) {
        [res addObjectsFromArray:itemsBlock(appDataItem).copy];
    }
    // 按照进入内存的时间 升序排列
    [res sortUsingComparator:^NSComparisonResult(ZHDPListSecItem *obj1, ZHDPListSecItem  *obj2) {
        if (obj1.enterMemoryTime > obj2.enterMemoryTime) {
            return NSOrderedDescending;
        }else if (obj1.enterMemoryTime < obj2.enterMemoryTime){
            return NSOrderedAscending;
        }
        return NSOrderedSame;
    }];
    return res.copy;
}
// self.window  window一旦创建就会自动显示在屏幕上
// 如果当前列表正在显示，刷新列表
- (void)addSecItemToList:(Class)listClass appItem:(ZHDPAppItem *)appItem secItem:(ZHDPListSecItem *)secItem{
    
    ZHDPManager *dpMg = ZHDPMg();
    
    NSDictionary *map = [self opSecItemsMap];
    NSMutableArray * (^itemsBlock) (ZHDPAppDataItem *) = [[map objectForKey:NSStringFromClass(listClass)] objectForKey:[self opSecItemsMapKey_items]];
    ZHDPDataSpaceItem * (^spaceBlock) (ZHDPAppDataItem *) = [[map objectForKey:NSStringFromClass(listClass)] objectForKey:[self opSecItemsMapKey_space]];
    if (!itemsBlock || !spaceBlock) {
        return;
    }
    
    // 追加到全局数据管理
    ZHDPAppDataItem *appDataItem = [dpMg.dataTask fetchAppDataItem:appItem];
    secItem.appDataItem = appDataItem;
    [dpMg.dataTask addAndCleanItems:itemsBlock(appDataItem) item:secItem spaceItem:spaceBlock(appDataItem)];
    
    // 如果当前列表正在显示，刷新列表
    if (_window && self.window.debugPanel.status == ZHDebugPanelStatus_Show) {
        ZHDPList *list = self.window.debugPanel.content.selectList;
        if ([list isKindOfClass:listClass]) {
            [list addSecItem:secItem spaceItem:spaceBlock(appDataItem)];
        }
    }
}
- (void)removeSecItemsList:(Class)listClass secItems:(NSArray <ZHDPListSecItem *> *)secItems{
    if (!secItems || ![secItems isKindOfClass:NSArray.class] || secItems.count == 0) {
        return;
    }
    NSDictionary *map = [self opSecItemsMap];
    NSMutableArray * (^itemsBlock) (ZHDPAppDataItem *) = [[map objectForKey:NSStringFromClass(listClass)] objectForKey:[self opSecItemsMapKey_items]];
    if (!itemsBlock) {
        return;
    }
    for (ZHDPListSecItem *secItem in secItems) {
        if (!secItem || ![secItem isKindOfClass:ZHDPListSecItem.class]) {
            continue;
        }
        NSMutableArray *items = itemsBlock(secItem.appDataItem);
        if (!items || ![items isKindOfClass:NSArray.class] || items.count == 0) {
            continue;
        }
        
        // 从全局数据管理中删除
        if ([items containsObject:secItem]) {
            [items removeObject:secItem];
        }
        
        // 如果当前列表正在显示，从列表中删除，刷新列表
        if (_window && self.window.debugPanel.status == ZHDebugPanelStatus_Show) {
            ZHDPList *list = self.window.debugPanel.content.selectList;
            if (1) {
                [list removeSecItem:secItem];
            }
        }
    }
}
- (void)clearSecItemsList:(Class)listClass appItem:(ZHDPAppItem *)appItem{
    NSDictionary *map = [self opSecItemsMap];
    NSMutableArray * (^itemsBlock) (ZHDPAppDataItem *) = [[map objectForKey:NSStringFromClass(listClass)] objectForKey:[self opSecItemsMapKey_items]];
    if (!itemsBlock) {
        return;
    }
    
    ZHDPManager *dpMg = ZHDPMg();
    // 是否清除所有
    BOOL isRemoveAll = (!appItem || ![appItem isKindOfClass:ZHDPAppItem.class]);
    
    // 从全局数据管理中移除数据
    NSArray <ZHDPAppDataItem *> *appDataItems = nil;
    if (isRemoveAll) {
        appDataItems = [dpMg.dataTask fetchAllAppDataItems];
    }else{
        ZHDPAppDataItem *appDataItem = [dpMg.dataTask fetchAppDataItem:appItem];
        appDataItems = (appDataItem ? @[appDataItem] : @[]);
    }
    for (ZHDPAppDataItem *appDataItem in appDataItems) {
        [dpMg.dataTask cleanAllItems:itemsBlock(appDataItem)];
    }
    
    // 如果当前列表正在显示，从列表中删除，刷新列表
    if (_window && self.window.debugPanel.status == ZHDebugPanelStatus_Show) {
        ZHDPList *list = self.window.debugPanel.content.selectList;
        if (1) {
            [list clearSecItems];
        }
    }
}

#pragma mark - getter

- (ZHDPNetworkTask *)networkTask{
    if (!_networkTask) {
        _networkTask = [[ZHDPNetworkTask alloc] init];
    }
    return _networkTask;
}

#pragma mark - share

- (instancetype)init{
    if (self = [super init]) {
        // 只加载一次的资源
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self config];
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

@implementation ZHDPManager (ZHPlatformTest)

#pragma mark - monitor

- (void)startMonitorMpLog{
}
- (void)stopMonitorMpLog{
}

- (void)zh_log{
    [ZHDPMg() zh_test_addLog];
}

#pragma mark - data

- (void)receiveImMessage:(NSNotification *)note{
    NSDictionary *info = note.userInfo;
    if (!info ||
        ![info isKindOfClass:NSDictionary.class] ||
        info.allKeys.count == 0) return;
    
    [self zh_test_addIM:@[info[@"type"]?:@"", info[@"data"] ?:@""]];
}

- (void)zh_test_addIM:(NSArray *)args{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ZHDPMg().status != ZHDPManagerStatus_Open) {
            return;
        }
        [self zh_test_addIMSafe:args];
    });
}
- (void)zh_test_addIMSafe:(NSArray *)args{
    
    ZHDPManager *dpMg = ZHDPMg();
    
    if (dpMg.status != ZHDPManagerStatus_Open) {
        return;
    }
    
//    NSArray *args = [JSContext currentArguments];
    if (!args || args.count <= 0) {
        return;
    }
    
    // 哪个应用的数据
    ZHDPAppItem *appItem = [[ZHDPAppItem alloc] init];
    appItem.appId = @"App";
    appItem.appName = @"App";
    
    // 内容
    NSInteger count = args.count;
    CGFloat freeW = [dpMg basicW] - ([dpMg marginW] * (count + 1));
    NSArray *otherPercents = @[@(0.3 * freeW / [dpMg basicW]), @(0.7 * freeW / [dpMg basicW])];
    
    // 每一行中的各个分段数据
    NSMutableArray <ZHDPListColItem *> *colItems = [NSMutableArray array];
    NSMutableArray <ZHDPListDetailItem*> *detailItems = [NSMutableArray array];
    NSMutableArray *titles = [NSMutableArray array];
    NSMutableArray *descs = [NSMutableArray array];
    
    CGFloat X = [dpMg marginW];
    for (NSUInteger i = 0; i < count; i++) {
        NSString *title = args[i];
        NSNumber *percent = otherPercents[i];
        
        __block NSString *concise = nil;
        __block NSString *detail = nil;
        [dpMg convertToString:title block:^(NSString *conciseStr, NSString *detailStr) {
            concise = conciseStr;
            detail = detailStr;
        }];
        // 添加参数
        ZHDPListColItem *colItem = [self createColItem:detail percent:percent.floatValue X:X colorType:ZHDPOutputColorType_Default];
        [colItems addObject:colItem];
        X += (colItem.rectValue.CGRectValue.size.width + [dpMg marginW]);
        
        [titles addObject:@"\n"];
        [descs addObject:detail?:@""];
    }
    
    // 弹窗详情数据
    ZHDPListDetailItem *item = [[ZHDPListDetailItem alloc] init];
    item.title = @"概要";
    item.content = [dpMg createDetailAttStr:titles descs:descs];
    [detailItems addObject:item];
        
    // 每一组中的每行数据
    ZHDPListRowItem *rowItem = [[ZHDPListRowItem alloc] init];
    rowItem.colItems = colItems.copy;
    
    // 每一组数据
    ZHDPListSecItem *secItem = [[ZHDPListSecItem alloc] init];
    secItem.enterMemoryTime = [[NSDate date] timeIntervalSince1970];
    secItem.open = YES;
    secItem.colItems = @[];
    secItem.rowItems = @[rowItem];
    secItem.detailItems = detailItems.copy;
    secItem.pasteboardBlock = ^NSString *{
        NSMutableString *str = [NSMutableString string];
        for (ZHDPListDetailItem *item in detailItems) {
            [str appendFormat:@"\n\n%@:\n%@", item.title, item.content.string];
        }
        return str;
    };
    // 添加数据
    [self addSecItemToList:ZHDPListIM.class appItem:appItem secItem:secItem];
}

- (void)zh_test_addLog{
    // 以下代码不可切换线程执行   JSContext在哪个线程  就在哪个线程执行   否则线程锁死
    NSArray *args = [JSContext currentArguments];
    NSMutableArray *res = [NSMutableArray array];
    for (JSValue *jsValue in args) {
        [res addObject:[self jsValueToNative:jsValue]?:@""];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ZHDPMg().status != ZHDPManagerStatus_Open) {
            return;
        }
        [self zh_test_addLogSafe:ZHDPOutputColorType_Default args:res.copy];
    });
}
- (void)zh_test_addLogSafe:(ZHDPOutputColorType)colorType args:(NSArray *)args{
    
    ZHDPManager *dpMg = ZHDPMg();
    
    if (dpMg.status != ZHDPManagerStatus_Open) {
        return;
    }
    
//    NSArray *args = [JSContext currentArguments];
    if (!args || args.count <= 0) {
        return;
    }
    
    // 哪个应用的数据
    ZHDPAppItem *appItem = [[ZHDPAppItem alloc] init];
    appItem.appId = @"App";
    appItem.appName = @"App";
    
    // 内容
    NSInteger count = args.count;
    CGFloat datePercent = [dpMg dateW] / [dpMg basicW];
    CGFloat freeW = ([dpMg basicW] - ([dpMg marginW] * (count + 1 + 1)) - [dpMg dateW]) * 1.0 / (count * 1.0);
    CGFloat otherPercent = freeW / [dpMg basicW];
    
    // 每一行中的各个分段数据
    NSMutableArray <ZHDPListColItem *> *colItems = [NSMutableArray array];
    NSMutableArray <ZHDPListDetailItem *> *detailItems = [NSMutableArray array];
    NSMutableArray *titles = [NSMutableArray array];
    NSMutableArray *descs = [NSMutableArray array];
    
    // 添加时间
    CGFloat X = [dpMg marginW];
    NSString *dateStr = [[dpMg dateFormat] stringFromDate:[NSDate date]];
    ZHDPListColItem *colItem = [self createColItem:dateStr percent:datePercent X:X colorType:colorType];
    [colItems addObject:colItem];
    X += (colItem.rectValue.CGRectValue.size.width + [dpMg marginW]);
    
    for (NSUInteger i = 0; i < count; i++) {
        NSString *title = args[i];
        
        __block NSString *concise = nil;
        __block NSString *detail = nil;
        [dpMg convertToString:title block:^(NSString *conciseStr, NSString *detailStr) {
            concise = conciseStr;
            detail = detailStr;
        }];
        // 添加参数
        colItem = [self createColItem:detail percent:otherPercent X:X colorType:colorType];
        [colItems addObject:colItem];
        X += (colItem.rectValue.CGRectValue.size.width + [dpMg marginW]);
        
        [titles addObject:[NSString stringWithFormat:@"%@参数%ld: \n", (i == 0 ? @"" : @"\n"), i]];
        [descs addObject:detail?:@""];
    }
    
    // 弹窗详情数据
    ZHDPListDetailItem *item = [[ZHDPListDetailItem alloc] init];
    item.title = @"参数";
    item.content = [dpMg createDetailAttStr:titles descs:descs];
    [detailItems addObject:item];
        
    // 每一组中的每行数据
    ZHDPListRowItem *rowItem = [[ZHDPListRowItem alloc] init];
    rowItem.colItems = colItems.copy;

    // 每一组数据
    ZHDPListSecItem *secItem = [[ZHDPListSecItem alloc] init];
    secItem.enterMemoryTime = [[NSDate date] timeIntervalSince1970];
    secItem.open = YES;
    secItem.colItems = @[];
    secItem.rowItems = @[rowItem];
    secItem.detailItems = detailItems.copy;
    secItem.pasteboardBlock = ^NSString *{
        NSMutableString *str = [NSMutableString string];
        [str appendString:dateStr];
        for (ZHDPListDetailItem *item in detailItems) {
            [str appendFormat:@"\n\n%@:\n%@", item.title, item.content.string];
        }
        return str;
    };
    // 添加数据
    [self addSecItemToList:ZHDPListLog.class appItem:appItem secItem:secItem];
}

- (void)zh_test_addNetwork:(NSDate *)startDate request:(NSURLRequest *)request response:(NSURLResponse *)response responseData:(NSData *)responseData{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ZHDPMg().status != ZHDPManagerStatus_Open) {
            return;
        }
        [self zh_test_addNetworkSafe:startDate request:request response:response responseData:responseData];
    });
}
- (void)zh_test_addNetworkSafe:(NSDate *)startDate request:(NSURLRequest *)request response:(NSURLResponse *)response responseData:(NSData *)responseData{
    
    ZHDPManager *dpMg = ZHDPMg();
    if (dpMg.status != ZHDPManagerStatus_Open) {
        return;
    }
    
    NSHTTPURLResponse *httpResponse = nil;
    if ([response isKindOfClass:NSHTTPURLResponse.class]) {
        httpResponse = (NSHTTPURLResponse*)response;
    }
    
    NSURL *url = request.URL;
    NSDictionary *headers = request.allHTTPHeaderFields;
    NSDictionary *responseHeaders = httpResponse.allHeaderFields;
    NSDictionary *paramsInBody = [self parseDataFromRequestBody:request.HTTPBody];
    NSDictionary *paramsInBodyStream = [self parseDataFromRequestBody:[dpMg.networkTask convertToDataByInputStream:request.HTTPBodyStream]];
    NSString *urlStr = url.absoluteString;
    NSString *host = [request valueForHTTPHeaderField:@"host"];
    if (host) {
        urlStr = [urlStr stringByReplacingOccurrencesOfString:request.URL.host withString:host];
    }

    NSMutableDictionary *paramsInUrl = [NSMutableDictionary dictionary];
    NSURLComponents *comp = [NSURLComponents componentsWithString:urlStr];
    for (NSURLQueryItem *item in comp.queryItems) {
        if (item.name.length && item.value.length) {
            [paramsInUrl setObject:item.value forKey:item.name];
        }
    }
    
    NSString *urlStrRemoveParams = url.absoluteString;
    if ([url query].length > 0) {
        urlStrRemoveParams = [urlStrRemoveParams stringByReplacingOccurrencesOfString:[url query] withString:@""];
    }
    
    NSString *method = request.HTTPMethod;
    NSString *statusCode = [NSString stringWithFormat:@"%ld",(NSInteger)httpResponse.statusCode];
    ZHDPOutputColorType colorType = ((statusCode.integerValue < 200 || statusCode.integerValue >= 300) ? ZHDPOutputColorType_Error :  ZHDPOutputColorType_Default);

    NSDate *endDate = [NSDate date];
    NSTimeInterval startTimeDouble = [startDate timeIntervalSince1970];
    NSTimeInterval endTimeDouble = [endDate timeIntervalSince1970];
    NSTimeInterval durationDouble = fabs(endTimeDouble - startTimeDouble);
//    model.startTime = [NSString stringWithFormat:@"%f", startTimeDouble];
//    model.endTime = [NSString stringWithFormat:@"%f", endTimeDouble];
    NSString *duration = [NSString stringWithFormat:@"%.3fs", durationDouble];
    
    NSString *appId = nil;
    NSString *appEnv = nil;
    NSString *appPath = nil;
    
    NSString *referer = [request valueForHTTPHeaderField:@"Referer"];
    if (referer && [referer isKindOfClass:NSString.class] &&
        referer.length > 0 && [referer containsString:@"https://mpservice.com"]) {
        NSURL *url = [NSURL URLWithString:referer];
        NSArray *coms = url.pathComponents;
        for (NSUInteger i = 0; i< coms.count; i++) {
            if (i == 1) {
                appId = coms[i];
            }else if (i == 2){
                appEnv = coms[i];
            }else if (i >= 3){
                NSMutableArray *newComs = [coms mutableCopy];
                [newComs removeObjectsInRange:NSMakeRange(0, 3)];
                appPath = [NSString pathWithComponents:newComs.copy];
                break;
            }
        }
    }
    
    // 哪个应用的数据  默认App的数据
    ZHDPAppItem *appItem = [[ZHDPAppItem alloc] init];
    appItem.appId = @"App";
    appItem.appName =  @"App";
    
    NSArray *args = @[urlStrRemoveParams?:@"", method?:@"", statusCode?:@"", duration?:@""];
    // 内容
    NSInteger count = args.count;
    CGFloat freeW = [dpMg basicW] - ([dpMg marginW] * (count + 1));
    NSArray *otherPercents = @[@(0.65 * freeW / [dpMg basicW]), @(0.10 * freeW / [dpMg basicW]), @(0.10 * freeW / [dpMg basicW]), @(0.15 * freeW / [dpMg basicW])];
    
    // 每一行中的各个分段数据
    NSMutableArray <ZHDPListColItem *> *colItems = [NSMutableArray array];
    
    CGFloat X = [dpMg marginW];
    for (NSUInteger i = 0; i < count; i++) {
        NSString *title = args[i];
        NSNumber *percent = otherPercents[i];
        
        __block NSString *concise = nil;
        __block NSString *detail = nil;
        [dpMg convertToString:title block:^(NSString *conciseStr, NSString *detailStr) {
            concise = conciseStr;
            detail = detailStr;
        }];
        // 添加参数
        ZHDPListColItem *colItem = [self createColItem:detail percent:percent.floatValue X:X colorType:colorType];
        [colItems addObject:colItem];
        X += (colItem.rectValue.CGRectValue.size.width + [dpMg marginW]);
    }

    // 弹窗详情数据
    NSMutableArray <ZHDPListDetailItem *> *detailItems = [NSMutableArray array];
    ZHDPListDetailItem *item = [[ZHDPListDetailItem alloc] init];
    NSArray *titles = @[@"URL: ", @"\nMethod: ", @"\nStatus Code: ", @"\nStart Time: ", @"\nEnd Time: ", @"\nDuration:"];
    NSArray *descs = @[urlStr?:@"",
                       method?:@"",
                       statusCode?:@"",
                       [[dpMg dateByFormat:@"yyyy-MM-dd HH:mm:ss.SSS"] stringFromDate:startDate]?:@"",
                       [[dpMg dateByFormat:@"yyyy-MM-dd HH:mm:ss.SSS"] stringFromDate:endDate]?:@"",
                       duration?:@""];
    
    item.title = @"概要";
    item.content = [dpMg createDetailAttStr:titles descs:descs];
    [detailItems addObject:item];
    
    item = [[ZHDPListDetailItem alloc] init];
    titles = @[@"Request Query (In URL): \n", @"\nRequest Query (In Body): \n", @"\nRequest Query (In BodyStream): \n"];
    descs = @[
        (^NSString *(){
            if (paramsInUrl.allKeys.count == 0) {
                return @"";
            }
            return [self jsonToString:paramsInUrl]?:@"";
        })(),
        (^NSString *(){
            __block NSString *res = nil;
            [self convertToString:paramsInBody block:^(NSString *conciseStr, NSString *detailStr) {
                res = detailStr;
            }];
            return res?:@"";
        })(),
        (^NSString *(){
            __block NSString *res = nil;
            [self convertToString:paramsInBodyStream block:^(NSString *conciseStr, NSString *detailStr) {
                res = detailStr;
            }];
            return res?:@"";
        })()];
    item.title = @"参数";
    item.content = [dpMg createDetailAttStr:titles descs:descs];
    [detailItems addObject:item];
    
    item = [[ZHDPListDetailItem alloc] init];
    titles = @[@"Response Data: \n"];
    descs = @[
        (^NSString *(){
            if (!responseData) {
                return @"";
            }
            id obj = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingFragmentsAllowed error:nil];
            if (!obj) {
                return @"";
            }
            __block NSString *res = nil;
            [self convertToString:obj block:^(NSString *conciseStr, NSString *detailStr) {
                res = detailStr;
            }];
            return res?:@"";
        })()
       ];
    item.title = @"数据";
    item.content = [dpMg createDetailAttStr:titles descs:descs];
    [detailItems addObject:item];
    
    item = [[ZHDPListDetailItem alloc] init];
    titles = @[@"Request Headers: \n"];
    descs = @[
        [self jsonToString:headers?:@{}]?:@""
       ];
    item.title = @"请求头";
    item.content = [dpMg createDetailAttStr:titles descs:descs];
    [detailItems addObject:item];
    
    item = [[ZHDPListDetailItem alloc] init];
    titles = @[@"Response Headers: \n"];
    descs = @[
        [self jsonToString:responseHeaders?:@{}]?:@"",
       ];
    item.title = @"响应头";
    item.content = [dpMg createDetailAttStr:titles descs:descs];
    [detailItems addObject:item];
    
    item = [[ZHDPListDetailItem alloc] init];
    item.title = @"小程序";
    titles = @[@"小程序信息: \n"].mutableCopy;
        
    descs = @[[self jsonToString:@{@"appName": appItem.appName?:@"", @"appId": appItem.appId?:@""}]?:@""].mutableCopy;
    item.content = [dpMg createDetailAttStr:titles descs:descs];
    [detailItems addObject:item];
    
    // 每一组中的每行数据
    ZHDPListRowItem *rowItem = [[ZHDPListRowItem alloc] init];
    rowItem.colItems = colItems.copy;

    // 每一组数据
    ZHDPListSecItem *secItem = [[ZHDPListSecItem alloc] init];
    secItem.enterMemoryTime = [[NSDate date] timeIntervalSince1970];
    secItem.open = YES;
    secItem.colItems = @[];
    secItem.rowItems = @[rowItem];
    secItem.detailItems = detailItems.copy;
    secItem.pasteboardBlock = ^NSString *{
        NSMutableString *str = [NSMutableString string];
        for (ZHDPListDetailItem *item in detailItems) {
            [str appendFormat:@"\n\n%@:\n%@", item.title, item.content.string];
        }
        return str;
    };
    // 添加数据
    [self addSecItemToList:ZHDPListNetwork.class appItem:appItem secItem:secItem];
}

- (void)zh_test_reloadStorage{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ZHDPMg().status != ZHDPManagerStatus_Open) {
            return;
        }
        [self zh_test_reloadStorageSafe];
    });
}
- (void)zh_test_reloadStorageSafe{
    ZHDPManager *dpMg = ZHDPMg();
    
    // 从全局数据管理中移除所有storage数据
    NSArray <ZHDPAppDataItem *> *appDataItems = [dpMg.dataTask fetchAllAppDataItems];
    for (ZHDPAppDataItem *appDataItem in appDataItems) {
        [dpMg.dataTask cleanAllItems:appDataItem.storageItems];
    }
    
    // 读取storage数据
    NSArray *arr = @[
        @{@"test": @"ffffffffffffff"}
    ];
    for (NSDictionary *info in arr) {
        // 载入新数据
        [self zh_test_addStorageSafe:info];
    }
    
}
- (void)zh_test_addStorageSafe:(NSDictionary *)storage{
    ZHDPManager *dpMg = ZHDPMg();
    
    if (dpMg.status != ZHDPManagerStatus_Open) {
        return;
    }
    
    if (!storage || ![storage isKindOfClass:NSDictionary.class] || storage.allKeys.count == 0) {
        return;
    }
    
    [storage enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        [self zh_test_addStorageSafeSingle:@[key, obj]];
    }];
}
- (void)zh_test_addStorageSafeSingle:(NSArray *)args{
    ZHDPManager *dpMg = ZHDPMg();
    
    // 哪个应用的数据
    ZHDPAppItem *appItem = [[ZHDPAppItem alloc] init];
    appItem.appId = @"App";
    appItem.appName = @"App";
    
    // 内容
    NSInteger count = args.count;
    CGFloat freeW = [dpMg basicW] - ([dpMg marginW] * (count + 1));
    NSArray *otherPercents = @[@(0.3 * freeW / [dpMg basicW]), @(0.7 * freeW / [dpMg basicW])];
    
    // 每一行中的各个分段数据
    NSMutableArray <ZHDPListColItem *> *colItems = [NSMutableArray array];
    NSMutableArray *descs = [NSMutableArray array];
        
    CGFloat X = [dpMg marginW];
    for (NSUInteger i = 0; i < count; i++) {
        NSString *title = args[i];
        NSNumber *percent = otherPercents[i];
        
        __block NSString *concise = nil;
        __block NSString *detail = nil;
        [dpMg convertToString:title block:^(NSString *conciseStr, NSString *detailStr) {
            concise = conciseStr;
            detail = detailStr;
        }];
        // 添加参数
        ZHDPListColItem *colItem = [self createColItem:detail percent:percent.floatValue X:X colorType:ZHDPOutputColorType_Default];
        [colItems addObject:colItem];
        X += (colItem.rectValue.CGRectValue.size.width + [dpMg marginW]);
        
        if (detail) [descs addObject:detail];
    }
    
    // 弹窗详情数据
    NSMutableArray <ZHDPListDetailItem *> *detailItems = [NSMutableArray array];
    ZHDPListDetailItem *item = [[ZHDPListDetailItem alloc] init];
    item.title = @"数据";
    NSArray *titles = @[@"Key: \n", @"\nValue: \n"];
    item.content = [dpMg createDetailAttStr:titles descs:descs];
    [detailItems addObject:item];
        
    // 每一组中的每行数据
    ZHDPListRowItem *rowItem = [[ZHDPListRowItem alloc] init];
    rowItem.colItems = colItems.copy;

    // 每一组数据
    ZHDPListSecItem *secItem = [[ZHDPListSecItem alloc] init];
    secItem.enterMemoryTime = [[NSDate date] timeIntervalSince1970];
    secItem.open = YES;
    secItem.colItems = @[];
    secItem.rowItems = @[rowItem];
    secItem.detailItems = detailItems.copy;
    secItem.pasteboardBlock = ^NSString *{
        NSMutableString *str = [NSMutableString string];
        for (ZHDPListDetailItem *item in detailItems) {
            [str appendFormat:@"\n%@:\n%@", item.title, item.content.string];
        }
        return str;
    };
    // 添加数据
    [self addSecItemToList:ZHDPListStorage.class appItem:appItem secItem:secItem];
}

- (void)zh_test_reloadMemory{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ZHDPMg().status != ZHDPManagerStatus_Open) {
            return;
        }
        [self zh_test_reloadMemorySafe];
    });
}
- (void)zh_test_reloadMemorySafe{
    ZHDPManager *dpMg = ZHDPMg();
    
    // 从全局数据管理中移除所有Memory数据
    NSArray <ZHDPAppDataItem *> *appDataItems = [dpMg.dataTask fetchAllAppDataItems];
    for (ZHDPAppDataItem *appDataItem in appDataItems) {
        [dpMg.dataTask cleanAllItems:appDataItem.memoryItems];
    }
    // 载入新数据
    [self zh_test_addMemorySafe];
    
}
- (void)zh_test_addMemorySafe{
    ZHDPManager *dpMg = ZHDPMg();
    
    if (dpMg.status != ZHDPManagerStatus_Open) {
        return;
    }
    /*
     获取到的memory
     {
         key: {
             source: {
                 appId: xxx
             }
             data: data
         }
     }
     */
    NSDictionary *memory = @{@"abc": @{@"data": @"数据", @"source": @{@"appId": @"App"}}};
    if (!memory || ![memory isKindOfClass:NSDictionary.class] || memory.allKeys.count == 0) {
        return;
    }
    [memory enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *map, BOOL * stop1) {
        id data = [map objectForKey:@"data"];
        NSString *appId = [[map objectForKey:@"source"] objectForKey:@"appId"];
        [self zh_test_addMemorySafeSingle:appId args:@[key, data?:@""]];
    }];
}
- (void)zh_test_addMemorySafeSingle:(NSString *)appId args:(NSArray *)args{
    ZHDPManager *dpMg = ZHDPMg();
    
    // 哪个应用的数据
    ZHDPAppItem *appItem = [[ZHDPAppItem alloc] init];
    appItem.appId = appId ?: @"App";
    appItem.appName = @"App";
    
    // 内容
    NSInteger count = args.count;
    CGFloat freeW = [dpMg basicW] - ([dpMg marginW] * (count + 1));
    NSArray *otherPercents = @[@(0.3 * freeW / [dpMg basicW]), @(0.7 * freeW / [dpMg basicW])];
    
    // 每一行中的各个分段数据
    NSMutableArray <ZHDPListColItem *> *colItems = [NSMutableArray array];
    NSMutableArray *descs = [NSMutableArray array];
        
    CGFloat X = [dpMg marginW];
    for (NSUInteger i = 0; i < count; i++) {
        NSString *title = args[i];
        NSNumber *percent = otherPercents[i];
        
        __block NSString *concise = nil;
        __block NSString *detail = nil;
        [dpMg convertToString:title block:^(NSString *conciseStr, NSString *detailStr) {
            concise = conciseStr;
            detail = detailStr;
        }];
        // 添加参数
        ZHDPListColItem *colItem = [self createColItem:detail percent:percent.floatValue X:X colorType:ZHDPOutputColorType_Default];
        [colItems addObject:colItem];
        X += (colItem.rectValue.CGRectValue.size.width + [dpMg marginW]);
        
        if (detail) [descs addObject:detail];
    }
    
    // 弹窗详情数据
    NSMutableArray <ZHDPListDetailItem *> *detailItems = [NSMutableArray array];
    ZHDPListDetailItem *item = [[ZHDPListDetailItem alloc] init];
    item.title = @"数据";
    NSArray *titles = @[@"Key: \n", @"\nValue: \n"];
    item.content = [dpMg createDetailAttStr:titles descs:descs];
    [detailItems addObject:item];
        
    // 每一组中的每行数据
    ZHDPListRowItem *rowItem = [[ZHDPListRowItem alloc] init];
    rowItem.colItems = colItems.copy;
    
    // 每一组数据
    ZHDPListSecItem *secItem = [[ZHDPListSecItem alloc] init];
    secItem.enterMemoryTime = [[NSDate date] timeIntervalSince1970];
    secItem.open = YES;
    secItem.colItems = @[];
    secItem.rowItems = @[rowItem];
    secItem.detailItems = detailItems.copy;
    secItem.pasteboardBlock = ^NSString *{
        NSMutableString *str = [NSMutableString string];
        for (ZHDPListDetailItem *item in detailItems) {
            [str appendFormat:@"\n%@:\n%@", item.title, item.content.string];
        }
        return str;
    };
    // 添加数据
    [self addSecItemToList:ZHDPListMemory.class appItem:appItem secItem:secItem];
}

- (void)zh_test_addException:(NSString *)title stack:(NSString *)stack{
    if (!title || ![title isKindOfClass:NSString.class] || title.length == 0) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ZHDPMg().status != ZHDPManagerStatus_Open) {
            return;
        }
        ZHDPOutputColorType type = ZHDPOutputColorType_Error;
        [self zh_test_addExceptionSafe:@"App" colorType:type args:@[title] stack:stack];
    });
}
- (void)zh_test_addExceptionSafe:(NSString *)appId colorType:(ZHDPOutputColorType)colorType args:(NSArray *)args stack:(NSString *)stack{
    ZHDPManager *dpMg = ZHDPMg();
    
    if (dpMg.status != ZHDPManagerStatus_Open) {
        return;
    }
    
    if (!args || args.count <= 0) {
        return;
    }
    
    // 哪个应用的数据
    ZHDPAppItem *appItem = [[ZHDPAppItem alloc] init];
    appItem.appId = appId ?: @"App";
    appItem.appName = @"App";
    
    // 内容
    NSInteger count = args.count;
    CGFloat datePercent = [dpMg dateW] / [dpMg basicW];
    CGFloat freeW = ([dpMg basicW] - ([dpMg marginW] * (count + 1 + 1)) - [dpMg dateW]) * 1.0 / (count * 1.0);
    CGFloat otherPercent = freeW / [dpMg basicW];
    
    // 每一行中的各个分段数据
    NSMutableArray <ZHDPListColItem *> *colItems = [NSMutableArray array];
    NSMutableArray <ZHDPListDetailItem *> *detailItems = [NSMutableArray array];
    NSMutableArray *descs = [NSMutableArray array];
    
    // 添加时间
    CGFloat X = [dpMg marginW];
    NSString *dateStr = [[dpMg dateFormat] stringFromDate:[NSDate date]];
    ZHDPListColItem *colItem = [self createColItem:dateStr percent:datePercent X:X colorType:colorType];
    [colItems addObject:colItem];
    X += (colItem.rectValue.CGRectValue.size.width + [dpMg marginW]);
    
    for (NSUInteger i = 0; i < count; i++) {
        NSString *title = args[i];
        
        __block NSString *concise = nil;
        __block NSString *detail = nil;
        [dpMg convertToString:title block:^(NSString *conciseStr, NSString *detailStr) {
            concise = conciseStr;
            detail = detailStr;
        }];
        // 添加参数
        colItem = [self createColItem:detail percent:otherPercent X:X colorType:colorType];
        [colItems addObject:colItem];
        X += (colItem.rectValue.CGRectValue.size.width + [dpMg marginW]);
        
        [descs addObject:detail?:@""];
    }
    
    // 弹窗详情数据
    ZHDPListDetailItem *item = [[ZHDPListDetailItem alloc] init];
    item.title = @"简要";
    item.content = [dpMg createDetailAttStr:@[@"message: \n"] descs:descs];
    [detailItems addObject:item];
    
    item = [[ZHDPListDetailItem alloc] init];
    item.title = @"调用栈";
    item.content = [dpMg createDetailAttStr:@[@"stacktrace: \n"] descs:@[stack?:@""]];
    [detailItems addObject:item];
        
    // 每一组中的每行数据
    ZHDPListRowItem *rowItem = [[ZHDPListRowItem alloc] init];
    rowItem.colItems = colItems.copy;
    
    // 每一组数据
    ZHDPListSecItem *secItem = [[ZHDPListSecItem alloc] init];
    secItem.enterMemoryTime = [[NSDate date] timeIntervalSince1970];
    secItem.open = YES;
    secItem.colItems = @[];
    secItem.rowItems = @[rowItem];
    secItem.detailItems = detailItems.copy;
    secItem.pasteboardBlock = ^NSString *{
        NSMutableString *str = [NSMutableString string];
        [str appendString:dateStr];
        for (ZHDPListDetailItem *item in detailItems) {
            [str appendFormat:@"\n\n%@:\n%@", item.title, item.content.string];
        }
        return str;
    };
    
    // 添加数据
    [self addSecItemToList:ZHDPListException.class appItem:appItem secItem:secItem];
}
@end

