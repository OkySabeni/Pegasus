//
//  MyVideosCell.m
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

#import "MyVideosCell.h"

#import "VIMVideo.h"
#import "VIMUser.h"
#import "UIImageView+AFNetworking.h"
#import "VIMPicture.h"
#import "VIMPictureCollection.h"

@interface MyVideosCell ()

@property (nonatomic, weak) IBOutlet UIImageView *thumbnailImageView;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, weak) IBOutlet UILabel *uploadDateLabel;
@property (nonatomic, weak) IBOutlet UILabel *uploadStatusLabel;

@end

@implementation MyVideosCell

- (void)awakeFromNib
{
    
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self.thumbnailImageView cancelImageRequestOperation];
    
    self.video = nil;
    self.titleLabel.text = @"";
    self.descriptionLabel.text = @"";
    self.uploadDateLabel.text = @"";
    self.uploadStatusLabel.text = @"";
    self.thumbnailImageView.image = nil;
}

- (void)setVideo:(VIMVideo *)video
{
    if (_video != video)
    {
        _video = video;
        
        if (_video != nil)
        {
            self.titleLabel.text = _video.name;
            self.descriptionLabel.text = [self videoDescription];
            self.uploadDateLabel.text = [self formattedDate];
            self.uploadStatusLabel.text = [_video.status capitalizedString];
            
            [self.thumbnailImageView cancelImageRequestOperation];
            
            CGFloat height = 2.0f * self.thumbnailImageView.bounds.size.height;
            VIMPicture *picture = [_video.pictureCollection pictureForHeight:height];
            if (picture)
            {
                NSURL *URL = [NSURL URLWithString:picture.link];
                [self.thumbnailImageView setImageWithURL:URL];
            }
            else
            {
                NSLog(@"No image available for asset");
            }
        }
    }
}

- (NSString *)videoDescription
{
    return _video.videoDescription ? _video.videoDescription : @"No description";
}

- (NSString *)formattedDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"'Uploaded on' MM/dd 'at' HH:mm"]; // yyyy
    
    return [dateFormatter stringFromDate:self.video.createdTime];
}

@end
