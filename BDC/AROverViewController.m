//
//  AROverViewController.m
//  BDC
//
//  Created by Qinwei Gong on 8/31/12.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "AROverViewController.h"
#import "APIHandler.h"
#import "Organization.h"
#import "BDCViewController.h"
#import "Util.h"
#import "Constants.h"
#import "InvoicesTableViewController.h"
#import "Constants.h"
#import "UIHelper.h"

#define OVERDUE_INVOICES_SEGUE        @"OverdueInvoices"
#define DUE_IN_7_INVOICES_SEGUE       @"DueIn7DaysInvoices"
#define DUE_OVER_7_INVOICES_SEGUE     @"DueOver7DaysInvoices"
#define TOTAL_INVOICES_SEGUE          @"TotalInvoices"


@interface AROverViewController ()

@property (nonatomic, strong) NSArray *totalInvoices;
@property (nonatomic, strong) NSMutableArray *overDueInvoices;
@property (nonatomic, strong) NSMutableArray *dueIn7DaysInvoices;
@property (nonatomic, strong) NSMutableArray *dueOver7DaysInvoices;

@property (nonatomic, strong) NSDecimalNumber *overDueInvoiceAmount;
@property (nonatomic, strong) NSDecimalNumber *dueIn7DaysInvoiceAmount;
@property (nonatomic, strong) NSDecimalNumber *dueOver7DaysInvoiceAmount;
@property (nonatomic, strong) NSDecimalNumber *totalInvoiceAmount;

@property (nonatomic, strong) UIActivityIndicatorView *indicator;

@end

@implementation AROverViewController

@synthesize overDueInvCount;
@synthesize overDueInvAmount;
@synthesize dueIn7InvCount;
@synthesize dueIn7InvAmount;
@synthesize dueOver7InvCount;
@synthesize dueOver7InvAmount;
@synthesize totalInvCount;
@synthesize totalInvAmount;

@synthesize totalInvoices;
@synthesize overDueInvoices;
@synthesize dueIn7DaysInvoices;
@synthesize dueOver7DaysInvoices;

@synthesize overDueInvoiceAmount;
@synthesize dueIn7DaysInvoiceAmount;
@synthesize dueOver7DaysInvoiceAmount;
@synthesize totalInvoiceAmount;

@synthesize indicator;


#pragma mark - private methods

- (void)populateValues {
    __weak AROverViewController *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.overDueInvoices = [[NSMutableArray alloc] init];
        weakSelf.dueIn7DaysInvoices = [[NSMutableArray alloc] init];
        weakSelf.dueOver7DaysInvoices = [[NSMutableArray alloc] init];
        weakSelf.overDueInvoiceAmount = [NSDecimalNumber zero];
        weakSelf.dueIn7DaysInvoiceAmount = [NSDecimalNumber zero];
        weakSelf.dueOver7DaysInvoiceAmount = [NSDecimalNumber zero];
        weakSelf.totalInvoiceAmount = [NSDecimalNumber zero];
        
        NSDate *today = [NSDate date];
        NSDate *nextWeek = [NSDate dateWithTimeIntervalSinceNow: 3600 * 24 * 7];
        
        for(Invoice *inv in weakSelf.totalInvoices) {
            if ([Util isDay:inv.dueDate earlierThanDay:today]) {
                [weakSelf.overDueInvoices addObject:inv];
                weakSelf.overDueInvoiceAmount = [weakSelf.overDueInvoiceAmount decimalNumberByAdding:inv.amount];
            } else if ([Util isDay:inv.dueDate earlierThanDay:nextWeek]) {
                [weakSelf.dueIn7DaysInvoices addObject:inv];
                weakSelf.dueIn7DaysInvoiceAmount = [weakSelf.dueIn7DaysInvoiceAmount decimalNumberByAdding:inv.amount];
            } else {
                [weakSelf.dueOver7DaysInvoices addObject:inv];
                weakSelf.dueOver7DaysInvoiceAmount = [weakSelf.dueOver7DaysInvoiceAmount decimalNumberByAdding:inv.amount];
            }
            
            weakSelf.totalInvoiceAmount = [weakSelf.totalInvoiceAmount decimalNumberByAdding:inv.amount];
        }
        
        weakSelf.overDueInvCount.text = [NSString stringWithFormat:@"%u", [weakSelf.overDueInvoices count]];
        weakSelf.dueIn7InvCount.text = [NSString stringWithFormat:@"%u", [weakSelf.dueIn7DaysInvoices count]];
        weakSelf.dueOver7InvCount.text = [NSString stringWithFormat:@"%u", [weakSelf.dueOver7DaysInvoices count]];
        weakSelf.totalInvCount.text = [NSString stringWithFormat:@"%u", [weakSelf.totalInvoices count]];
        
        weakSelf.overDueInvAmount.text = [Util formatCurrency:weakSelf.overDueInvoiceAmount];
        weakSelf.dueIn7InvAmount.text = [Util formatCurrency:weakSelf.dueIn7DaysInvoiceAmount];
        weakSelf.dueOver7InvAmount.text = [Util formatCurrency:weakSelf.dueOver7DaysInvoiceAmount];
        weakSelf.totalInvAmount.text = [Util formatCurrency:weakSelf.totalInvoiceAmount];
        
//        weakSelf.navigationItem.title = [@"Receivables for " stringByAppendingString:[Organization getSelectedOrg].name];
        
        int invCnt = [weakSelf.totalInvoices count];
        [[[weakSelf.tabBarController.viewControllers objectAtIndex:kARTab] tabBarItem] setBadgeValue: [NSString stringWithFormat:@"%u", invCnt]];
    });
}

#pragma mark - view controller life cycle

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationItem.title = [@"Receivables for " stringByAppendingString:[Organization getSelectedOrg].name];
}

- (void)viewWillDisappear:(BOOL)animated {
    self.navigationItem.title = @"Receivables";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:self.indicator];
    self.navigationItem.rightBarButtonItem = barButton;
    
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    [refresh addTarget:self action:@selector(refreshView) forControlEvents:UIControlEventValueChanged];
//    refresh.attributedTitle = PULL_TO_REFRESH;
    self.refreshControl = refresh;
}

- (void)refreshView {
    self.refreshControl.attributedTitle = REFRESHING;
    [Invoice retrieveList];
}

- (void)viewDidUnload
{
    [self setOverDueInvCount:nil];
    [self setOverDueInvAmount:nil];
    [self setDueIn7InvCount:nil];
    [self setDueIn7InvAmount:nil];
    [self setDueOver7InvCount:nil];
    [self setDueOver7InvAmount:nil];
    [self setTotalInvCount:nil];
    [self setTotalInvAmount:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
//    if([segue.identifier isEqualToString:OVERDUE_INVOICES_SEGUE]) {
//        [segue.destinationViewController setHeaderTitle:OVERDUE];
//        [segue.destinationViewController setInvoices:self.overDueInvoices];
//    } else if ([segue.identifier isEqualToString:DUE_IN_7_INVOICES_SEGUE]) {
//        [segue.destinationViewController setHeaderTitle:DUE_IN_7];
//        [segue.destinationViewController setInvoices:self.dueIn7DaysInvoices];
//    } else if ([segue.identifier isEqualToString:DUE_OVER_7_INVOICES_SEGUE]) {
//        [segue.destinationViewController setHeaderTitle:DUE_OVER_7];
//        [segue.destinationViewController setInvoices:self.dueOver7DaysInvoices];
//    } else if ([segue.identifier isEqualToString:TOTAL_INVOICES_SEGUE]) {
//        [segue.destinationViewController setHeaderTitle:ALL_OPEN_INVS];
//        [segue.destinationViewController setInvoices:self.totalInvoices];
//    } else {
//        Debug(@"wrong invoices segue!");
//    }
}

#pragma mark - model delegate

- (void)didGetInvoices:(NSArray *)invoiceList {
    self.totalInvoices = invoiceList;
    
    [self populateValues];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.indicator stopAnimating];
        self.indicator.hidden = YES;
        self.navigationItem.rightBarButtonItem = nil;
        
        self.refreshControl.attributedTitle = LAST_REFRESHED;
        [self.refreshControl endRefreshing];
    });

//    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if ([invoiceList count] == 0) {
        [UIHelper showInfo:@"You have no invoice in this organization" withStatus:kInfo];
    }
}

- (void)failedToGetInvoices {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.indicator stopAnimating];
        self.indicator.hidden = YES;
        self.navigationItem.rightBarButtonItem = nil;
    });
    
//    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

@end
