//
//  ZHDebugPanelSearch.m
//  ZHJSNative
//
//  Created by Zheng on 2021/4/18.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDebugPanelSearch.h"

@interface ZHDebugPanelSearch ()
@property (nonatomic, strong) UITextField *textField;
@end

@implementation ZHDebugPanelSearch

#pragma mark - init

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configData];
        [self configUI];
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - config

- (void)configData{
}

- (void)configUI{
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor greenColor];
    
    [self addSubview:self.textField];
}

#pragma mark - notification

- (void)addNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldChange) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)textFieldChange{
    if (self.textFieldChangeBlock) {
        self.textFieldChangeBlock(self.textField.text);
    }
}

#pragma mark - layout

- (void)layoutSubviews{
    [super layoutSubviews];
    
    self.textField.frame = self.bounds;
}

#pragma mark - getter

- (UITextField *)textField{
    if (!_textField) {
        _textField = [[UITextField alloc] initWithFrame:CGRectZero];
        _textField.placeholder = @"在此输入以检索";
        //    _textField.borderStyle = UITextBorderStyleLine;
        _textField.clearButtonMode = UITextFieldViewModeAlways;
    }
    return _textField;
}

@end
