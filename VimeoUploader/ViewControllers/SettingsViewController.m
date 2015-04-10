//
//  SettingsViewController.m
//  VimeoUploader
//
//  Created by Hanssen, Alfie on 12/23/14.
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

#import "SettingsViewController.h"
#import "SettingsCell.h"
#import "VIMUploadTaskQueue.h"

typedef NS_ENUM(NSInteger, SettingsCellType)
{
    SettingsCellTypeCellular = 0,
    SettingsCellTypeNumberOfCells
};

@interface SettingsViewController () <UITableViewDataSource, SettingsCellDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Settings";
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(didTapDone:)];
    [self.navigationItem setRightBarButtonItem:item];

    self.tableView.allowsSelection = NO;
    
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([SettingsCell class]) bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:SettingsCellIdentifier];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (void)didTapDone:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return SettingsCellTypeNumberOfCells;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SettingsCell *cell = (SettingsCell *)[tableView dequeueReusableCellWithIdentifier:SettingsCellIdentifier];
    cell.delegate = self;

    switch (indexPath.row)
    {
        case SettingsCellTypeCellular:
            cell.textLabel.text = @"Upload via Cellular";
            cell.toggleSwitch.hidden = NO;
            cell.toggleSwitch.on = [VIMUploadTaskQueue sharedAppQueue].isCellularUploadEnabled;
            cell.detailTextLabel.text = nil;
            break;

        default:
            break;
    }
    
    return cell;
}

#pragma mark - SettingsCell Delegate

- (void)settingsCell:(SettingsCell *)cell didToggleSwitch:(UISwitch *)toggleSwitch
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    switch (indexPath.row)
    {
        case SettingsCellTypeCellular:
            [VIMUploadTaskQueue sharedAppQueue].cellularUploadEnabled = toggleSwitch.isOn;
            break;
            
        default:
            break;
    }
}

@end
