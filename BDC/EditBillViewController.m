//
//  EditBillViewController.m
//  BDC
//
//  Created by Qinwei Gong on 4/23/13.
//
//

#import "EditBillViewController.h"
#import "VendorsTableViewController.h"
#import "Bill.h"
#import "APLineItem.h"                              //temp
//#import "APLineItemsTableViewController.h"
#import "ScannerViewController.h"
#import "AttachmentPreviewViewController.h"
#import "EditVendorViewController.h"
#import "PayBillViewController.h"
//#import "EditAPLineItemViewController.h"
#import "Util.h"
#import "Constants.h"
#import "UIHelper.h"
#import "Vendor.h"
#import "BankAccount.h"
#import "Organization.h"
#import "Document.h"

#import <QuartzCore/QuartzCore.h>
#import <MessageUI/MessageUI.h>
#import <QuickLook/QuickLook.h>

enum BillSections {
    kBillInfo,
    kBillLineItems,
    kBillDocs
};

enum InfoType {
    kBillVendor,
    kBillNumber,
    kBillDate,
    kBillDueDate,
    kBillApprovalStatus,
    kBillPaymentStatus
};

typedef enum {
    kEditBill, kEmailBill, kDeleteBill, kCancelBillAction
} BillActionIndice;

#define BILL_ACTIONS                    [NSArray arrayWithObjects:@"Pay bill", @"Edit Bill", @"Delete bill", @"Cancel", nil]

#define BILL_INFO_CELL_ID               @"BillInfo"
#define BILL_ITEM_CELL_ID               @"BillLineItem"
#define BILL_ATTACH_CELL_ID             @"BillDocs"

#define BILL_SELECT_VENDOR_SEGUE        @"SelectVendorForBill"
#define BILL_SCAN_PHOTO_SEGUE           @"ScanMoreBillPhoto"
//#define BILL_PREVIEW_ATTACHMENT_SEGUE   @"PreviewBillDoc"
#define BILL_VIEW_VENDOR_DETAILS_SEGUE  @"ViewVendorDetails"
#define BILL_PAY_BILL_SEGUE             @"PayBill"

#define BILL_LABEL_FONT_SIZE            13
#define BillInfo                 [NSArray arrayWithObjects:@"Vendor", @"Invoice #", @"Inv Date", @"Due Date", @"Approval", @"Payment", nil]
#define BILL_INFO_INPUT_RECT     CGRectMake(CELL_WIDTH - 190, 5, 190, CELL_HEIGHT - 10)
#define BILL_ITEM_ACCOUNT_RECT   CGRectMake(cell.viewForBaselineLayout.bounds.origin.x + 46, 6, 150, cell.viewForBaselineLayout.bounds.size.height - 10)
#define BILL_ITEM_AMOUNT_RECT    CGRectMake(cell.viewForBaselineLayout.bounds.size.width - 115, 6, 100, cell.viewForBaselineLayout.bounds.size.height - 10)

#define DELETE_BILL_ALERT_TAG           1
#define REMOVE_ATTACHMENT_ALERT_TAG     2


@interface EditBillViewController () <VendorSelectDelegate, ScannerDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIActionSheetDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate>

@property (nonatomic, strong) NSDecimalNumber *totalAmount;
@property (nonatomic, strong) UIDatePicker *billDatePicker;
@property (nonatomic, strong) UIDatePicker *dueDatePicker;

@property (nonatomic, strong) UITextField *billNumTextField;
@property (nonatomic, strong) UITextField *billDateTextField;
@property (nonatomic, strong) UITextField *billDueDateTextField;
//@property (nonatomic, strong) UILabel *billApprovalStatusLabel;
//@property (nonatomic, strong) UILabel *billPaymentStatusLabel;
@property (nonatomic, strong) UILabel *billPaidAmountLabel;
@property (nonatomic, strong) UILabel *billAmountLabel;

@property (nonatomic, strong) UIPickerView *accountPickerView;

@property (nonatomic, strong) MFMailComposeViewController *mailer;

@property (nonatomic, strong) NSArray *chartOfAccounts;

@property (nonatomic, strong) UITextField *currentField;

@end


@implementation EditBillViewController

@synthesize totalAmount;
@synthesize billDatePicker;
@synthesize dueDatePicker;
@synthesize billNumTextField;
@synthesize billDateTextField;
@synthesize billDueDateTextField;
//@synthesize billApprovalStatusLabel;
//@synthesize billPaymentStatusLabel;
@synthesize billPaidAmountLabel;
@synthesize billAmountLabel;
@synthesize accountPickerView;
@synthesize mailer;
@synthesize chartOfAccounts;
@synthesize currentField;

- (Class)busObjClass {
    return [Bill class];
}

- (NSIndexPath *)getAttachmentPath {
    return [NSIndexPath indexPathForRow:0 inSection:kBillDocs];
}

- (NSIndexSet *)getNonAttachmentSections {
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(kBillInfo, kBillLineItems)];
}

- (NSString *)getDocImageAPI {
    return DOC_IMAGE_API;
}

- (NSString *)getDocIDParam {
    return ID;
}

- (void)handleRemovalForDocument:(Document *)doc {
    [Document addToInbox:doc];
}

- (void)setMode:(ViewMode)mode {
    self.totalAmount = [NSDecimalNumber zero];
    
    [super setMode:mode];
    
    [self setActions];
}

- (void)refreshView {
    [super refreshView];
    
    Organization *org = [Organization getSelectedOrg];
    [org retrieveNeedApprovalToPayBill];
}

//- (void)quitAttachMode {
//    [self.shaddowBusObj read];
//}

#pragma mark - private methods

- (void)updateLineItems {
    self.totalAmount = [NSDecimalNumber zero];
    
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:kBillLineItems];
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)setLineItems:(NSArray *)lineItems {    
    [self updateLineItems];
}

- (void)addMoreItems {
    [self.view findAndResignFirstResponder];
    
    APLineItem *newItem = [[APLineItem alloc] init];
    newItem.amount = [NSDecimalNumber zero];
    [((Bill *)self.shaddowBusObj).lineItems addObject:newItem];
    self.totalAmount = [NSDecimalNumber zero];
    
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:kBillLineItems];
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)addMoreAttachment {
    [self.view findAndResignFirstResponder];
    [self performSegueWithIdentifier:BILL_SCAN_PHOTO_SEGUE sender:self];
}


#pragma mark - Target Action

- (IBAction)saveBusObj:(UIBarButtonItem *)sender {
    if ([self tryTap]) {
        [self.view findAndResignFirstResponder];
        
        Bill *shaddowBill = (Bill *)self.shaddowBusObj;
        
        if (shaddowBill.vendorId == nil) {
            [UIHelper showInfo:@"No vendor chosen" withStatus:kError];
            return;
        }
        
        if (shaddowBill.invoiceNumber == nil) {
            [UIHelper showInfo:@"No invoice number" withStatus:kError];
            return;
        }
        
        if ([shaddowBill.lineItems count] == 0) {
            [UIHelper showInfo:@"No amount" withStatus:kError];
            return;
        }
        
        [super saveBusObj:sender];
        
        if (self.mode == kCreateMode || self.mode == kAttachMode) {
            [shaddowBill create];
        } else if (self.mode == kUpdateMode){
            [shaddowBill update];
        }
    }
}

- (void)setActions {
    if (self.mode == kViewMode) {
        self.crudActions = nil;
        
        if (((Bill *)self.shaddowBusObj).paymentStatus && ![((Bill *)self.shaddowBusObj).paymentStatus isEqualToString:PAYMENT_UNPAID]) {
            self.crudActions = [NSArray arrayWithObjects:ACTION_UPDATE, nil];
        } else {
            if (self.isActive) {
                self.crudActions = [NSArray arrayWithObjects:ACTION_UPDATE, ACTION_DELETE, nil];
            } else {
                self.crudActions = [NSArray arrayWithObjects:ACTION_UPDATE, ACTION_UNDELETE, nil];
            }
        }
        
        if (self.isActive) {
            Organization *org = [Organization getSelectedOrg];
            
            if ((!org.needApprovalToPayBill
                 || [((Bill *)self.shaddowBusObj).approvalStatus isEqualToString:APPROVAL_UNASSIGNED]
                 || [((Bill *)self.shaddowBusObj).approvalStatus isEqualToString:APPROVAL_APPROVED])
                && ([((Bill *)self.shaddowBusObj).paymentStatus isEqualToString:PAYMENT_UNPAID]
                    || [((Bill *)self.shaddowBusObj).paymentStatus isEqualToString:PAYMENT_PARTIAL]))
            {
                self.crudActions = [@[ACTION_PAY] arrayByAddingObjectsFromArray:self.crudActions];
            }
        }
    }
}

#pragma mark - Life Cycle

- (void)viewDidLoad
{
    if (!self.busObj) {
        self.busObj = [[Bill alloc] init];
        self.shaddowBusObj = [[Bill alloc] init];
    }
    
    if (self.shaddowBusObj.newBorn) {
        [self.shaddowBusObj read];
    }
    
    [super viewDidLoad];
    
    [self setActions];
    
    if (self.mode != kViewMode) {
        self.crudActions = nil;
        
        if (self.mode == kCreateMode || self.mode == kAttachMode) {
            self.title = @"New Bill";
        }
    }
        
    self.totalAmount = [NSDecimalNumber zero];
    
    self.busObj.editDelegate = self;
    self.shaddowBusObj.editDelegate = self;
    
    self.billDatePicker = [[UIDatePicker alloc] initWithFrame:PICKER_RECT];
    self.billDatePicker.datePickerMode = UIDatePickerModeDate;
    [self.billDatePicker addTarget:self action:@selector(selectBillDateFromPicker:) forControlEvents:UIControlEventValueChanged];
    
    self.dueDatePicker = [[UIDatePicker alloc] initWithFrame:PICKER_RECT];
    self.dueDatePicker.datePickerMode = UIDatePickerModeDate;
    [self.dueDatePicker addTarget:self action:@selector(selectDueDateFromPicker:) forControlEvents:UIControlEventValueChanged];
    
    self.billNumTextField = [[UITextField alloc] initWithFrame:BILL_INFO_INPUT_RECT];
    [self initializeTextField:self.billNumTextField];
    self.billNumTextField.tag = kBillNumber * TAG_BASE;
    self.billNumTextField.delegate = self;
    self.billNumTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    self.billDateTextField = [[UITextField alloc] initWithFrame:BILL_INFO_INPUT_RECT];
    [self initializeTextField:self.billDateTextField];
    self.billDateTextField.tag = kBillDate * TAG_BASE;
    self.billDateTextField.clearButtonMode = UITextFieldViewModeNever;
    self.billDateTextField.inputView = self.billDatePicker;
    self.billDateTextField.inputAccessoryView = self.inputAccessoryView;
//    self.billDateTextField.inputAccessoryView = [self inputAccessoryViewForTag:kBillDate];
    
    self.billDueDateTextField = [[UITextField alloc] initWithFrame:BILL_INFO_INPUT_RECT];
    [self initializeTextField:self.billDueDateTextField];
    self.billDueDateTextField.tag = kBillDueDate * TAG_BASE;
    self.billDueDateTextField.clearButtonMode = UITextFieldViewModeNever;
    self.billDueDateTextField.inputView = self.dueDatePicker;
    self.billDueDateTextField.inputAccessoryView = self.inputAccessoryView;
//    self.billDueDateTextField.inputAccessoryView = [self inputAccessoryViewForTag:kBillDueDate];
    
//    self.billApprovalStatusLabel = [[UILabel alloc] initWithFrame:BILL_INFO_INPUT_RECT];
//    self.billApprovalStatusLabel.font = [UIFont fontWithName:APP_FONT size:BILL_LABEL_FONT_SIZE];
//    self.billApprovalStatusLabel.textColor = APP_LABEL_BLUE_COLOR;
//    self.billApprovalStatusLabel.textAlignment = NSTextAlignmentRight;
//    
//    self.billPaymentStatusLabel = [[UILabel alloc] initWithFrame:BILL_INFO_INPUT_RECT];
//    self.billPaymentStatusLabel.font = [UIFont fontWithName:APP_FONT size:BILL_LABEL_FONT_SIZE];
//    self.billPaymentStatusLabel.textColor = APP_LABEL_BLUE_COLOR;
//    self.billPaymentStatusLabel.textAlignment = NSTextAlignmentRight;

    self.billPaidAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(CELL_WIDTH - 100, 24, 100, 20)];
    self.billPaidAmountLabel.font = [UIFont fontWithName:APP_FONT size:14];
    self.billPaidAmountLabel.textColor = APP_LABEL_BLUE_COLOR;
    self.billPaidAmountLabel.textAlignment = NSTextAlignmentRight;
    self.billPaidAmountLabel.backgroundColor = [UIColor clearColor];

    self.billAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(CELL_WIDTH - 100, 3, 100, 20)];
    self.billAmountLabel.textAlignment = NSTextAlignmentRight;
    self.billAmountLabel.font = [UIFont fontWithName:APP_FONT size:15];
    self.billAmountLabel.backgroundColor = [UIColor clearColor];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activityIndicator.hidesWhenStopped = YES;
    
    self.chartOfAccounts = [ChartOfAccount listOrderBy:ACCOUNT_NAME ascending:YES active:YES];
    
    self.accountPickerView = [[UIPickerView alloc] initWithFrame:PICKER_RECT];
    self.accountPickerView.delegate = self;
    self.accountPickerView.dataSource = self;
    self.accountPickerView.showsSelectionIndicator = YES;
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:BILL_SELECT_VENDOR_SEGUE]) {
        [segue.destinationViewController setMode:kSelectMode];
        ((VendorsTableViewController *)segue.destinationViewController).selectDelegate = self;
    } else if ([segue.identifier isEqualToString:BILL_SCAN_PHOTO_SEGUE]) {
        ((ScannerViewController *)segue.destinationViewController).delegate = self;
        [segue.destinationViewController setMode:kAttachMode];
//    } else if ([segue.identifier isEqualToString:BILL_PREVIEW_ATTACHMENT_SEGUE]) {
//        NSInteger idx = ((UIImageView *)sender).tag;
//        if (self.mode != kCreateMode && self.mode != kAttachMode) {
//            idx--;
//        }
//        [segue.destinationViewController setDocument:[self.shaddowBusObj.attachments objectAtIndex:idx]];
    } else if ([segue.identifier isEqualToString:BILL_VIEW_VENDOR_DETAILS_SEGUE]) {
        [segue.destinationViewController setBusObj:sender];
        [segue.destinationViewController setMode:kViewMode];
    } else if ([segue.identifier isEqualToString:BILL_PAY_BILL_SEGUE]) {
        [segue.destinationViewController setBill:(Bill *)self.shaddowBusObj];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kBillInfo) {        
        if (self.mode == kViewMode) {
            return [BillInfo count];
        } else {
            return [BillInfo count] - 2;
        }
    } else if (section == kBillLineItems) {
        return [((Bill *)self.shaddowBusObj).lineItems count];
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    Bill *shaddowBill = (Bill *)self.shaddowBusObj;
    
    switch (indexPath.section) {
        case kBillInfo:
        {
            if (self.modeChanged) {
                if (self.mode == kViewMode) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:BILL_INFO_CELL_ID];
                } else {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:BILL_INFO_CELL_ID];
                }
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:BILL_INFO_CELL_ID];
                if (!cell) {
                    if (self.mode == kViewMode) {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:BILL_INFO_CELL_ID];
                    } else {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:BILL_INFO_CELL_ID];
                    }
                }
            }
            
            cell.textLabel.text = [BillInfo objectAtIndex:indexPath.row];
            cell.textLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:BILL_LABEL_FONT_SIZE];
            cell.detailTextLabel.font = [UIFont fontWithName:APP_FONT size:BILL_LABEL_FONT_SIZE];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            switch (indexPath.row) {
                case kBillVendor:
                    if (self.mode == kViewMode) {
                        if (shaddowBill.vendorId != nil) {
                            cell.detailTextLabel.text = [Vendor objectForKey:shaddowBill.vendorId].name;
                        } else {
                            cell.detailTextLabel.text = nil;
                        }
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    } else {
                        if (shaddowBill.vendorId != nil) {
                            cell.detailTextLabel.text = [Vendor objectForKey:shaddowBill.vendorId].name;
                        } else {
                            cell.detailTextLabel.text = SELECT_ONE;
                        }
                        
                        if (!shaddowBill.paymentStatus || [shaddowBill.paymentStatus isEqualToString:PAYMENT_UNPAID]) {
                            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        }
                    }
                    
                    break;
                case kBillNumber:
                    if (self.mode == kViewMode) {
                        if (shaddowBill.invoiceNumber != nil) {
                            cell.detailTextLabel.text = shaddowBill.invoiceNumber;
                        } else {
                            cell.detailTextLabel.text = nil;
                        }
                    } else {
                        if (shaddowBill.invoiceNumber != nil) {
                            self.billNumTextField.text = shaddowBill.invoiceNumber;
                        }
                        self.billNumTextField.backgroundColor = cell.backgroundColor;
                        
                        [cell addSubview:self.billNumTextField];
                    }
                    break;
                case kBillDate:
                    if (self.mode == kViewMode) {
                        if (shaddowBill.invoiceDate != nil) {
                            cell.detailTextLabel.text = [Util formatDate:shaddowBill.invoiceDate format:nil];
                        } else {
                            cell.detailTextLabel.text = nil;
                        }
                    } else {
                        if (shaddowBill.invoiceDate != nil) {
                            self.billDatePicker.date = shaddowBill.invoiceDate;
                            self.billDateTextField.text = [Util formatDate:shaddowBill.invoiceDate format:nil];
                        } else {
                            self.billDatePicker.date = [NSDate date];
                            self.billDateTextField.text = [Util formatDate:[NSDate date] format:nil];
                            shaddowBill.invoiceDate = [NSDate date];
                        }
                        self.billDateTextField.backgroundColor = cell.backgroundColor;
                        
                        [cell addSubview:self.billDateTextField];
                    }
                    break;
                case kBillDueDate:
                    if (self.mode == kViewMode) {
                        if (shaddowBill.dueDate != nil) {
                            cell.detailTextLabel.text = [Util formatDate:shaddowBill.dueDate format:nil];
                        } else {
                            cell.detailTextLabel.text = nil;
                        }
                    } else {
                        if (shaddowBill.dueDate != nil) {
                            self.dueDatePicker.date = shaddowBill.dueDate;
                            self.billDueDateTextField.text = [Util formatDate:shaddowBill.dueDate format:nil];
                        } else {
                            self.dueDatePicker.date = [NSDate date];
                            self.billDueDateTextField.text = [Util formatDate:[NSDate date] format:nil];
                            shaddowBill.dueDate = [NSDate date];
                        }
                        self.billDueDateTextField.backgroundColor = cell.backgroundColor;
                        
                        [cell addSubview:self.billDueDateTextField];
                    }
                    break;
                case kBillApprovalStatus:
//                    cell.textLabel.numberOfLines = 2;
//                    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
                    
                    if (shaddowBill.approvalStatus != nil) {
                        cell.detailTextLabel.text = [APPROVAL_STATUSES objectForKey:shaddowBill.approvalStatus];
                    } else {
                        cell.detailTextLabel.text = @"Unassigned";
                    }
                    break;
                case kBillPaymentStatus:
//                    cell.textLabel.numberOfLines = 2;
//                    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
                    if (shaddowBill.paymentStatus != nil) {
                        cell.detailTextLabel.text = [PAYMENT_STATUSES objectForKey:shaddowBill.paymentStatus];
                    } else {
                        cell.detailTextLabel.text = nil;
                    }
                    break;
//                case kBillPaidAmount:
//                    cell.detailTextLabel.text = [Util formatCurrency:self.shaddowBill.paidAmount];
                    break;
                default:
                    break;
            }
            
        }
            break;
        case kBillLineItems:
        {
//            if (self.modeChanged) {
//                if (self.mode == kViewMode) {
//                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:BILL_ITEM_CELL_ID];
//                } else {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:BILL_ITEM_CELL_ID];
//                }
//            } else {
//                cell = [tableView dequeueReusableCellWithIdentifier:BILL_ITEM_CELL_ID];
//                if (!cell) {
//                    if (self.mode == kViewMode) {
//                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:BILL_ITEM_CELL_ID];
//                    } else {
//                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:BILL_ITEM_CELL_ID];
//                    }
//                }
//            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.numberOfLines = 2;
            cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
            
            APLineItem *item = [shaddowBill.lineItems objectAtIndex:indexPath.row];
            ChartOfAccount *account = item.account;
            
            if (self.mode == kViewMode || (((Bill *)self.shaddowBusObj).paymentStatus && ![((Bill *)self.shaddowBusObj).paymentStatus isEqualToString:PAYMENT_UNPAID])) {
                cell.textLabel.text = account ? account.name : @" ";
                cell.textLabel.font = [UIFont fontWithName:APP_FONT size:BILL_LABEL_FONT_SIZE];
                [cell.textLabel sizeToFit];
                
                cell.detailTextLabel.text = [Util formatCurrency:item.amount];
                cell.detailTextLabel.font = [UIFont fontWithName:APP_FONT size:BILL_LABEL_FONT_SIZE];
            } else {
                UITextField *itemAccountField = [[UITextField alloc] initWithFrame:BILL_ITEM_ACCOUNT_RECT];
                itemAccountField.text = account && account.name.length ? account.name : @"None";
                [self initializeTextField:itemAccountField];
                itemAccountField.textAlignment = NSTextAlignmentCenter;
                itemAccountField.inputView = self.accountPickerView;
                itemAccountField.rightViewMode = UITextFieldViewModeAlways;
                itemAccountField.delegate = self;
                itemAccountField.tag = [BillInfo count] * TAG_BASE + indexPath.row * 2;
                itemAccountField.objectTag = item;
                
                [cell addSubview:itemAccountField];
                
                UITextField *itemAmountTextField = [[UITextField alloc] initWithFrame:BILL_ITEM_AMOUNT_RECT];
                if ((self.mode != kCreateMode && self.mode != kAttachMode) || [item.amount isEqualToNumber:0]) {
                    itemAmountTextField.text = [Util formatCurrency:item.amount];
                }
                [self initializeTextField:itemAmountTextField];
                itemAmountTextField.keyboardType = UIKeyboardTypeDecimalPad;
//                itemAmountTextField.objectTag = item;
                itemAmountTextField.delegate = self;
                itemAmountTextField.tag = [BillInfo count] * TAG_BASE + indexPath.row * 2 + 1;
                itemAmountTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
                
                [cell addSubview:itemAmountTextField];
                
                [self.tableView setEditing:YES animated:YES];
            }
            
            self.totalAmount = [self.totalAmount decimalNumberByAdding:item.amount];
        }
            break;
        case kBillDocs:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:BILL_ATTACH_CELL_ID];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:BILL_ATTACH_CELL_ID];
            }
            
            [cell.contentView addSubview:self.attachmentScrollView];
            [cell.contentView addSubview:self.attachmentPageControl];
            cell.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        }
            break;
        default:
            break;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kBillInfo) {
        return CELL_HEIGHT;
    } else if (indexPath.section == kBillLineItems) {
        return CELL_HEIGHT;
    } else {
        return IMG_HEIGHT + IMG_PADDING + ATTACHMENT_PV_HEIGHT;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == kBillInfo) {
        return 0;
    } else if (section == kBillLineItems) {
        return 30;
    } else {
        return 30;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == kBillInfo) {
        return 20;
    } else if (section == kBillLineItems) { // && [self.shaddowBill.lineItems count] > 0) {
        return 50; //35;
    } else {
        return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == kBillInfo) {
        return nil;
    } else if (section == kBillLineItems) {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 360, 40)];
        headerView.backgroundColor = [UIColor clearColor];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 100, 20)];
        label.text = @"Line Items";
        label.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = APP_SYSTEM_BLUE_COLOR;
        label.shadowColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0, 1);
        
        [headerView addSubview:label];
        
        if (self.mode != kViewMode && (!((Bill *)self.shaddowBusObj).paymentStatus || [((Bill *)self.shaddowBusObj).paymentStatus isEqualToString:PAYMENT_UNPAID])) {
            UIButton *addButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
            CGRect frame = CGRectMake(265, -10, 40, 40);
            addButton.frame = frame;
            addButton.backgroundColor = [UIColor clearColor];
            [addButton addTarget:self action:@selector(addMoreItems) forControlEvents:UIControlEventTouchUpInside];
            
            [headerView addSubview:addButton];
        }
        
        return headerView;
    } else {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 360, 30)];
        headerView.backgroundColor = [UIColor clearColor];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 200, 20)];
        label.text = @"Documents";
        label.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = APP_SYSTEM_BLUE_COLOR;
        label.shadowColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0, 1);
        
        [headerView addSubview:label];
        
        if (self.mode != kViewMode) {
            UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
            CGRect frame = CGRectMake(265, -10, 40, 40);
            cameraButton.frame = frame;
            cameraButton.backgroundColor = [UIColor clearColor];
            [cameraButton addTarget:self action:@selector(addMoreAttachment) forControlEvents:UIControlEventTouchUpInside];
            
            [headerView addSubview:cameraButton];
        }
        
        return headerView;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == kBillLineItems) { // && [self.shaddowBill.lineItems count] > 0) {
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 360, 30)];
        footerView.backgroundColor = [UIColor clearColor];
        
        UILabel *amoutLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 3, 85, 20)];
        amoutLabel.text = @"Bill Amount:";
        amoutLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:14];
        amoutLabel.backgroundColor = [UIColor clearColor];
        amoutLabel.textColor = APP_LABEL_BLUE_COLOR;
        amoutLabel.textAlignment = NSTextAlignmentRight;
        [footerView addSubview:amoutLabel];
        
        self.billAmountLabel.text = [Util formatCurrency:self.totalAmount];        
        ((Bill *)self.shaddowBusObj).amount = self.totalAmount;
        [footerView addSubview:self.billAmountLabel];
        
        UILabel *paidAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 24, 85, 20)];
        paidAmountLabel.text = @"Paid:";
        paidAmountLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:13];
        paidAmountLabel.backgroundColor = [UIColor clearColor];
        paidAmountLabel.textColor = APP_LABEL_BLUE_COLOR;
        paidAmountLabel.textAlignment = NSTextAlignmentRight;
        [footerView addSubview:paidAmountLabel];

        self.billPaidAmountLabel.text = [Util formatCurrency:((Bill *)self.shaddowBusObj).paidAmount];
        [footerView addSubview:self.billPaidAmountLabel];
        
        return footerView;
    }
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kBillLineItems && self.mode != kViewMode) {
        return YES;
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kBillLineItems) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            // Delete the row from the data source
            [((Bill *)self.shaddowBusObj).lineItems removeObjectAtIndex:indexPath.row];
            [self updateLineItems];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    
    if (self.mode != kViewMode) {
        switch (indexPath.section) {
            case kBillInfo:
                switch (indexPath.row) {
                    case kBillVendor:
                    {
                        Bill *shaddowBill = (Bill *)self.shaddowBusObj;
                        if (!shaddowBill.paymentStatus || [shaddowBill.paymentStatus isEqualToString:PAYMENT_UNPAID]) {
                            [self performSegueWithIdentifier:BILL_SELECT_VENDOR_SEGUE sender:self];
                        }
                        
                        break;
                    }
                    default:
                        break;
                }
                break;
            default:
                break;
        }
    } else {
        switch (indexPath.section) {
            case kBillInfo:
                switch (indexPath.row) {
                    case kBillVendor:
                    {
                        Vendor *vendor = [Vendor objectForKey:((Bill *)self.shaddowBusObj).vendorId];
                        vendor.editBillDelegate = self;
                        [self performSegueWithIdentifier:BILL_VIEW_VENDOR_DETAILS_SEGUE sender:vendor];
                    }
                        break;
                    default:
                        break;
                }
                break;
            default:
                break;
        }
    }
}

#pragma mark - Text Field delegate

// private
- (void)textFieldDoneEditing:(UITextField *)textField {
    if (textField.tag == kBillNumber * TAG_BASE) {
        ((Bill *)self.shaddowBusObj).invoiceNumber = [Util trim:textField.text];
    } else {
        int idx = (textField.tag - [BillInfo count] * TAG_BASE) / 2;
        APLineItem * item = [((Bill *)self.shaddowBusObj).lineItems objectAtIndex:idx];
        
        if (textField.tag % 2) {
            self.totalAmount = [self.totalAmount decimalNumberBySubtracting:item.amount];
            item.amount = [Util parseCurrency:textField.text];
            self.totalAmount = [self.totalAmount decimalNumberByAdding:item.amount];
            self.billAmountLabel.text = [Util formatCurrency:self.totalAmount];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    [self textFieldDoneEditing:textField];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.currentField = textField;
    
    if (textField.objectTag) {
        APLineItem *item = textField.objectTag;
        int row;
        
        if (item.account.objectId) {
            row = [self.chartOfAccounts indexOfObject:item.account] + 1;
        } else {
            row = 0;
        }

        [self.accountPickerView selectRow:row inComponent:0 animated:NO];
    }
    
    [super textFieldDidBeginEditing:textField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self textFieldDoneEditing:textField];
    self.currentField = nil;
    
    [super textFieldDidEndEditing:textField];
}

#pragma mark - Date Picker target action

- (void)selectBillDateFromPicker:(UIDatePicker *)sender {
    self.billDateTextField.text = [Util formatDate:sender.date format:nil];
    ((Bill *)self.shaddowBusObj).invoiceDate = sender.date;
}

- (void)selectDueDateFromPicker:(UIDatePicker *)sender {
    self.billDueDateTextField.text = [Util formatDate:sender.date format:nil];
    ((Bill *)self.shaddowBusObj).dueDate = sender.date;
}

#pragma mark - Alert delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case DELETE_BILL_ALERT_TAG:
            if (buttonIndex == 1) {
                [self.busObj remove];
            }
            break;
        case REMOVE_ATTACHMENT_ALERT_TAG:
            if (buttonIndex == 1) {
                UIImageView *imageView = self.currAttachment;
                if (imageView != nil) {
                    for (UIGestureRecognizer *recognizer in imageView.gestureRecognizers) {
                        [imageView removeGestureRecognizer:recognizer];
                    }
                    
                    NSInteger idx = imageView.tag;
                    if (self.mode != kCreateMode || self.mode != kAttachMode) {
                        idx--;
                    }
                    
                    [((Bill *)self.shaddowBusObj).attachments removeObjectAtIndex:idx];
                    [imageView removeFromSuperview];
                    [self layoutScrollImages:NO];
                    
                    self.currAttachment = nil;
                }
            }
        default:
            [super alertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
    }
}

#pragma mark - UIPickerView Datascource

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.chartOfAccounts count] + 1;
}

- (NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (row == 0) {
        return @"None";
    }
    return ((ChartOfAccount *)[self.chartOfAccounts objectAtIndex: row - 1]).name;
}

#pragma mark - UIPickerView Delegate

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    int idx = (self.currentField.tag - [BillInfo count] * TAG_BASE) / 2;
    APLineItem * item = [((Bill *)self.shaddowBusObj).lineItems objectAtIndex:idx];
    
    if (row == 0) {
        self.currentField.text = @"None";
        item.account = nil;
    } else {
        self.currentField.text = ((ChartOfAccount *)[self.chartOfAccounts objectAtIndex:row - 1]).name;
        item.account = [self.chartOfAccounts objectAtIndex:row - 1];
    }
}

#pragma mark - model delegate

- (void)didReadObject {    
    self.totalAmount = [NSDecimalNumber zero];
    [super didReadObject];

    [self.shaddowBusObj cloneTo:self.busObj];
    ((Bill *)self.busObj).amount = ((Bill *)self.shaddowBusObj).amount;
    
    [self setActions];
    [self.actionMenuVC.tableView reloadData];
}

//- (void)didCreateObject:(NSString *)newObjectId {
//    [super didCreateObject:newObjectId];
//}

- (void)didUpdateObject {
    [super didUpdateObject];
    
    ((Bill *)self.busObj).amount = self.totalAmount;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.actionMenuVC.tableView reloadData];
    });
}

- (void)didSelectVendor:(NSString *)vendorId {
    ((Bill *)self.shaddowBusObj).vendorId = vendorId;
    
    NSIndexPath *path = [NSIndexPath indexPathForRow:kBillVendor inSection:kBillInfo];
    [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)didSelectItems:(NSArray *)items {
    for (APLineItem *item in items) {
        [((Bill *)self.shaddowBusObj).lineItems addObject:item];
    }
    
    [self updateLineItems];
}

- (void)didUpdateVendor {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath *path = [NSIndexPath indexPathForRow:kBillVendor inSection:kBillInfo];
        [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:YES];
    });
}

- (void)didModifyItem:(APLineItem *)item forIndex:(int)index {
    [APLineItem clone:item to:[((Bill *)self.shaddowBusObj).lineItems objectAtIndex:index]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateLineItems];
    });
}

#pragma mark - Action Menu delegate

- (void)didSelectCrudAction:(NSString *)action {
    [super didSelectCrudAction:action];
    
    if ([action isEqualToString:ACTION_PAY]) {
//        if ([((NSArray *)[BankAccount list]) count]) {
            [self performSegueWithIdentifier:BILL_PAY_BILL_SEGUE sender:self];
//        } else {
//            [UIHelper showInfo:@"You haven't set up bank account in Bill.com!" withStatus:kInfo];
//        }
    }
}


@end
