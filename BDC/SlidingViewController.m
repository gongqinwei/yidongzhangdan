//
//  SlidingViewController.m
//  BDC
//
//  Created by Qinwei Gong on 10/16/12.
//
//

#import "SlidingViewController.h"
#import "RootMenuViewController.h"


@implementation SlidingViewController

#pragma mark - life cycle methods

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    self.isActive = YES;
    
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [RootMenuViewController sharedInstance].currVC = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initialize];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [super viewDidUnload];
}


@end

