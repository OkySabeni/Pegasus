//
//  CameraRollDatasource.m
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

#import "CameraRollDatasource.h"

#import <Photos/Photos.h>

#import "VIMVideoAsset.h"

static NSString *CameraRollDatasourceErrorDomain = @"CameraRollDatasourceErrorDomain";

@interface CameraRollDatasource () <PHPhotoLibraryChangeObserver>

@end

@implementation CameraRollDatasource

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (instancetype)initWithCellIdentifier:(NSString *)cellIdentifier cellSetupBlock:(CellSetupBlock)cellSetupBlock
{
    self = [super initWithCellIdentifier:cellIdentifier cellSetupBlock:cellSetupBlock];
    if (self)
    {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    
    return self;
}

- (void)refreshItems
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusNotDetermined)
    {
        [self requestAuthorization];
        
        return;
    }
    else if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted)
    {
        [self handleAccessDenied];
        
        return;
    }

    __block NSMutableArray *items = [NSMutableArray array];
    
    PHFetchOptions *options = [PHFetchOptions new];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    
    PHFetchResult *result = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeVideo options:options];
    [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
                
        if (asset)
        {
            VIMVideoAsset *videoAsset = [[VIMVideoAsset alloc] initWithPHAsset:asset];
            [items addObject:videoAsset];
        }
        
    }];
    
    self.items = items;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(datasourceDidRefresh:)])
    {
        [self.delegate datasourceDidRefresh:self];
    }
}

- (void)cancelRefresh
{
    // Nothing to do...
}

- (void)requestAuthorization
{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        
        dispatch_async(dispatch_get_main_queue(), ^{

            [self refreshItems];

        });
        
    }];
}

- (void)handleAccessDenied
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(datasource:refreshFailedWithError:)])
    {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Camera Roll access denied or restricted. Update in iOS Settings."};
        NSError *error = [NSError errorWithDomain:CameraRollDatasourceErrorDomain code:666 userInfo:userInfo];
        
        [self.delegate datasource:self refreshFailedWithError:error];
    }
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self refreshItems];
        
    });
}

@end
