//
//  BillsTableViewController.m
//  BDC
//
//  Created by Qinwei Gong on 4/22/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "BillsTableViewController.h"
//#import "BillDetailsViewController.h"
#import "EditBillViewController.h"
#import "ScannerViewController.h"
#import "Bill.h"
#import "Vendor.h"
#import "ChartOfAccount.h"
#import "BankAccount.h"
#import "Organization.h"
#import "Constants.h"
#import "Util.h"
#import "Uploader.h"
#import "APIHandler.h"
#import "UIHelper.h"


#define BILL_DETAILS_CELL_ID                @"BillDetails"
#define VIEW_BILL_SEGUE                     @"ViewBill"
#define CREATE_BILL_SEGUE                   @"CreateNewBill"

@interface BillsTableViewController () <BillListDelegate>

@property (nonatomic, strong) NSArray *readyToPayBills;
@property (nonatomic, strong) NSMutableArray *approvingBills;
@property (nonatomic, strong) NSMutableArray *assignedBills;
@property (nonatomic, strong) NSMutableArray *deniedBills;

@property (nonatomic, strong) NSDecimalNumber *readyToPayBillAmount;
@property (nonatomic, strong) NSDecimalNumber *approvingBillAmount;
@property (nonatomic, strong) NSDecimalNumber *assignedBillAmount;
@property (nonatomic, strong) NSDecimalNumber *deniedBillAmount;

@property (nonatomic, strong) UIButton *readyToPaySectionButton;
@property (nonatomic, strong) UIButton *approvingSectionButton;
@property (nonatomic, strong) UIButton *assignedSectionButton;
@property (nonatomic, strong) UIButton *deniedSectionButton;

@property (nonatomic, strong) NSMutableArray *approvalBills;
@property (nonatomic, strong) NSArray *approvalAmounts;
@property (nonatomic, strong) NSArray *approvalSectionButtons;
@property (nonatomic, strong) NSArray *approvalSectionLabels;

@property (nonatomic, strong) NSMutableArray *dueIn7DaysBills;
@property (nonatomic, strong) NSMutableArray *dueOver7DaysBills;
@property (nonatomic, strong) NSMutableArray *overDueBills;

@property (nonatomic, strong) NSDecimalNumber *overDueBillAmount;
@property (nonatomic, strong) NSDecimalNumber *dueIn7DaysBillAmount;
@property (nonatomic, strong) NSDecimalNumber *dueOver7DaysBillAmount;

@property (nonatomic, strong) UIButton *overDueSectionButton;
@property (nonatomic, strong) UIButton *dueIn7DaysSectionButton;
@property (nonatomic, strong) UIButton *dueOver7DaysSectionButton;

@property (nonatomic, strong) NSMutableArray *dueDateBills;
@property (nonatomic, strong) NSArray *dueDateAmounts;
@property (nonatomic, strong) NSArray *dueDateSectionButtons;
@property (nonatomic, strong) NSArray *dueDateSectionLabels;

@property (nonatomic, strong) NSMutableArray *vendorBills;
@property (nonatomic, strong) NSMutableArray *vendorTotalBillAmounts;
@property (nonatomic, strong) NSMutableArray *vendorSectionButtons;

@property (nonatomic, strong) NSDecimalNumber *totalBillAmount;

@property (nonatomic, strong) NSMutableArray *billListsCopy;

@end


@implementation BillsTableViewController

@synthesize bills = _bills;

@synthesize approvalBills;
@synthesize approvalAmounts;
@synthesize approvalSectionButtons;
@synthesize approvalSectionLabels;

@synthesize readyToPayBills;
@synthesize approvingBills;
@synthesize assignedBills;
@synthesize deniedBills;

@synthesize readyToPayBillAmount;
@synthesize approvingBillAmount;
@synthesize assignedBillAmount;
@synthesize deniedBillAmount;

@synthesize readyToPaySectionButton;
@synthesize approvingSectionButton;
@synthesize assignedSectionButton;
@synthesize deniedSectionButton;

@synthesize overDueBills;
@synthesize dueIn7DaysBills;
@synthesize dueOver7DaysBills;

@synthesize overDueBillAmount;
@synthesize dueIn7DaysBillAmount;
@synthesize dueOver7DaysBillAmount;
@synthesize totalBillAmount;

@synthesize overDueSectionButton;
@synthesize dueIn7DaysSectionButton;
@synthesize dueOver7DaysSectionButton;
@synthesize dueDateSectionButtons;
@synthesize dueDateSectionLabels;

@synthesize vendorBills;
@synthesize vendorTotalBillAmounts;
@synthesize vendorSectionButtons;
@synthesize vendorSectionLabels;

@synthesize billListsCopy;


- (Class)busObjClass {
    return [Bill class];
}

- (void)setBills:(NSArray *)bills {
    _bills = [NSMutableArray arrayWithArray:bills];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)navigateAttach {
    [super navigateAttach];
    [self attachDocumentForObject:self.bills[self.lastSelected.row]];
}

- (void)refreshView {
    [super refreshView];
    
    Organization *org = [Organization getSelectedOrg];
//    [org retrieveNeedApprovalToPayBill];
    [org getOrgPrefs];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    self.sortAttribute = BILL_NUMBER;
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.mode == kAttachMode) {
        self.title = @"Select Bill";
        [super viewWillAppear:animated];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.bills = [Bill listOrderBy:BILL_NUMBER ascending:YES active:YES];
    [Bill setListDelegate:self];
    
    if (self.mode != kAttachMode) {
        self.sortAttributes = [NSArray arrayWithObjects:BILL_APPROVAL_STATUS, BILL_VENDOR_NAME, BILL_NUMBER, BILL_DATE, BILL_DUE_DATE, BILL_AMOUNT, BILL_AMOUNT_PAID, nil];
        self.sortAttributeLabels = BILL_LABELS;
        
        if ([Organization getSelectedOrg].enableAP) {
            self.crudActions = [NSArray arrayWithObjects:ACTION_CREATE, ACTION_DELETE, nil];
            self.inactiveCrudActions = [NSArray arrayWithObjects:ACTION_UNDELETE, nil];
        }
    } else {
        if ([Organization getSelectedOrg].enableAP) {
            self.crudActions = [NSArray arrayWithObjects:ACTION_CREATE, nil];
        }
    }
    
    self.createNewSegue = CREATE_BILL_SEGUE;
    
    self.totalBillAmount = [NSDecimalNumber zero];
    
    for(Bill *bill in self.bills) {
        self.totalBillAmount = [self.totalBillAmount decimalNumberByAdding:bill.amount];
    }
    
    [BankAccount retrieveList];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(Bill *)sender
{
    if ([segue.identifier isEqualToString:VIEW_BILL_SEGUE]) {
        [segue.destinationViewController setBusObj:sender];
        [(EditBillViewController *)segue.destinationViewController setMode:kViewMode];
        [segue.destinationViewController setTitle:sender.invoiceNumber];
    } else if ([segue.identifier isEqualToString:CREATE_BILL_SEGUE]) {
        [segue.destinationViewController setTitle:@"New Bill"];
        [segue.destinationViewController setMode:kCreateMode];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (!self.isActive) {
        return 1;
    } else {
        if ([self.sortAttribute isEqualToString:BILL_VENDOR_NAME]) {
            return self.vendorBills.count;
        } else if ([self.sortAttribute isEqualToString:BILL_DUE_DATE]) {
            return 3;
        } else if ([self.sortAttribute isEqualToString:BILL_APPROVAL_STATUS]) {
            return 4;
        } else {
            return 1;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.isActive) {
        return [self.bills count];
    } else {
        if ([self.sortAttribute isEqualToString:BILL_VENDOR_NAME]) {
            return ((NSArray*)[self.vendorBills objectAtIndex:section]).count;
        } else if ([self.sortAttribute isEqualToString:BILL_DUE_DATE]) {
            return ((NSArray *)[self.dueDateBills objectAtIndex:section]).count;
        } else if ([self.sortAttribute isEqualToString:BILL_APPROVAL_STATUS]) {
            return ((NSArray *)[self.approvalBills objectAtIndex:section]).count;
        } else {
            return [self.bills count];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = BILL_DETAILS_CELL_ID;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    Bill *bill;
    
    if (!self.isActive) {
        bill = [self.bills objectAtIndex:indexPath.row];
    } else {
        if ([self.sortAttribute isEqualToString:BILL_VENDOR_NAME]) {
            bill = [[self.vendorBills objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        } else if ([self.sortAttribute isEqualToString:BILL_DUE_DATE]) {
            bill = [((NSArray *)[self.dueDateBills objectAtIndex:indexPath.section]) objectAtIndex:indexPath.row];
        } else if ([self.sortAttribute isEqualToString:BILL_APPROVAL_STATUS]) {
            bill = [((NSArray *)[self.approvalBills objectAtIndex:indexPath.section]) objectAtIndex:indexPath.row];
        } else {
            bill = [self.bills objectAtIndex:indexPath.row];
        }
    }
    
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
        lblStatus.textColor = [UIColor colorWithRed:60/255.0 green:180/255.0 blue:60/255.0 alpha:1.0];
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
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return BILL_TABLE_SECTION_HEADER_HEIGHT;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:SECTION_HEADER_RECT];
    [UIHelper addGradientForView:headerView];
    
    UILabel *label;
    UIButton *sectionButton = nil;
    
    if (!self.isActive) {
        label = [[UILabel alloc] initWithFrame:SECTION_HEADER_LABEL_RECT];
        [UIHelper initializeHeaderLabel:label];
        label.text = ALL_INACTIVE_BILLS;
    } else {
        if ([self.sortAttribute isEqualToString:BILL_VENDOR_NAME] || [self.sortAttribute isEqualToString:BILL_DUE_DATE] || [self.sortAttribute isEqualToString:BILL_APPROVAL_STATUS]) {
            label = [[UILabel alloc] initWithFrame:SECTION_HEADER_LABEL_RECT2];
            [UIHelper initializeHeaderLabel:label];
            
            if ([self.sortAttribute isEqualToString:BILL_VENDOR_NAME]) {
                //            label.text = [Vendor objectForKey:((Bill *)[[self.vendorBills objectAtIndex:section] objectAtIndex:0]).vendorId].name;
                label.text = [self.vendorSectionLabels objectAtIndex:section];
                
                UILabel *qtyAndAmountLabel = [[UILabel alloc] initWithFrame:SECTION_HEADER_QTY_AMT_RECT];
                [UIHelper initializeHeaderLabel:qtyAndAmountLabel];
                NSMutableString *qtyAndAmount = [NSMutableString stringWithFormat:@"Total: %d / ", ((NSArray *)[self.billListsCopy objectAtIndex:section]).count];
                [qtyAndAmount appendString:[Util formatCurrency:[self.vendorTotalBillAmounts objectAtIndex:section]]];
                
                qtyAndAmountLabel.text = qtyAndAmount;
                [headerView addSubview:qtyAndAmountLabel];
                
                UIButton *btn = [self.vendorSectionButtons objectAtIndex:section];
                btn.tag = section;
                sectionButton = btn;
                
                //            UIImageView *accessoryImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Accessory_disclosure.png"]];
                //            accessoryImage.frame = SECTION_ACCESSORY_RECT;
                //            [headerView addSubview:accessoryImage];
            } else if ([self.sortAttribute isEqualToString:BILL_DUE_DATE]) {
//                NSArray *bills = nil;
                NSDecimalNumber *amt = nil;
                
                label.text = [self.dueDateSectionLabels objectAtIndex:section];
//                bills = [self.dueDateBills objectAtIndex:section];
                amt = [self.dueDateAmounts objectAtIndex:section];
                
                UILabel *qtyAndAmountLabel = [[UILabel alloc] initWithFrame:SECTION_HEADER_QTY_AMT_RECT];
                [UIHelper initializeHeaderLabel:qtyAndAmountLabel];
                NSMutableString *qtyAndAmount = [NSMutableString stringWithFormat:@"Total: %d / ", ((NSArray *)[self.billListsCopy objectAtIndex:section]).count];
                if (amt) {
                    [qtyAndAmount appendString:[Util formatCurrency:amt]];
                }
                
                qtyAndAmountLabel.text = qtyAndAmount;
                [headerView addSubview:qtyAndAmountLabel];
                
                UIButton *btn = [self.dueDateSectionButtons objectAtIndex:section];
                btn.tag = section;
                sectionButton = btn;
            } else {    // approval status
                NSDecimalNumber *amt = nil;
                
                label.text = [self.approvalSectionLabels objectAtIndex:section];
                amt = [self.approvalAmounts objectAtIndex:section];
                
                UILabel *qtyAndAmountLabel = [[UILabel alloc] initWithFrame:SECTION_HEADER_QTY_AMT_RECT];
                [UIHelper initializeHeaderLabel:qtyAndAmountLabel];
                NSMutableString *qtyAndAmount = [NSMutableString stringWithFormat:@"Total: %d / ", ((NSArray *)[self.billListsCopy objectAtIndex:section]).count];
                if (amt) {
                    [qtyAndAmount appendString:[Util formatCurrency:amt]];
                }
                
                qtyAndAmountLabel.text = qtyAndAmount;
                [headerView addSubview:qtyAndAmountLabel];
                
                UIButton *btn = [self.approvalSectionButtons objectAtIndex:section];
                btn.tag = section;
                sectionButton = btn;
            }
            
            UIImageView *arrowImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:TOGGLE_ARROW_IMG_NAME]];
            arrowImage.frame = TOGGLE_ARROW_RECT;
            arrowImage.center = TOGGLE_ARROW_CENTER;
            arrowImage.transform = CGAffineTransformMakeRotation(- M_PI_2 * ([self.tableView numberOfRowsInSection:section] == 0));
            [headerView addSubview:arrowImage];
        } else {
            label = [[UILabel alloc] initWithFrame:SECTION_HEADER_LABEL_RECT];
            [UIHelper initializeHeaderLabel:label];
            label.text = ALL_OPEN_BILLS;
            
            UILabel *qtyAndAmountLabel = [[UILabel alloc] initWithFrame:SECTION_HEADER_QTY_AMT_RECT];
            [UIHelper initializeHeaderLabel:qtyAndAmountLabel];
            NSMutableString *qtyAndAmount = [NSMutableString stringWithFormat:@"Total: %d / ", self.bills.count];
            //            if (self.totalBillAmount) {
            [qtyAndAmount appendString:[Util formatCurrency:self.totalBillAmount]];
            //            }
            
            qtyAndAmountLabel.text = qtyAndAmount;
            [headerView addSubview:qtyAndAmountLabel];
        }
    }
    
    [headerView addSubview:label];
    [headerView addSubview:sectionButton];
    return headerView;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return BILL_TABLE_CELL_HEIGHT;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        Bill *bill;
        
        if (!self.isActive) {
            bill = [self.bills objectAtIndex:indexPath.row];
            [self.bills removeObjectAtIndex:indexPath.row];
            [bill revive];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            if ([self.sortAttribute isEqualToString:BILL_VENDOR_NAME]) {
                bill = [[self.vendorBills objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
                
                [[self.vendorBills objectAtIndex:indexPath.section] removeObjectAtIndex:indexPath.row];
                if (((NSArray*)[self.vendorBills objectAtIndex:indexPath.section]).count == 0) {
                    [self.vendorBills removeObjectAtIndex:indexPath.section];
                    [self.vendorSectionLabels removeObjectAtIndex:indexPath.section];
                    [self.vendorTotalBillAmounts removeObjectAtIndex:indexPath.section];
                    [self.vendorSectionButtons removeObjectAtIndex:indexPath.section];
                    [self.billListsCopy removeObjectAtIndex:indexPath.section];
                    [self.tableView reloadData];
                } else {
                    //                    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                    NSDecimalNumber *subTotalAmt = [self.vendorTotalBillAmounts objectAtIndex:indexPath.section];
                    NSDecimalNumber *newSubTotalAmt = [subTotalAmt decimalNumberBySubtracting:bill.amount];
                    [self.vendorTotalBillAmounts replaceObjectAtIndex:indexPath.section withObject:newSubTotalAmt];
                    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:indexPath.section];
                    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            } else if ([self.sortAttribute isEqualToString:BILL_DUE_DATE]) {
                bill = [[self.dueDateBills objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
                
                [[self.dueDateBills objectAtIndex:indexPath.section] removeObjectAtIndex:indexPath.row];
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            } else {
                bill = [self.bills objectAtIndex:indexPath.row];
                
                [self.bills removeObjectAtIndex:indexPath.row];
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            
            [bill remove];
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isActive) {
        return @"Delete";
    } else {
        return @"Undelete";
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if (self.mode == kAttachMode) {
        if (self.lastSelected != nil) { //TODO: may need to reset self.lastSelected on viewWillAppear
            UITableViewCell *oldRow = [self.tableView cellForRowAtIndexPath:self.lastSelected];
            oldRow.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        }
        
        UITableViewCell *newRow = [self.tableView cellForRowAtIndexPath:indexPath];
        newRow.accessoryType = UITableViewCellAccessoryCheckmark;
        
        self.lastSelected = indexPath;
    } else {
        Bill *bill;
        
        if (!self.isActive) {
            bill = [self.bills objectAtIndex:indexPath.row];
        } else {
            if ([self.sortAttribute isEqualToString:BILL_VENDOR_NAME]) {
                bill = [[self.vendorBills objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            } else if ([self.sortAttribute isEqualToString:BILL_DUE_DATE]) {
                bill = [[self.dueDateBills objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            } else {
                bill = [self.bills objectAtIndex:indexPath.row];
            }
        }
        
        [self performSegueWithIdentifier:VIEW_BILL_SEGUE sender:bill];
    }
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if ([self tryTap]) {
        [self performSegueWithIdentifier:VIEW_BILL_SEGUE sender:[self.bills objectAtIndex:indexPath.row]];
    }
}

#pragma mark - Bill delegate

- (void)didGetBills:(NSArray *)billList {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.refreshControl.attributedTitle = LAST_REFRESHED;
        [self.refreshControl endRefreshing];
    });
    
    self.bills = [self sortBills:billList];
}

- (void)failedToGetBills {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
    });
}

- (void)didDeleteObject {
    self.bills = [Bill listOrderBy:BILL_NUMBER ascending:YES active:self.isActive];
    self.bills = [self sortBills:self.bills];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - Action Menu delegate

- (void)didSelectSortAttribute:(NSString *)attribute ascending:(BOOL)ascending active:(BOOL)active {
    NSArray *billList;
    
    if (active) {
        if (!self.isActive || !self.bills) {
            billList = [Bill list];
            self.isActive = YES;
        } else {
            billList = [Bill list]; //self.bills;//have to do [Bill List] for vendor/due date sort cases
        }
    } else {
        if (self.isActive || !self.bills) {
            billList = [Bill listInactive];
            self.isActive = NO;
        } else {
            billList = [Bill listInactive]; //self.bills;
        }
    }
    
    self.sortAttribute = attribute ? attribute : BILL_NUMBER;
    self.isAsc = ascending;
    
    self.bills = [self sortBills:billList];
    
    if (billList.count) {
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
        //        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

#pragma mark - private methods

- (void)toggleSection:(UIButton *)sender {
    if ([self tryTap]) {
        NSInteger section = sender.tag;
        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:section];
        
        if ([self.sortAttribute isEqualToString:BILL_VENDOR_NAME] || [self.sortAttribute isEqualToString:BILL_DUE_DATE] || [self.sortAttribute isEqualToString:BILL_APPROVAL_STATUS]) {
            if ([self.sortAttribute isEqualToString:BILL_VENDOR_NAME]) {
                if ([self.tableView numberOfRowsInSection:section] > 0) {
                    [self.vendorBills replaceObjectAtIndex:section withObject:[NSMutableArray array]];
                    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
                } else {
                    [self.vendorBills replaceObjectAtIndex:section withObject:[self.billListsCopy objectAtIndex:section]];
                    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            } else if ([self.sortAttribute isEqualToString:BILL_DUE_DATE]) {
                if ([self.tableView numberOfRowsInSection:section] > 0) {
                    [self.dueDateBills replaceObjectAtIndex:section withObject:[NSMutableArray array]];
                    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
                } else {
                    [self.dueDateBills replaceObjectAtIndex:section withObject:[self.billListsCopy objectAtIndex:section]];
                    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            } else {    // approval status
                if ([self.tableView numberOfRowsInSection:section] > 0) {
                    [self.approvalBills replaceObjectAtIndex:section withObject:[NSMutableArray array]];
                    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
                } else {
                    [self.approvalBills replaceObjectAtIndex:section withObject:[self.billListsCopy objectAtIndex:section]];
                    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            }
            
            for (UIView *view in sender.superview.subviews) {
                if ([view isMemberOfClass:[UIImageView class]]) {
                    UIImageView *toggleImage = (UIImageView *)view;
                    toggleImage.transform = CGAffineTransformMakeRotation(- M_PI_2 * ([self.tableView numberOfRowsInSection:section] == 0));
                }
            }
        }
    }
}

- (UIButton *)createSectionButton {
    UIButton *button = [[UIButton alloc] initWithFrame:SECTION_HEADER_RECT];
    button.alpha = 0.1;
    [button addTarget:self action:@selector(toggleSection:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (NSMutableArray *)sortBills:(NSArray *)billArr  {
    NSMutableArray * billList = [Bill list:billArr orderBy:self.sortAttribute ascending:self.isAsc];
    
    if ([self.sortAttribute isEqualToString:BILL_DUE_DATE]) {
        self.overDueBills = [NSMutableArray array];
        self.dueIn7DaysBills = [NSMutableArray array];
        self.dueOver7DaysBills = [NSMutableArray array];
        
        self.overDueBillAmount = [NSDecimalNumber zero];
        self.dueIn7DaysBillAmount = [NSDecimalNumber zero];
        self.dueOver7DaysBillAmount = [NSDecimalNumber zero];
        
        self.overDueSectionButton = [self createSectionButton];
        self.dueIn7DaysSectionButton = [self createSectionButton];
        self.dueOver7DaysSectionButton = [self createSectionButton];
        
        NSDate *today = [NSDate date];
        NSDate *nextWeek = [NSDate dateWithTimeIntervalSinceNow: 3600 * 24 * 7];
        
        for(Bill *bill in billList) {
            if ([Util isDay:bill.dueDate earlierThanDay:today]) {
                [self.overDueBills addObject:bill];
                self.overDueBillAmount = [self.overDueBillAmount decimalNumberByAdding:bill.amount];
            } else if ([Util isDay:bill.dueDate earlierThanDay:nextWeek]) {
                [self.dueIn7DaysBills addObject:bill];
                self.dueIn7DaysBillAmount = [self.dueIn7DaysBillAmount decimalNumberByAdding:bill.amount];
            } else {
                [self.dueOver7DaysBills addObject:bill];
                self.dueOver7DaysBillAmount = [self.dueOver7DaysBillAmount decimalNumberByAdding:bill.amount];
            }
        }
        
        if (self.isAsc) {
            self.dueDateBills = [NSMutableArray arrayWithObjects:self.overDueBills, self.dueIn7DaysBills, self.dueOver7DaysBills, nil];
            self.dueDateAmounts = [NSArray arrayWithObjects:self.overDueBillAmount, self.dueIn7DaysBillAmount, self.dueOver7DaysBillAmount, nil];
            self.dueDateSectionButtons = @[self.overDueSectionButton, self.dueIn7DaysSectionButton, self.dueOver7DaysSectionButton];
            self.dueDateSectionLabels = @[OVERDUE, DUE_IN_7, DUE_OVER_7];
        } else {
            self.dueDateBills = [NSMutableArray arrayWithObjects:self.dueOver7DaysBills, self.dueIn7DaysBills, self.overDueBills, nil];
            self.dueDateAmounts = [NSArray arrayWithObjects:self.dueOver7DaysBillAmount, self.dueIn7DaysBillAmount, self.overDueBillAmount, nil];
            self.dueDateSectionButtons = @[self.dueOver7DaysSectionButton, self.dueIn7DaysSectionButton, self.overDueSectionButton];
            self.dueDateSectionLabels = @[DUE_OVER_7, DUE_IN_7, OVERDUE];
        }
        
        self.billListsCopy = [NSMutableArray array];
        for (NSArray *bills in self.dueDateBills) {
            [self.billListsCopy addObject:bills];
        }
    } else if ([self.sortAttribute isEqualToString:BILL_VENDOR_NAME]) {
        self.vendorBills = [NSMutableArray array];
        self.vendorTotalBillAmounts = [NSMutableArray array];
        self.vendorSectionButtons = [NSMutableArray array];
        self.vendorSectionLabels = [NSMutableArray array];
        NSString *currName = @"";
        
        for (Bill *bill in billList) {
            if ([currName isEqualToString:[Vendor objectForKey:bill.vendorId].name]) {
                NSInteger idx = self.vendorBills.count - 1;
                [[self.vendorBills objectAtIndex:idx] addObject:bill];
                
                NSDecimalNumber * amt = [self.vendorTotalBillAmounts objectAtIndex:idx];
                amt = [amt decimalNumberByAdding:bill.amount];
                [self.vendorTotalBillAmounts replaceObjectAtIndex:idx withObject:amt];
            } else {
                NSMutableArray *newVendorInvArr = [NSMutableArray array];
                [self.vendorBills addObject:newVendorInvArr];
                [newVendorInvArr addObject:bill];
                currName = [Vendor objectForKey:bill.vendorId].name;
                
                NSDecimalNumber *amt = [NSDecimalNumber zero];
                amt = [amt decimalNumberByAdding:bill.amount];
                [self.vendorTotalBillAmounts addObject:amt];
                
                UIButton *btn = [self createSectionButton];
                [self.vendorSectionButtons addObject:btn];
                [self.vendorSectionLabels addObject:currName];
            }
        }
        
        self.billListsCopy = [NSMutableArray array];
        for (NSArray *bills in self.vendorBills) {
            [self.billListsCopy addObject:bills];
        }
    } else if ([self.sortAttribute isEqualToString:BILL_APPROVAL_STATUS]) {
        self.approvingBills = [NSMutableArray array];
        self.assignedBills = [NSMutableArray array];
        self.deniedBills = [NSMutableArray array];
        
        self.readyToPayBillAmount = [NSDecimalNumber zero];
        self.approvingBillAmount = [NSDecimalNumber zero];
        self.assignedBillAmount = [NSDecimalNumber zero];
        self.deniedBillAmount = [NSDecimalNumber zero];
        
        self.readyToPaySectionButton = [self createSectionButton];
        self.approvingSectionButton = [self createSectionButton];
        self.assignedSectionButton = [self createSectionButton];
        self.deniedSectionButton = [self createSectionButton];
        
        NSMutableArray *approvedBills = [NSMutableArray array];
        NSMutableArray *unassignedBills = [NSMutableArray array];
        
        for(Bill *bill in billList) {
            if ([APPROVAL_APPROVED isEqualToString:bill.approvalStatus]) {
                [approvedBills addObject:bill];
                self.readyToPayBillAmount = [self.readyToPayBillAmount decimalNumberByAdding:bill.amount];
            } else if ([APPROVAL_UNASSIGNED isEqualToString:bill.approvalStatus]) {
                [unassignedBills addObject:bill];
                self.readyToPayBillAmount = [self.readyToPayBillAmount decimalNumberByAdding:bill.amount];
            } else if ([APPROVAL_APPROVING isEqualToString:bill.approvalStatus]) {
                [self.approvingBills addObject:bill];
                self.approvingBillAmount = [self.approvingBillAmount decimalNumberByAdding:bill.amount];
            } else if ([APPROVAL_ASSIGNED isEqualToString:bill.approvalStatus]) {
                [self.assignedBills addObject:bill];
                self.assignedBillAmount = [self.assignedBillAmount decimalNumberByAdding:bill.amount];
            } else if ([APPROVAL_DENIED isEqualToString:bill.approvalStatus]) {
                [self.deniedBills addObject:bill];
                self.deniedBillAmount = [self.deniedBillAmount decimalNumberByAdding:bill.amount];
            }
        }
        
        Organization *org = [Organization getSelectedOrg];
        NSString *readyToPaySectionLabel;
        if (org.needApprovalToPayBill) {
            readyToPaySectionLabel = @"Ready to Pay";
        } else {
            readyToPaySectionLabel = @"Approval Cleared";
        }
        
        self.readyToPayBills = [approvedBills arrayByAddingObjectsFromArray:unassignedBills];
        
        if (self.isAsc) {
            self.approvalBills = [NSMutableArray arrayWithObjects:self.readyToPayBills, self.approvingBills, self.assignedBills, self.deniedBills, nil];
            self.approvalAmounts = [NSArray arrayWithObjects:self.readyToPayBillAmount, self.approvingBillAmount, self.assignedBillAmount, self.deniedBillAmount, nil];
            self.approvalSectionButtons = @[self.readyToPaySectionButton, self.approvingSectionButton, self.assignedSectionButton, self.deniedSectionButton];
            self.approvalSectionLabels = @[readyToPaySectionLabel, @"Approving", @"Assigned", @"Denied"];
        } else {
            self.approvalBills = [NSMutableArray arrayWithObjects:self.deniedBills, self.assignedBills, self.approvingBills, self.readyToPayBills, nil];
            self.approvalAmounts = [NSArray arrayWithObjects:self.deniedBillAmount, self.assignedBillAmount, self.approvingBillAmount, self.readyToPayBillAmount, nil];
            self.approvalSectionButtons = @[self.deniedSectionButton, self.assignedSectionButton, self.approvingSectionButton, self.readyToPaySectionButton];
            self.approvalSectionLabels = @[@"Denied", @"Assigned", @"Approving", readyToPaySectionLabel];
        }
        
        self.billListsCopy = [NSMutableArray array];
        for (NSArray *bills in self.approvalBills) {
            [self.billListsCopy addObject:bills];
        }
    } else {
        self.totalBillAmount = [NSDecimalNumber zero];
        
        for(Bill *bill in billList) {
            self.totalBillAmount = [self.totalBillAmount decimalNumberByAdding:bill.amount];
        }
    }
    
    return billList;
}

@end

