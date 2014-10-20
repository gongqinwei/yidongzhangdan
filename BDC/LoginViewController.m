//
//  LoginViewController.m
//  BDC
//
//  Created by Qinwei Gong on 6/20/12.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import "LoginViewController.h"
#import "Constants.h"
#import "APIHandler.h"
#import "Organization.h"
#import "Util.h"
#import "User.h"
#import "SelectOrgViewController.h"
#import "BDCAppDelegate.h"
#import "UIHelper.h"
#import "Branch.h"
#import "Mixpanel.h"
#import <QuartzCore/QuartzCore.h>

#define INVALID_CREDENTIAL          @"Wrong username/password!"
#define FAIL_LIST_ORGS              @"Failed to retrieve Org list!"


@interface LoginViewController () <OrgDelegate, ProfileDelegate>

@property (nonatomic, strong) Organization *firstOrg;

@end

@implementation LoginViewController

@synthesize firstOrg;
@synthesize email;
@synthesize password;
@synthesize warning;
@synthesize indicator;
@synthesize stayLoggedIn;
//@synthesize signUpButton;

- (IBAction)login:(id)sender {
    [self.email resignFirstResponder];
    [self.password resignFirstResponder];
    
    self.indicator.hidden = NO;
    [self.indicator startAnimating];
    
    [Util setUsername:self.email.text andPassword:self.password.text];  //set up keychain
    [Util setStayLoggedIn:self.stayLoggedIn.on];
    
    [Organization retrieveList];
}

//- (IBAction)toggleSignUp:(UIButton *)sender {
//    self.signUpButton.alpha = self.signUpButton.hidden ? 0.0 : 1.0;
//    self.signUpButton.hidden = !self.signUpButton.hidden;
//    
//    [UIView animateWithDuration:0.5
//                     animations:^{
//                         self.signUpButton.alpha = self.signUpButton.hidden ? 0.0 : 1.0;
//                     }
//     ];
//}
//
//- (IBAction)signUpWithBDC:(UIButton *)sender {
//    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/Signup", DOMAIN_URL]];
//    [[UIApplication sharedApplication] openURL:url];
//}

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
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.email.text = [Util getUsername];
    
    self.email.layer.borderColor = [[UIColor grayColor] CGColor];
    self.email.layer.borderWidth = 1.0f;
    
    self.password.layer.borderColor = [[UIColor grayColor] CGColor];
    self.password.layer.borderWidth = 1.0f;
    
    self.stayLoggedIn.on = [Util isStayLoggedIn];
    
    [Organization setDelegate:self];
}

- (void)viewDidUnload
{
    [self setEmail:nil];
    [self setPassword:nil];
    [self setWarning:nil];
    [self setIndicator:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"SelectOrg"]) {
        [(SelectOrgViewController *)segue.destinationViewController setIsInitialLogin:YES];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    
    if (![[touch view] isKindOfClass:[UITextField class]]) {
        [self.view endEditing:YES];
    }
    [super touchesBegan:touches withEvent:event];
}

- (void)transitToLogin {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.indicator stopAnimating];
        self.warning.hidden = YES;
        
        [self performSegueWithIdentifier:@"Login" sender:self];
    });
}

#pragma mark - Organization delegate

- (void)didGetOrgFeatures {
    [self transitToLogin];
}

- (void)failedToGetOrgFeatures {
//    [User useProfileToGetOrgFeatures];
}

- (void)didGetOrgs:(NSArray *)orgList status:(LoginStatus)status {
    __weak LoginViewController *weakSelf = self;
    
    if (status == kSucceedLogin) {
        self.firstOrg = [orgList objectAtIndex:0];
        NSString *orgId = self.firstOrg.objectId;
        
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        
        [info setObject:APP_KEY forKey:APP_KEY_VALUE];
        [info setObject:ORG_ID forKey:orgId];
        [info setObject:USERNAME forKey:[Util URLEncode:[Util getUsername]]];
        [info setObject:PASSWORD forKey:[Util URLEncode:[Util getPassword]]];
        
        [APIHandler asyncCallWithAction:LOGIN_API Info:info AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
            NSInteger status;
            NSDictionary *responseData = [APIHandler getResponse:response data:data error:&err status:&status];
            if (status == RESPONSE_SUCCESS) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [weakSelf.indicator stopAnimating];
//                    weakSelf.warning.hidden = YES;
//                });
                
                // set cookie for session id
                NSString *sessionId = [responseData objectForKey:SESSION_ID_KEY];
                [Util setSession:sessionId];
                NSString *userId = [responseData objectForKey:USER_ID];
                [Util setUserId:userId];
                                
                if ([orgList count] > 1) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.indicator stopAnimating];
                        weakSelf.warning.hidden = YES;
                        [weakSelf performSegueWithIdentifier:@"SelectOrg" sender:weakSelf];
                    });
                    
                    // Mixpanel
                    Mixpanel *mixpanel = [Mixpanel sharedInstance];
                    [mixpanel identify:userId];
                    [mixpanel track:@"Login Only"];
                } else {
                    [Organization selectOrg:self.firstOrg];
                    
                    [User GetLoginUser].profileDelegate = self;
                    
                    [User GetUserInfo:userId];
                    
//                    [User RetrieveProfiles];      // only admin can list profiles
                    [self.firstOrg getOrgFeatures];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [weakSelf.indicator stopAnimating];
                        weakSelf.warning.hidden = YES;
                    });
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.indicator stopAnimating];
                        weakSelf.indicator.hidden = YES;
                        weakSelf.warning.text = [err localizedDescription];     //INVALID_CREDENTIAL;
                        weakSelf.warning.hidden = NO;
                    });
                });        
            }
        }];
    } else if (status == kFailListOrgs) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.indicator stopAnimating];
            weakSelf.indicator.hidden = YES;
            weakSelf.warning.text = FAIL_LIST_ORGS;
            weakSelf.warning.hidden = NO;
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.indicator stopAnimating];
            weakSelf.indicator.hidden = YES;
            weakSelf.warning.text = INVALID_CREDENTIAL;
            weakSelf.warning.hidden = NO;
        });
    }
}

#pragma mark - Profile delegate method
- (void)didFinishProfileCheckList {
    [self transitToLogin];
    [self tracking];    //TODO: not called!
}

- (void)tracking {
    // Branch Metrics
    Branch *branch = [Branch getInstance:BNC_APP_KEY];
    [branch identifyUser:[Util getUserId]];
    
    NSDictionary *properties = [NSDictionary dictionaryWithObjects:@[[Util getUserId], [Util getUserFullName], [Util getUserEmail], self.firstOrg.objectId, self.firstOrg.name] forKeys:TRACKING_EVENT_KEYS];
    [branch userCompletedAction:@"Login" withState:properties];
    
    // Mixpanel
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel identify:[Util getUserId]];
    [mixpanel registerSuperProperties:properties];
    [mixpanel track:@"Login"];
}

@end
