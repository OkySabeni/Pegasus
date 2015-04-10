//
//  MetadataViewController.m
//  VimeoUploader
//
//  Created by Hanssen, Alfie on 1/29/15.
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

#import "MetadataViewController.h"
#import "AnimatedLoadingBar.h"
#import "VIMVideoAsset.h"
#import "VIMVideoMetadata.h"

static NSString *DescriptionPlaceholder = @"Description";

static void *UploadStateContext = &UploadStateContext;
static void *UploadProgressContext = &UploadProgressContext;

@interface MetadataViewController () <UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, strong, readwrite) VIMVideoAsset *videoAsset;
@property (nonatomic, strong, readwrite) VIMVideoMetadata *videoMetadata;

@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet AnimatedLoadingBar *uploadStateView;
@property (nonatomic, weak) IBOutlet UILabel *uploadStateLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *uploadProgressTrailingConstraint;

@property (nonatomic, weak) IBOutlet UITextField *titleTextField;
@property (nonatomic, weak) IBOutlet UITextView *descriptionTextView;

@property (nonatomic, assign) BOOL didRegisterObservers;

@end

@implementation MetadataViewController

- (void)dealloc
{
    if (self.didRegisterObservers)
    {
        [self removeObservers];
    }
}

- (instancetype)initWithVideoAsset:(VIMVideoAsset *)videoAsset
{
    self = [super init];
    if (self)
    {
        _videoAsset = videoAsset;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSAssert(self.videoAsset != nil, @"Use designated initializer to set videoAsset");
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.title = @"Video Metadata";

    [self setupBarButtonItem];
    [self setupProgressViews];
    
    self.descriptionTextView.text = DescriptionPlaceholder;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self uploadProgressDidChange];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Setup

- (void)setupBarButtonItem
{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(didTapDone:)];
    [self.navigationItem setRightBarButtonItem:item];
}

- (void)setupProgressViews
{
    if (self.videoAsset.uploadState == VIMUploadState_None)
    {
        [self.containerView removeFromSuperview];
    }
    else
    {
        [self.uploadStateView startAnimating];
        
        [self uploadStateDidChange];
        
        [self addObservers];
    }
}

#pragma mark - Actions

- (void)didTapDone:(id)sender
{
    VIMVideoMetadata *videoMetadata = [[VIMVideoMetadata alloc] init];
    videoMetadata.videoTitle = self.titleTextField.text;
    videoMetadata.videoDescription = self.descriptionTextView.text;
    videoMetadata.videoPrivacy = (NSString *)VIMPrivacy_Private;
    videoMetadata.tags = @[@"surfing", @"cats"];
    
    self.videoMetadata = videoMetadata;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(metadataViewControlerDidFinish:)])
    {
        [self.delegate metadataViewControlerDidFinish:self];
    }
}

#pragma mark - Observers

- (void)addObservers
{
    [self.videoAsset addObserver:self forKeyPath:NSStringFromSelector(@selector(uploadState)) options:NSKeyValueObservingOptionNew context:UploadStateContext];
    
    [self.videoAsset addObserver:self forKeyPath:NSStringFromSelector(@selector(uploadProgressFraction)) options:NSKeyValueObservingOptionNew context:UploadProgressContext];

    self.didRegisterObservers = YES;
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

- (void)uploadStateDidChange
{
    switch (self.videoAsset.uploadState)
    {
        case VIMUploadState_None:
            self.uploadStateLabel.text = @"";
            break;

        case VIMUploadState_Enqueued:
            self.uploadStateLabel.text = @"Enqueued";
            break;

        case VIMUploadState_CreatingRecord:
            self.uploadStateLabel.text = @"Creating Record";
            break;

        case VIMUploadState_UploadingFile:
            self.uploadStateLabel.text = @"Uploading File";
            break;

        case VIMUploadState_ActivatingRecord:
            self.uploadStateLabel.text = @"Activating Record";
            break;

        case VIMUploadState_AddingMetadata:
            self.uploadStateLabel.text = @"Adding Metadata";
            break;

        case VIMUploadState_Succeeded:
            self.uploadStateLabel.text = @"Succeeded";
            [self.uploadStateView stopAnimating];
            break;

        case VIMUploadState_Failed:
            self.uploadStateLabel.text = @"Failed";
            [self.uploadStateView stopAnimating];
            break;

        default:
            break;
    }
    
    self.uploadStateView.hidden = NO;
}

- (void)uploadProgressDidChange
{
    CGFloat constant = self.view.frame.size.width * (1.0f - self.videoAsset.uploadProgressFraction);
    
    self.uploadProgressTrailingConstraint.constant = constant;
}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.descriptionTextView becomeFirstResponder];
    
    return YES;
}

#pragma mark - UITextView Delegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:DescriptionPlaceholder])
    {
        textView.text = nil;
    }
}

@end
