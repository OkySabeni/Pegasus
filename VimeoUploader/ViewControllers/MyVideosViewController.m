//
//  MyVideosViewController.m
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

#import "MyVideosViewController.h"

#import "MyVideosDatasource.h"
#import "MyVideosCell.h"
#import "PlayerViewController.h"

static NSString *MyVideosTitle = @"My Videos";

@interface MyVideosViewController ()

@end

@implementation MyVideosViewController

- (instancetype)init
{
    StreamDescriptor *streamDescriptor = [[StreamDescriptor alloc] init];
    streamDescriptor.title = MyVideosTitle;
    streamDescriptor.cellIdentifier = MyVideosCellIdentifier;
    streamDescriptor.cellClass = [MyVideosCell class];
    streamDescriptor.tabBarImageName = @"MyVideosIcon";
    streamDescriptor.tabBarSelectedImageName = @"MyVideosIcon-Active";

    self = [super initWithStreamDescriptor:streamDescriptor];
    if (self)
    {
        
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.datasource = [[MyVideosDatasource alloc] initWithCellIdentifier:MyVideosCellIdentifier cellSetupBlock:^(id item, UICollectionViewCell *cell) {
        
        ((MyVideosCell *)cell).video = item;
        
    }];
    self.datasource.delegate = self;
    self.collectionView.dataSource = self.datasource;

    [self.datasource refreshItems];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PlayerViewController *viewController = [[PlayerViewController alloc] init];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

@end
