//
//  ActionViewController.m
//  UploadExtension
//
//  Created by Hanssen, Alfie on 1/30/15.
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

#import "ExtensionNavigationController.h"
#import "VIMVideoAsset.h"
#import "MetadataViewController.h"
#import "VIMUploadTaskQueue.h"
#import "VIMSessionConfiguration.h"
#import "VIMSession.h"
#import "VIMAccount.h"
#import "NSString+MD5.h"
#import "VIMAPIClient.h"
#import "VIMVideoMetadata.h"
#import "KeychainUtility.h"
#import "VIMTempFileMaker.h"

#import <MobileCoreServices/MobileCoreServices.h>

static NSString *ClientKey = @"YOUR_CLIENT_KEY";
static NSString *ClientSecret = @"YOUR_CLIENT_SECRET";
static NSString *Scope = @"private public create edit delete interact upload";

static NSString *BackgroundSessionIdentifierApp = @"YOUR_APP_BG_SESSION_ID";
static NSString *BackgroundSessionIdentifierExtension = @"YOUR_EXTENSION_BG_SESSION_ID"; // Must be different from BackgroundSessionIdentifierApp
static NSString *SharedContainerID = @"YOUR_SHARED_CONTAINER_ID";

static NSString *KeychainAccessGroup = @"YOUR_KEYCHAIN_ACCESS_GROUP";
static NSString *KeychainService = @"YOUR_KEYCHAIN_SERVICE";

static NSString *ExtensionErrorDomain = @"ExtensionErrorDomain";

@interface ExtensionNavigationController () <MetadataViewControllerDelegate>

@end

@implementation ExtensionNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupVIMNetworking];
    
    // Load Task Queue [AH]
    [VIMUploadTaskQueue sharedExtensionQueue];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -

- (void)findInputItem
{
    BOOL videoFound = NO;
    
    for (NSExtensionItem *item in self.extensionContext.inputItems)
    {
        for (NSItemProvider *itemProvider in item.attachments)
        {
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeMovie]) // TODO: include MPEG4? [AH]
            {
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeMovie options:nil completionHandler:^(NSURL *fileURL, NSError *error) {

                    if (!fileURL)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.extensionContext cancelRequestWithError:error];
                        });
                        
                        return;
                    }
                    
                    AVURLAsset *URLAsset = [AVURLAsset assetWithURL:fileURL];
                    [VIMTempFileMaker tempFileFromURLAsset:URLAsset completionBlock:^(NSString *path, NSError *error) {
                    
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            if (error)
                            {
                                [self.extensionContext cancelRequestWithError:error];
                            
                                return;
                            }
                            
                            AVURLAsset *tempURLAsset = [AVURLAsset assetWithURL:[NSURL URLWithString:path]];
                            VIMVideoAsset *videoAsset = [[VIMVideoAsset alloc] initWithURLAsset:tempURLAsset canUploadFromSource:YES];
                            [[VIMUploadTaskQueue sharedExtensionQueue] uploadVideoAssets:@[videoAsset]];
                            
                            MetadataViewController *viewController = [[MetadataViewController alloc] initWithVideoAsset:videoAsset];
                            viewController.delegate = self;
                            
                            [self setViewControllers:@[viewController] animated:YES];
                            
                        });

                    }];
                    
                }];
                
                videoFound = YES;
                break;
            }
        }
        
        if (videoFound)
        {
            break;
        }
    }
    
    if (videoFound == NO)
    {
        NSError *error = [NSError errorWithDomain:ExtensionErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"No video found"}];
        [self.extensionContext cancelRequestWithError:error];
    }
}

#pragma mark - MetadataViewController Delegate

- (void)metadataViewControlerDidFinish:(MetadataViewController *)viewController
{
    VIMVideoAsset *videoAsset = viewController.videoAsset;
    VIMVideoMetadata *videoMetadata = viewController.videoMetadata;
    
    [[VIMUploadTaskQueue sharedExtensionQueue] addMetadata:videoMetadata toVideoAsset:videoAsset withCompletionBlock:^(BOOL didAdd) {

        if (!didAdd)
        {
            if (videoAsset.videoURI)
            {
                [[VIMAPIClient sharedClient] updateVideoWithURI:videoAsset.videoURI title:videoMetadata.videoTitle description:videoMetadata.videoDescription privacy:videoMetadata.videoPrivacy completionHandler:^(VIMServerResponse *response, NSError *error) {
                    
                    if (error)
                    {
                        NSLog(@"E1rror setting metadata via VIMAPIClient");
                    }
                    else
                    {
                        NSLog(@"Metadata set via VIMAPIClient");
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
                    });

                }];
                
                return;
            }
            else
            {
                NSLog(@"Error completing upload: %@", videoAsset.error);
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
        });

    }];
}

#pragma mark - Setup

- (void)setupVIMNetworking
{
    [KeychainUtility configureWithService:KeychainService accessGroup:KeychainAccessGroup];

    VIMSessionConfiguration *config = [[VIMSessionConfiguration alloc] init];
    config.clientKey = ClientKey;
    config.clientSecret = ClientSecret;
    config.scope = Scope;
    config.backgroundSessionIdentifierApp = BackgroundSessionIdentifierApp;
    config.backgroundSessionIdentifierExtension = BackgroundSessionIdentifierExtension;
    config.sharedContainerID = SharedContainerID;
    
    [[VIMSession sharedSession] setupWithConfiguration:config completionBlock:^(BOOL success) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (success)
            {
                if ([[VIMSession sharedSession].account isAuthenticated] == NO)
                {
                    [self handleNoAuthenticatedUser];
                }
                else
                {
                    [self handleAuthenticatedUser];
                }
            }
            else
            {
                [self handleNetworkingSetupFailure];
            }
            
        });
        
    }];
}

- (void)handleNoAuthenticatedUser
{
    self.view.backgroundColor = [UIColor yellowColor];
}

- (void)handleAuthenticatedUser
{
    self.view.backgroundColor = [UIColor greenColor];
    
    [self findInputItem];
}

- (void)handleNetworkingSetupFailure
{
    self.view.backgroundColor = [UIColor redColor];
}

@end
