//
//  ApproveBillsTableViewController.m
//  Mobill
//
//  Created by Qinwei Gong on 10/16/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "ApproveBillsTableViewController.h"
#import "EditBillViewController.h"
#import "Bill.h"
#import "Vendor.h"


#define APPROVER_DETAILS_CELL_ID        @"ApproverItem"
#define APPROVE_BILL_SEGUE              @"ApproveBill"


@interface ApproveBillsTableViewController () <BillListDelegate>

@end

@implementation ApproveBillsTableViewController

@synthesize billsToApprove;

//- (void)setApproverList:(NSMutableArray *)approvers {
//    _approverLists = [self sortAlphabeticallyForList:approvers];
//    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.tableView reloadData];
//    });
//}

- (void)refreshView {
    self.refreshControl.attributedTitle = REFRESHING;
    [Bill retrieveListForApproval];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    
    self.billsToApprove = [Bill listBillsToApprove];
    [Bill setListForApprovalDelegate:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.billsToApprove.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = APPROVER_DETAILS_CELL_ID;
    UITableViewCell *cell = nil;
    
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    }
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    Bill *bill = [self.billsToApprove objectAtIndex:indexPath.row];
    
    UILabel * lblInvNum = [[UILabel alloc] initWithFrame:BILL_NUM_RECT];
    lblInvNum.text = bill.invoiceNumber;
    lblInvNum.font = [UIFont fontWithName:APP_BOLD_FONT size:BILL_NUM_FONT_SIZE];
    lblInvNum.textAlignment = NSTextAlignmentLeft;
    [cell addSubview:lblInvNum];
    
    UILabel * lblVendor = [[UILabel alloc] initWithFrame:VENDOR_RECT];
    Vendor *vendor = [Vendor objectForKey:bill.vendorId];
    lblVendor.text = vendor.name;
    lblVendor.font = [UIFont fontWithName:APP_FONT size:BILL_FONT_SIZE];
    lblVendor.textAlignment = NSTextAlignmentLeft;
    [cell addSubview:lblVendor];
    
    UILabel * lblInvDate = [[UILabel alloc] initWithFrame:BILL_DATE_RECT];
    lblInvDate.text = [@"Inv Date " stringByAppendingString:[Util formatDate:bill.invoiceDate format:nil]];
    lblInvDate.font = [UIFont fontWithName:APP_FONT size:BILL_FONT_SIZE];
    lblInvDate.textAlignment = NSTextAlignmentLeft;
    [cell addSubview:lblInvDate];
    
    UILabel * lblStatus = [[UILabel alloc] initWithFrame:APPROVAL_STATUS_RECT];
    lblStatus.text = [APPROVAL_STATUSES objectForKey:bill.approvalStatus];
    if ([APPROVAL_APPROVED isEqualToString:bill.approvalStatus]) {
        lblStatus.font = [UIFont fontWithName:APP_BOLD_FONT size:BILL_FONT_SIZE];
        lblStatus.textColor = [UIColor colorWithRed:34/255.0 green:139/255.0 blue:34/255.0 alpha:1.0];
    } else if ([APPROVAL_DENIED isEqualToString:bill.approvalStatus]) {
        lblStatus.font = [UIFont fontWithName:APP_BOLD_FONT size:BILL_FONT_SIZE];
        lblStatus.textColor = [UIColor redColor];
    } else if ([APPROVAL_APPROVING isEqualToString:bill.approvalStatus]) {
        lblStatus.font = [UIFont fontWithName:APP_BOLD_FONT size:BILL_FONT_SIZE];
        lblStatus.textColor = [UIColor colorWithRed:60/255.0 green:90/255.0 blue:180/255.0 alpha:1.0];
    } else {
        lblStatus.font = [UIFont fontWithName:APP_FONT size:BILL_FONT_SIZE];
    }
    lblStatus.textAlignment = NSTextAlignmentLeft;
    [cell addSubview:lblStatus];
    
    UILabel * lblDueDate = [[UILabel alloc] initWithFrame:DUE_DATE_RECT];
    lblDueDate.text = [@"Due " stringByAppendingString:[Util formatDate:bill.dueDate format:nil]];
    lblDueDate.font = [UIFont fontWithName:APP_FONT size:BILL_FONT_SIZE];
    lblDueDate.textAlignment = NSTextAlignmentLeft;
    [cell addSubview:lblDueDate];
    
    UILabel * lblPaymentStatus = [[UILabel alloc] initWithFrame:PAYMENT_STATUS_RECT];
    lblPaymentStatus.text = [PAYMENT_STATUSES objectForKey:bill.paymentStatus];
    if ([PAYMENT_PAID isEqualToString:bill.paymentStatus]) {
        lblPaymentStatus.font = [UIFont fontWithName:APP_BOLD_FONT size:BILL_FONT_SIZE];
        lblPaymentStatus.textColor = [UIColor colorWithRed:60/255.0 green:180/255.0 blue:60/255.0 alpha:1.0];
    } else if ([PAYMENT_UNPAID isEqualToString:bill.paymentStatus]
               && [Util isDay:bill.dueDate earlierThanDay:[NSDate date]] ) {
        lblPaymentStatus.font = [UIFont fontWithName:APP_BOLD_FONT size:BILL_FONT_SIZE];
        lblPaymentStatus.textColor = [UIColor redColor];
    } else if ([PAYMENT_UNPAID isEqualToString:bill.paymentStatus]
               && [Util isSameDay:bill.dueDate otherDay:[NSDate date]]) {
        lblPaymentStatus.font = [UIFont fontWithName:APP_BOLD_FONT size:BILL_FONT_SIZE];
        lblPaymentStatus.textColor = [UIColor orangeColor];
    } else if ([PAYMENT_SCHEDULED isEqualToString:bill.paymentStatus]
               || [PAYMENT_PENDING isEqualToString:bill.paymentStatus]
               || [PAYMENT_PARTIAL isEqualToString:bill.paymentStatus]) {
        lblPaymentStatus.font = [UIFont fontWithName:APP_BOLD_FONT size:BILL_FONT_SIZE];
        lblPaymentStatus.textColor = [UIColor colorWithRed:60/255.0 green:90/255.0 blue:180/255.0 alpha:1.0];
    } else {
        lblPaymentStatus.font = [UIFont fontWithName:APP_FONT size:BILL_FONT_SIZE];
    }
    lblPaymentStatus.textAlignment = NSTextAlignmentLeft;
    [cell addSubview:lblPaymentStatus];
    
    //    UILabel * lblAmountPaid = [[UILabel alloc] initWithFrame:PAYMENT_STATUS_RECT];
    //    lblAmountPaid.text = [@"Paid " stringByAppendingString:[Util formatCurrency:bill.paidAmount]];
    //    lblAmountPaid.font = [UIFont fontWithName:APP_FONT size:BILL_FONT_SIZE];
    //    lblAmountPaid.textAlignment = NSTextAlignmentLeft;
    //    [cell addSubview:lblAmountPaid];
    
    UILabel * lblAmount = [[UILabel alloc] initWithFrame:AMOUNT_RECT];
    lblAmount.text = [@"Amount " stringByAppendingString:[Util formatCurrency:bill.amount]];
    lblAmount.font = [UIFont fontWithName:APP_FONT size:BILL_FONT_SIZE];
    lblAmount.textAlignment = NSTextAlignmentLeft;
    [cell addSubview:lblAmount];
    
    if (self.mode == kAttachMode) {
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return BILL_TABLE_CELL_HEIGHT;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Bill *bill = [self.billsToApprove objectAtIndex:indexPath.row];
        [self.billsToApprove removeObjectAtIndex:indexPath.row];
        [bill approve];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Approve";
}

#pragma mark - Table view delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(Bill *)sender
{
    if ([segue.identifier isEqualToString:APPROVE_BILL_SEGUE]) {
        [segue.destinationViewController setForApproval:YES];
        [segue.destinationViewController setBusObj:sender];
        [segue.destinationViewController setMode:kViewMode];

        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:nil action:nil];
        self.navigationItem.backBarButtonItem = backButton;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Bill *bill = self.billsToApprove[indexPath.row];
    [self performSegueWithIdentifier:APPROVE_BILL_SEGUE sender:bill];
}


#pragma mark - model delegate

- (void)didGetBillsToApprove:(NSMutableArray *)bills {
    self.billsToApprove = bills;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.refreshControl.attributedTitle = LAST_REFRESHED;
        [self.refreshControl endRefreshing];
        [self.tableView reloadData];
    });
}

- (void)failedToGetBillsToApprove {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
    });
}

- (void)didProcessApproval {
    self.billsToApprove = [Bill listBillsToApprove];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)failedToProcessApproval {
    self.billsToApprove = [Bill listBillsToApprove];
    [self.tableView reloadData];
}

@end
