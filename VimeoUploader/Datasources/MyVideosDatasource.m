//
//  MyVideosDatasource.m
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

#import "MyVideosDatasource.h"

#import "VIMRequestOperationManager.h"
#import "VIMRequestDescriptor.h"
#import "VIMVideo.h"
#import "VIMServerResponse.h"

static NSString *MyVideosURI = @"/me/videos";
static NSString *ModelKeyPath = @"data";
static NSString *MyVideosDatasourceErrorDomain = @"MyVideosDatasourceErrorDomain";

@interface MyVideosDatasource ()

@property (nonatomic, strong) id<VIMRequestToken> currentRequest;

@end

@implementation MyVideosDatasource

- (void)dealloc
{
    [[VIMRequestOperationManager sharedManager] cancelAllRequestsForHandler:self];
}

- (void)refreshItems
{
    [[VIMRequestOperationManager sharedManager] cancelRequest:self.currentRequest];

    VIMRequestDescriptor *descriptor = [[VIMRequestDescriptor alloc] init];
    descriptor.cachePolicy = VIMCachePolicy_NetworkOnly;
    descriptor.urlPath = MyVideosURI;
    descriptor.modelClass = [VIMVideo class];
    descriptor.modelKeyPath = ModelKeyPath;

    NSLog(@"request my videos");

    self.currentRequest = [[VIMRequestOperationManager sharedManager] fetchWithRequestDescriptor:descriptor handler:self completionBlock:^(VIMServerResponse *response, NSError *error) {

        NSLog(@"response my videos");

        dispatch_async(dispatch_get_main_queue(), ^{

            self.currentRequest = nil;
            
            NSArray *items = response.result;
            if (error)
            {
                if (self.delegate && [self.delegate respondsToSelector:@selector(datasource:refreshFailedWithError:)])
                {
                    [self.delegate datasource:self refreshFailedWithError:error];
                }
            }
            else if (items == nil)
            {
                if (self.delegate && [self.delegate respondsToSelector:@selector(datasource:refreshFailedWithError:)])
                {
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Datasource refresh returned nil items list"};
                    NSError *error = [NSError errorWithDomain:MyVideosDatasourceErrorDomain code:666 userInfo:userInfo];
                    
                    [self.delegate datasource:self refreshFailedWithError:error];
                }
            }
            else
            {
                self.items = items;
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(datasourceDidRefresh:)])
                {
                    [self.delegate datasourceDidRefresh:self];
                }
            }
            
        });

    }];
}

- (void)cancelRefresh
{
    [[VIMRequestOperationManager sharedManager] cancelAllRequestsForHandler:self];
}

@end
