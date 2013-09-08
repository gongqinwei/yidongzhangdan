//
//  UserProfileViewController.m
//  BDC
//
//  Created by Qinwei Gong on 7/10/12.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import "UserProfileViewController.h"
#import "Util.h"


@interface UserProfileViewController ()

@end

@implementation UserProfileViewController

- (IBAction)switchOrg:(UIBarButtonItem *)sender {
    [self.tabBarController performSegueWithIdentifier:@"SwitchOrg" sender:self];
}

- (IBAction)signOut:(id)sender {
    [self.tabBarController performSegueWithIdentifier:@"LogOut" sender:self];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];    
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

@end
