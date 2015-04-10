//
//  UploadCountLabel.m
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

#import "UploadCountLabel.h"
#import "VIMUploadTaskQueue.h"

static void *UploadCountContext = &UploadCountContext;

@implementation UploadCountLabel

- (void)dealloc
{
    [self removeObservers];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self addObservers];
        [self uploadCountDidChange];
    }
    
    return self;
}

#pragma mark - Observers

- (void)addObservers
{
    [[VIMUploadTaskQueue sharedAppQueue] addObserver:self forKeyPath:NSStringFromSelector(@selector(taskCount)) options:NSKeyValueObservingOptionNew context:UploadCountContext];
}

- (void)removeObservers
{
    @try
    {
        [[VIMUploadTaskQueue sharedAppQueue] removeObserver:self forKeyPath:NSStringFromSelector(@selector(taskCount)) context:UploadCountContext];
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
    if (context == UploadCountContext)
    {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(taskCount))])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self uploadCountDidChange];
            });
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)uploadCountDidChange
{
    NSInteger count = [VIMUploadTaskQueue sharedAppQueue].taskCount;
    
    self.text = [NSString stringWithFormat:@"%li", (long)count];
    
    self.hidden = (count == 0);
}

@end
