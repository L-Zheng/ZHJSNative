//
//  ZHJSApiListController.m
//  ZHJSNative
//
//  Created by Zheng on 2021/3/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHJSApiListController.h"
#import "ZHJSApiHandler.h"
#import "ZHJSInWebSocketApi.h"

@interface ZHJSApiListController ()<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic, weak) ZHJSApiHandler *apiHandler;

@property (nonatomic,strong) UITextField *field;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,retain) NSArray *items;
@end

@implementation ZHJSApiListController


- (instancetype)initWithApiHandler:(ZHJSApiHandler *)apiHandler{
    self = [super init];
    if (self) {
        self.apiHandler = apiHandler;
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"原生注入的API";
    self.navigationController.navigationBar.translucent = NO;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(closeClick)];
    
    if (@available(iOS 11.0, *)){
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    }else{
        self.automaticallyAdjustsScrollViewInsets = YES;
    }
    self.tableView.tableFooterView = [UIView new];
    [self.view addSubview:self.tableView];
    
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectZero];
    field.placeholder = @"在此输入检索API";
//    field.borderStyle = UITextBorderStyleLine;
    field.clearButtonMode = UITextFieldViewModeAlways;
    self.field = field;
    [self.view addSubview:field];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldChange) name:UITextFieldTextDidChangeNotification object:nil];
    
    [self loadData:nil];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    CGFloat h = 40;
    self.field.frame = CGRectMake(10, 0, self.view.bounds.size.width - 10, h);
    self.tableView.frame = CGRectMake(0, h, self.view.bounds.size.width, self.view.bounds.size.height - h);
}

- (void)closeClick{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
- (void)clickHeader:(UITapGestureRecognizer *)tap{
    UIView *view = tap.view;
    NSMutableDictionary *item = self.items[view.tag];
    BOOL open = [item[@"open"] boolValue];
    [item setValue:@(!open) forKey:@"open"];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:view.tag] withRowAnimation:(UITableViewRowAnimationAutomatic)];
}

- (void)textFieldChange{
    if (!self.field.text) return;
    [self loadData:self.field.text];
}

- (void)loadData:(NSString *)keyword{
    if (!self.apiHandler) return;
    
    // 过滤私有api
    NSMutableArray *privateApis = [NSMutableArray array];
    ZHJSInWebSocketApi *socketApi = [[ZHJSInWebSocketApi alloc] init];
    if ([socketApi conformsToProtocol:@protocol(ZHJSApiProtocol)] &&
        [socketApi respondsToSelector:@selector(zh_jsApiPrefixName)]) {
            NSString *jsPrefix = [socketApi zh_jsApiPrefixName];
        if (jsPrefix) [privateApis addObject:jsPrefix];
    }
    
    
//    @{
//        @"fund" : @{
//                @"getSystemInfoSync" : ZHJSApiRegisterItem
//        }
//    }
//    @[
//        @{
//            @"funcPre": @"fund",
//            @"subItems": @[
//                    @{
//                        @"funcName": @"getSystemInfoSync",
//                        @"funcItem": ZHJSApiRegisterItem
//                    }
//            ]
//        }
//    ]
    NSMutableArray *res = [NSMutableArray array];
    [self.apiHandler enumRegsiterApiMap:^(NSString *apiPrefix, NSDictionary<NSString *,ZHJSApiRegisterItem *> *apiMap) {
        
        NSMutableArray *subItems = [NSMutableArray array];
        [apiMap enumerateKeysAndObjectsUsingBlock:^(NSString * key, ZHJSApiRegisterItem *obj, BOOL *stop) {
            if (key.length == 0 || !obj) return;
            if (keyword.length > 0) {
                if (![key.lowercaseString containsString:keyword.lowercaseString]) return;
            }
            [subItems addObject:@{
                @"funcName": key,
                @"funcItem": obj
            }];
        }];
        
        if (subItems.count > 0 && ![privateApis containsObject:apiPrefix]) {
            [res addObject:@{
                @"open": @(YES),
                @"funcPre": apiPrefix?:@"",
                @"subItems": subItems.copy
            }.mutableCopy];
        }
    }];
    
    self.items = res.copy;
    
    
    UILabel *foot = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
    foot.textAlignment = NSTextAlignmentCenter;
    foot.text = @"无内容";
    self.tableView.tableFooterView = res.count > 0 ? [UIView new] : foot;
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.items.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    NSDictionary *item = self.items[section];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)];
    view.backgroundColor = [UIColor colorWithRed:229.0/255.0 green:229.0/255.0 blue:229.0/255.0 alpha:1.0];
    view.tag = section;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickHeader:)];
    [view addGestureRecognizer:tap];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(13, 0, view.bounds.size.width - 13, view.bounds.size.height)];
    label.text = [NSString stringWithFormat:@"%@ %@", [item[@"open"] boolValue] ? @"▼" : @"▶", item[@"funcPre"]];
    [view addSubview:label];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 30;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSDictionary *item = self.items[section];
    BOOL open = [item[@"open"] boolValue];
    if (!open) return 0;
    NSArray *subItems = item[@"subItems"];
    return subItems.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSAttributedString *attStr = [self fetchText:indexPath];
    return [attStr boundingRectWithSize:CGSizeMake(self.view.bounds.size.width - 30, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size.height + 15;
}

- (NSAttributedString *)fetchText:(NSIndexPath *)indexPath{
    
    NSDictionary *item = self.items[indexPath.section];
    NSArray *subItems = item[@"subItems"];
    NSDictionary *subItem = subItems[indexPath.row];
    
    
    ZHJSApiRegisterItem *registerItem = subItem[@"funcItem"];
    
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] init];
    
    NSArray *strings = @[
        @"JsFunc:  ", [NSString stringWithFormat:@"%@ (%@)", subItem[@"funcName"], registerItem.isSync ? @"同步函数" : @"异步函数"], @"\n",
        @"iOSFunc:  ", registerItem.nativeMethodName?:@"", @"\n",
        @"iOSInstance:  ", [NSString stringWithFormat:@"<%@: %p>", NSStringFromClass([registerItem.nativeInstance class]), registerItem.nativeInstance], @"\n",
        @"iOSClassName:  ", registerItem.nativeMethodInClassName?:@"",
    ];
    
    NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
    paraStyle.lineSpacing = 5.0;
    
    UIColor *textColor = nil;
    for (NSInteger i = 0; i< strings.count; i++) {
        NSInteger resIdx = i % 3;
        if (resIdx == 1){
            textColor = [UIColor grayColor];
        }else{
            textColor = [UIColor blackColor];
        }
        if (i == 1) {
            textColor = [UIColor colorWithRed:32.0/255.0 green:137.0/255.0 blue:1.0 alpha:1.0];
        }
        [attStr appendAttributedString:[[NSAttributedString alloc] initWithString:strings[i] attributes:@{
            NSForegroundColorAttributeName: textColor,
            NSFontAttributeName : i == 1 ? [UIFont boldSystemFontOfSize:17] : [UIFont systemFontOfSize:17],
            NSParagraphStyleAttributeName: paraStyle
        }]];
    }
    return attStr;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellID = @"BaseCellId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.attributedText = [self fetchText:indexPath];
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self.view endEditing:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - getter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        
        _tableView.directionalLockEnabled = YES;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    return _tableView;
}

@end
