//
//  ViewController.m
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

#import "CameraRollViewController.h"

#import <Photos/Photos.h>

#import "CameraRollDatasource.h"
#import "CameraRollCell.h"
#import "VIMUploadTaskQueue.h"
#import "VIMVideoAsset.h"
#import "MetadataViewController.h"
#import "VIMAPIClient.h"
#import "VIMVideoMetadata.h"

static NSString *CameraRollTitle = @"Camera Roll";

@interface CameraRollViewController () <CameraRollCellDelegate, MetadataViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UIButton *pauseResumeButton;

@end

@implementation CameraRollViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    StreamDescriptor *streamDescriptor = [[StreamDescriptor alloc] init];
    streamDescriptor.title = CameraRollTitle;
    streamDescriptor.cellIdentifier = CameraRollCellIdentifier;
    streamDescriptor.cellClass = [CameraRollCell class];
    streamDescriptor.tabBarImageName = @"CameraRollIcon";
    streamDescriptor.tabBarSelectedImageName = @"CameraRollIcon-Active";
    
    self = [super initWithStreamDescriptor:streamDescriptor];
    if (self)
    {
        
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.datasource = [[CameraRollDatasource alloc] initWithCellIdentifier:CameraRollCellIdentifier cellSetupBlock:^(id item, UICollectionViewCell *cell) {
        
        ((CameraRollCell *)cell).videoAsset = item;
        ((CameraRollCell *)cell).delegate = self;
        
    }];
    self.datasource.delegate = self;
    self.collectionView.dataSource = self.datasource;
    
    BOOL isSuspended = [[VIMUploadTaskQueue sharedAppQueue] isSuspended];
    [self.pauseResumeButton setSelected:isSuspended];
    
    [self.datasource refreshItems];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadTaskQueueDidSuspendOrResume:) name:VIMNetworkTaskQueue_DidSuspendOrResumeNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Notifications

- (void)uploadTaskQueueDidSuspendOrResume:(NSNotification *)notification
{
    [self configurePauseButton];
}

- (void)configurePauseButton
{
    BOOL isSuspended = [[VIMUploadTaskQueue sharedAppQueue] isSuspended];
    [self.pauseResumeButton setSelected:isSuspended];
}

#pragma mark - DatasourceDelegate

- (void)datasourceDidRefresh:(Datasource *)datasource
{
    [super datasourceDidRefresh:datasource];
    
    [self configurePauseButton];
    
    [[VIMUploadTaskQueue sharedAppQueue] associateVideoAssetsWithUploads:self.datasource.items];
}

#pragma mark - Actions

- (IBAction)didTapUploadAll:(id)sender
{
    [[VIMUploadTaskQueue sharedAppQueue] uploadVideoAssets:self.datasource.items];
}

- (IBAction)didTapCancelAll:(id)sender
{
    [[VIMUploadTaskQueue sharedAppQueue] cancelAllUploads];
}

- (IBAction)didTapSuspendResumeAll:(UIButton *)sender
{
    if ([[VIMUploadTaskQueue sharedAppQueue] isSuspended])
    {
        [[VIMUploadTaskQueue sharedAppQueue] resume];
        [[VIMUploadTaskQueue sharedExtensionQueue] resume];
//        [sender setSelected:NO];
    }
    else
    {
        [[VIMUploadTaskQueue sharedAppQueue] suspend];
        [[VIMUploadTaskQueue sharedExtensionQueue] suspend];
//        [sender setSelected:YES];
    }
}

#pragma mark - CameraRollCell Delegate

- (void)cameraRollCell:(CameraRollCell *)cell uploadAsset:(VIMVideoAsset *)videoAsset
{
    [[VIMUploadTaskQueue sharedAppQueue] uploadVideoAssets:@[videoAsset]];
}

- (void)cameraRollCell:(CameraRollCell *)cell cancelUploadForAsset:(VIMVideoAsset *)videoAsset
{
    [[VIMUploadTaskQueue sharedAppQueue] cancelUploadForVideoAsset:videoAsset];
}

#pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    VIMVideoAsset *videoAsset = self.datasource.items[indexPath.item];
    
    MetadataViewController *viewController = [[MetadataViewController alloc] initWithVideoAsset:videoAsset];
    viewController.delegate = self;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - MetadataViewController Delegate

- (void)metadataViewControlerDidFinish:(MetadataViewController *)viewController
{
    VIMVideoAsset *videoAsset = viewController.videoAsset;
    VIMVideoMetadata *videoMetadata = viewController.videoMetadata;
    
    [[VIMUploadTaskQueue sharedAppQueue] addMetadata:videoMetadata toVideoAsset:videoAsset withCompletionBlock:^(BOOL didAdd) {
        
        if (!didAdd)
        {
            if (videoAsset.videoURI)
            {
                [[VIMAPIClient sharedClient] updateVideoWithURI:videoAsset.videoURI title:videoMetadata.videoTitle description:videoMetadata.videoDescription privacy:videoMetadata.videoPrivacy completionHandler:^(VIMServerResponse *response, NSError *error) {
                    
                    if (error)
                    {
                        NSLog(@"Error setting metadata via VIMAPIClient");
                    }
                    else
                    {
                        NSLog(@"Metadata set via VIMAPIClient");
                    }
                    
                }];
            }
            else
            {
                NSLog(@"Error completing upload: %@", videoAsset.error);
            }
        }
        
    }];
    
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

@end
