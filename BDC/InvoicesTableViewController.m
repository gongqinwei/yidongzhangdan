//
//  InvoicesTableViewController.m
//  BDC
//
//  Created by Qinwei Gong on 8/31/12.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "InvoicesTableViewController.h"
#import "InvoiceDetailsViewController.h"
#import "EditInvoiceViewController.h"
#import "ScannerViewController.h"
#import "Invoice.h"
//#import "BDCViewController.h"
#import "Customer.h"
#import "Constants.h"
#import "Util.h"
#import "Uploader.h"
#import "APIHandler.h"
#import "UIHelper.h"


#define INVOICE_DETAILS_CELL_ID             @"InvoiceDetails"
#define INVOICE_TABLE_SECTION_HEADER_HEIGHT 28
#define INVOICE_TABLE_CELL_HEIGHT           90
#define INVOICE_TABLE_LABEL_HEIGHT          15
#define INVOICE_TABLE_LABEL_WIDTH           130
#define INVOICE_NUM_RECT                    CGRectMake(10, 5, INVOICE_TABLE_LABEL_WIDTH, INVOICE_TABLE_LABEL_HEIGHT)
#define CUSTOMER_RECT                       CGRectMake(10, 25, INVOICE_TABLE_LABEL_WIDTH, INVOICE_TABLE_LABEL_HEIGHT)
#define INVOICE_DATE_RECT                   CGRectMake(160, 25, INVOICE_TABLE_LABEL_WIDTH, INVOICE_TABLE_LABEL_HEIGHT)
#define STATUS_RECT                         CGRectMake(10, 45, INVOICE_TABLE_LABEL_WIDTH, INVOICE_TABLE_LABEL_HEIGHT)
#define DUE_DATE_LABEL_RECT                 CGRectMake(160, 52, 25, INVOICE_TABLE_LABEL_HEIGHT)
#define DUE_DATE_RECT                       CGRectMake(188, 45, INVOICE_TABLE_LABEL_WIDTH - 20, INVOICE_TABLE_LABEL_HEIGHT)
#define AMOUNT_RECT                         CGRectMake(10, 65, INVOICE_TABLE_LABEL_WIDTH, INVOICE_TABLE_LABEL_HEIGHT)
#define AMOUNT_DUE_RECT                     CGRectMake(188, 65, INVOICE_TABLE_LABEL_WIDTH, INVOICE_TABLE_LABEL_HEIGHT)
#define SECTION_HEADER_RECT                 CGRectMake(0, 0, SCREEN_WIDTH, INVOICE_TABLE_SECTION_HEADER_HEIGHT)
#define SECTION_HEADER_LABEL_RECT           CGRectMake(10, 7, 150, 15)
#define SECTION_HEADER_LABEL_RECT2          CGRectMake(20, 7, 150, 15)
#define TOGGLE_ARROW_RECT                   CGRectMake(5, 10, 10, 10)
#define TOGGLE_ARROW_CENTER                 CGPointMake(10, 15)
#define SECTION_HEADER_QTY_AMT_RECT         CGRectMake(SCREEN_WIDTH - 170, 7, 170, 15)
#define SECTION_ACCESSORY_RECT              CGRectMake(SCREEN_WIDTH - 30, 7, 30, 15)
#define INVOICE_NUM_FONT_SIZE               16
#define INVOICE_FONT_SIZE                   13

#define VIEW_INVOICE_SEGUE                  @"ViewInvoice"
#define CREATE_INVOICE_SEGUE                @"CreateNewInvoice"


@interface InvoicesTableViewController () <InvoiceListDelegate>

@property (nonatomic, strong) NSMutableArray *overDueInvoices;
@property (nonatomic, strong) NSMutableArray *dueIn7DaysInvoices;
@property (nonatomic, strong) NSMutableArray *dueOver7DaysInvoices;
@property (nonatomic, strong) NSMutableArray *dueDateInvoices;

@property (nonatomic, strong) NSDecimalNumber *overDueInvoiceAmount;
@property (nonatomic, strong) NSDecimalNumber *dueIn7DaysInvoiceAmount;
@property (nonatomic, strong) NSDecimalNumber *dueOver7DaysInvoiceAmount;
@property (nonatomic, strong) NSArray *dueDateAmounts;
@property (nonatomic, strong) NSDecimalNumber *totalInvoiceAmount;

@property (nonatomic, strong) UIButton *overDueSectionButton;
@property (nonatomic, strong) UIButton *dueIn7DaysSectionButton;
@property (nonatomic, strong) UIButton *dueOver7DaysSectionButton;
@property (nonatomic, strong) NSArray *dueDateSectionButtons;
@property (nonatomic, strong) NSArray *dueDateSectionLabels;

@property (nonatomic, strong) NSMutableArray *customerInvoices;
@property (nonatomic, strong) NSMutableArray *customerTotalInvoiceAmounts;
@property (nonatomic, strong) NSMutableArray *customerSectionButtons;

@property (nonatomic, strong) NSMutableArray *invoiceListsCopy;

@end


@implementation InvoicesTableViewController

@synthesize invoices = _invoices;

@synthesize overDueInvoices;
@synthesize dueIn7DaysInvoices;
@synthesize dueOver7DaysInvoices;

@synthesize overDueInvoiceAmount;
@synthesize dueIn7DaysInvoiceAmount;
@synthesize dueOver7DaysInvoiceAmount;
@synthesize totalInvoiceAmount;

@synthesize overDueSectionButton;
@synthesize dueIn7DaysSectionButton;
@synthesize dueOver7DaysSectionButton;
@synthesize dueDateSectionButtons;
@synthesize dueDateSectionLabels;

@synthesize customerInvoices;
@synthesize customerTotalInvoiceAmounts;
@synthesize customerSectionButtons;
@synthesize customerSectionLabels;

@synthesize invoiceListsCopy;

//@synthesize deleteDelegate;


- (Class)busObjClass {
    return [Invoice class];
}

- (void)setInvoices:(NSArray *)invoices {
    _invoices = [NSMutableArray arrayWithArray:invoices];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)navigateAttach {
    [super navigateAttach];
    [self attachDocumentForObject:self.invoices[self.lastSelected.row]];
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
    
    self.sortAttribute = INV_NUMBER;
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.mode == kAttachMode) {
        self.title = @"Select Invoice";
        [super viewWillAppear:animated];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.invoices = [Invoice listOrderBy:INV_NUMBER ascending:YES active:YES];
    [Invoice setListDelegate:self];
    
    Organization *org = [Organization getSelectedOrg];
    if (self.mode != kAttachMode) {
        self.sortAttributes = [NSArray arrayWithObjects:INV_CUSTOMER_NAME, INV_NUMBER, INV_DATE, INV_DUE_DATE, INV_AMOUNT, INV_AMOUNT_DUE, nil];
        self.sortAttributeLabels = INV_LABELS;
        
        if (org.enableAR) {
            self.crudActions = [NSArray arrayWithObjects:ACTION_CREATE, ACTION_DELETE, nil];
            self.inactiveCrudActions = [NSArray arrayWithObjects:ACTION_UNDELETE, nil];

        }
        
        // retrieve inactive invoice list in the background
        [Invoice retrieveListForActive:NO reload:NO];
    } else {
        if (org.enableAR) {
            self.crudActions = [NSArray arrayWithObjects:ACTION_CREATE, nil];
        }
    }
    
    self.createNewSegue = CREATE_INVOICE_SEGUE;
    
    self.totalInvoiceAmount = [NSDecimalNumber zero];
    
    for(Invoice *inv in self.invoices) {
        self.totalInvoiceAmount = [self.totalInvoiceAmount decimalNumberByAdding:inv.amountDue];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(Invoice *)sender
{
    if ([segue.identifier isEqualToString:VIEW_INVOICE_SEGUE]) {
        [segue.destinationViewController setBusObj:sender];
        [(EditInvoiceViewController *)segue.destinationViewController setMode:kViewMode];
        [segue.destinationViewController setTitle:sender.invoiceNumber];
    } else if ([segue.identifier isEqualToString:CREATE_INVOICE_SEGUE]) {
        [segue.destinationViewController setTitle:@"New Invoice"];
        [segue.destinationViewController setMode:kCreateMode];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (!self.isActive) {
        return 1;
    } else {
        if ([self.sortAttribute isEqualToString:INV_CUSTOMER_NAME]) {
            return self.customerInvoices.count;
        } else if ([self.sortAttribute isEqualToString:INV_DUE_DATE]) {
            return 3;
        } else {
            return 1;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.isActive) {
        return [self.invoices count];
    } else {
        if ([self.sortAttribute isEqualToString:INV_CUSTOMER_NAME]) {
            return ((NSArray*)[self.customerInvoices objectAtIndex:section]).count;
        } else if ([self.sortAttribute isEqualToString:INV_DUE_DATE]) {
            return ((NSArray *)[self.dueDateInvoices objectAtIndex:section]).count;
        } else {
            return [self.invoices count];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = INVOICE_DETAILS_CELL_ID;
    UITableViewCell *cell = nil;
    
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    }
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    Invoice *inv;
    
    if (!self.isActive) {
        inv = [self.invoices objectAtIndex:indexPath.row];
    } else {
        if ([self.sortAttribute isEqualToString:INV_CUSTOMER_NAME]) {
            if (((NSArray *)[self.customerInvoices objectAtIndex:indexPath.section]).count > indexPath.row) {
                inv = [[self.customerInvoices objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            } else {
                return cell;
            }
        } else if ([self.sortAttribute isEqualToString:INV_DUE_DATE]) {
            if (((NSArray *)[self.dueDateInvoices objectAtIndex:indexPath.section]).count > indexPath.row) {
                inv = [((NSArray *)[self.dueDateInvoices objectAtIndex:indexPath.section]) objectAtIndex:indexPath.row];
            } else {
                return cell;
            }
        } else {
            inv = [self.invoices objectAtIndex:indexPath.row];
        }
    }
    
    UILabel * lblInvNum = [[UILabel alloc] initWithFrame:INVOICE_NUM_RECT];
    lblInvNum.text = inv.invoiceNumber;
    lblInvNum.font = [UIFont fontWithName:APP_BOLD_FONT size:INVOICE_NUM_FONT_SIZE];
    lblInvNum.textAlignment = NSTextAlignmentLeft;
    [cell addSubview:lblInvNum];
    
    UILabel * lblCustomer = [[UILabel alloc] initWithFrame:CUSTOMER_RECT];
    Customer *customer = [Customer objectForKey:inv.customerId];
    lblCustomer.text = customer.name;
    lblCustomer.font = [UIFont fontWithName:APP_FONT size:INVOICE_FONT_SIZE];
    lblCustomer.textAlignment = NSTextAlignmentLeft;
    [cell addSubview:lblCustomer];
    
    UILabel * lblInvDate = [[UILabel alloc] initWithFrame:INVOICE_DATE_RECT];
    lblInvDate.text = [Util formatDate:inv.invoiceDate format:nil]; //[@"Inv Date " stringByAppendingString:[Util formatDate:inv.invoiceDate format:nil]];
    lblInvDate.font = [UIFont fontWithName:APP_FONT size:INVOICE_FONT_SIZE];
    lblInvDate.textAlignment = NSTextAlignmentLeft;
    [cell addSubview:lblInvDate];
    
    UILabel * lblStatus = [[UILabel alloc] initWithFrame:STATUS_RECT];
    lblStatus.text = [PAYMENT_STATUSES objectForKey:inv.paymentStatus];
    if ([PAYMENT_PAID isEqualToString:inv.paymentStatus]) {
        lblStatus.font = [UIFont fontWithName:APP_BOLD_FONT size:INVOICE_FONT_SIZE];
        lblStatus.textColor = [UIColor colorWithRed:34/255.0 green:139/255.0 blue:34/255.0 alpha:1.0];
    } else if ([PAYMENT_UNPAID isEqualToString:inv.paymentStatus]
               && [Util isDay:inv.dueDate earlierThanDay:[NSDate date]] ) {
        lblStatus.font = [UIFont fontWithName:APP_BOLD_FONT size:INVOICE_FONT_SIZE];
        lblStatus.textColor = [UIColor redColor];
    } else if ([PAYMENT_UNPAID isEqualToString:inv.paymentStatus]
               && [Util isSameDay:inv.dueDate otherDay:[NSDate date]]) {
        lblStatus.font = [UIFont fontWithName:APP_BOLD_FONT size:INVOICE_FONT_SIZE];
        lblStatus.textColor = [UIColor orangeColor];
    } else if ([PAYMENT_SCHEDULED isEqualToString:inv.paymentStatus]
               || [PAYMENT_PENDING isEqualToString:inv.paymentStatus]
               || [PAYMENT_PARTIAL isEqualToString:inv.paymentStatus]) {
        lblStatus.font = [UIFont fontWithName:APP_BOLD_FONT size:INVOICE_FONT_SIZE];
        lblStatus.textColor = [UIColor colorWithRed:60/255.0 green:90/255.0 blue:180/255.0 alpha:1.0];
    } else {
        lblStatus.font = [UIFont fontWithName:APP_FONT size:INVOICE_FONT_SIZE];
    }
    lblStatus.textAlignment = NSTextAlignmentLeft;
    [cell addSubview:lblStatus];
    
    UILabel * lblDueDateLabel = [[UILabel alloc] initWithFrame:DUE_DATE_LABEL_RECT];
    lblDueDateLabel.text = @"Due";
    lblDueDateLabel.font = [UIFont fontWithName:APP_FONT size:INVOICE_FONT_SIZE];
    lblDueDateLabel.textAlignment = NSTextAlignmentLeft;
    [cell addSubview:lblDueDateLabel];
    
    UILabel * lblDueDate = [[UILabel alloc] initWithFrame:DUE_DATE_RECT];
    lblDueDate.text = [Util formatDate:inv.dueDate format:nil]; //[@"Due " stringByAppendingString:[Util formatDate:inv.dueDate format:nil]];
    lblDueDate.font = [UIFont fontWithName:APP_FONT size:INVOICE_FONT_SIZE];
    lblDueDate.textAlignment = NSTextAlignmentLeft;
    [cell addSubview:lblDueDate];
    
    UILabel * lblAmount = [[UILabel alloc] initWithFrame:AMOUNT_RECT];
    lblAmount.text = [@"Amount " stringByAppendingString:[Util formatCurrency:inv.amount]];
    lblAmount.font = [UIFont fontWithName:APP_FONT size:INVOICE_FONT_SIZE];
    lblAmount.textAlignment = NSTextAlignmentLeft;
    [cell addSubview:lblAmount];
    
    UILabel * lblAmountDue = [[UILabel alloc] initWithFrame:AMOUNT_DUE_RECT];
    lblAmountDue.text = [Util formatCurrency:inv.amountDue];
    lblAmountDue.font = [UIFont fontWithName:APP_FONT size:INVOICE_FONT_SIZE];
    lblAmountDue.textAlignment = NSTextAlignmentLeft;
    [cell addSubview:lblAmountDue];
    
    if (self.mode == kAttachMode) {
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return INVOICE_TABLE_SECTION_HEADER_HEIGHT;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:SECTION_HEADER_RECT];
    [UIHelper addGradientForView:headerView];
    
    UILabel *label;
    UIButton *sectionButton = nil;
    
    if (!self.isActive) {
        label = [[UILabel alloc] initWithFrame:SECTION_HEADER_LABEL_RECT];
        [UIHelper initializeHeaderLabel:label];
        label.text = ALL_INACTIVE_INVS;
    } else {
        if ([self.sortAttribute isEqualToString:INV_CUSTOMER_NAME] || [self.sortAttribute isEqualToString:INV_DUE_DATE]) {
            label = [[UILabel alloc] initWithFrame:SECTION_HEADER_LABEL_RECT2];
            [UIHelper initializeHeaderLabel:label];
            
            if ([self.sortAttribute isEqualToString:INV_CUSTOMER_NAME]) {
    //            label.text = [Customer objectForKey:((Invoice *)[[self.customerInvoices objectAtIndex:section] objectAtIndex:0]).customerId].name;
                label.text = [self.customerSectionLabels objectAtIndex:section];
                
                UILabel *qtyAndAmountLabel = [[UILabel alloc] initWithFrame:SECTION_HEADER_QTY_AMT_RECT];
                [UIHelper initializeHeaderLabel:qtyAndAmountLabel];
                NSMutableString *qtyAndAmount = [NSMutableString stringWithFormat:@"Total: %d / ", ((NSArray *)[self.invoiceListsCopy objectAtIndex:section]).count];
                [qtyAndAmount appendString:[Util formatCurrency:[self.customerTotalInvoiceAmounts objectAtIndex:section]]];
                
                qtyAndAmountLabel.text = qtyAndAmount;
                [headerView addSubview:qtyAndAmountLabel];
                
                UIButton *btn = [self.customerSectionButtons objectAtIndex:section];
                btn.tag = section;
                sectionButton = btn;
                
    //            UIImageView *accessoryImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Accessory_disclosure.png"]];
    //            accessoryImage.frame = SECTION_ACCESSORY_RECT;
    //            [headerView addSubview:accessoryImage];
            } else if ([self.sortAttribute isEqualToString:INV_DUE_DATE]) {
                NSArray *invs = nil;
                NSDecimalNumber *amt = nil;
                
                label.text = [self.dueDateSectionLabels objectAtIndex:section];
                invs = [self.dueDateInvoices objectAtIndex:section];
                amt = [self.dueDateAmounts objectAtIndex:section];            
                            
                UILabel *qtyAndAmountLabel = [[UILabel alloc] initWithFrame:SECTION_HEADER_QTY_AMT_RECT];
                [UIHelper initializeHeaderLabel:qtyAndAmountLabel];
                NSMutableString *qtyAndAmount = [NSMutableString stringWithFormat:@"Total: %d / ", ((NSArray *)[self.invoiceListsCopy objectAtIndex:section]).count];
                if (amt) {
                    [qtyAndAmount appendString:[Util formatCurrency:amt]];
                }
                
                qtyAndAmountLabel.text = qtyAndAmount;
                [headerView addSubview:qtyAndAmountLabel];
                
                UIButton *btn = [self.dueDateSectionButtons objectAtIndex:section];
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
            label.text = ALL_OPEN_INVS;
            
            UILabel *qtyAndAmountLabel = [[UILabel alloc] initWithFrame:SECTION_HEADER_QTY_AMT_RECT];
            [UIHelper initializeHeaderLabel:qtyAndAmountLabel];
            NSMutableString *qtyAndAmount = [NSMutableString stringWithFormat:@"Total: %d / ", self.invoices.count];
//            if (self.totalInvoiceAmount) {
                [qtyAndAmount appendString:[Util formatCurrency:self.totalInvoiceAmount]];
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
    return INVOICE_TABLE_CELL_HEIGHT;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.editing) {
        return YES;
    } else {
        return NO;
    }
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        Invoice *inv;
        
        if (!self.isActive) {
            inv = [self.invoices objectAtIndex:indexPath.row];
            [self.invoices removeObjectAtIndex:indexPath.row];
            [inv revive];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            if ([self.sortAttribute isEqualToString:INV_CUSTOMER_NAME]) {
                inv = [[self.customerInvoices objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
                
                [[self.customerInvoices objectAtIndex:indexPath.section] removeObjectAtIndex:indexPath.row];
                if (((NSArray*)[self.customerInvoices objectAtIndex:indexPath.section]).count == 0) {
                    [self.customerInvoices removeObjectAtIndex:indexPath.section];
                    [self.customerSectionLabels removeObjectAtIndex:indexPath.section];
                    [self.customerTotalInvoiceAmounts removeObjectAtIndex:indexPath.section];
                    [self.customerSectionButtons removeObjectAtIndex:indexPath.section];
                    [self.invoiceListsCopy removeObjectAtIndex:indexPath.section];
                    [self.tableView reloadData];
                } else {
//                    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                    NSDecimalNumber *subTotalAmt = [self.customerTotalInvoiceAmounts objectAtIndex:indexPath.section];
                    NSDecimalNumber *newSubTotalAmt = [subTotalAmt decimalNumberBySubtracting:inv.amount];
                    [self.customerTotalInvoiceAmounts replaceObjectAtIndex:indexPath.section withObject:newSubTotalAmt];
                    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:indexPath.section];
                    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            } else if ([self.sortAttribute isEqualToString:INV_DUE_DATE]) {
                inv = [[self.dueDateInvoices objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
                
                [[self.dueDateInvoices objectAtIndex:indexPath.section] removeObjectAtIndex:indexPath.row];
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            } else {
                inv = [self.invoices objectAtIndex:indexPath.row];
                
                [self.invoices removeObjectAtIndex:indexPath.row];
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            
            [inv remove];
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
        if (self.lastSelected != nil) { // TODO: may need to reset self.lastSelected on viewWillAppear
            UITableViewCell *oldRow = [self.tableView cellForRowAtIndexPath:self.lastSelected];
            oldRow.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        }
        
        UITableViewCell *newRow = [self.tableView cellForRowAtIndexPath:indexPath];
        newRow.accessoryType = UITableViewCellAccessoryCheckmark;
        
        self.lastSelected = indexPath;
    } else {
        Invoice *inv;
        
        if (!self.isActive) {
            inv = [self.invoices objectAtIndex:indexPath.row];
        } else {
            if ([self.sortAttribute isEqualToString:INV_CUSTOMER_NAME]) {
                inv = [[self.customerInvoices objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            } else if ([self.sortAttribute isEqualToString:INV_DUE_DATE]) {
                inv = [[self.dueDateInvoices objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            } else {
                inv = [self.invoices objectAtIndex:indexPath.row];
            }
        }

        [self performSegueWithIdentifier:VIEW_INVOICE_SEGUE sender:inv];
    }
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if ([self tryTap]) {
        [self performSegueWithIdentifier:VIEW_INVOICE_SEGUE sender:[self.invoices objectAtIndex:indexPath.row]];
    }
}

#pragma mark - Invoice delegate

- (void)didGetInvoices:(NSArray *)invoiceList {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.refreshControl.attributedTitle = LAST_REFRESHED;
        [self.refreshControl endRefreshing];
    });

    self.invoices = [self sortInvoices:invoiceList];
}

- (void)failedToGetInvoices {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
    });    
}

- (void)didDeleteObject {
    self.invoices = [Invoice listOrderBy:INV_NUMBER ascending:YES active:self.isActive];
    self.invoices = [self sortInvoices:self.invoices];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - Action Menu delegate

- (void)didSelectSortAttribute:(NSString *)attribute ascending:(BOOL)ascending active:(BOOL)active {
    NSArray *invoiceList;
    
    if (active) {
        if (!self.isActive || !self.invoices) {
            invoiceList = [Invoice list];
            self.isActive = YES;
        } else {
            invoiceList = [Invoice list]; //self.invoices;//have to do [Invoice List] for customer/due date sort cases
        }
    } else {
        if (self.isActive || !self.invoices) {
            invoiceList = [Invoice listInactive];
            self.isActive = NO;
        } else {
            invoiceList = [Invoice listInactive]; //self.invoices;
        }
    }
    
    self.sortAttribute = attribute ? attribute : INV_NUMBER;
    self.isAsc = ascending;
    
    self.invoices = [self sortInvoices:invoiceList];
    
    if (invoiceList.count) {
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
//        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

//- (void)didSelectCrudAction:(NSString *)action {
//    if ([action isEqualToString:ACTION_CREATE]) {
//        [self.view removeGestureRecognizer:self.tapRecognizer];
//        [self performSegueWithIdentifier:CREATE_INVOICE_SEGUE sender:nil];
//    } else if ([action isEqualToString:ACTION_DELETE] || [action isEqualToString:ACTION_UNDELETE]) {
//        [self enterEditMode];
//    }
//}

#pragma mark - private methods

- (void)toggleSection:(UIButton *)sender {
    if ([self tryTap]) {
        NSInteger section = sender.tag;
        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:section];
        
        if ([self.sortAttribute isEqualToString:INV_CUSTOMER_NAME] || [self.sortAttribute isEqualToString:INV_DUE_DATE]) {
            if ([self.sortAttribute isEqualToString:INV_CUSTOMER_NAME]) {
                if ([self.tableView numberOfRowsInSection:section] > 0) {
                    [self.customerInvoices replaceObjectAtIndex:section withObject:[NSMutableArray array]];
                } else {
                    [self.customerInvoices replaceObjectAtIndex:section withObject:[self.invoiceListsCopy objectAtIndex:section]];
                }
            } else if ([self.sortAttribute isEqualToString:INV_DUE_DATE]) {
                if ([self.tableView numberOfRowsInSection:section] > 0) {
                    [self.dueDateInvoices replaceObjectAtIndex:section withObject:[NSMutableArray array]];
                } else {
                    [self.dueDateInvoices replaceObjectAtIndex:section withObject:[self.invoiceListsCopy objectAtIndex:section]];
                }
            }
            
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
            
//            for (UIView *view in sender.superview.subviews) {
//                if ([view isMemberOfClass:[UIImageView class]]) {
//                    UIImageView *toggleImage = (UIImageView *)view;
//                    toggleImage.transform = CGAffineTransformMakeRotation(- M_PI_2 * ([self.tableView numberOfRowsInSection:section] == 0));
//                }
//            }
        }
    }
}

- (NSMutableArray *)sortInvoices:(NSArray *)invoiceArr  {
    NSMutableArray * invoiceList = [Invoice list:invoiceArr orderBy:self.sortAttribute ascending:self.isAsc];

    if ([self.sortAttribute isEqualToString:INV_DUE_DATE]) {
        self.overDueInvoices = [NSMutableArray array];
        self.dueIn7DaysInvoices = [NSMutableArray array];
        self.dueOver7DaysInvoices = [NSMutableArray array];
        
        self.overDueInvoiceAmount = [NSDecimalNumber zero];
        self.dueIn7DaysInvoiceAmount = [NSDecimalNumber zero];
        self.dueOver7DaysInvoiceAmount = [NSDecimalNumber zero];
        
        self.overDueSectionButton = [[UIButton alloc] initWithFrame:SECTION_HEADER_RECT];
        self.overDueSectionButton.alpha = 0.1;
        [self.overDueSectionButton addTarget:self action:@selector(toggleSection:) forControlEvents:UIControlEventTouchUpInside];
        
        self.dueIn7DaysSectionButton = [[UIButton alloc] initWithFrame:SECTION_HEADER_RECT];
        self.dueIn7DaysSectionButton.alpha = 0.1;
        [self.dueIn7DaysSectionButton addTarget:self action:@selector(toggleSection:) forControlEvents:UIControlEventTouchUpInside];
        
        self.dueOver7DaysSectionButton = [[UIButton alloc] initWithFrame:SECTION_HEADER_RECT];
        self.dueOver7DaysSectionButton.alpha = 0.1;
        [self.dueOver7DaysSectionButton addTarget:self action:@selector(toggleSection:) forControlEvents:UIControlEventTouchUpInside];
        
        NSDate *today = [NSDate date];
        NSDate *nextWeek = [NSDate dateWithTimeIntervalSinceNow: 3600 * 24 * 7];
        
        for(Invoice *inv in invoiceList) {
            if ([Util isDay:inv.dueDate earlierThanDay:today]) {
                [self.overDueInvoices addObject:inv];
                self.overDueInvoiceAmount = [self.overDueInvoiceAmount decimalNumberByAdding:inv.amount];
            } else if ([Util isDay:inv.dueDate earlierThanDay:nextWeek]) {
                [self.dueIn7DaysInvoices addObject:inv];
                self.dueIn7DaysInvoiceAmount = [self.dueIn7DaysInvoiceAmount decimalNumberByAdding:inv.amount];
            } else {
                [self.dueOver7DaysInvoices addObject:inv];
                self.dueOver7DaysInvoiceAmount = [self.dueOver7DaysInvoiceAmount decimalNumberByAdding:inv.amount];
            }            
        }
        
        if (self.isAsc) {
            self.dueDateInvoices = [NSMutableArray arrayWithObjects:self.overDueInvoices, self.dueIn7DaysInvoices, self.dueOver7DaysInvoices, nil];
            self.dueDateAmounts = [NSArray arrayWithObjects:self.overDueInvoiceAmount, self.dueIn7DaysInvoiceAmount, self.dueOver7DaysInvoiceAmount, nil];
            self.dueDateSectionButtons = @[self.overDueSectionButton, self.dueIn7DaysSectionButton, self.dueOver7DaysSectionButton];
            self.dueDateSectionLabels = @[OVERDUE, DUE_IN_7, DUE_OVER_7];
        } else {
            self.dueDateInvoices = [NSMutableArray arrayWithObjects:self.dueOver7DaysInvoices, self.dueIn7DaysInvoices, self.overDueInvoices, nil];
            self.dueDateAmounts = [NSArray arrayWithObjects:self.dueOver7DaysInvoiceAmount, self.dueIn7DaysInvoiceAmount, self.overDueInvoiceAmount, nil];
            self.dueDateSectionButtons = @[self.dueOver7DaysSectionButton, self.dueIn7DaysSectionButton, self.overDueSectionButton];
            self.dueDateSectionLabels = @[DUE_OVER_7, DUE_IN_7, OVERDUE];
        }
        
        self.invoiceListsCopy = [NSMutableArray array];
        for (NSArray *invs in self.dueDateInvoices) {
            [self.invoiceListsCopy addObject:invs];
        }
    } else if ([self.sortAttribute isEqualToString:INV_CUSTOMER_NAME]) {
        self.customerInvoices = [NSMutableArray array];
        self.customerTotalInvoiceAmounts = [NSMutableArray array];
        self.customerSectionButtons = [NSMutableArray array];
        self.customerSectionLabels = [NSMutableArray array];
        NSString *currName = @"";

        for (Invoice *inv in invoiceList) {
            if ([currName isEqualToString:[Customer objectForKey:inv.customerId].name]) {
                NSInteger idx = self.customerInvoices.count - 1;
                [[self.customerInvoices objectAtIndex:idx] addObject:inv];
                
                NSDecimalNumber * amt = [self.customerTotalInvoiceAmounts objectAtIndex:idx];
                amt = [amt decimalNumberByAdding:inv.amount];
                [self.customerTotalInvoiceAmounts replaceObjectAtIndex:idx withObject:amt];
            } else {
                NSMutableArray *newCustomerInvArr = [NSMutableArray array];
                [self.customerInvoices addObject:newCustomerInvArr];
                [newCustomerInvArr addObject:inv];
                currName = [Customer objectForKey:inv.customerId].name;
                
                NSDecimalNumber *amt = [NSDecimalNumber zero];
                amt = [amt decimalNumberByAdding:inv.amount];
                [self.customerTotalInvoiceAmounts addObject:amt];
                
                UIButton *btn = [[UIButton alloc] initWithFrame:SECTION_HEADER_RECT];
                btn.alpha = 0.1;
//                btn.tag = self.customerSectionButtons.count;
                [btn addTarget:self action:@selector(toggleSection:) forControlEvents:UIControlEventTouchUpInside];
                [self.customerSectionButtons addObject:btn];
                
                [self.customerSectionLabels addObject:currName];
            }
        }
        
        self.invoiceListsCopy = [NSMutableArray array];
        for (NSArray *invs in self.customerInvoices) {
            [self.invoiceListsCopy addObject:invs];
        }
    } else {
        self.totalInvoiceAmount = [NSDecimalNumber zero];
        
        for(Invoice *inv in invoiceList) {
            self.totalInvoiceAmount = [self.totalInvoiceAmount decimalNumberByAdding:inv.amount];
        }
    }

    return invoiceList;
}

@end
