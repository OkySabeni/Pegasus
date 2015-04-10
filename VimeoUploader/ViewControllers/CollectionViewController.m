//
//  CollectionViewController.m
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

#import "CollectionViewController.h"

@interface CollectionViewController ()

@property (nonatomic, strong, readwrite) StreamDescriptor *streamDescriptor;

@property (nonatomic, strong) UIRefreshControl *refreshControl;

// Used to determine natural height, for calculating UICollectionViewDelegateFlowLayout sizeForItem [AH]
@property (nonatomic, strong) UICollectionViewCell *sizingCell;

@end

@implementation CollectionViewController

- (void)dealloc
{
    [self.datasource cancelRefresh];
}

- (instancetype)initWithStreamDescriptor:(StreamDescriptor *)streamDescriptor
{
    self = [super init];
    if (self)
    {
        _streamDescriptor = streamDescriptor;

        [[UITabBar appearance] setTintColor:[UIColor colorWithRed:49.0f/255.0f green:174.0f/255.0f blue:215.0f/255.0f alpha:1.0f]];

        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil
                                                        image:[UIImage imageNamed:_streamDescriptor.tabBarImageName]
                                                selectedImage:[UIImage imageNamed:_streamDescriptor.tabBarSelectedImageName]];
        self.tabBarItem.imageInsets = UIEdgeInsetsMake(5, 0, -5, 0);
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl];
    
    self.collectionView.scrollsToTop = YES;
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, self.tabBarController.tabBar.bounds.size.height, 0);

    UINib *nib = [UINib nibWithNibName:NSStringFromClass(self.streamDescriptor.cellClass) bundle:nil];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:self.streamDescriptor.cellIdentifier];

    self.sizingCell = [[nib instantiateWithOwner:nil options:nil] objectAtIndex:0];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.datasource cancelRefresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions

- (void)refresh:(UIRefreshControl *)sender
{
    [self.datasource refreshItems];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize size = [self.sizingCell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    
    if (self.collectionView.frame.size.width < self.collectionView.frame.size.height)
    {
        size = CGSizeMake(self.collectionView.frame.size.width, size.height);
    }
    else
    {
        size = CGSizeMake(self.collectionView.frame.size.width / 2.0f, size.height);
    }
    
    return size;
}

#pragma mark - DatasourceDelegate

- (void)datasourceDidRefresh:(Datasource *)datasource
{
    if ([self.refreshControl isRefreshing])
    {
        [self.refreshControl endRefreshing];
    }
    
    [self.collectionView reloadData];
}

- (void)datasource:(Datasource *)datasource refreshFailedWithError:(NSError *)error
{
    NSString *title = @"Refresh Error";
    NSString *message = error.localizedDescription;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Okay", nil)
                                   style:UIAlertActionStyleCancel
                                   handler:nil];
    
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"Try Again", nil)
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                   [self.datasource refreshItems];
                               }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
