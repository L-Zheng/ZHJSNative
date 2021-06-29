//
//  ViewController.m
//  ZHJSNative
//
//  Created by Zheng on 2020/2/22.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ViewController.h"
#import "ZHController.h"
#import "ZHWebViewManager.h"
#import "ZHJSWebTestController.h"
#import <ZHDebugPanel/ZHDPManager.h>

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,retain) NSArray *items;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"示例";
    self.navigationController.navigationBar.translucent = NO;
        
    if (@available(iOS 11.0, *)){
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    }else{
        self.automaticallyAdjustsScrollViewInsets = YES;
    }
    self.tableView.tableFooterView = [UIView new];
    [self.view addSubview:self.tableView];
    
    [self loadData];
    [self.tableView reloadData];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

- (void)loadData{
    __weak __typeof__(self) weakSelf = self;
    self.items = @[
        @{
            @"title": @"本地html调试",
            @"block": ^(void){
                [weakSelf.navigationController pushViewController:[[ZHController alloc] init] animated:YES];
            }
        },
        @{
            @"title": @"web加载示例",
            @"block": ^(void){
                [weakSelf.navigationController pushViewController:[[ZHJSWebTestController alloc] init] animated:YES];
            }
        },
        @{
            @"title": @"调试控制台",
            @"block": ^(void){
                [ZHDPMg() open];
            }
        },
        @{
            @"title": @"移除 调试控制台",
            @"block": ^(void){
                [ZHDPMg() close];
            }
        }
    ];
}

- (void)c{
    UILabel *badgeLabel = [[UILabel alloc] init];
    badgeLabel.textAlignment = NSTextAlignmentCenter;
    badgeLabel.clipsToBounds = YES;
    badgeLabel.layer.masksToBounds = YES;
    badgeLabel.font = [UIFont systemFontOfSize:17];
    badgeLabel.backgroundColor = [UIColor redColor];
    badgeLabel.textColor = [UIColor whiteColor];
    badgeLabel.text = @"发非爱";
    
    BOOL isHaveBadgeText = (badgeLabel.text && badgeLabel.text.length > 0);
    
    CGSize fitSize = [badgeLabel.text boundingRectWithSize:CGSizeMake(10000, 10000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: badgeLabel.font} context:nil].size;
//    CGFloat limitH = 24.0;  ios系统图标高度24
    CGFloat limitH = fitSize.height + 4.0;
    
    if (badgeLabel.text.length == 1) {
        fitSize.width = limitH;
    }else{
        fitSize.width += 2 * 5;
        if (fitSize.width < limitH) fitSize.width = limitH;
    }
    CGFloat bageX = 10;
    CGFloat bageY = 300;
    CGFloat bageH = isHaveBadgeText ? ceilf((limitH) * 10.0) / 10.0 : 10;
    CGFloat bageW = isHaveBadgeText ? ceilf((fitSize.width) * 10.0) / 10.0 : 10;
    badgeLabel.layer.cornerRadius = bageH * 0.5;
    badgeLabel.frame = CGRectMake(bageX, bageY, bageW, bageH);
    
    [self.view addSubview:badgeLabel];
}

#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.items.count;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellID = @"BaseCellId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.text = self.items[indexPath.row][@"title"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    void (^block) (void) = self.items[indexPath.row][@"block"];
    if (block) {
        block();
    }
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
