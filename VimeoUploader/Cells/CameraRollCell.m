//
//  CameraRollCell.m
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

#import "CameraRollCell.h"

#import <Photos/Photos.h>

#import "VIMVideoAsset.h"
#import "VIMTaskQueue.h"
#import "VIMUploadState.h"

static void *UploadStateContext = &UploadStateContext;
static void *UploadProgressContext = &UploadProgressContext;

@interface CameraRollCell ()

@property (nonatomic, weak) IBOutlet UIImageView *thumbnailImageView;

@property (nonatomic, weak) IBOutlet UILabel *uniqueIDLabel;
@property (nonatomic, weak) IBOutlet UILabel *durationLabel;
@property (nonatomic, weak) IBOutlet UILabel *rawSizeLabel;
@property (nonatomic, weak) IBOutlet UILabel *uploadStatus;

@property (nonatomic, weak) IBOutlet UIButton *uploadButton;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *uploadProgressConstraint;

@property (nonatomic, assign) PHImageRequestID currentFileSizeRequest;
@property (nonatomic, assign) PHImageRequestID currentImageRequest;

@end

@implementation CameraRollCell

- (void)dealloc
{
    [self removeObservers];
}

- (void)awakeFromNib
{
    self.currentFileSizeRequest = PHInvalidImageRequestID;
    self.currentImageRequest = PHInvalidImageRequestID;
    
    self.rawSizeLabel.hidden = YES;
    
    [self configureForUploading:NO];
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    [[PHImageManager defaultManager] cancelImageRequest:self.currentFileSizeRequest];
    [[PHImageManager defaultManager] cancelImageRequest:self.currentImageRequest];

    self.currentFileSizeRequest = PHInvalidImageRequestID;
    self.currentImageRequest = PHInvalidImageRequestID;
    
    [self configureForUploading:NO];

    [self removeObservers];
    
    self.videoAsset = nil;
    self.uniqueIDLabel.text = @"";
    self.durationLabel.text = @"";

    self.rawSizeLabel.hidden = YES;
    self.rawSizeLabel.text = @"";
    
    self.uploadStatus.text = @"";
    self.thumbnailImageView.image = nil;
}

#pragma mark - Setup

- (void)setVideoAsset:(VIMVideoAsset *)videoAsset
{
    if (_videoAsset != videoAsset)
    {
        _videoAsset = videoAsset;
        
        if (_videoAsset != nil)
        {
            self.uniqueIDLabel.text = [NSString stringWithFormat:@"ID: %@", [_videoAsset.phAsset.localIdentifier substringToIndex:10]];
            self.durationLabel.text = [self stringFromDurationInSeconds:_videoAsset.phAsset.duration];
            
            [self configureFileSize];
            [self configureImage];
            
            [self uploadStateDidChange];
            [self uploadProgressDidChange];
            
            [self addObservers];
        }
    }
}

- (void)configureFileSize
{
    [[PHImageManager defaultManager] cancelImageRequest:self.currentFileSizeRequest];

    VIMVideoAsset *currentAsset = self.videoAsset;
    
    __weak typeof(self) welf = self;
    self.currentFileSizeRequest = [self.videoAsset fileSizeWithCompletionBlock:^(CGFloat fileSize, NSError *error) {

        if (welf == nil || currentAsset != welf.videoAsset)
            return;

        dispatch_async(dispatch_get_main_queue(), ^{
            
            __strong typeof(self) strongSelf = welf;
            if (strongSelf == nil || currentAsset != welf.videoAsset)
                return;
            
            strongSelf.currentFileSizeRequest = PHInvalidImageRequestID;

            strongSelf.rawSizeLabel.hidden = (error != nil);

            if (!error)
            {
                if (fileSize == 0)
                {
                    strongSelf.rawSizeLabel.text = @"No Size (slomo)";
                }
                else
                {
                    strongSelf.rawSizeLabel.text = [NSString stringWithFormat:@"%.1f MB", fileSize];
                }
            }
            
        });

    }];
}

- (void)configureImage
{
    [[PHImageManager defaultManager] cancelImageRequest:self.currentImageRequest];

    VIMVideoAsset *currentAsset = self.videoAsset;

    __weak typeof(self) welf = self;
    CGSize size = self.thumbnailImageView.bounds.size;
    
    self.currentImageRequest = [self.videoAsset imageWithSize:size completionBlock:^(UIImage *image, NSError *error) {
       
        if (welf == nil || currentAsset != welf.videoAsset)
            return;

        dispatch_async(dispatch_get_main_queue(), ^{
            
            __strong typeof(self) strongSelf = welf;
            if (strongSelf == nil || currentAsset != welf.videoAsset)
                return;
            
            strongSelf.currentImageRequest = PHInvalidImageRequestID;
            strongSelf.thumbnailImageView.image = image;
            
        });

    }];
}

#pragma mark - Observers

- (void)addObservers
{
    [self.videoAsset addObserver:self forKeyPath:NSStringFromSelector(@selector(uploadState)) options:NSKeyValueObservingOptionNew context:UploadStateContext];
    
    [self.videoAsset addObserver:self forKeyPath:NSStringFromSelector(@selector(uploadProgressFraction)) options:NSKeyValueObservingOptionNew context:UploadProgressContext];
}

- (void)removeObservers
{
    @try
    {
        [self.videoAsset removeObserver:self forKeyPath:NSStringFromSelector(@selector(uploadState)) context:UploadStateContext];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception removing observer: %@", exception);
    }

    @try
    {
        [self.videoAsset removeObserver:self forKeyPath:NSStringFromSelector(@selector(uploadProgressFraction)) context:UploadProgressContext];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception removing observer: %@", exception);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == UploadStateContext)
    {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(uploadState))])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self uploadStateDidChange];
            });
        }
    }
    else if (context == UploadProgressContext)
    {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(uploadProgressFraction))])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self uploadProgressDidChange];
            });
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Actions

- (IBAction)didTapCancel:(id)sender
{
    [self configureForUploading:NO];

    if (self.delegate && [self.delegate respondsToSelector:@selector(cameraRollCell:cancelUploadForAsset:)])
    {
        [self.delegate cameraRollCell:self cancelUploadForAsset:self.videoAsset];
    }
}

- (IBAction)didTapUpload:(id)sender
{
    [self configureForUploading:YES];

    if (self.delegate && [self.delegate respondsToSelector:@selector(cameraRollCell:uploadAsset:)])
    {
        [self.delegate cameraRollCell:self uploadAsset:self.videoAsset];
    }
}

- (void)configureForUploading:(BOOL)isUploading
{
    self.cancelButton.hidden = !isUploading;
    self.uploadButton.hidden = isUploading;
}

#pragma mark - Helpers

- (void)uploadStateDidChange
{
    NSString *statusString = @"";

    switch (self.videoAsset.uploadState)
    {
        case VIMUploadState_None:
            statusString = @"-";
            [self configureForUploading:NO];
            break;

        case VIMUploadState_Enqueued:
            statusString = @"Enqueued";
            [self configureForUploading:YES];
            break;

        case VIMUploadState_CreatingRecord:
            statusString = @"Creating Record";
            [self configureForUploading:YES];
            break;

        case VIMUploadState_UploadingFile:
            statusString = @"Uploading File";
            [self configureForUploading:YES];
            break;

        case VIMUploadState_ActivatingRecord:
            statusString = @"Activating Record";
            [self configureForUploading:YES];
            break;
            
        case VIMUploadState_AddingMetadata:
            statusString = @"Adding Metadata";
            [self configureForUploading:YES];
            break;

        case VIMUploadState_Succeeded:
            statusString = @"Succeeded";
            [self configureForUploading:NO];
            break;

        case VIMUploadState_Failed:
            statusString = @"Failed";
            [self configureForUploading:NO];
            break;

        default:
            break;
    }
    
    self.uploadStatus.text = statusString;
}

- (void)uploadProgressDidChange
{
    CGFloat constant = self.frame.size.width * (1.0f - self.videoAsset.uploadProgressFraction);
    
    self.uploadProgressConstraint.constant = constant;
}

- (NSString *)stringFromDurationInSeconds:(int)duration
{
    int secondsPerHour = 60 * 60;
    int secondsPerMinute = 60;
    
    int hours = duration / secondsPerHour;
    int seconds = duration % secondsPerMinute;
    int minutes = ((duration % secondsPerHour) - seconds) / secondsPerMinute;
    
    NSString *hoursString = nil;
    if (hours < 10) {
        hoursString = [NSString stringWithFormat:@"0%d", hours];
    } else {
        hoursString = [NSString stringWithFormat:@"%d", hours];
    }
    
    NSString *minutesString = nil;
    if (minutes < 10) {
        minutesString = [NSString stringWithFormat:@"0%d", minutes];
    } else {
        minutesString = [NSString stringWithFormat:@"%d", minutes];
    }
    
    NSString *secondsString = nil;
    if (seconds < 10) {
        secondsString = [NSString stringWithFormat:@"0%d", seconds];
    } else {
        secondsString = [NSString stringWithFormat:@"%d", seconds];
    }
    
    NSString *durationString = [NSString stringWithFormat:@"%@:%@", minutesString, secondsString];
    if (hours > 0) {
        durationString = [NSString stringWithFormat:@"%@:%@", hoursString, durationString];
    }
    
    return durationString;
}

@end
