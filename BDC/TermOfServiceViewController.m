//
//  TermOfServiceViewController.m
//  BDC
//
//  Created by Qinwei Gong on 6/21/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "TermOfServiceViewController.h"

@interface TermOfServiceViewController ()

@end

@implementation TermOfServiceViewController

@synthesize termOfServiceWebView;

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
	    
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"Term_of_service" ofType:@"txt"];
    NSError *err;
    NSString* htmlString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&err];

    [self.termOfServiceWebView loadHTMLString:htmlString baseURL:nil];
    
    [self setActionMenuRightBarButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setTermOfServiceWebView:nil];
    [super viewDidUnload];
}
@end
