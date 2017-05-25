//
//  BaseViewController.m
//  新闻
//
//  Created by 范英强 on 16/9/8.
//  Copyright © 2016年 apple. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];

}

- (BOOL)canSwipBack
{
    return YES;
}

- (void)back
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dealloc
{
    DLog(@"Controller dealloc = %@",NSStringFromClass([self class]));
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
