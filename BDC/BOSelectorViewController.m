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
#import "ItemsTableViewController.h"
#import "ScannerViewController.h"
#import "Invoice.h"
#import "Bill.h"
#import "Vendor.h"
#import "Customer.h"
#import "Item.h"
#import "Uploader.h"
#import "APIHandler.h"
#import "Constants.h"
#import "UIHelper.h"

#define RESET_SCANNER_FROM_BO_SELECT_SEGUE          @"ResetScanner"
#define ATTACH_TO_NEW_INVOICE_SEGUE                 @"AttachToNewInvoice"
#define ATTACH_TO_EXISTING_INVOICE_SEGUE            @"AttachToExistingInvoice"
#define ATTACH_TO_NEW_BILL_SEGUE                    @"AttachToNewBill"
#define ATTACH_TO_EXISTING_BILL_SEGUE               @"AttachToExistingBill"
#define ATTACH_TO_NEW_VENDCREDIT_SEGUE              @"AttachToNewVendorCredit"
#define ATTACH_TO_EXISTING_VENDCREDIT_SEGUE         @"AttachToExistingVendorCredit"
#define ATTACH_TO_NEW_VENDOR_SEGUE                  @"AttachToNewVendor"
#define ATTACH_TO_EXISTING_VENDOR_SEGUE             @"AttachToExistingVendor"
#define ATTACH_TO_NEW_CUSTOMER_SEGUE                @"AttachToNewCustomer"
#define ATTACH_TO_EXISTING_CUSTOMER_SEGUE           @"AttachToExistingCustomer"
#define ATTACH_TO_NEW_ITEM_SEGUE                    @"AttachToNewItem"
#define ATTACH_TO_EXISTING_ITEM_SEGUE               @"AttachToExistingItem"
#define UPLOAD_TO_INBOX_SEGUE                       @"UploadToInbox"


@interface BOSelectorViewController ()

@property (nonatomic, strong) UIActivityIndicatorView *uploadIndicator;

@end


@implementation BOSelectorViewController

@synthesize document;
@synthesize uploadIndicator;


- (IBAction)uploadToInbox:(id)sender {
    if (!self.document.objectId) {
        self.uploadIndicator.hidden = NO;
        [self.uploadIndicator startAnimating];
        
        __weak BOSelectorViewController *weakSelf = self;
        
        [Uploader uploadFile:self.document.name data:self.document.data objectId:nil handler:^(NSURLResponse * response, NSData * data, NSError * err) {
            NSInteger status;
            [APIHandler getResponse:response data:data error:&err status:&status];
            
            if(status == RESPONSE_SUCCESS) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self performSegueWithIdentifier:UPLOAD_TO_INBOX_SEGUE sender:self];
//                    [UIHelper switchViewController:self toTab:kInboxTab withSegue:RESET_SCANNER_FROM_BO_SELECT_SEGUE animated:YES];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIHelper showInfo:@"Failed to upload picture to Inbox!" withStatus:kFailure];
                });
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.uploadIndicator stopAnimating];
            });
        }];
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([segue.identifier isEqualToString:ATTACH_TO_NEW_INVOICE_SEGUE] || [segue.identifier isEqualToString:ATTACH_TO_NEW_BILL_SEGUE] || [segue.identifier isEqualToString:ATTACH_TO_NEW_VENDCREDIT_SEGUE]) {
    if ([segue.destinationViewController isKindOfClass:[SlidingDetailsTableViewController class]]) {
        [segue.destinationViewController addDocument:self.document];
        [segue.destinationViewController setMode:kAttachMode];
    } else if ([segue.destinationViewController isKindOfClass:[SlidingTableViewController class]]) {
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
        } else if ([segue.identifier isEqualToString:ATTACH_TO_EXISTING_ITEM_SEGUE]) {
            [segue.destinationViewController setItems:[Item list]];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem.customView = self.uploadIndicator;
    self.uploadIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.uploadIndicator.hidesWhenStopped = YES;
    [self.uploadIndicator stopAnimating];
    
    self.title = self.document.name;
}

- (void)viewDidUnload
{
    [self setUploadIndicator:nil];
    [self setDocument:nil];
    [super viewDidUnload];
}

#pragma mark - Table view datasource

// need this temparorily; once Attachment view controller is implemented, remove this.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.document.objectId) {
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
            return 3;
            break;
        case 2:
            if (self.document.objectId) {
                return 1;
            } else {
                return 2;
            }
            break;
    }
    return 0;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2 && indexPath.row == 1) {
        [self uploadToInbox:self];
    }
}

@end
