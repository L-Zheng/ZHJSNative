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
@property (nonatomic,strong) UIButton *keyboardBtn;
@property (nonatomic,strong) UIButton *closeBtn;
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
    
    CGFloat H = self.bounds.size.height * 0.5;
    CGFloat W = [[self.closeBtn titleForState:UIControlStateNormal] boundingRectWithSize:CGSizeMake(self.bounds.size.width, H) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: self.closeBtn.titleLabel.font} context:nil].size.width + 10;
    CGFloat X = self.bounds.size.width - W - 10;
    CGFloat Y = (self.bounds.size.height - H) * 0.5;
    self.closeBtn.frame = CGRectMake(X, Y, W, H);
    
    Y = (self.bounds.size.height - H) * 0.5;
    H = self.bounds.size.height * 0.5;
    W = [[self.keyboardBtn titleForState:UIControlStateNormal] boundingRectWithSize:CGSizeMake(self.bounds.size.width, H) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: self.keyboardBtn.titleLabel.font} context:nil].size.width + 10;
    X = self.closeBtn.frame.origin.x - W - 10;
    self.keyboardBtn.frame = CGRectMake(X, Y, W, H);

    X = 0;
    Y = 0;
    H = self.bounds.size.height;
    W = H;
    self.searchIcon.frame = CGRectMake(X, Y, W, H);
    
    X = CGRectGetMaxX(self.searchIcon.frame) + 0;
    Y = 0;
    W = self.keyboardBtn.frame.origin.x - 5 - X;
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
    [self addSubview:self.closeBtn];
    [self addSubview:self.keyboardBtn];
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

- (void)becomeFirstResponder{
    [self.field becomeFirstResponder];
}
- (void)resignFirstResponder{
    [self.field resignFirstResponder];
}
- (BOOL)isFirstResponder{
    return [self.field isFirstResponder];
}

#pragma mark - click

- (void)keyboardBtnClick{
    [self resignFirstResponder];
}

- (void)closeBtnClick{
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
- (UIButton *)keyboardBtn{
    if (!_keyboardBtn) {
        _keyboardBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        [_keyboardBtn setTitle:@"收起键盘" forState:UIControlStateNormal];
        [_keyboardBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        _keyboardBtn.titleLabel.font = [ZHDPMg() defaultFont];
        _keyboardBtn.layer.borderColor = [UIColor blackColor].CGColor;
        _keyboardBtn.layer.borderWidth = [ZHDPMg() defaultLineW];
        _keyboardBtn.layer.cornerRadius = 5.0;
        _keyboardBtn.layer.masksToBounds = YES;
        _keyboardBtn.clipsToBounds = YES;
        [_keyboardBtn addTarget:self action:@selector(keyboardBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _keyboardBtn;
}
- (UIButton *)closeBtn{
    if (!_closeBtn) {
        _closeBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        [_closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
        [_closeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        _closeBtn.titleLabel.font = [ZHDPMg() defaultFont];
        _closeBtn.layer.borderColor = [UIColor blackColor].CGColor;
        _closeBtn.layer.borderWidth = [ZHDPMg() defaultLineW];
        _closeBtn.layer.cornerRadius = 5.0;
        _closeBtn.layer.masksToBounds = YES;
        _closeBtn.clipsToBounds = YES;
        [_closeBtn addTarget:self action:@selector(closeBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

@end
