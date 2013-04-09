//
//  BDCViewController.m
//  BDC
//
//  Created by Qinwei Gong on 6/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BDCViewController.h"
#import "Constants.h"
//#import "APIHandler.h"
//#import "Invoice.h"
#import "Customer.h"
#import "Item.h"
#import "Util.h"

@interface BDCViewController ()

@end

@implementation BDCViewController

//@synthesize bills;
//@synthesize customers;
//@synthesize paymentStatus;

@synthesize items;

//
//- (NSArray *)invoices {
//    return invoices;
//}
//
//- (void)setInvoices:(NSArray *)invoiceList {
//    invoices = invoiceList;
//
////    __weak BDCViewController *weakSelf = self;
////    int invCnt = [invoices count];
////    dispatch_async(dispatch_get_main_queue(), ^{
////        [[[weakSelf.viewControllers objectAtIndex:0] tabBarItem] setBadgeValue: [NSString stringWithFormat:@"%u", invCnt]];
////    });
//}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES];
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Customer retrieveList];
    [Item retrieveList];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"LogOut"]) {
        [Util logout];
    }
}


@end
