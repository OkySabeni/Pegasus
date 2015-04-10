//
//  Datasource.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^CellSetupBlock)(id item, UICollectionViewCell *cell);

@class Datasource;

@protocol DatasourceDelegate <NSObject>

@required
- (void)datasourceDidRefresh:(Datasource *)datasource;
- (void)datasource:(Datasource *)datasource refreshFailedWithError:(NSError *)error;

@end

@interface Datasource : NSObject <UICollectionViewDataSource>

@property (nonatomic, copy, readonly) NSString *cellIdentifier;
@property (nonatomic, copy, readonly) CellSetupBlock cellSetupBlock;

@property (nonatomic, weak) id<DatasourceDelegate> delegate;
@property (nonatomic, strong) NSArray *items;

- (instancetype)initWithCellIdentifier:(NSString *)cellIdentifier cellSetupBlock:(CellSetupBlock)cellSetupBlock;

- (void)refreshItems;
- (void)cancelRefresh;

@end
