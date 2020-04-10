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

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    btn.backgroundColor = [UIColor orangeColor];
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    
    [ZHWebViewManager install];
}

- (void)btnClick{
//    NSURL *url = [NSURL URLWithString:@"https://act.1234567.com.cn/topic/repository/fund-toapp-page/toapp.html?schema=fund://mp.1234567.com.cn/weex/4e11280eef6a4277aa855e98eb385bec/pages/index"];
//    [[UIApplication sharedApplication] openURL:url options:nil completionHandler:^(BOOL success) {
//        NSLog(@"--------------------");
//    }];
    [self.navigationController pushViewController:[[ZHController alloc] init] animated:YES];
}


@end
