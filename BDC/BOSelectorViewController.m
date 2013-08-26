//
//  BOSelectorViewController.m
//  BDC
//
//  Created by Qinwei Gong on 6/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BOSelectorViewController.h"
#import "InvoicesTableViewController.h"
#import "BillsTableViewController.h"
#import "VendorsTableViewController.h"
#import "CustomersTableViewController.h"
#import "InboxViewController.h"
#import "ScannerViewController.h"
#import "RootMenuViewController.h"
#import "Invoice.h"
#import "Bill.h"
#import "Vendor.h"
#import "Customer.h"
#import "Uploader.h"
#import "APIHandler.h"
#import "Constants.h"
#import "UIHelper.h"

#define RESET_SCANNER_FROM_BO_SELECT_SEGUE          @"ResetScanner"
#define ATTACH_TO_NEW_BILL_SEGUE                    @"AttachToNewBill"
#define ATTACH_TO_EXISTING_BILL_SEGUE               @"AttachToExistingBill"
#define ATTACH_TO_NEW_VENDCREDIT_SEGUE              @"AttachToNewVendorCredit"
#define ATTACH_TO_EXISTING_VENDCREDIT_SEGUE         @"AttachToExistingVendorCredit"
#define ATTACH_TO_NEW_VENDOR_SEGUE                  @"AttachToNewVendor"
#define ATTACH_TO_EXISTING_VENDOR_SEGUE             @"AttachToExistingVendor"
#define ATTACH_TO_NEW_INVOICE_SEGUE                 @"AttachToNewInvoice"
#define ATTACH_TO_EXISTING_INVOICE_SEGUE            @"AttachToExistingInvoice"
#define ATTACH_TO_NEW_CUSTOMER_SEGUE                @"AttachToNewCustomer"
#define ATTACH_TO_EXISTING_CUSTOMER_SEGUE           @"AttachToExistingCustomer"

#define AttachToExistingSegues  [NSArray arrayWithObjects: \
                                    [NSArray arrayWithObjects:ATTACH_TO_EXISTING_BILL_SEGUE, ATTACH_TO_EXISTING_VENDOR_SEGUE, nil], \
                                    [NSArray arrayWithObjects:ATTACH_TO_EXISTING_INVOICE_SEGUE, ATTACH_TO_EXISTING_CUSTOMER_SEGUE, nil], \
                                nil]

#define AttachToNewSegues       [NSArray arrayWithObjects: \
                                    [NSArray arrayWithObjects:ATTACH_TO_NEW_BILL_SEGUE, ATTACH_TO_NEW_VENDOR_SEGUE, nil], \
                                    [NSArray arrayWithObjects:ATTACH_TO_NEW_INVOICE_SEGUE, ATTACH_TO_NEW_CUSTOMER_SEGUE, nil], \
                                nil]


@interface BOSelectorViewController ()

@property (nonatomic, strong) UIActivityIndicatorView *uploadIndicator;

@end


@implementation BOSelectorViewController

@synthesize document;
@synthesize uploadIndicator;
@synthesize pickOrCreateSwitch;


- (IBAction)uploadToInbox:(id)sender {
    if (!self.document.objectId) {
        self.uploadIndicator.hidden = NO;
        [self.uploadIndicator startAnimating];
                
        [Uploader uploadFile:self.document.name data:self.document.data objectId:nil handler:^(NSURLResponse * response, NSData * data, NSError * err) {
            NSInteger status;
            NSString *info = [APIHandler getResponse:response data:data error:&err status:&status];
            
            if(status == RESPONSE_SUCCESS) {
                if (![info isEqualToString:EMPTY_ID]) {
                    self.document.objectId = info; // at this moment, returned document id is empty, coz there's only a DocumentUploadedObject but no DocumentObject yet
                }
                
                [Document addToInbox:self.document];
                [UIHelper showInfo:[NSString stringWithFormat:@"Bill.com is still processing %@.\n\nNot available for association yet.", self.document.name] withStatus:kInfo];
            } else {
                [UIHelper showInfo:@"Failed to upload picture to Inbox!" withStatus:kFailure];
            }
        }];
    }
}

// private
- (void)resetScanner {
    ScannerViewController *scannerVC = self.navigationController.childViewControllers[0];
    [self.navigationController popToRootViewControllerAnimated:NO];
    
    [[ActionMenuViewController sharedInstance] performSegueForObject:self.document];
    [scannerVC disappear];
    [scannerVC reset];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[SlidingDetailsTableViewController class]]) {
        [segue.destinationViewController resetScrollView];
        [segue.destinationViewController addDocument:self.document];
        [segue.destinationViewController setMode:kAttachMode];
    } else if ([segue.destinationViewController isKindOfClass:[SlidingListTableViewController class]]) {
        [segue.destinationViewController setDocument:self.document];
        [segue.destinationViewController setMode:kAttachMode];
        
        if ([segue.identifier isEqualToString:ATTACH_TO_EXISTING_INVOICE_SEGUE]) {
            [segue.destinationViewController setInvoices:[Invoice list]];
        } else if ([segue.identifier isEqualToString:ATTACH_TO_EXISTING_BILL_SEGUE]) {
            [segue.destinationViewController setBills:[Bill list]];
        } else if ([segue.identifier isEqualToString:ATTACH_TO_EXISTING_VENDOR_SEGUE]) {
            [segue.destinationViewController setVendors:[Vendor list]];
        } else if ([segue.identifier isEqualToString:ATTACH_TO_EXISTING_CUSTOMER_SEGUE]) {
            [segue.destinationViewController setCustomers:[Customer list]];
        }
    }
}

- (void)performNewSegueForCell:(UIButton *)button {
    int i = button.tag / 10;
    int j = button.tag % 10;
    NSString *segueId = AttachToNewSegues[i][j];
    [self performSegueWithIdentifier:segueId sender:self];
}

- (void)switchPickOrCreate {
    for (int i = 0; i < [AttachToExistingSegues count]; i++) {
        for (int j = 0; j < [[AttachToExistingSegues objectAtIndex:i] count]; j++) {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:j inSection:i]];
            if (self.pickOrCreateSwitch.selectedSegmentIndex == 1) {
                cell.accessoryView = nil;
            } else {
                UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeContactAdd];
                addBtn.tag = i * 10 + j;
                [addBtn addTarget:self action:@selector(performNewSegueForCell:) forControlEvents:UIControlEventTouchUpInside];
                cell.accessoryView = addBtn;
            }
        }
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [self switchPickOrCreate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.uploadIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.uploadIndicator.hidesWhenStopped = YES;
    [self.uploadIndicator stopAnimating];
    
//    self.title = self.document.name;
    
    [self.pickOrCreateSwitch addTarget:self action:@selector(switchPickOrCreate) forControlEvents:UIControlEventValueChanged];
}

- (void)viewDidUnload
{
    [self setUploadIndicator:nil];
    [self setDocument:nil];
    [self setPickOrCreateSwitch:nil];
    [super viewDidUnload];
}

#pragma mark - Table view datasource

// need this temparorily; once Attachment view controller is implemented, remove this.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.mode == kAttachMode) {
        return 2;
    } else {
        return 3;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 2;
            break;
        case 1:
            return 2;
            break;
        case 2:
//            if (self.mode == kAttachMode) {
                return 1;
//            } else {
//                return 2;
//            }
            break;
    }
    return 0;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < [AttachToExistingSegues count]) {
        NSString *segueId;
        if (self.pickOrCreateSwitch.selectedSegmentIndex == 1) {
            segueId = AttachToExistingSegues[indexPath.section][indexPath.row];
        } else {
            segueId = AttachToNewSegues[indexPath.section][indexPath.row];
        }
        [self performSegueWithIdentifier:segueId sender:self];
    } else if (indexPath.row == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIHelper showInfo:@"Document upload in progress.\n\nI'll show up in Inbox once uploaded." withStatus:kInfo];
        });
        
        [self uploadToInbox:self];
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryView = self.uploadIndicator;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.uploadIndicator stopAnimating];
            [self resetScanner];
            
            UINavigationController *navVC = [[RootMenuViewController sharedInstance].menuItems objectForKey:MENU_INBOX];
            SlidingTableViewController *vc = [navVC.childViewControllers objectAtIndex:0];
            
            [RootMenuViewController sharedInstance].currVC = vc;
            [RootMenuViewController sharedInstance].currVC.navigation = navVC;
            [RootMenuViewController sharedInstance].currVC.navigationId = MENU_INBOX;

        });
    }
}


@end
