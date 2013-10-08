//
//  EditBillViewController.m
//  BDC
//
//  Created by Qinwei Gong on 4/23/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
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
#define BILL_IMAGE_CELL_ID              @"BillImage"

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

#define VENDOR_PICKER_TAG               1
#define ACCOUNT_PICKER_TAG              2


@interface EditBillViewController () <VendorSelectDelegate, ScannerDelegate, PayBillDelegate, UITextFieldDelegate, UIScrollViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIActionSheetDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate>

@property (nonatomic, strong) NSDecimalNumber *totalAmount;
@property (nonatomic, strong) UIDatePicker *billDatePicker;
@property (nonatomic, strong) UIDatePicker *dueDatePicker;

@property (nonatomic, strong) UITextField *billVendorTextField;
@property (nonatomic, strong) UIToolbar *billVendorInputAccessoryView;
@property (nonatomic, strong) UITextField *billVendorInputAccessoryTextField;
@property (nonatomic, strong) UIBarButtonItem *billVendorInputAccessoryTextItem;
@property (nonatomic, strong) UIBarButtonItem *billVendorInputAccessoryDoneItem;
@property (nonatomic, strong) UIBarButtonItem *billVendorInputAccessoryNextItem;

@property (nonatomic, strong) UITextField *billNumTextField;
@property (nonatomic, strong) UIToolbar *billNumInputAccessoryView;
@property (nonatomic, strong) UITextField *billNumInputAccessoryTextField;
@property (nonatomic, strong) UIBarButtonItem *billNumInputAccessoryTextItem;
//@property (nonatomic, strong) UIBarButtonItem *billNumInputAccessoryPrevItem;
//@property (nonatomic, strong) UIBarButtonItem *billNumInputAccessoryNextItem;
@property (nonatomic, strong) UISegmentedControl *billNumInputAccessoryNavSwitch;
@property (nonatomic, strong) UIBarButtonItem *billNumInputAccessoryNavItem;
@property (nonatomic, strong) UIBarButtonItem *billNumInputAccessoryDoneItem;

@property (nonatomic, strong) UITextField *billDateTextField;
@property (nonatomic, strong) UIToolbar *billDateInputAccessoryView;
@property (nonatomic, strong) UITextField *billDateInputAccessoryTextField;
@property (nonatomic, strong) UIBarButtonItem *billDateInputAccessoryTextItem;
//@property (nonatomic, strong) UIBarButtonItem *billDateInputAccessoryPrevItem;
//@property (nonatomic, strong) UIBarButtonItem *billDateInputAccessoryNextItem;
@property (nonatomic, strong) UISegmentedControl *billDateInputAccessoryNavSwitch;
@property (nonatomic, strong) UIBarButtonItem *billDateInputAccessoryNavItem;
@property (nonatomic, strong) UIBarButtonItem *billDateInputAccessoryDoneItem;

@property (nonatomic, strong) UITextField *billDueDateTextField;
@property (nonatomic, strong) UIToolbar *billDueDateInputAccessoryView;
@property (nonatomic, strong) UITextField *billDueDateInputAccessoryTextField;
@property (nonatomic, strong) UIBarButtonItem *billDueDateInputAccessoryTextItem;
@property (nonatomic, strong) UIBarButtonItem *billDueDateInputAccessoryPrevItem;
@property (nonatomic, strong) UIBarButtonItem *billDueDateInputAccessoryDoneItem;

@property (nonatomic, strong) UIToolbar *billItemAccountInputAccessoryView;
@property (nonatomic, strong) UITextField *billItemAccountInputAccessoryTextField;
@property (nonatomic, strong) UIBarButtonItem *billItemAccountInputAccessoryTextItem;
@property (nonatomic, strong) UIBarButtonItem *billItemAccountInputAccessoryPrevItem;
@property (nonatomic, strong) UIBarButtonItem *billItemAccountInputAccessoryDoneItem;

@property (nonatomic, strong) UIToolbar *billItemAmountInputAccessoryView;
@property (nonatomic, strong) UITextField *billItemAmountInputAccessoryTextField;
@property (nonatomic, strong) UIBarButtonItem *billItemAmountInputAccessoryTextItem;
@property (nonatomic, strong) UIBarButtonItem *billItemAmountInputAccessoryPrevItem;
@property (nonatomic, strong) UIBarButtonItem *billItemAmountInputAccessoryDoneItem;

@property (nonatomic, strong) NSMutableArray *itemAccountTextFields;
@property (nonatomic, strong) NSMutableArray *itemAmountTextFields;

//@property (nonatomic, strong) UILabel *billApprovalStatusLabel;
//@property (nonatomic, strong) UILabel *billPaymentStatusLabel;
@property (nonatomic, strong) UILabel *billPaidAmountLabel;
@property (nonatomic, strong) UILabel *billAmountLabel;

@property (nonatomic, strong) UIPickerView *accountPickerView;
@property (nonatomic, strong) UIPickerView *vendorPickerView;

@property (nonatomic, strong) MFMailComposeViewController *mailer;

@property (nonatomic, strong) NSArray *chartOfAccounts;

@property (nonatomic, strong) UITextField *currentField;

@property (nonatomic, strong) NSArray *vendors;

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
@synthesize vendorPickerView;
@synthesize mailer;
@synthesize chartOfAccounts;
@synthesize currentField;
@synthesize vendors;

@synthesize billVendorTextField;
@synthesize billVendorInputAccessoryView;
@synthesize billVendorInputAccessoryTextField;
@synthesize billVendorInputAccessoryTextItem;
@synthesize billVendorInputAccessoryDoneItem;
@synthesize billVendorInputAccessoryNextItem;

@synthesize billNumInputAccessoryView;
@synthesize billNumInputAccessoryTextField;
@synthesize billNumInputAccessoryTextItem;
//@synthesize billNumInputAccessoryPrevItem;
//@synthesize billNumInputAccessoryNextItem;
@synthesize billNumInputAccessoryNavSwitch;
@synthesize billNumInputAccessoryNavItem;
@synthesize billNumInputAccessoryDoneItem;

@synthesize billDateInputAccessoryView;
@synthesize billDateInputAccessoryTextField;
@synthesize billDateInputAccessoryTextItem;
//@synthesize billDateInputAccessoryPrevItem;
//@synthesize billDateInputAccessoryNextItem;
@synthesize billDateInputAccessoryNavSwitch;
@synthesize billDateInputAccessoryNavItem;
@synthesize billDateInputAccessoryDoneItem;

@synthesize billDueDateInputAccessoryView;
@synthesize billDueDateInputAccessoryTextField;
@synthesize billDueDateInputAccessoryTextItem;
@synthesize billDueDateInputAccessoryPrevItem;
@synthesize billDueDateInputAccessoryDoneItem;

@synthesize billItemAccountInputAccessoryView;
@synthesize billItemAccountInputAccessoryTextField;
@synthesize billItemAccountInputAccessoryTextItem;
@synthesize billItemAccountInputAccessoryPrevItem;
@synthesize billItemAccountInputAccessoryDoneItem;

@synthesize billItemAmountInputAccessoryView;
@synthesize billItemAmountInputAccessoryTextField;
@synthesize billItemAmountInputAccessoryTextItem;
@synthesize billItemAmountInputAccessoryPrevItem;
@synthesize billItemAmountInputAccessoryDoneItem;

@synthesize itemAccountTextFields;
@synthesize itemAmountTextFields;


- (Class)busObjClass {
    return [Bill class];
}

- (BOOL)isAP {
    return YES;
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
//    [org retrieveNeedApprovalToPayBill];
    [org getOrgPrefs];
}

//- (void)quitAttachMode {
//    [self.shaddowBusObj read];
//}

#pragma mark - private methods

- (void)updateLineItems {
    self.totalAmount = [NSDecimalNumber zero];
    
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:kBillLineItems];
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
    self.billAmountLabel.text = [Util formatCurrency:self.totalAmount];
}

- (void)setLineItems:(NSArray *)lineItems {    
    [self updateLineItems];
}

- (void)addMoreItems {
    if ([self tryTap]) {
        [self.view findAndResignFirstResponder];
        
        APLineItem *newItem = [[APLineItem alloc] init];
        newItem.amount = [NSDecimalNumber zero];
        [((Bill *)self.shaddowBusObj).lineItems addObject:newItem];
        self.totalAmount = [NSDecimalNumber zero];
        
        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:kBillLineItems];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        
        if (self.mode == kAttachMode && self.firstItemAdded) {
            UITextField *itemAccountField = self.itemAccountTextFields[self.itemAccountTextFields.count - 1];
            [itemAccountField becomeFirstResponder];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:kBillDocs] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        } else if (self.mode != kAttachMode) {
            self.billAmountLabel.text = [Util formatCurrency:self.totalAmount];
        }
    }
}

- (void)addMoreAttachment {
    if ([self tryTap]) {
        [self.view findAndResignFirstResponder];
        [self performSegueWithIdentifier:BILL_SCAN_PHOTO_SEGUE sender:self];
    }
}


#pragma mark - Target Action

- (void)hideAdditionalKeyboard {
    [self.billVendorInputAccessoryTextField resignFirstResponder];
    [self.billNumInputAccessoryTextField resignFirstResponder];
    [self.billDateInputAccessoryTextField resignFirstResponder];
    [self.billDueDateInputAccessoryTextField resignFirstResponder];
}

- (void)hideAdditionalKeyboardAndScrollUp {
    [self hideAdditionalKeyboard];
    
}

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
        
        [self hideAdditionalKeyboard];
        [self scrollToTop];
        
        [super saveBusObj:sender];
        
        if (self.mode == kCreateMode || self.mode == kAttachMode) {
            [shaddowBill create];
        } else if (self.mode == kUpdateMode){
            [shaddowBill update];
        }
    }
}

- (void)setActions {
    if (self.mode == kViewMode && [Organization getSelectedOrg].enableAP) {
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.mode == kAttachMode && !self.viewHasAppeared) {
        self.viewHasAppeared = YES;
        
        [self.billVendorTextField becomeFirstResponder];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:kBillDocs] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        [self.billVendorInputAccessoryTextField becomeFirstResponder];
        if (self.vendors.count) {
            [self didSelectVendor:self.vendors[0]];
        }
    }
}

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
    
    if (self.mode == kAttachMode) {
        if (![self.shaddowBusObj.attachments[0] isImage]) {
            self.mode = kCreateMode;
        }
    }
    
    if (self.mode == kCreateMode || self.mode == kAttachMode) {
        if (!self.firstItemAdded) {
            [self addMoreItems];
        }
        
        if (self.mode == kAttachMode) {
            self.attachmentImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, SCREEN_WIDTH - 20, NORMAL_SCREEN_HEIGHT)];

            BOOL usingImageData = YES;
            Document *doc = (Document *)self.shaddowBusObj.attachments[0];
            NSData *imgData = doc.data;
            if (!imgData || imgData.length == 0) {
                if ([doc docFileExists]) {
                    self.attachmentImageView.image = [UIImage imageWithContentsOfFile:[doc getDocFilePath]];
                } else {
                    usingImageData = NO;
                    imgData = doc.thumbnail;
                    doc.documentDelegate = nil;                     // nil or self?
                    [self downloadAttachPreviewDocument:doc];
                }
            }
            if (!self.attachmentImageView.image && imgData) {
                self.attachmentImageView.image = [UIImage imageWithData:imgData];
            }
            
            self.previewScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, SCREEN_WIDTH - 20, NORMAL_SCREEN_HEIGHT - PORTRAIT_KEYBOARD_HEIGHT)];
            self.previewScrollView.delegate = self;
            self.previewScrollView.contentSize = self.attachmentImageView.bounds.size;
            self.previewScrollView.showsHorizontalScrollIndicator = NO;
            self.previewScrollView.showsVerticalScrollIndicator = NO;
            self.previewScrollView.scrollEnabled = YES;
            self.previewScrollView.maximumZoomScale = 4.0;
            self.previewScrollView.minimumZoomScale = 1.0;
            self.previewScrollView.bouncesZoom = YES;
            
            [self.previewScrollView addSubview:self.attachmentImageView];
            
            if (!usingImageData) {
                self.attachmentImageObscure = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, SCREEN_WIDTH - 20, NORMAL_SCREEN_HEIGHT)];
                self.attachmentImageObscure.backgroundColor = [UIColor lightGrayColor];
                self.attachmentImageObscure.alpha = 0.9;
                
                self.attachmentImageDownloadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
                self.attachmentImageDownloadingIndicator.center = CGPointMake((SCREEN_WIDTH) / 2 , (NORMAL_SCREEN_HEIGHT - PORTRAIT_KEYBOARD_HEIGHT) / 2);
                self.attachmentImageDownloadingIndicator.hidesWhenStopped = YES;
                [self.attachmentImageDownloadingIndicator startAnimating];

                [self.attachmentImageView addSubview:self.attachmentImageObscure];
                [self.previewScrollView addSubview:self.attachmentImageDownloadingIndicator];
            }
        }
    }
    
    self.vendors = [Vendor listOrderBy:VENDOR_NAME ascending:YES active:YES];
    self.chartOfAccounts = [ChartOfAccount list];
    
    self.accountPickerView = [[UIPickerView alloc] initWithFrame:PICKER_RECT];
    self.accountPickerView.delegate = self;
    self.accountPickerView.dataSource = self;
    self.accountPickerView.showsSelectionIndicator = YES;
    self.accountPickerView.tag = ACCOUNT_PICKER_TAG;
    
    self.vendorPickerView = [[UIPickerView alloc] initWithFrame:PICKER_RECT];
    self.vendorPickerView.delegate = self;
    self.vendorPickerView.dataSource = self;
    self.vendorPickerView.showsSelectionIndicator = YES;
    self.vendorPickerView.tag = VENDOR_PICKER_TAG;
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    
    // Vendor
    self.billVendorTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    
    self.billVendorInputAccessoryView = [[UIToolbar alloc] initWithFrame:INPUT_ACCESSORY_VIEW_FRAME];
    self.billVendorInputAccessoryView.barStyle = UIBarStyleBlackTranslucent;
    
    self.billVendorInputAccessoryDoneItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:INPUT_ACCESSORY_DONE]
                                                                             style:UIBarButtonItemStyleDone
                                                                            target:self
                                                                            action:@selector(changeInputAccessoryViewFor:)];
    self.billVendorInputAccessoryNextItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:INPUT_ACCESSORY_NEXT]
                                                                             style:UIBarButtonItemStyleDone
                                                                            target:self
                                                                            action:@selector(changeInputAccessoryViewFor:)];
    if (self.mode != kAttachMode) {
        self.billVendorInputAccessoryView.items = [NSArray arrayWithObjects:self.billVendorInputAccessoryNextItem, flexibleSpace, self.billVendorInputAccessoryDoneItem, nil];
    } else {
        UIBarButtonItem *billVendorAccessoryLabelItem = [self initializeInputAccessoryLabelItem:@"Vendor"];
        self.billVendorInputAccessoryTextField = [self initializeInputAccessoryTextField];
        self.billVendorInputAccessoryTextField.inputView = self.vendorPickerView;
        self.billVendorInputAccessoryTextItem = [[UIBarButtonItem alloc] initWithCustomView:self.billVendorInputAccessoryTextField];
        self.billVendorInputAccessoryView.items = [NSArray arrayWithObjects:self.billVendorInputAccessoryNextItem, billVendorAccessoryLabelItem, self.billVendorInputAccessoryTextItem, flexibleSpace, self.billVendorInputAccessoryDoneItem, nil];
    }
    self.billVendorTextField.inputAccessoryView = self.billVendorInputAccessoryView;
    
    
    // Invoice Number
    self.billNumTextField = [[UITextField alloc] initWithFrame:BILL_INFO_INPUT_RECT];
    [self initializeTextField:self.billNumTextField];
    self.billNumTextField.tag = kBillNumber * TAG_BASE;
    self.billNumTextField.delegate = self;
    self.billNumTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    self.billNumInputAccessoryView = [[UIToolbar alloc] initWithFrame:INPUT_ACCESSORY_VIEW_FRAME];
    self.billNumInputAccessoryView.barStyle = UIBarStyleBlackTranslucent;
    
    self.billNumInputAccessoryNavSwitch = [[UISegmentedControl alloc] initWithItems:@[@"", @""]];
    [self.billNumInputAccessoryNavSwitch setImage:[UIImage imageNamed:INPUT_ACCESSORY_PREV] forSegmentAtIndex:0];
    [self.billNumInputAccessoryNavSwitch setImage:[UIImage imageNamed:INPUT_ACCESSORY_NEXT] forSegmentAtIndex:1];
    self.billNumInputAccessoryNavSwitch.frame = INPUT_ACCESSORY_NAV_FRAME;
    self.billNumInputAccessoryNavSwitch.segmentedControlStyle = UISegmentedControlStyleBar;
    self.billNumInputAccessoryNavSwitch.tintColor = APP_BUTTON_BLUE_COLOR;
    [self.billNumInputAccessoryNavSwitch addTarget:self action:@selector(changeInputAccessoryViewFor:) forControlEvents:UIControlEventValueChanged];
    self.billNumInputAccessoryNavItem = [[UIBarButtonItem alloc] initWithCustomView:self.billNumInputAccessoryNavSwitch];
    
    self.billNumInputAccessoryDoneItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:INPUT_ACCESSORY_DONE]
                                                                          style:UIBarButtonItemStyleDone
                                                                         target:self
                                                                         action:@selector(changeInputAccessoryViewFor:)];
    
    if (self.mode != kAttachMode) {
        self.billNumInputAccessoryView.items = [NSArray arrayWithObjects:self.billNumInputAccessoryNavItem, flexibleSpace, self.billNumInputAccessoryDoneItem, nil];
    } else {
        UIBarButtonItem *billNumAccessoryLabelItem = [self initializeInputAccessoryLabelItem:@"Invoice #"];
        self.billNumInputAccessoryTextField = [self initializeInputAccessoryTextField:YES];
        self.billNumInputAccessoryTextItem = [[UIBarButtonItem alloc] initWithCustomView:self.billNumInputAccessoryTextField];
        self.billNumInputAccessoryView.items = [NSArray arrayWithObjects:self.billNumInputAccessoryNavItem, billNumAccessoryLabelItem, self.billNumInputAccessoryTextItem, flexibleSpace, self.billNumInputAccessoryDoneItem, nil];
    }
    self.billNumTextField.inputAccessoryView = self.billNumInputAccessoryView;
    
    
    // Invoice Date
    self.billDatePicker = [[UIDatePicker alloc] initWithFrame:PICKER_RECT];
    self.billDatePicker.datePickerMode = UIDatePickerModeDate;
    [self.billDatePicker addTarget:self action:@selector(selectBillDateFromPicker:) forControlEvents:UIControlEventValueChanged];
    
    self.billDateTextField = [[UITextField alloc] initWithFrame:BILL_INFO_INPUT_RECT];
    [self initializeTextField:self.billDateTextField];
    self.billDateTextField.delegate = self;
    self.billDateTextField.tag = kBillDate * TAG_BASE;
    self.billDateTextField.clearButtonMode = UITextFieldViewModeNever;
    self.billDateTextField.inputView = self.billDatePicker;
    
    self.billDateInputAccessoryView = [[UIToolbar alloc] initWithFrame:INPUT_ACCESSORY_VIEW_FRAME];
    self.billDateInputAccessoryView.barStyle = UIBarStyleBlackTranslucent;
    
    self.billDateInputAccessoryNavSwitch = [[UISegmentedControl alloc] initWithItems:@[@"", @""]];
    [self.billDateInputAccessoryNavSwitch setImage:[UIImage imageNamed:INPUT_ACCESSORY_PREV] forSegmentAtIndex:0];
    [self.billDateInputAccessoryNavSwitch setImage:[UIImage imageNamed:INPUT_ACCESSORY_NEXT] forSegmentAtIndex:1];
    self.billDateInputAccessoryNavSwitch.frame = INPUT_ACCESSORY_NAV_FRAME;
    self.billDateInputAccessoryNavSwitch.segmentedControlStyle = UISegmentedControlStyleBar;
    self.billDateInputAccessoryNavSwitch.tintColor = APP_BUTTON_BLUE_COLOR;
    [self.billDateInputAccessoryNavSwitch addTarget:self action:@selector(changeInputAccessoryViewFor:) forControlEvents:UIControlEventValueChanged];
    self.billDateInputAccessoryNavItem = [[UIBarButtonItem alloc] initWithCustomView:self.billDateInputAccessoryNavSwitch];
    
    self.billDateInputAccessoryDoneItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:INPUT_ACCESSORY_DONE]
                                                                           style:UIBarButtonItemStyleDone
                                                                          target:self
                                                                          action:@selector(changeInputAccessoryViewFor:)];
    if (self.mode != kAttachMode) {
        self.billDateInputAccessoryView.items = [NSArray arrayWithObjects:self.billDateInputAccessoryNavItem, flexibleSpace, self.billDateInputAccessoryDoneItem, nil];
    } else {
        UIBarButtonItem *billDateAccessoryLabelItem = [self initializeInputAccessoryLabelItem:@"Inv Date"];
        self.billDateInputAccessoryTextField = [self initializeInputAccessoryTextField:YES];
        self.billDateInputAccessoryTextField.inputView = self.billDatePicker;
        self.billDateInputAccessoryTextItem = [[UIBarButtonItem alloc] initWithCustomView:self.billDateInputAccessoryTextField];

        self.billDateInputAccessoryView.items = [NSArray arrayWithObjects:self.billDateInputAccessoryNavItem, billDateAccessoryLabelItem, self.billDateInputAccessoryTextItem, flexibleSpace, self.billDateInputAccessoryDoneItem, nil];
    }
    self.billDateTextField.inputAccessoryView = self.billDateInputAccessoryView;
    
    
    // Due Date
    self.dueDatePicker = [[UIDatePicker alloc] initWithFrame:PICKER_RECT];
    self.dueDatePicker.datePickerMode = UIDatePickerModeDate;
    [self.dueDatePicker addTarget:self action:@selector(selectDueDateFromPicker:) forControlEvents:UIControlEventValueChanged];
    
    self.billDueDateTextField = [[UITextField alloc] initWithFrame:BILL_INFO_INPUT_RECT];
    [self initializeTextField:self.billDueDateTextField];
    self.billDueDateTextField.delegate = self;
    self.billDueDateTextField.tag = kBillDueDate * TAG_BASE;
    self.billDueDateTextField.clearButtonMode = UITextFieldViewModeNever;
    self.billDueDateTextField.inputView = self.dueDatePicker;

    self.billDueDateInputAccessoryView = [[UIToolbar alloc] initWithFrame:INPUT_ACCESSORY_VIEW_FRAME];
    self.billDueDateInputAccessoryView.barStyle = UIBarStyleBlackTranslucent;

    self.billDueDateInputAccessoryPrevItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:INPUT_ACCESSORY_PREV]
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(changeInputAccessoryViewFor:)];
    self.billDueDateInputAccessoryDoneItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:INPUT_ACCESSORY_DONE]
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(changeInputAccessoryViewFor:)];
    if (self.mode != kAttachMode) {
        self.billDueDateInputAccessoryView.items = [NSArray arrayWithObjects:self.billDueDateInputAccessoryPrevItem, flexibleSpace, self.billDueDateInputAccessoryDoneItem, nil];
    } else {
        UIBarButtonItem *billDueDateAccessoryLabelItem = [self initializeInputAccessoryLabelItem:@"Due Date"];
        self.billDueDateInputAccessoryTextField = [self initializeInputAccessoryTextField];
        self.billDueDateInputAccessoryTextField.inputView = self.dueDatePicker;
        self.billDueDateInputAccessoryTextItem = [[UIBarButtonItem alloc] initWithCustomView:self.billDueDateInputAccessoryTextField];
        
        self.billDueDateInputAccessoryView.items = [NSArray arrayWithObjects:self.billDueDateInputAccessoryPrevItem, billDueDateAccessoryLabelItem, self.billDueDateInputAccessoryTextItem, flexibleSpace, self.billDueDateInputAccessoryDoneItem, nil];
    }
    self.billDueDateTextField.inputAccessoryView = self.billDueDateInputAccessoryView;
    
    
    // Line Item
    self.billItemAccountInputAccessoryDoneItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:INPUT_ACCESSORY_DONE]
                                                                                  style:UIBarButtonItemStyleDone
                                                                                 target:self
                                                                                 action:@selector(changeInputAccessoryViewFor:)];
    self.billItemAccountInputAccessoryView = [[UIToolbar alloc] initWithFrame:INPUT_ACCESSORY_VIEW_FRAME];
    self.billItemAccountInputAccessoryView.barStyle = UIBarStyleBlackTranslucent;
    if (self.mode != kAttachMode) {
        self.billItemAccountInputAccessoryView.items = [NSArray arrayWithObjects:flexibleSpace, self.billItemAccountInputAccessoryDoneItem, nil];
    } else {
        UIBarButtonItem *billItemAccountAccessoryLabelItem = [self initializeInputAccessoryLabelItem:@"Account"];
        self.billItemAccountInputAccessoryView.items = [NSArray arrayWithObjects:billItemAccountAccessoryLabelItem, flexibleSpace, self.billItemAccountInputAccessoryDoneItem, nil];
    }
    
    self.billItemAmountInputAccessoryView = [[UIToolbar alloc] initWithFrame:INPUT_ACCESSORY_VIEW_FRAME];
    self.billItemAmountInputAccessoryView.barStyle = UIBarStyleBlackTranslucent;
    
    self.billItemAmountInputAccessoryDoneItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:INPUT_ACCESSORY_DONE]
                                                                                 style:UIBarButtonItemStyleDone
                                                                                target:self
                                                                                action:@selector(changeInputAccessoryViewFor:)];
    if (self.mode != kAttachMode) {
        self.billItemAmountInputAccessoryView.items = [NSArray arrayWithObjects:flexibleSpace, self.billItemAmountInputAccessoryDoneItem, nil];
    } else {
        UIBarButtonItem *billItemAmountAccessoryLabelItem = [self initializeInputAccessoryLabelItem:@"Amount"];
        self.billItemAmountInputAccessoryTextField = [self initializeInputAccessoryTextField];
        self.billItemAmountInputAccessoryTextField.userInteractionEnabled = NO;
        self.billItemAmountInputAccessoryTextItem = [[UIBarButtonItem alloc] initWithCustomView:self.billItemAmountInputAccessoryTextField];
        
        self.billItemAmountInputAccessoryView.items = [NSArray arrayWithObjects:billItemAmountAccessoryLabelItem, self.billItemAmountInputAccessoryTextItem, flexibleSpace, self.billItemAmountInputAccessoryDoneItem, nil];
    }
    

    self.billPaidAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(CELL_WIDTH - 100, 24, 100, 20)];
    self.billPaidAmountLabel.font = [UIFont fontWithName:APP_FONT size:14];
    self.billPaidAmountLabel.textColor = APP_LABEL_BLUE_COLOR;
    self.billPaidAmountLabel.textAlignment = NSTextAlignmentRight;
    self.billPaidAmountLabel.backgroundColor = [UIColor clearColor];

    self.billAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(CELL_WIDTH - 100, 3, 100, 20)];
    self.billAmountLabel.textAlignment = NSTextAlignmentRight;
    self.billAmountLabel.font = [UIFont fontWithName:APP_FONT size:15];
    self.billAmountLabel.backgroundColor = [UIColor clearColor];
    if (false && self.mode == kAttachMode) {        // not in use!
        self.billAmountLabel.textColor = [UIColor yellowColor];
    }
    
    self.itemAccountTextFields = [NSMutableArray array];
    self.itemAmountTextFields = [NSMutableArray array];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activityIndicator.hidesWhenStopped = YES;
}

- (void)getBillNumberFromTextField:(UITextField *)textField {
    ((Bill *)self.shaddowBusObj).invoiceNumber = [Util trim:textField.text];
    self.billNumTextField.text = textField.text;
    self.billNumInputAccessoryTextField.text = textField.text;
}

- (void)changeInputAccessoryViewFor:(id)sender {
    self.totalAmount = [NSDecimalNumber zero];
    
    if (sender == self.billVendorInputAccessoryDoneItem) {
        [self.billVendorInputAccessoryTextField resignFirstResponder];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kBillInfo] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    } else if (sender == self.billNumInputAccessoryDoneItem) {
        if (self.mode != kAttachMode) {
            [self.billNumTextField resignFirstResponder];
        } else {
            ((Bill *)self.shaddowBusObj).invoiceNumber = self.billNumInputAccessoryTextField.text;
            [self.billNumInputAccessoryTextField becomeFirstResponder];
            [self.billNumInputAccessoryTextField resignFirstResponder];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kBillInfo] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    } else if (sender == self.billDateInputAccessoryDoneItem) {
        if (self.mode != kAttachMode) {
            [self.billDateTextField resignFirstResponder];
        } else {
            [self.billDateInputAccessoryTextField becomeFirstResponder];
            [self.billDateInputAccessoryTextField resignFirstResponder];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kBillInfo] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    } else if (sender == self.billDueDateInputAccessoryDoneItem) {
        if (self.mode != kAttachMode) {
            [self.billDueDateTextField resignFirstResponder];
        } else {
            [self.billDueDateInputAccessoryTextField becomeFirstResponder];
            [self.billDueDateInputAccessoryTextField resignFirstResponder];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kBillInfo] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    } else if (sender == self.billItemAccountInputAccessoryDoneItem) {
        [self.view findAndResignFirstResponder];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kBillInfo] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    } else if (sender == self.billItemAmountInputAccessoryDoneItem) {
        [self.view findAndResignFirstResponder];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kBillInfo] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        self.billAmountLabel.text = [Util formatCurrency:self.totalAmount];
    } else {
        if (self.mode != kAttachMode) {
            [self changeFirstResponderFor:sender];
            [self resetInputAccessoryNavSwitches];
        } else {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kBillInfo] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
            
            [UIView animateWithDuration:0.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{}
                completion:^ (BOOL finished){
                    [self changeFirstResponderFor:sender];
                    
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:kBillDocs] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                    
                    [self resetInputAccessoryNavSwitches];
                    
                    if (sender == self.billVendorInputAccessoryNextItem) {
                        [self.billNumInputAccessoryTextField becomeFirstResponder];
                    } else if (sender == self.billNumInputAccessoryNavSwitch && self.billNumInputAccessoryNavSwitch.selectedSegmentIndex == 0) {
                        [self.billVendorInputAccessoryTextField becomeFirstResponder];
                    } else if (sender == self.billNumInputAccessoryNavSwitch && self.billNumInputAccessoryNavSwitch.selectedSegmentIndex == 1) {
                        [self.billDateInputAccessoryTextField becomeFirstResponder];
                    } else if (sender == self.billDateInputAccessoryNavSwitch && self.billDateInputAccessoryNavSwitch.selectedSegmentIndex == 0) {
                        [self.billNumInputAccessoryTextField becomeFirstResponder];
                    } else if (sender == self.billDateInputAccessoryNavSwitch && self.billDateInputAccessoryNavSwitch.selectedSegmentIndex == 1) {
                        [self.billDueDateInputAccessoryTextField becomeFirstResponder];
                    } else if (sender == self.billDueDateInputAccessoryPrevItem) {
                        [self.billDateInputAccessoryTextField becomeFirstResponder];
                    }
                }];
        }
    }
}

- (void)changeFirstResponderFor:(id)sender {
    if (sender == self.billVendorInputAccessoryNextItem) {
        [self.billNumTextField becomeFirstResponder];
    } else if (sender == self.billNumInputAccessoryNavSwitch && self.billNumInputAccessoryNavSwitch.selectedSegmentIndex == 0) {
        [self getBillNumberFromTextField:self.billNumInputAccessoryTextField];
        if (self.mode == kAttachMode) {
            [self.billVendorTextField becomeFirstResponder];
        } else {
            [self performSegueWithIdentifier:BILL_SELECT_VENDOR_SEGUE sender:self];
        }
    } else if (sender == self.billNumInputAccessoryNavSwitch && self.billNumInputAccessoryNavSwitch.selectedSegmentIndex == 1) {
        [self getBillNumberFromTextField:self.billNumInputAccessoryTextField];
        [self.billDateTextField becomeFirstResponder];
    } else if (sender == self.billDateInputAccessoryNavSwitch && self.billDateInputAccessoryNavSwitch.selectedSegmentIndex == 0) {
        [self.billNumTextField becomeFirstResponder];
    } else if (sender == self.billDateInputAccessoryNavSwitch && self.billDateInputAccessoryNavSwitch.selectedSegmentIndex == 1) {
        [self.billDueDateTextField becomeFirstResponder];
    } else if (sender == self.billDueDateInputAccessoryPrevItem) {
        [self.billDateTextField becomeFirstResponder];
    }
}

- (void)resetInputAccessoryNavSwitches {
    self.billNumInputAccessoryNavSwitch.selectedSegmentIndex = UISegmentedControlNoSegment;
    self.billNumInputAccessoryNavSwitch.selectedSegmentIndex = UISegmentedControlNoSegment;
    self.billDateInputAccessoryNavSwitch.selectedSegmentIndex = UISegmentedControlNoSegment;
    self.billDateInputAccessoryNavSwitch.selectedSegmentIndex = UISegmentedControlNoSegment;
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
        [segue.destinationViewController setPayBillDelegate:self];
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
        if (!self.firstItemAdded && (self.mode == kCreateMode || self.mode == kAttachMode)) {
            self.firstItemAdded = YES;
            return 1;
        } else {
            return [((Bill *)self.shaddowBusObj).lineItems count];
        }
    } else {
        return 1 + (self.mode == kAttachMode);
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
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if (false && self.mode == kAttachMode) {    //not in use!
                cell.backgroundColor = [UIColor clearColor];
                cell.textLabel.textColor = [UIColor yellowColor];
                cell.detailTextLabel.textColor = [UIColor yellowColor];
                cell.textLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:BILL_LABEL_FONT_SIZE + 2];
                cell.detailTextLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:BILL_LABEL_FONT_SIZE + 2];
            } else {
                cell.textLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:BILL_LABEL_FONT_SIZE];
                cell.detailTextLabel.font = [UIFont fontWithName:APP_FONT size:BILL_LABEL_FONT_SIZE];
            }
            
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
                        
                        if (self.mode == kAttachMode) {
                            [cell addSubview:self.billVendorTextField]; // just for bringing up keyboard
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
                        self.billDateInputAccessoryTextField.text = self.billDateTextField.text;
                        
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
                        self.billDueDateInputAccessoryTextField.text = self.billDueDateTextField.text;
                        
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
            
            if (false && self.mode == kAttachMode) {    // not in use!
                cell.backgroundColor = [UIColor clearColor];
            }
            
            APLineItem *item = [shaddowBill.lineItems objectAtIndex:indexPath.row];
            ChartOfAccount *account = item.account;
            
            if (self.mode == kViewMode || (((Bill *)self.shaddowBusObj).paymentStatus && ![((Bill *)self.shaddowBusObj).paymentStatus isEqualToString:PAYMENT_UNPAID])) {
                cell.textLabel.text = account ? account.fullName : @" ";
                cell.textLabel.font = [UIFont fontWithName:APP_FONT size:BILL_LABEL_FONT_SIZE];
                [cell.textLabel sizeToFit];
                
                cell.detailTextLabel.text = [Util formatCurrency:item.amount];
                cell.detailTextLabel.font = [UIFont fontWithName:APP_FONT size:BILL_LABEL_FONT_SIZE];
            } else {
                UITextField *itemAccountField = [[UITextField alloc] initWithFrame:BILL_ITEM_ACCOUNT_RECT];
                itemAccountField.text = account && account.fullName.length ? account.fullName : @"None";
                [self initializeTextField:itemAccountField];
                itemAccountField.textAlignment = NSTextAlignmentCenter;
                itemAccountField.inputView = self.accountPickerView;
                itemAccountField.rightViewMode = UITextFieldViewModeAlways;
                itemAccountField.delegate = self;
                itemAccountField.tag = [BillInfo count] * TAG_BASE + indexPath.row * 2;
                itemAccountField.objectTag = item;
                itemAccountField.inputView = self.accountPickerView;
                itemAccountField.inputAccessoryView = self.billItemAccountInputAccessoryView;
                
                [cell addSubview:itemAccountField];
                [self.itemAccountTextFields addObject:itemAccountField];
                
                UITextField *itemAmountTextField = [[UITextField alloc] initWithFrame:BILL_ITEM_AMOUNT_RECT];
                if ((self.mode != kCreateMode && self.mode != kAttachMode) || ![item.amount isEqualToNumber:[NSDecimalNumber zero]]) {
                    itemAmountTextField.text = [Util formatCurrency:item.amount];
                }
                [self initializeTextField:itemAmountTextField];
                itemAmountTextField.keyboardType = UIKeyboardTypeDecimalPad;
                itemAmountTextField.delegate = self;
                itemAmountTextField.tag = [BillInfo count] * TAG_BASE + indexPath.row * 2 + 1;
                itemAmountTextField.objectTag = item;
                itemAmountTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
                itemAmountTextField.inputAccessoryView = self.billItemAmountInputAccessoryView;
                
                [cell addSubview:itemAmountTextField];
                [self.itemAmountTextFields addObject:itemAmountTextField];
                
                [self.tableView setEditing:YES animated:YES];
            }

            self.totalAmount = [self.totalAmount decimalNumberByAdding:item.amount];
        }
            break;
        case kBillDocs:
        {
            if (indexPath.row == 0) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:BILL_ATTACH_CELL_ID];
                
                [cell.contentView addSubview:self.attachmentScrollView];
                [cell.contentView addSubview:self.attachmentPageControl];
                cell.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:BILL_IMAGE_CELL_ID];
                if (!cell) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:BILL_IMAGE_CELL_ID];
                }
                
                cell.backgroundColor = [UIColor clearColor];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;

                self.previewScrollView.zoomScale = 1.1;
                
                [cell.contentView addSubview:self.previewScrollView];
            }
        }
            break;
        default:
            break;
    }
    
    return cell;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return [scrollView subviews][0];
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kBillInfo) {
        return CELL_HEIGHT;
    } else if (indexPath.section == kBillLineItems) {
        return CELL_HEIGHT;
    } else {
        if (indexPath.row == 0) {
            return IMG_HEIGHT + IMG_PADDING + ATTACHMENT_PV_HEIGHT + ((self.mode == kAttachMode) ? 110 : 0);
        } else {
            return NORMAL_SCREEN_HEIGHT + 30;
        }
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
        if (false && self.mode == kAttachMode) {        // not in use!
            label.textColor = [UIColor yellowColor];
        } else {
            label.textColor = APP_SYSTEM_BLUE_COLOR;
            label.shadowColor = [UIColor whiteColor];
            label.shadowOffset = CGSizeMake(0, 1);
        }
        
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
        if (false && self.mode == kAttachMode) {    // not in use!
            label.textColor = [UIColor yellowColor];
        } else {
            label.textColor = APP_SYSTEM_BLUE_COLOR;
            label.shadowColor = [UIColor whiteColor];
            label.shadowOffset = CGSizeMake(0, 1);
        }
        
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
        if (false && self.mode == kAttachMode) {        // not in use!
            amoutLabel.textColor = [UIColor yellowColor];
        } else {
            amoutLabel.textColor = APP_LABEL_BLUE_COLOR;
        }
        amoutLabel.textAlignment = NSTextAlignmentRight;
        [footerView addSubview:amoutLabel];
        
        Bill *bill = (Bill *)self.shaddowBusObj;
        if ([self.totalAmount isEqualToNumber:[NSDecimalNumber zero]] && bill.amount) {
            self.billAmountLabel.text = [Util formatCurrency:bill.amount];
        } else {
            self.billAmountLabel.text = [Util formatCurrency:self.totalAmount];
            bill.amount = self.totalAmount;
        }
        [footerView addSubview:self.billAmountLabel];
        
        if (self.mode != kCreateMode && self.mode != kAttachMode) {
            UILabel *paidAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 24, 85, 20)];
            paidAmountLabel.text = @"Paid:";
            paidAmountLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:13];
            paidAmountLabel.backgroundColor = [UIColor clearColor];
            paidAmountLabel.textColor = APP_LABEL_BLUE_COLOR;
            paidAmountLabel.textAlignment = NSTextAlignmentRight;
            [footerView addSubview:paidAmountLabel];
            
            self.billPaidAmountLabel.text = [Util formatCurrency:bill.paidAmount];
            [footerView addSubview:self.billPaidAmountLabel];
        }
        
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
    if (textField == self.billNumTextField) { // textField.tag == kBillNumber * TAG_BASE) {
        [self getBillNumberFromTextField:textField];
    } else {
        if (textField.tag % 2) {
            int idx = (textField.tag - [BillInfo count] * TAG_BASE) / 2;
            APLineItem * item = [((Bill *)self.shaddowBusObj).lineItems objectAtIndex:idx];
            
            if (self.mode == kAttachMode) {
                item.amount = [Util parseCurrency:textField.text];
            } else {
                self.totalAmount = [self.totalAmount decimalNumberBySubtracting:item.amount];
                item.amount = [Util parseCurrency:textField.text];
                self.totalAmount = [self.totalAmount decimalNumberByAdding:item.amount];
                self.billAmountLabel.text = [Util formatCurrency:self.totalAmount];
            }
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    [self textFieldDoneEditing:textField];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if ([self tryTap]) {
        self.currentField = textField;
        
        if (textField.objectTag) {
            if (textField.tag % 2 == 0) {
                APLineItem *item = textField.objectTag;
                int row;
                
                if (item.account.objectId) {
                    row = [self.chartOfAccounts indexOfObject:item.account] + 1;
                } else {
                    row = 0;
                }
                
                [self.accountPickerView selectRow:row inComponent:0 animated:NO];
            }
            
//            if (self.mode == kAttachMode) {
//                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:kBillDocs] atScrollPosition:UITableViewScrollPositionTop animated:YES];
//                if (textField.tag % 2 == 1) {
//                    self.billItemAmountInputAccessoryTextField.text = textField.text;
//                }
//                return;
//            }
        }
        
        if (self.mode == kAttachMode) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:kBillDocs] atScrollPosition:UITableViewScrollPositionTop animated:YES];
            
            if (textField == self.billNumTextField) { // textField.tag == kBillNumber * TAG_BASE) {
                self.billNumInputAccessoryTextField.text = textField.text;
            } else if (textField == self.billDateTextField) { // textField.tag == kBillDate * TAG_BASE) {
                self.billDateInputAccessoryTextField.text = textField.text;
            } else if (textField == self.billDueDateTextField) { // textField.tag == kBillDueDate * TAG_BASE) {
                self.billDueDateInputAccessoryTextField.text = textField.text;
            } else {
                if (textField.tag % 2) {
                    self.billItemAmountInputAccessoryTextField.text = textField.text;
                }
            }
            
            // doesn't need scroll up for keyboard
            return;
        }
        
        [super textFieldDidBeginEditing:textField];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self textFieldDoneEditing:textField];
    self.currentField = nil;
    
    [super textFieldDidEndEditing:textField];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (self.mode == kAttachMode) {
        if (textField == self.billNumTextField) { // textField.tag == kBillNumber * TAG_BASE) {
            self.billNumInputAccessoryTextField.text = [textField.text stringByReplacingCharactersInRange:range withString:string];
        } else if (textField.objectTag && textField.tag % 2) {
            self.billItemAmountInputAccessoryTextField.text = [textField.text stringByReplacingCharactersInRange:range withString:string];
        }
    }
    
    return YES;
}


#pragma mark - Date Picker target action

- (void)selectBillDateFromPicker:(UIDatePicker *)sender {
    self.billDateTextField.text = [Util formatDate:sender.date format:nil];
    self.billDateInputAccessoryTextField.text = self.billDateTextField.text;
    ((Bill *)self.shaddowBusObj).invoiceDate = sender.date;
}

- (void)selectDueDateFromPicker:(UIDatePicker *)sender {
    self.billDueDateTextField.text = [Util formatDate:sender.date format:nil];
    self.billDueDateInputAccessoryTextField.text = self.billDueDateTextField.text;
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
    if (pickerView.tag == VENDOR_PICKER_TAG) {
        return self.vendors.count;
    } else {
        return [self.chartOfAccounts count] + 1;
    }
}

- (NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (pickerView.tag == VENDOR_PICKER_TAG) {
        Vendor *vendor = self.vendors[row];
        return vendor.name;
    } else {
        if (row == 0) {
            return @"None";
        }
        
        ChartOfAccount * acct = (ChartOfAccount *)[self.chartOfAccounts objectAtIndex: row - 1];
        return acct.indentedName;
    }
}

#pragma mark - UIPickerView Delegate

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (pickerView.tag == VENDOR_PICKER_TAG) {
        [self didSelectVendor:self.vendors[row]];
    } else {
        int idx = (self.currentField.tag - [BillInfo count] * TAG_BASE) / 2;
        APLineItem * item = [((Bill *)self.shaddowBusObj).lineItems objectAtIndex:idx];
        
        if (row == 0) {
            self.currentField.text = @"None";
            item.account = nil;
        } else {
            ChartOfAccount *acct = (ChartOfAccount *)[self.chartOfAccounts objectAtIndex:row - 1];
            self.currentField.text = acct.fullName;
            item.account = [self.chartOfAccounts objectAtIndex:row - 1];
        }
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

- (void)didSelectVendor:(Vendor *)vendor {
    ((Bill *)self.shaddowBusObj).vendorId = vendor.objectId;
    self.billVendorInputAccessoryTextField.text = vendor.name;

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
    if ([action isEqualToString:ACTION_PAY]) {
        if ([((NSArray *)[BankAccount list]) count]) {
            [self performSegueWithIdentifier:BILL_PAY_BILL_SEGUE sender:self];
        }
    } else {
        [super didSelectCrudAction:action];
    }
}

#pragma mark - Pay Bill delegate

- (void)billPaid {
    // update payment status to scheduled
    NSIndexPath *path = [NSIndexPath indexPathForRow:kBillPaymentStatus inSection:kBillInfo];
    [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
}

@end
