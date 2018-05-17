//
//  ViewController.m
//  KTPlay
//
//  Created by Ki on 2018/5/16.
//  Copyright © 2018年 Ki. All rights reserved.
//

#import "ViewController.h"
#import "KTPlayerView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    KTPlayerView * playView = [[KTPlayerView alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, 300)];
    //playView.backgroundColor = UIColor.lightGrayColor;
    [self.view addSubview:playView];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
