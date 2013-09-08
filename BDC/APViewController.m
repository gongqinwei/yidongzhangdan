//
//  APViewController.m
//  BDC
//
//  Created by Qinwei Gong on 6/21/12.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import "APViewController.h"
#import "Constants.h"

@interface APViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation APViewController
@synthesize webView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.webView.scalesPageToFit = YES;
    NSString *urlStr = [NSString stringWithFormat:@"%@/%@/%@", DOMAIN_URL, MOBILE_PAGE_BASE, AP_PAGE];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [self setWebView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
