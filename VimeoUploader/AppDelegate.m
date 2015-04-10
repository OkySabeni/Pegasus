//
//  AppDelegate.m
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

#import "AppDelegate.h"

#import "VIMSessionConfiguration.h"
#import "VIMSession.h"
#import "VIMAccount.h"
#import "VIMAPIClient.h"
#import "LaunchViewController.h"
#import "AuthViewController.h"
#import "TabBarController.h"
#import "CameraRollViewController.h"
#import "MyVideosViewController.h"
#import "VIMUploadTaskQueue.h"
#import "VIMTaskQueueDebugger.h"
#import "VIMUploadSessionManager.h"
#import "VIMTaskQueue.h"
#import "KeychainUtility.h"

static NSString *ClientKey = @"YOUR_CLIENT_KEY";
static NSString *ClientSecret = @"YOUR_CLIENT_SECRET";
static NSString *Scope = @"private public create edit delete interact upload";

static NSString *BackgroundSessionIdentifierApp = @"YOUR_APP_BG_SESSION_ID";
static NSString *BackgroundSessionIdentifierExtension = @"YOUR_EXTENSION_BG_SESSION_ID"; // Must be different from BackgroundSessionIdentifierApp
static NSString *SharedContainerID = @"YOUR_SHARED_CONTAINER_ID";

static NSString *KeychainAccessGroup = @"YOUR_KEYCHAIN_ACCESS_GROUP";
static NSString *KeychainService = @"YOUR_KEYCHAIN_SERVICE";

@interface AppDelegate ()

@property (nonatomic, strong) UINavigationController *navigationController;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setupNotifications];
    
    [VIMTaskQueueDebugger postLocalNotificationWithMessage:@"APP LAUNCH"];

    CGRect frame = [UIScreen mainScreen].bounds;
    self.window = [[UIWindow alloc] initWithFrame:frame];
    
    LaunchViewController *launchViewController = [[LaunchViewController alloc] init];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:launchViewController];
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.view.backgroundColor = [UIColor whiteColor];

    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    
    [self setupVIMNetworking];
    
     // Load Task Queues [AH]
    [VIMUploadTaskQueue sharedAppQueue];
    [VIMUploadTaskQueue sharedExtensionQueue];

    return YES;
}

#pragma mark - Application Lifecycle

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Background Session

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    [VIMTaskQueueDebugger postLocalNotificationWithContext:identifier message:@"application:handleEvents:"];

    if ([identifier isEqualToString:BackgroundSessionIdentifierApp])
    {
        [VIMUploadSessionManager sharedAppInstance].completionHandler = completionHandler;
    }
    else if ([identifier isEqualToString:BackgroundSessionIdentifierExtension])
    {
        [VIMUploadSessionManager sharedExtensionInstance].completionHandler = completionHandler;
    }
}

#pragma mark - Authentication

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    [[VIMAPIClient sharedClient] authenticateWithCodeGrantResponseURL:url completionBlock:^(NSError *error) {
        
        if (error == nil)
        {
            [self handleAuthenticatedUser];
        }
        else
        {
            NSString *message = [NSString stringWithFormat:@"Authentication failure: %@", url];
            [self showAlertWithTitle:@"Major Error" message:message];
        }
        
    }];
    
    return YES;
}

#pragma mark - Setup

- (void)setupNotifications
{
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
}

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
    AuthViewController *authViewController = [[AuthViewController alloc] init];
    [self.navigationController setViewControllers:@[authViewController] animated:YES];
}

- (void)handleAuthenticatedUser
{
    CameraRollViewController *cameraRollViewController = [[CameraRollViewController alloc] init];
    MyVideosViewController *myVideosViewController = [[MyVideosViewController alloc] init];
    
    TabBarController *tabBarController = [[TabBarController alloc] init];
    [tabBarController setViewControllers:@[cameraRollViewController, myVideosViewController]];
    [tabBarController setSelectedIndex:0];
    
    [self.navigationController setViewControllers:@[tabBarController] animated:YES];
}

- (void)handleNetworkingSetupFailure
{
    [self showAlertWithTitle:@"Major Error" message:@"Unable to setup VIMNetworking"];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"Okay", nil)
                               style:UIAlertActionStyleDefault
                               handler:nil];
    
    [alertController addAction:okAction];
    
    [self.navigationController presentViewController:alertController animated:YES completion:nil];
}

@end
