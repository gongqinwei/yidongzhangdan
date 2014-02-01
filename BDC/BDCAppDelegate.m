//
//  BDCAppDelegate.m
//  BDC
//
//  Created by Qinwei Gong on 6/20/12.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import "BDCAppDelegate.h"
#import "Organization.h"
#import "Invoice.h"
#import "Customer.h"
#import "CustomerContact.h"
#import "Item.h"
#import "Bill.h"
#import "Vendor.h"
#import "Approver.h"
#import "Document.h"
#import "ChartOfAccount.h"
#import "BankAccount.h"
#import "SplashViewController.h"
#import "InboxViewController.h"
#import "APIHandler.h"


@interface BDCAppDelegate () <UIAlertViewDelegate>

@property (nonatomic, assign) BOOL isFirstLaunch;

@end

static NSString *const iOSAppStoreURLFormat = @"http://itunes.apple.com/app/id%d?at=10l6dK";

@implementation BDCAppDelegate

@synthesize window = _window;
@synthesize numNetworkActivities = _numNetworkActivities;
@synthesize isFirstLaunch;

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat: iOSAppStoreURLFormat, FULL_VERSION_ID]]];
    }
}

- (void)presentUpgrade {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upgrade"
                                                    message:@"You need Mobill full version to use this advanced feature"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Upgrade", nil];
    [alert show];
}

- (void)setupNavigationBarForiOS7 {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
        shadow.shadowOffset = CGSizeMake(0, 1);
        [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                               [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                                               shadow, NSShadowAttributeName,
                                                               [UIFont fontWithName:APP_BOLD_FONT size:20.0], NSFontAttributeName, nil]];
        
        [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"iOS7NavBarBackground.png"] forBarMetrics:UIBarMetricsDefault];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setupNavigationBarForiOS7];
    
    self.isFirstLaunch = YES;
    self.numNetworkActivities = 0;
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

    if (![Util isStayLoggedIn]) {
        [Util removePassword];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    UIStoryboard *mainstoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    UINavigationController *initialController = (UINavigationController *)[mainstoryboard instantiateInitialViewController];
    SplashViewController *splashScreen = initialController.childViewControllers[0];
    
    NSString *userName = [Util getUsername];
    NSString *password = [Util getPassword];
    
    if (!userName || userName.length == 0 || !password || password.length == 0) {
        self.window.rootViewController = initialController;
        [self.window makeKeyAndVisible];
        [splashScreen performSegueWithIdentifier:@"PresentLogin" sender:splashScreen];
    } else {
        NSString *selectedOrgId = [Util getSelectedOrgId];
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        if (selectedOrgId) {
            [info setObject:ORG_ID forKey:selectedOrgId];
        }
        [info setObject:USERNAME forKey:userName];
        [info setObject:PASSWORD forKey:password];
        
        [APIHandler asyncCallWithAction:LOGIN_API Info:info AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
            NSInteger status;
            NSDictionary *responseData = [APIHandler getResponse:response data:data error:&err status:&status];
            
            if (status == RESPONSE_SUCCESS) {
                // set cookie for session id
                NSString *sessionId = [responseData objectForKey:SESSION_ID_KEY];
                [Util setSession:sessionId];
                
                Organization *currentOrg = [Organization getSelectedOrg];
                
                if (currentOrg.enableAP) {
                    [Bill retrieveListForActive:YES reload:YES];
                    [Vendor retrieveListForActive:YES];
                    [ChartOfAccount retrieveListForActive:YES];
                    [Bill retrieveListForApproval];
                }
                
                [Invoice retrieveListForActive:YES reload:YES];
                [Customer retrieveListForActive:YES];
                
                if (currentOrg.enableAP || currentOrg.enableAR) {
                    [Item retrieveList];
                }
                [CustomerContact retrieveListForActive:YES];
                
                if (currentOrg.enableAP || currentOrg.enableAR) {
                    [Document retrieveListForCategory:FILE_CATEGORY_DOCUMENT];
                }
                
                [Invoice retrieveListForActive:NO reload:NO];
                [Customer retrieveListForActive:NO];
                
                if (currentOrg.enableAP) {
                    [currentOrg getOrgPrefs];
                    [Bill retrieveListForActive:NO reload:NO];
                    [Vendor retrieveListForActive:NO];
                    [BankAccount retrieveList];
                }
            } else {
                self.window.rootViewController = initialController;
                [self.window makeKeyAndVisible];
                [splashScreen performSegueWithIdentifier:@"PresentLogin" sender:nil];
            }
        }];
    }
}

//- (void)switchToVC:(NSString *)vcID {
//    UIStoryboard *mainstoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
//    SplashViewController* splash = [mainstoryboard instantiateViewControllerWithIdentifier:vcID];
//    [self.window makeKeyAndVisible];
//    [self.window.rootViewController presentViewController:splash animated:YES completion:NULL];
//}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (self.isFirstLaunch) {
        self.isFirstLaunch = NO;
    } else {        
        
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
//    [InboxViewController freeMem];
}

// increment numNetworkActivities
// always set networkActivityIndicatorVisible to YES
- (void)incrNetworkActivities {
    @synchronized(self) {
        self.numNetworkActivities++;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
}

// decrement numNetworkActivities
// set networkActivityIndicatorVisible to NO if numNetworkActivities becomes 0
- (void)decrNetworkActivities {
    @synchronized(self) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = --self.numNetworkActivities > 0;
    }
}

@end
