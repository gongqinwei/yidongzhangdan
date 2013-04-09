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
    
    // keep a strong reference to self.navigationController so that it won't be released by ARC
    self.navigation = self.navigationController;
    
    self.leftSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toggleMenu:)];
    self.leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:self.leftSwipeRecognizer];
    
    self.rightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toggleMenu:)];
    self.rightSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:self.rightSwipeRecognizer];
    
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleMenu:)];
    
    self.actionMenuVC = nil;
    self.slidingOutDelegate = [RootMenuViewController sharedInstance];
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

