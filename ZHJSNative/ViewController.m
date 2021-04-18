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
#import "ZHDebugPanel.h"

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
    
}

- (void)btnClick{
    
    ZHDebugPanel *panelView = [[ZHDebugPanel alloc] initWithFrame:CGRectMake(0, 300, self.view.bounds.size.width, 300)];
    [self.view addSubview:panelView];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [panelView removeFromSuperview];
//    });
    
    return;
    
    
    
//    NSURL *url = [NSURL URLWithString:@"https://act.1234567.com.cn/topic/repository/fund-toapp-page/toapp.html?schema=fund://mp.1234567.com.cn/weex/4e11280eef6a4277aa855e98eb385bec/pages/index"];
//    [[UIApplication sharedApplication] openURL:url options:nil completionHandler:^(BOOL success) {
//        NSLog(@"--------------------");
//    }];
    [self.navigationController pushViewController:[[ZHController alloc] init] animated:YES];
}


@end
