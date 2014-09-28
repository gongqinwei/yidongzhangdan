//
//  SplashViewController.m
//  BDC
//
//  Created by Qinwei Gong on 9/18/12.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "SplashViewController.h"
#import "Util.h"
#import "Organization.h"
#import "User.h"
#import "APIHandler.h"


@interface SplashViewController () <OrgDelegate>

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;

@end

@implementation SplashViewController

@synthesize username;
@synthesize password;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [Organization setDelegate:self];
    
    self.username = [Util getUsername];
    self.password = [Util getPassword];
    
    if ([self.username length] == 0 || [self.password length] == 0) {
        [self performSegueWithIdentifier:@"PresentLogin" sender:self];
    } else {
        [Organization retrieveList];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Organization delegate

- (void)enterBDC {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:@"EnterBDC" sender:self];
    });
}

- (void)backToLogin {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:@"PresentLogin" sender:self];
    });
}

- (void)didGetOrgFeatures {
    [self enterBDC];
}

- (void)failedToGetOrgFeatures {
    [self backToLogin];
//    [User useProfileToGetOrgFeatures];
}

- (void)didGetOrgs:(NSArray *)orgList status:(LoginStatus)status {
//    __weak SplashViewController *weakSelf = self;
    
    if (status == kSucceedLogin) {
        NSString *selectedOrgId = [Util getSelectedOrgId];
        
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        
        if (selectedOrgId) {
            [info setObject:ORG_ID forKey:selectedOrgId];
        }
        
        [info setObject:USERNAME forKey:[Util URLEncode:self.username]];
        [info setObject:PASSWORD forKey:[Util URLEncode:self.password]];
        
        [APIHandler asyncCallWithAction:LOGIN_API Info:info AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
            NSInteger status;
            NSDictionary *responseData = [APIHandler getResponse:response data:data error:&err status:&status];
            
            if (status == RESPONSE_SUCCESS) {
                // set cookie for session id
                NSString *sessionId = [responseData objectForKey:SESSION_ID_KEY];
                [Util setSession:sessionId];
                
                [[Organization getSelectedOrg] getOrgFeatures];
            } else {
                Error(@"Splash View Controller: Failed to login! %ld, %@", (long)status, err);
                [self backToLogin];
            }
        }];
    } else if (status == kFailListOrgs) {
        Error(@"Splash View Controller: Failed to list orgs!");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"PresentLogin" sender:self];
        });
    } else {
        Error(@"Splash View Controller: Failed to login!");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"PresentLogin" sender:self];
        });
    }
}


@end
