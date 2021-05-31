//
//  ZHDebugPanel.m
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDebugPanel.h"
#import "ZHDPOption.h"
#import "ZHDPContent.h"
#import "ZHDPList.h"
#import "ZHDPDataTask.h"

@interface ZHDebugPanel ()
@end

@implementation ZHDebugPanel

#pragma mark - override

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configData];
        [self configUI];
    }
    return self;
}
- (void)layoutSubviews{
    [super layoutSubviews];
    
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
    
    CGFloat marginTop = 5;
    CGFloat marginBottom = safeAreaInsets.bottom + 5;
    
    self.option.frame = CGRectMake(0, marginTop, self.bounds.size.width, 30);
    
    CGFloat contentY = CGRectGetMaxY(self.option.frame) + marginTop;
    CGFloat contentH = self.bounds.size.height - contentY - marginBottom;
    self.content.frame = CGRectMake(0, contentY, self.bounds.size.width, contentH);
}
- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
}
- (void)didMoveToSuperview{
    BOOL show = self.superview;
    self.status = show ? ZHDebugPanelStatus_Show : ZHDebugPanelStatus_Hide;
    
    if (!show) return;
    [self reloadAndSelectOptionOnlyOnce:0];
    
    if (self.content.selectList) {
        [self.content.selectList reloadListWhenShow];
    }
}

#pragma mark - config

- (void)configData{
}
- (void)configUI{
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor colorWithRed:243.0/255.0 green:243.0/255.0 blue:243.0/255.0 alpha:1.0];
    
    [self addSubview:self.option];
    [self addSubview:self.content];
}

#pragma mark - option

- (void)selectOption:(NSInteger)idx{
    [self.option selectIndexPath:[NSIndexPath indexPathForItem:idx inSection:0]];
}
- (void)reloadAndSelectOptionOnlyOnce:(NSInteger)idx{
    if (self.option.selectItem) return;
    [self reloadAndSelectOption:idx];
}
- (void)reloadAndSelectOption:(NSInteger)idx{
    NSMutableArray <ZHDPOptionItem *> *items = [NSMutableArray array];
    
    NSArray <ZHDPList *> *lists = [self.content allLists];
    for (ZHDPList *list in lists) {
        ZHDPOptionItem *item = [[ZHDPOptionItem alloc] init];
        item.title = list.item.title;
        item.selected = NO;
        item.list = list;
        
        [items addObject:item];
    }
    
    [self.option reloadWithItems:items.copy];
    [self selectOption:idx];
}

#pragma mark - content

#pragma mark - getter

- (ZHDPOption *)option{
    if (!_option) {
        _option = [[ZHDPOption alloc] initWithFrame:CGRectZero];
        __weak __typeof__(self) weakSelf = self;
        _option.selectBlock = ^(NSIndexPath *indexPath, ZHDPOptionItem *item) {
            [weakSelf.content selectList:item.list];
        };
        _option.debugPanel = self;
    }
    return _option;
}
- (ZHDPContent *)content{
    if (!_content) {
        _content = [[ZHDPContent alloc] initWithFrame:CGRectZero];
        _content.debugPanel = self;
    }
    return _content;
}
@end
