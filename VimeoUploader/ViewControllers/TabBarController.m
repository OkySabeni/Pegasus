//
//  TabBarController.m
//  VimeoUploader
//
//  Created by Hanssen, Alfie on 12/22/14.
//  Copyright (c) 2014-2015 Vimeo (https://vimeo.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "TabBarController.h"
#import "UploadCountLabel.h"
#import "SettingsViewController.h"

static NSString *TabBarTitle = @"Pegasus";

@implementation TabBarController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.navigationItem.title = TabBarTitle;
    self.navigationItem.hidesBackButton = YES;

    [self setupSettingsButton];
    [self setupUploadCountLabel];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Setup

- (void)setupSettingsButton
{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self action:@selector(didTapSettings:)];
    [self.navigationItem setRightBarButtonItem:item];
}

- (void)setupUploadCountLabel
{
    CGRect frame = CGRectMake(0, 0, 44, 44);
    UploadCountLabel *label = [[UploadCountLabel alloc] initWithFrame:frame];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:label];
    [self.navigationItem setLeftBarButtonItem:item];
}

#pragma mark - Actions

- (void)didTapSettings:(id)sender
{
    SettingsViewController *viewController = [[SettingsViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
}

@end
