//
//  ViewController.m
//  GCD_example
//
//  Created by Tony on 2019/4/26.
//  Copyright © 2019 宋涛. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self allRequest];
    
}

// MARK:为了让所有请求都完成后再进行UI操作 用了GCD的group+信号量方案解决
- (void)allRequest{
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_group_async(group, queue, ^{
        // 广告请求
        [self adRequest];
    });
    dispatch_group_async(group, queue, ^{
        // web页面请求
        [self webRequest];
    });
    dispatch_group_async(group, queue, ^{
        // 列表数据请求
        [self listRequest];
    });
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        // 回到主线程刷新UI
        NSLog(@"刷新UI");
    });
}

// MARK:例如首页三个请求，都是异步的
- (void)adRequest{
    
    // 创建一个信号量为0的信号
    dispatch_semaphore_t semap = dispatch_semaphore_create(0);
    [self getDataWithSuccess:^(id response) {
        
        NSLog(@"①:请求首页轮播广告成功");
        // 请求成功信号量加1
        dispatch_semaphore_signal(semap);
    } andFailed:^(NSError *error) {
        
        // 请求失败的时候也让信号加1 不然会一直阻塞线程
        dispatch_semaphore_signal(semap);
    }];
    
    // 如果信号量为0就会一直等待，阻塞线程 直到信号量大于0的时候返回，并且将信号量减1
    dispatch_semaphore_wait(semap, DISPATCH_TIME_FOREVER);
}

- (void)webRequest{
    dispatch_semaphore_t semap = dispatch_semaphore_create(0);
    [self getDataWithSuccess:^(id response) {
        NSLog(@"②:请求首页web展示页成功");
        dispatch_semaphore_signal(semap);
    } andFailed:^(NSError *error) {
        dispatch_semaphore_signal(semap);
    }];
    dispatch_semaphore_wait(semap, DISPATCH_TIME_FOREVER);
}

- (void)listRequest{
    
    dispatch_semaphore_t semap = dispatch_semaphore_create(0);
    [self getDataWithSuccess:^(id response) {
        NSLog(@"③:请求列表数据成功");
        dispatch_semaphore_signal(semap);
    } andFailed:^(NSError *error) {
        dispatch_semaphore_signal(semap);
    }];
    dispatch_semaphore_wait(semap, DISPATCH_TIME_FOREVER);
}

// MARK:模拟network
- (void)getDataWithSuccess:(void (^) (id response))success andFailed:(void (^) (NSError *error))failed{
    success(@"请求成功");// 请求成功
}

@end
