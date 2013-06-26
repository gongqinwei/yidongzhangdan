//
//  LoginViewController.m
//  BDC
//
//  Created by Qinwei Gong on 6/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoginViewController.h"
#import "Constants.h"
#import "APIHandler.h"
#import "Organization.h"
#import "Util.h"
#import "SelectOrgViewController.h"

#define INVALID_CREDENTIAL          @"Wrong username/password!"
#define FAIL_LIST_ORGS              @"Failed to retrieve Org list!"

@interface LoginViewController () <OrgDelegate>

@end

@implementation LoginViewController

@synthesize email;
@synthesize password;
@synthesize warning;
@synthesize indicator;

- (IBAction)login:(id)sender {
    [self.email resignFirstResponder];
    [self.password resignFirstResponder];
    
    self.indicator.hidden = NO;
    [self.indicator startAnimating];
    
    [Util setUsername:self.email.text andPassword:self.password.text];  //set up keychain
    
    [Organization retrieveList];
}

- (void)launchSignup {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/Signup", DOMAIN_URL]];
    [[UIApplication sharedApplication] openURL:url];
}

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
//    self.password.text = [Util getPassword];
    
    UIButton *signUpUrl = [UIButton buttonWithType:UIButtonTypeCustom];
    signUpUrl.frame = CGRectMake(80.0, 280.0, 160.0, 20.0);
    signUpUrl.titleLabel.font = [UIFont fontWithName:APP_FONT size:17.0];
    signUpUrl.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [signUpUrl setTitle:@"Sign up for Bill.com" forState:UIControlStateNormal];
    [signUpUrl setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [signUpUrl addTarget:self action:@selector(launchSignup) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:signUpUrl];
    
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

#pragma mark - Organization delegate

- (void)didGetOrgs:(NSArray *)orgList status:(LoginStatus)status {
    __weak LoginViewController *weakSelf = self;
    
    if (status == kSucceedLogin) {
        Organization *firstOrg = [orgList objectAtIndex:0];
        NSString *orgId = firstOrg.objectId;
        
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        
        [info setObject:APP_KEY forKey:APP_KEY_VALUE];
        [info setObject:ORG_ID forKey:orgId];
        [info setObject:USERNAME forKey:[Util URLEncode:[Util getUsername]]];
        [info setObject:PASSWORD forKey:[Util URLEncode:[Util getPassword]]];
        
        [APIHandler asyncCallWithAction:LOGIN_API Info:info AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
            NSInteger status;
            NSDictionary *responseData = [APIHandler getResponse:response data:data error:&err status:&status];
            if (status == RESPONSE_SUCCESS) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.indicator stopAnimating];
                    weakSelf.warning.hidden = YES;
                });
                                
                // set cookie for session id
                NSString *sessionId = [responseData objectForKey:SESSION_ID_KEY];
                [Util setSession:sessionId];
                                
                if ([orgList count] > 1) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.indicator stopAnimating];
                        weakSelf.warning.hidden = YES;
                        [weakSelf performSegueWithIdentifier:@"SelectOrg" sender:weakSelf];
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.indicator stopAnimating];
                        weakSelf.warning.hidden = YES;
                        [weakSelf performSegueWithIdentifier:@"Login" sender:weakSelf];
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

@end
