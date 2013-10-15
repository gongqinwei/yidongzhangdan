//
//  EditApproverViewController.m
//  Mobill
//
//  Created by Qinwei Gong on 10/10/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "EditApproverViewController.h"
#import "UIHelper.h"


@interface EditApproverViewController () <ApproverDelegate>

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation EditApproverViewController

@synthesize approver;
@synthesize firstName;
@synthesize lastName;
@synthesize email;
@synthesize activityIndicator;


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activityIndicator.hidesWhenStopped = YES;
}

- (IBAction)saveBusObj:(UIBarButtonItem *)sender {
    if ([self tryTap]) {
        [self.view findAndResignFirstResponder];
        
        if (self.firstName.text.length == 0) {
            [UIHelper showInfo:@"Missing first name!" withStatus:kError];
            return;
        }
        
        if (self.lastName.text.length == 0) {
            [UIHelper showInfo:@"Missing last name!" withStatus:kError];
            return;
        }
        
        if (self.email.text.length == 0) {
            [UIHelper showInfo:@"Missing email!" withStatus:kError];
            return;
        }
        
        self.navigationItem.rightBarButtonItem.customView = self.activityIndicator;
        
        self.approver = [[Approver alloc] init];
        self.approver.createDelegate = self;
        [self.approver createWithFirstName:self.firstName.text lastName:self.lastName.text andEmail:self.email.text];
    }
}

- (void)didAddApprover:(Approver *)approver {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
    });
}

- (void)failedToAddApprover {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.navigationItem.rightBarButtonItem.customView = nil;
    });
}

@end
