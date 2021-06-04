//
//  ZHDPListSearch.m
//  ZHJSNative
//
//  Created by EM on 2021/5/28.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListSearch.h"
#import "ZHDPList.h"// 列表
#import "ZHDPManager.h"// 调试面板管理

@interface ZHDPListSearch ()
@property (nonatomic,strong) UILabel *searchIcon;
@property (nonatomic,strong) UITextField *field;
@property (nonatomic,strong) UIButton *btn;
@end

@implementation ZHDPListSearch

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
    
    CGFloat W = 40;
    CGFloat H = self.bounds.size.height * 0.5;
    CGFloat X = self.bounds.size.width - W - 10;
    CGFloat Y = (self.bounds.size.height - H) * 0.5;
    self.btn.frame = CGRectMake(X, Y, W, H);
    
    X = 0;
    Y = 0;
    H = self.bounds.size.height;
    W = H;
    self.searchIcon.frame = CGRectMake(X, Y, W, H);
    
    X = CGRectGetMaxX(self.searchIcon.frame) + 0;
    Y = 0;
    W = self.btn.frame.origin.x - X;
    H = self.bounds.size.height;
    self.field.frame = CGRectMake(X, Y, W, H);
}
- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
    BOOL show = self.superview;
    if (!show) return;
}
- (void)didMoveToSuperview{
    [super didMoveToSuperview];
}
- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - config

- (void)configData{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldChange:) name:UITextFieldTextDidChangeNotification object:self.field];
}
- (void)configUI{
    self.clipsToBounds = YES;
    self.layer.masksToBounds = YES;
    self.backgroundColor = [UIColor clearColor];
    
    [self addSubview:self.searchIcon];
    [self addSubview:self.field];
    [self addSubview:self.btn];
}

#pragma mark - field

- (void)textFieldChange:(NSNotification *)note{
    if (![note.object isEqual:self.field]) return;
    NSString *keyWord = self.field.text;
    if (!keyWord) return;
    
    self.keyWord = keyWord;
    if (self.fieldChangeBlock) {
        self.fieldChangeBlock(keyWord);
    }
}

#pragma mark - click

- (void)btnClick{
    [self.field resignFirstResponder];
    self.keyWord = @"";
    self.field.text = self.keyWord;
    [self.list hideSearch];
}

#pragma mark - getter

- (UILabel *)searchIcon {
    if (!_searchIcon) {
        _searchIcon = [[UILabel alloc] initWithFrame:CGRectZero];
        _searchIcon.font = [ZHDPMg() iconFontWithSize:15];
        _searchIcon.adjustsFontSizeToFitWidth = YES;
        _searchIcon.textAlignment = NSTextAlignmentCenter;
        _searchIcon.backgroundColor = [UIColor clearColor];
        _searchIcon.text = @"\ue609";
    }
    return _searchIcon;
}
- (UITextField *)field{
    if (!_field) {
        _field = [[UITextField alloc] initWithFrame:CGRectZero];
        _field.clipsToBounds = YES;
        _field.layer.masksToBounds = YES;
        _field.placeholder = @"输入以查找";
        //    _field.borderStyle = UITextBorderStyleLine;
        _field.clearButtonMode = UITextFieldViewModeAlways;
        _field.font = [ZHDPMg() defaultFont];
        _field.textColor = [UIColor blackColor];
    }
    return _field;
}
- (UIButton *)btn{
    if (!_btn) {
        _btn = [[UIButton alloc] initWithFrame:CGRectZero];
        [_btn setTitle:@"关闭" forState:UIControlStateNormal];
        [_btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        _btn.titleLabel.font = [ZHDPMg() defaultFont];
        _btn.layer.borderColor = [UIColor blackColor].CGColor;
        _btn.layer.borderWidth = [ZHDPMg() defaultLineW];
        _btn.layer.cornerRadius = 5.0;
        _btn.layer.masksToBounds = YES;
        _btn.clipsToBounds = YES;
        [_btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btn;
}

@end
