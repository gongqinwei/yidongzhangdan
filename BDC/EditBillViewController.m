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
#import "ApproversTableViewController.h"
#import "ApprovalCommentViewController.h"
//#import "EditAPLineItemViewController.h"
#import "Util.h"
#import "Constants.h"
#import "UIHelper.h"
#import "APIHandler.h"
#import "Vendor.h"
#import "Approver.h"
#import "BankAccount.h"
#import "Organization.h"
#import "Document.h"
#import "BDCAppDelegate.h"
#import "RateAppManager.h"

#import <QuartzCore/QuartzCore.h>
#import <MessageUI/MessageUI.h>
#import <QuickLook/QuickLook.h>
#import <LocalAuthentication/LocalAuthentication.h>


enum BillSections {
    kBillInfo,
    kBillLineItems,
    kBillApprovers,
    kBillDocs
};

enum InfoType {
    kBillVendor,
    kBillNumber,
    kBillDate,
    kBillDueDate,
    kBillApprovalStatus,
    kBillPaymentStatus,
    kBillDesc
};

typedef enum {
    kEditBill, kEmailBill, kDeleteBill, kCancelBillAction
} BillActionIndice;

#define BILL_ACTIONS                    [NSArray arrayWithObjects:@"Pay bill", @"Edit Bill", @"Delete bill", @"Cancel", nil]

#define BILL_INFO_CELL_ID               @"BillInfo"
#define BILL_ITEM_CELL_ID               @"BillLineItem"
#define BILL_APPROVER_CELL_ID           @"BillApprover"
#define BILL_ATTACH_CELL_ID             @"BillDocs"
#define BILL_IMAGE_CELL_ID              @"BillImage"

#define BILL_SELECT_VENDOR_SEGUE        @"SelectVendorForBill"
#define BILL_SCAN_PHOTO_SEGUE           @"ScanMoreBillPhoto"
//#define BILL_PREVIEW_ATTACHMENT_SEGUE   @"PreviewBillDoc"
#define BILL_VIEW_VENDOR_DETAILS_SEGUE  @"ViewVendorDetails"
#define BILL_PAY_BILL_SEGUE             @"PayBill"
#define BILL_ADD_APPROVER_SEGUE         @"AddBillAprover"
#define BILL_APPROVAL_COMMENT_SEGUE     @"WriteApprovalComment"
#define BILL_APPROVAL_COMMENT_6_SEGUE   @"WriteApprovalCommentiOS6"

#define BILL_LABEL_FONT_SIZE            13
#define BillInfo                 [NSArray arrayWithObjects:@"Vendor", @"Invoice #", @"Inv Date", @"Due Date", @"Approval", @"Payment", @"Description", nil]
#define BILL_INFO_INPUT_RECT     CGRectMake(CELL_WIDTH - 190, 5, 190, CELL_HEIGHT - 10)
#define BILL_DESC_RECT           CGRectMake(CELL_WIDTH - 190, 5, 190, CELL_HEIGHT * 2 - 16)
#define BILL_ITEM_ACCOUNT_RECT   CGRectMake(cell.viewForBaselineLayout.bounds.origin.x + 46, 6, 150, cell.viewForBaselineLayout.bounds.size.height - 10)
#define BILL_ITEM_AMOUNT_RECT    CGRectMake(cell.viewForBaselineLayout.bounds.size.width - 115, 6, 100, cell.viewForBaselineLayout.bounds.size.height - 10)

#define DELETE_BILL_ALERT_TAG           1
#define REMOVE_ATTACHMENT_ALERT_TAG     2
#define ACTION_AUTH_ALERT_TAG           3

#define VENDOR_PICKER_TAG               1
#define ACCOUNT_PICKER_TAG              2


@interface EditBillViewController () <VendorSelectDelegate, ScannerDelegate, PayBillDelegate, ApproverListDelegate, ApproverSelectDelegate, ApprovalDelegate, VendorNameDelegate, UITextFieldDelegate, UITextViewDelegate, UIScrollViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIActionSheetDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate>

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

@property (nonatomic, strong) UITextView *billDescTextView;
@property (nonatomic, assign) BOOL descExpanded;

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

@property (nonatomic, strong) NSArray *approvers;
@property (nonatomic, strong) NSMutableArray *modifiedApprovers;
@property (nonatomic, strong) NSMutableSet *approverSet;

@property (nonatomic, strong) NSString *userAction;

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
@synthesize approvers = _approvers;
@synthesize modifiedApprovers;
@synthesize approverSet;
@synthesize forApproval;

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

@synthesize billDescTextView;
@synthesize descExpanded;

@synthesize userAction;


- (Class)busObjClass {
    return [Bill class];
}

- (void)setBusObj:(BDCBusinessObjectWithAttachments *)busObj {
    [super setBusObj:busObj];
    
//    if (self.mode != kCreateMode && self.mode != kAttachMode) {
//        self.approvers = self.approvers;    // actually resetting modifiedApprovers and reload section
//    }
}

- (BOOL)isAP {
    return YES;
}

- (NSIndexPath *)getAttachmentPath {
    return [NSIndexPath indexPathForRow:0 inSection:kBillDocs];
}

- (NSIndexSet *)getNonAttachmentSections {
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(kBillInfo, kBillLineItems)];  // leave kBillApprovers alone, let it refresh separately
}

- (NSString *)getDocImageAPI {
    return DOC_IMAGE_API;
}

- (NSString *)getDocIDParam {
    return _ID;
}

- (void)handleRemovalForDocument:(Document *)doc {
    [Document addToInbox:doc];
}

- (void)setMode:(ViewMode)mode {
    self.totalAmount = [NSDecimalNumber zero];
    
    [super setMode:mode];
    
    [self setActions];
}

- (void)cancelEdit:(UIBarButtonItem *)sender {
    if ([self tryTap]) {
        if (self.mode == kUpdateMode) {
            [self setApprovers:self.approvers];
        }
    }
    
    [super cancelEdit:sender];
}

- (void)refreshView {
    [super refreshView];
    
    Organization *org = [Organization getSelectedOrg];
    [org getOrgPrefs];
}

//- (void)quitAttachMode {
//    [self.shaddowBusObj read];
//}


- (void)updateLineItems {
    self.totalAmount = [NSDecimalNumber zero];
    
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:kBillLineItems];
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
    self.billAmountLabel.text = [Util formatCurrency:self.totalAmount];
}

- (void)setLineItems:(NSArray *)lineItems {    
    [self updateLineItems];
}

- (void)setApprovers:(NSArray *)approvers {
    _approvers = approvers;
    self.modifiedApprovers = [NSMutableArray arrayWithArray:approvers];
    self.approverSet = [NSMutableSet setWithArray:approvers];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kBillApprovers] withRowAnimation:UITableViewRowAnimationAutomatic];
//        if (self.mode != kCreateMode && self.mode != kAttachMode) {
//            NSIndexPath *approvalStatusPath = [NSIndexPath indexPathForRow:kBillApprovalStatus inSection:kBillInfo];
//            [self.tableView reloadRowsAtIndexPaths:@[approvalStatusPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//        }
    });
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
            if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:kBillDocs] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }
        } else if (self.mode != kAttachMode) {
            self.billAmountLabel.text = [Util formatCurrency:self.totalAmount];
        }
    }
}

- (void)addMoreAttachment {
    if ([self tryTap]) {
#ifdef LITE_VERSION
        [UIAppDelegate presentUpgrade];
#else
        [self.view findAndResignFirstResponder];
        [self performSegueWithIdentifier:BILL_SCAN_PHOTO_SEGUE sender:self];
#endif
    }
}

- (void)addMoreApprover {
    if ([self tryTap]) {
        [self.view findAndResignFirstResponder];
        [self performSegueWithIdentifier:BILL_ADD_APPROVER_SEGUE sender:self];
    }
}

/******
- (void)retrieveDocAttachments {
    //TODO: for bill, separate documents from attachments -> two scroll views: Pages(DocumentPages) and Documents(Attachments)
    [super retrieveDocAttachments];     // retrieve attachment;
    
    // retrieve documents
    NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\", \"%@\" : \"%@\", \"start\" : 0, \"max\" : 999}", _ID, self.busObj.objectId, OBJ_ID, self.busObj.objectId];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA_, objStr, nil];
    
    [APIHandler asyncCallWithAction:GET_DOCS_API Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSDictionary *jsonDict = [APIHandler getResponse:response data:data error:&err status:&response_status];
        NSArray *jsonDocs = [jsonDict objectForKey:DOCUMENTS];
        
        if(response_status == RESPONSE_SUCCESS) {
            @synchronized (self) {
                if (!self.busObj.attachmentDict) {
                    self.busObj.attachmentDict = [NSMutableDictionary dictionary];
                }
                
                self.attachmentDict = [NSMutableDictionary dictionaryWithDictionary:self.busObj.attachmentDict];
                
                self.docsUploading = [NSMutableDictionary dictionary];
                for (Document *doc in self.shaddowBusObj.attachments) {
                    if (!doc.objectId) {
                        // Assumption: fileName is unique.
                        // This is a hack to work around the documentUploaded -> document/documentPage problem
                        [self.docsUploading setObject:doc forKey:doc.name];
                    }
                }
                
                // reset scroll view first!
                [self resetScrollView];
                
                int i = 0;
                for (NSDictionary *dict in jsonDocs) {
                    NSString *docId = [dict objectForKey:_ID];
                    
                    Document *doc;
                    if (![self.attachmentDict objectForKey:docId]) {
                        NSString *docName = [dict objectForKey:FILE_NAME];
                        doc = [self.docsUploading objectForKey:docName];
                        
                        if (doc) {
                            doc.objectId = docId;
                            [self.attachmentDict setObject:doc forKey:docId];
                            [self.shaddowBusObj.attachmentDict setObject:doc forKey:docId];
                            [self.busObj.attachmentDict setObject:doc forKey:docId];
                        } else {
                            doc = [[Document alloc] init];
                            doc.objectId = docId;
                            doc.name = docName;
                            doc.fileUrl = [dict objectForKey:FILE_URL];
                            doc.isPublic = [[dict objectForKey:FILE_IS_PUBLIC] intValue];
                            //                            doc.page = [[dict objectForKey:@"page"] intValue];
                            
                            if ([doc isImageOrPDF]) {
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                    //                                    NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@/%@?%@=%@&%@=%d&%@=%d&%@=%d", DOMAIN_URL, [self getDocImageAPI], [self getDocIDParam], doc.objectId, PAGE_NUMBER, (!doc.page || doc.page <= 0 ? 1: doc.page), IMAGE_WIDTH, DOCUMENT_CELL_DIMENTION * 2, IMAGE_HEIGHT, DOCUMENT_CELL_DIMENTION * 2]]];
                                    NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@/%@?%@=%@&%@=%d&%@=%d&%@=%d", DOMAIN_URL, [self getDocImageAPI], [self getDocIDParam], doc.objectId, PAGE_NUMBER, 1, IMAGE_WIDTH, DOCUMENT_CELL_DIMENTION * 2, IMAGE_HEIGHT, DOCUMENT_CELL_DIMENTION * 2]]];
                                    
                                    if (data != nil) {
                                        doc.thumbnail = data;
                                        
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            UIImageView *img = [self.attachmentScrollView.subviews objectAtIndex: i];
                                            img.alpha = 0.0;
                                            img.image = [UIImage imageWithData: data];
                                            [img setNeedsDisplay];
                                            
                                            [UIView animateWithDuration:2.0
                                                             animations:^{
                                                                 img.alpha = 1.0;
                                                             }
                                                             completion:^ (BOOL finished) {
                                                             }];
                                        });
                                    }
                                });
                            }
                            
                            [self.busObj.attachmentDict setObject:doc forKey:docId];
                            [self.busObj.attachments insertObject:doc atIndex:i];
                            [self.shaddowBusObj.attachmentDict setObject:doc forKey:docId];
                            [self.shaddowBusObj.attachments insertObject:doc atIndex:i];
                            [self.attachmentDict setObject:doc forKey:docId];
                        }
                        
                        [self addAttachment:[[doc.name pathExtension] lowercaseString] data:nil needScale:NO];
                    } else {
                        doc = [self.attachmentDict objectForKey:docId];
                        [self addAttachment:[[doc.name pathExtension] lowercaseString] data:doc.thumbnail needScale:NO];
                    }
                    
                    [self layoutScrollImages:NO];
                    
                    i++;
                }
            }
            
            NSIndexPath *path = [self getAttachmentPath];
            if (path) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:YES];
                    [self.previewController reloadData];
                });
            }
        } else {
            Debug(@"Failed to retrieve documents for %@: %@", self.busObj.name, [err localizedDescription]);
        }
    }];
}
*******/

#pragma mark - Target Action

- (void)hideAdditionalKeyboard {
    [self.billVendorInputAccessoryTextField resignFirstResponder];
    [self.billNumInputAccessoryTextField resignFirstResponder];
    [self.billDateInputAccessoryTextField resignFirstResponder];
    [self.billDueDateInputAccessoryTextField resignFirstResponder];
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
        
        NSDecimalNumber *newAmount = [NSDecimalNumber zero];
        for (APLineItem *item in shaddowBill.lineItems) {
            newAmount = [newAmount decimalNumberByAdding:item.amount];
        }
                
        if (self.mode == kUpdateMode
            && shaddowBill.paymentStatus && ![shaddowBill.paymentStatus isEqualToString:PAYMENT_UNPAID]
            && [newAmount compare:((Bill *)self.busObj).amount] != NSOrderedSame) {
            [UIHelper showInfo:@"This bill is already paid.\n\nThe total amount can't be modified." withStatus:kError];
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
    if (self.mode == kViewMode && ([Organization getSelectedOrg].enableAP || [Organization getSelectedOrg].canApprove)) {
        self.crudActions = nil;
        
        if (self.forApproval) {
            self.crudActions = [NSArray arrayWithObjects:ACTION_APPROVE, ACTION_DENY, ACTION_BNC_SHARE, nil];
        } else {
            if (((Bill *)self.shaddowBusObj).paymentStatus && ![((Bill *)self.shaddowBusObj).paymentStatus isEqualToString:PAYMENT_UNPAID]) {
                self.crudActions = [NSArray arrayWithObjects:ACTION_UPDATE, ACTION_BNC_SHARE, nil];
            } else {
                if (self.isActive) {
                    self.crudActions = [NSArray arrayWithObjects:ACTION_UPDATE, ACTION_DELETE, ACTION_BNC_SHARE, nil];
                } else {
                    self.crudActions = [NSArray arrayWithObjects:ACTION_UPDATE, ACTION_UNDELETE, ACTION_BNC_SHARE, nil];
                }
            }
            
            if (self.isActive) {
                Organization *org = [Organization getSelectedOrg];
                
                if (org.canPay
                    && (!org.needApprovalToPayBill
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
}

#pragma mark - Life Cycle

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        if (self.mode == kAttachMode && !self.viewHasAppeared) {
            self.viewHasAppeared = YES;
            
            [self.billVendorTextField becomeFirstResponder];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:kBillDocs] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            [self.billVendorInputAccessoryTextField becomeFirstResponder];
            
            if (self.vendors.count) {
                [self didSelectVendor:self.vendors[0]];
            }
        }
    }
    
    [Approver setListDelegate:self];
    
    if (!_approvers && self.mode != kCreateMode && self.mode != kAttachMode) {
        if (self.shaddowBusObj && self.shaddowBusObj.objectId) {      // safety check
            [Approver setListDelegate:self];
            [Approver retrieveListForObject:self.shaddowBusObj.objectId];
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
    
    // retrieve approvers in view/edit mode
//    _approvers = [NSArray array];
    self.modifiedApprovers = [NSMutableArray array];
    self.approverSet = [NSMutableSet set];
    
    if (self.mode == kCreateMode || self.mode == kAttachMode) {
        if (!self.firstItemAdded) {
            [self addMoreItems];
        }
        
        if (self.mode == kAttachMode && SYSTEM_VERSION_LESS_THAN(@"7.0")) {
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
            
            CGRect previewFrame;
            if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
                previewFrame = CGRectMake(0.0, 0.0, SCREEN_WIDTH - 20, NORMAL_SCREEN_HEIGHT - PORTRAIT_KEYBOARD_HEIGHT);
            } else {
                previewFrame = CGRectMake(10.0, 0.0, SCREEN_WIDTH - 20, NORMAL_SCREEN_HEIGHT - PORTRAIT_KEYBOARD_HEIGHT);
            }
            
            self.previewScrollView = [[UIScrollView alloc] initWithFrame:previewFrame];
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
    
    // For approvers can't get vendor object (hence vendor name) right away
    if (self.mode != kCreateMode && self.mode != kAttachMode) {
        Bill * bill = (Bill *)self.busObj;
        Bill *shaddowBill = (Bill *)self.shaddowBusObj;
        Vendor *vendor = [Vendor objectForKey:shaddowBill.vendorId];
        if (vendor) {
            bill.vendorName = shaddowBill.vendorName = vendor.name;
        } else {
            [Vendor setRetrieveVendorNameDelegate:self];
            [Vendor retrieveVendorName:shaddowBill.vendorId];
        }
    }
    
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
    
    self.billDescTextView = [[UITextView alloc] initWithFrame:BILL_DESC_RECT];
    self.billDescTextView.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support
    self.billDescTextView.autocapitalizationType = UITextAutocapitalizationTypeNone; // no auto capitalization support
    self.billDescTextView.textAlignment = NSTextAlignmentLeft;
    self.billDescTextView.editable = YES;
    self.billDescTextView.layer.cornerRadius = 8.0f;
    self.billDescTextView.layer.masksToBounds = YES;
    self.billDescTextView.font = [UIFont fontWithName:APP_FONT size:APP_LABEL_FONT_SIZE];
    self.billDescTextView.textColor = APP_LABEL_BLUE_COLOR;
    self.billDescTextView.layer.borderColor = [[UIColor grayColor]CGColor];
    self.billDescTextView.layer.borderWidth = 0.5f;
    self.billDescTextView.inputAccessoryView = self.inputAccessoryView;
    self.billDescTextView.scrollEnabled = YES;
    self.billDescTextView.tag = kBillDesc * TAG_BASE;
    self.billDescTextView.delegate = self;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activityIndicator.hidesWhenStopped = YES;
    
    if (self.forApproval) {
        UIImage *actionImage = [UIImage imageNamed:@"ApproveIcon.png"];
        CGRect frameActionImg = CGRectMake(0, 0, actionImage.size.width, actionImage.size.height);
        
        UIButton *actionButton = [[UIButton alloc] initWithFrame:frameActionImg];
        [actionButton setBackgroundImage:actionImage forState:UIControlStateNormal];
        [actionButton addTarget:self action:@selector(toggleMenu:) forControlEvents:UIControlEventTouchUpInside];
        [actionButton setShowsTouchWhenHighlighted:YES];
        actionButton.tag = 1;
        UIBarButtonItem *actionBarButton =[[UIBarButtonItem alloc] initWithCustomView:actionButton];
        self.navigationItem.rightBarButtonItem = actionBarButton;
        
        ((Bill *)self.busObj).approvalDelegate = self;
    }
}

- (void)processApproval:(ApproverStatusEnum)decision {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        [self performSegueWithIdentifier:BILL_APPROVAL_COMMENT_SEGUE sender:[NSNumber numberWithInt:decision]];
    } else {
        [self performSegueWithIdentifier:BILL_APPROVAL_COMMENT_6_SEGUE sender:[NSNumber numberWithInt:decision]];
        
//        UIStoryboard *mainstoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
//        ApprovalCommentViewController *approvalCommentVC = (ApprovalCommentViewController *)[mainstoryboard instantiateViewControllerWithIdentifier:@"ApprovalComment"];
//        
//        [approvalCommentVC setBusObj:(Bill *)self.busObj];
//        [approvalCommentVC setApprovalDecision:decision];
//        [self presentViewController:approvalCommentVC animated:YES completion:nil];
    }
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
        if (self.mode != kAttachMode || SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            [self.billNumTextField resignFirstResponder];
        } else {
            ((Bill *)self.shaddowBusObj).invoiceNumber = self.billNumInputAccessoryTextField.text;
            [self.billNumInputAccessoryTextField becomeFirstResponder];
            [self.billNumInputAccessoryTextField resignFirstResponder];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kBillInfo] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    } else if (sender == self.billDateInputAccessoryDoneItem) {
        if (self.mode != kAttachMode || SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            [self.billDateTextField resignFirstResponder];
        } else {
            [self.billDateInputAccessoryTextField becomeFirstResponder];
            [self.billDateInputAccessoryTextField resignFirstResponder];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kBillInfo] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    } else if (sender == self.billDueDateInputAccessoryDoneItem) {
        if (self.mode != kAttachMode || SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            [self.billDueDateTextField resignFirstResponder];
        } else {
            [self.billDueDateInputAccessoryTextField becomeFirstResponder];
            [self.billDueDateInputAccessoryTextField resignFirstResponder];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kBillInfo] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    } else if (sender == self.billItemAccountInputAccessoryDoneItem) {
        [self.view findAndResignFirstResponder];
        if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kBillInfo] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    } else if (sender == self.billItemAmountInputAccessoryDoneItem) {
        [self.view findAndResignFirstResponder];
        if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kBillInfo] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        }
        self.billAmountLabel.text = [Util formatCurrency:self.totalAmount];
    } else {
        if (self.mode != kAttachMode || SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            [self changeFirstResponderFor:sender];
            [self resetInputAccessoryNavSwitches];
        } else {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kBillInfo] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
            
            [UIView animateWithDuration:0.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{}
                completion:^ (BOOL finished){
                    [self changeFirstResponderFor:sender];
                    
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:kBillDocs] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                    
                    [self resetInputAccessoryNavSwitches];
                    
//                    if (sender == self.billVendorInputAccessoryNextItem) {
//                        [self.billNumInputAccessoryTextField becomeFirstResponder];
//                    } else if (sender == self.billNumInputAccessoryNavSwitch && self.billNumInputAccessoryNavSwitch.selectedSegmentIndex == 0) {
//                        [self.billVendorInputAccessoryTextField becomeFirstResponder];
//                    } else if (sender == self.billNumInputAccessoryNavSwitch && self.billNumInputAccessoryNavSwitch.selectedSegmentIndex == 1) {
//                        [self.billDateInputAccessoryTextField becomeFirstResponder];
//                    } else if (sender == self.billDateInputAccessoryNavSwitch && self.billDateInputAccessoryNavSwitch.selectedSegmentIndex == 0) {
//                        [self.billNumInputAccessoryTextField becomeFirstResponder];
//                    } else if (sender == self.billDateInputAccessoryNavSwitch && self.billDateInputAccessoryNavSwitch.selectedSegmentIndex == 1) {
//                        [self.billDueDateInputAccessoryTextField becomeFirstResponder];
//                    } else if (sender == self.billDueDateInputAccessoryPrevItem) {
//                        [self.billDateInputAccessoryTextField becomeFirstResponder];
//                    }
                }];
        }
    }
}

- (void)changeFirstResponderFor:(id)sender {
    if (sender == self.billVendorInputAccessoryNextItem) {
        [self.billNumTextField becomeFirstResponder];
    } else if (sender == self.billNumInputAccessoryNavSwitch && self.billNumInputAccessoryNavSwitch.selectedSegmentIndex == 0) {
        if (self.mode == kAttachMode && SYSTEM_VERSION_LESS_THAN(@"7.0")) {
            [self getBillNumberFromTextField:self.billNumInputAccessoryTextField];
            [self.billVendorTextField becomeFirstResponder];
        } else {
            [self getBillNumberFromTextField:self.billNumTextField];
            [self performSegueWithIdentifier:BILL_SELECT_VENDOR_SEGUE sender:self];
        }
    } else if (sender == self.billNumInputAccessoryNavSwitch && self.billNumInputAccessoryNavSwitch.selectedSegmentIndex == 1) {
        if (self.mode == kAttachMode && SYSTEM_VERSION_LESS_THAN(@"7.0")) {
            [self getBillNumberFromTextField:self.billNumInputAccessoryTextField];
        } else {
            [self getBillNumberFromTextField:self.billNumTextField];
        }
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
    } else if ([segue.identifier isEqualToString:BILL_ADD_APPROVER_SEGUE]) {
//        [segue.destinationViewController setMode:kSelectMode];
        [segue.destinationViewController setSelectDelegate:self];
    } else if ([segue.identifier isEqualToString:BILL_APPROVAL_COMMENT_SEGUE] || [segue.identifier isEqualToString:BILL_APPROVAL_COMMENT_6_SEGUE]) {
        [segue.destinationViewController setBusObj:self.busObj];
        [segue.destinationViewController setApprovalDecision:((NSNumber *)sender).intValue];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kBillDocs + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kBillInfo) {        
        if (self.mode != kCreateMode && self.mode != kUpdateMode && self.mode != kAttachMode) {
            Bill *bill = (Bill *)self.busObj;
            return bill.desc && bill.desc.length > 0 ? BillInfo.count : BillInfo.count - 1;
        } else {
            return BillInfo.count - 2;
        }
    } else if (section == kBillLineItems) {
        if (!self.firstItemAdded && (self.mode == kCreateMode || self.mode == kAttachMode)) {
            self.firstItemAdded = YES;
            return 1;
        } else {
            return [((Bill *)self.shaddowBusObj).lineItems count];
        }
    } else if (section == kBillApprovers) {
        return self.modifiedApprovers.count;
    } else if (section == kBillDocs) {
        return 1 + (self.mode == kAttachMode && SYSTEM_VERSION_LESS_THAN(@"7.0"));
    }
    return 0;
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
            cell.accessoryType = UITableViewCellAccessoryNone;
            
            switch (indexPath.row) {
                case kBillVendor:
                    if (self.mode == kViewMode) {
                        if (shaddowBill.vendorId != nil) {
                            cell.detailTextLabel.text = shaddowBill.vendorName;
                        } else {
                            cell.detailTextLabel.text = nil;
                        }
                        
                        if ([[Vendor list] count] > 0) {    //TODO: remove this check when BDC allows approvers to list/read vendors
                            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        }
                    } else {
                        if (shaddowBill.vendorId != nil) {
                            cell.detailTextLabel.text = shaddowBill.vendorName;
                        } else {
                            cell.detailTextLabel.text = SELECT_ONE;
                        }
                        
                        //TODO: need to check vendor count until BDC allows approver to retrieve vendor
                        if ((!shaddowBill.paymentStatus || [shaddowBill.paymentStatus isEqualToString:PAYMENT_UNPAID]) && [[Vendor list] count] > 0) {
                            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        }
                        
                        if (self.mode == kAttachMode && SYSTEM_VERSION_LESS_THAN(@"7.0")) {
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
                case 4:
                    if (self.mode != kCreateMode && self.mode != kUpdateMode && self.mode != kAttachMode) {   // kBillApprovalStatus:
                        if (shaddowBill.approvalStatus != nil) {
                            cell.detailTextLabel.text = [APPROVAL_STATUSES objectForKey:shaddowBill.approvalStatus];
                        } else {
                            cell.detailTextLabel.text = @"Unassigned";
                        }
                        
                        if (self.modifiedApprovers && self.modifiedApprovers.count) {
                            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        }
                    } else {    // kBillDesc
                        cell.textLabel.text = @"Description";
                        if (self.mode == kCreateMode || self.mode == kAttachMode) {
                            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                            NSString *lastDesc = [defaults stringForKey:[NSString stringWithFormat:@"%@:%@", ((Bill*)self.shaddowBusObj).vendorId, BILL_DESC]];
                            if (lastDesc) {
                                self.billDescTextView.text = lastDesc;
                            }
                        } else {
                            if (shaddowBill.desc != nil) {
                                self.billDescTextView.text = shaddowBill.desc;
                            }
                        }
                        self.billDescTextView.backgroundColor = cell.backgroundColor;
                        self.billDescTextView.layer.borderWidth = 0.5f;
                        self.billDescTextView.editable = YES;
                        [cell addSubview:self.billDescTextView];
                    }
                    
                    break;
                case kBillPaymentStatus:
                    if (shaddowBill.paymentStatus != nil) {
                        cell.detailTextLabel.text = [PAYMENT_STATUSES objectForKey:shaddowBill.paymentStatus];
                    } else {
                        cell.detailTextLabel.text = nil;
                    }
                    break;
                case kBillDesc:
                    if (self.descExpanded) {
                        cell.detailTextLabel.text = nil;
                        cell.accessoryType = UITableViewCellAccessoryNone;
                        
                        if (shaddowBill.desc != nil) {
                            self.billDescTextView.text = shaddowBill.desc;
                        }
                        self.billDescTextView.backgroundColor = cell.backgroundColor;
                        self.billDescTextView.layer.borderWidth = 0.0f;
                        self.billDescTextView.editable = NO;
                        [cell addSubview:self.billDescTextView];
                    } else {
                        cell.detailTextLabel.text = shaddowBill.desc;
                        cell.detailTextLabel.numberOfLines = 1;
                        cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
                        if ([cell.detailTextLabel.text rangeOfString:@"\r\n"].location != NSNotFound || cell.detailTextLabel.text.length > 30) {
                            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        }
                    }
                    
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
            
            if (self.mode == kViewMode) { // || (((Bill *)self.shaddowBusObj).paymentStatus && ![((Bill *)self.shaddowBusObj).paymentStatus isEqualToString:PAYMENT_UNPAID])) {
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
        case kBillApprovers:
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:BILL_APPROVER_CELL_ID];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.userInteractionEnabled = YES;
            
            Approver *approver = self.modifiedApprovers[indexPath.row];
            
            UILabel *approverNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(55, 1, 175, CELL_HEIGHT - 2)];
            approverNameLabel.text = approver.name;
            approverNameLabel.font = [UIFont fontWithName:APP_FONT size:BILL_LABEL_FONT_SIZE];
            approverNameLabel.backgroundColor = [UIColor clearColor];
            [cell addSubview:approverNameLabel];
            
            CGFloat statusLabelX;
            CGFloat statusDateLabelX;
            if (self.mode == kViewMode || approver.status == kApproverApproved || approver.status == kApproverDenied || approver.status == kApproverRerouted) {
                statusLabelX = SCREEN_WIDTH - 90;
                statusDateLabelX = SCREEN_WIDTH - 140;
            } else {
                statusLabelX = SCREEN_WIDTH - 115;
                statusDateLabelX = SCREEN_WIDTH - 165;
            }
            
            CGRect statusRect;
//            if (approver.status == kApproverNew || approver.status == kApproverStale) {
                statusRect = CGRectMake(statusLabelX, 1, 70, CELL_HEIGHT - 2);
//            } else {
//                statusRect = CGRectMake(statusLabelX, 2, 70, CELL_HEIGHT / 2);
//                
//                UILabel *approverStatusDateLabel = [[UILabel alloc] initWithFrame:CGRectMake(statusDateLabelX, CELL_HEIGHT / 2 + 2, 120, CELL_HEIGHT / 2 - 2)];
//                approverStatusDateLabel.text = approver.statusDate;
//                approverStatusDateLabel.textAlignment = NSTextAlignmentRight;
//                approverStatusDateLabel.font = [UIFont fontWithName:APP_FONT size:BILL_LABEL_FONT_SIZE - 1];
//                approverStatusDateLabel.textColor = [UIColor grayColor];
//                approverStatusDateLabel.backgroundColor = [UIColor clearColor];
//                [cell addSubview:approverStatusDateLabel];
//            }
            
            UILabel *approverStatusLabel = [[UILabel alloc] initWithFrame:statusRect];
            approverStatusLabel.text = approver.statusName;
            approverStatusLabel.textAlignment = NSTextAlignmentRight;
            approverStatusLabel.font = [UIFont fontWithName:APP_FONT size:BILL_LABEL_FONT_SIZE];
            approverStatusLabel.textColor = APP_LABEL_BLUE_COLOR;
            approverStatusLabel.backgroundColor = [UIColor clearColor];
            [cell addSubview:approverStatusLabel];
            
            if (self.mode == kViewMode || approver.status == kApproverApproved || approver.status == kApproverDenied || approver.status == kApproverRerouted) {
                if (approver.profilePicData) {
                    UIImageView *approverPic = [[UIImageView alloc] initWithImage:[UIImage imageWithData: approver.profilePicData]];
                    approverPic.frame = CGRectMake(12, 2, 39, 39);
                    [cell addSubview:approverPic];
                } else {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@/%@", DOMAIN_URL, approver.profilePicUrl]]];
                        
                        if (data != nil) {
                            approver.profilePicData = data;
                            
                            if ([UIImage imageWithData: data]) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    UIImageView *approverPic = [[UIImageView alloc] initWithImage:[UIImage imageWithData: data]];
                                    approverPic.frame = CGRectMake(12, 2, 39, 39);
                                    [cell addSubview:approverPic];
                                });
                            }
                        }
                    });
                }
            }
        }
            break;
        case kBillDocs:
        {
            if (indexPath.row == 0) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:BILL_ATTACH_CELL_ID];
                
                [cell.contentView addSubview:self.attachmentScrollView];
                [cell.contentView addSubview:self.attachmentPageControl];
                cell.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
                cell.backgroundColor = [UIColor clearColor];
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
    if (indexPath.section == kBillDocs) {
        if (indexPath.row == 0) {
            return IMG_HEIGHT + IMG_PADDING + ATTACHMENT_PV_HEIGHT + ((self.mode == kAttachMode) ? 110 : (SYSTEM_VERSION_LESS_THAN(@"7.0") ? 0 : 10));
        } else {
            return NORMAL_SCREEN_HEIGHT + 30;
        }
    } else if (indexPath.section == kBillInfo) {
        if ((self.mode == kCreateMode || self.mode == kUpdateMode || self.mode == kAttachMode) && indexPath.row == 4) {     // Bill Desc) {
            return CELL_HEIGHT * 2;
        } else if (indexPath.row == kBillDesc && self.mode != kCreateMode && self.mode != kUpdateMode && self.mode != kAttachMode) {
            return self.descExpanded ? CELL_HEIGHT * 2 : CELL_HEIGHT;
        } else {
            return CELL_HEIGHT;
        }
    } else {
        return CELL_HEIGHT;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == kBillInfo) {
        return 0;
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
        return [self initializeSectionHeaderViewWithLabel:@"Expenses" needAddButton:(self.mode != kViewMode && (!((Bill *)self.shaddowBusObj).paymentStatus || [((Bill *)self.shaddowBusObj).paymentStatus isEqualToString:PAYMENT_UNPAID])) addAction:@selector(addMoreItems)];
    } else if (section == kBillApprovers) {
        return [self initializeSectionHeaderViewWithLabel:@"Approvers" needAddButton:(self.mode != kViewMode) addAction:@selector(addMoreApprover)];
    } else if (section == kBillDocs) {
        return [self initializeSectionHeaderViewWithLabel:@"Documents" needAddButton:(self.mode != kViewMode) addAction:@selector(addMoreAttachment)];
    } else {
        return nil;
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
    if (self.mode != kViewMode) {
        if (indexPath.section == kBillLineItems) {
            return YES;
        }
        
        if ((self.mode == kCreateMode || self.mode == kAttachMode || self.mode == kUpdateMode) && indexPath.section == kBillApprovers) {
            Approver *approver = self.modifiedApprovers[indexPath.row];
            if (approver.status != kApproverApproved && approver.status != kApproverDenied && approver.status != kApproverRerouted) {
                return YES;
            }
        }
    }
    
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.mode == kCreateMode || self.mode == kAttachMode || self.mode == kUpdateMode) {
        if (indexPath.section == kBillApprovers) {
            Approver *approver = self.modifiedApprovers[indexPath.row];
            if (approver.status != kApproverApproved && approver.status != kApproverDenied && approver.status != kApproverRerouted) {
                return YES;
            }
        }
    }
    
    return NO;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    Approver *approver = self.modifiedApprovers[sourceIndexPath.row];
    [self.modifiedApprovers removeObjectAtIndex:sourceIndexPath.row];
    [self.modifiedApprovers insertObject:approver atIndex:destinationIndexPath.row];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (indexPath.section == kBillLineItems) {
            // Delete the row from the data source
            [((Bill *)self.shaddowBusObj).lineItems removeObjectAtIndex:indexPath.row];
            [self updateLineItems];
        } else {
            [self.approverSet removeObject:self.modifiedApprovers[indexPath.row]];
            [self.modifiedApprovers removeObjectAtIndex:indexPath.row];
            
            NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:kBillApprovers];
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
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
                        if ([[Vendor list] count] > 0) {    //TODO: remove this check when BDC allows approvers to list/read vendors
                            Bill *shaddowBill = (Bill *)self.shaddowBusObj;
                            if (!shaddowBill.paymentStatus || [shaddowBill.paymentStatus isEqualToString:PAYMENT_UNPAID]) {
                                [self performSegueWithIdentifier:BILL_SELECT_VENDOR_SEGUE sender:self];
                            }
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
                        if ([[Vendor list] count] > 0) {    //TODO: remove this check when BDC allows approvers to list/read vendors
                            Vendor *vendor = [Vendor objectForKey:((Bill *)self.shaddowBusObj).vendorId];
                            vendor.editBillDelegate = self;
                            [self performSegueWithIdentifier:BILL_VIEW_VENDOR_DETAILS_SEGUE sender:vendor];
                        }
                    }
                        break;
                    case kBillApprovalStatus:
                        if (self.modifiedApprovers && self.modifiedApprovers.count) {
                            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kBillApprovers] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                        }
                        
                        break;
                    case kBillDesc:
                    {
                        NSIndexPath *path = [NSIndexPath indexPathForRow:kBillDesc inSection:kBillInfo];
                        if (!self.descExpanded) {
                            UITableViewCell *descCell = [self.tableView cellForRowAtIndexPath:path];
                            if ([descCell.detailTextLabel.text rangeOfString:@"\r\n"].location != NSNotFound || descCell.detailTextLabel.text.length > 30) {
                                self.descExpanded = !self.descExpanded;
                                [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
                            }
                        } else {
                            self.descExpanded = !self.descExpanded;
                            [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
                        }
                        
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
            NSUInteger idx = (textField.tag - [BillInfo count] * TAG_BASE) / 2;
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
                NSUInteger row;
                
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
        
        if (self.mode == kAttachMode && SYSTEM_VERSION_LESS_THAN(@"7.0")) {
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
    if (self.mode == kAttachMode && SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        if (textField == self.billNumTextField) { // textField.tag == kBillNumber * TAG_BASE) {
            self.billNumInputAccessoryTextField.text = [textField.text stringByReplacingCharactersInRange:range withString:string];
        } else if (textField.objectTag && textField.tag % 2) {
            self.billItemAmountInputAccessoryTextField.text = [textField.text stringByReplacingCharactersInRange:range withString:string];
        }
    }
    
    return YES;
}

#pragma mark - Text View delegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [super textViewDidBeginEditing:textView];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    ((Bill *)self.shaddowBusObj).desc = [Util trim:textView.text];
    [super textViewDidEndEditing:textView];
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
            break;
        case ACTION_AUTH_ALERT_TAG:
            if (buttonIndex == 1) {
                if ([[alertView textFieldAtIndex:0].text isEqualToString:[Util getPassword]]) {
                    [self performAction];
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Password" message:@"Action can't be performed!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    [alert show];
                }
            }
            break;
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
        Vendor *vendor = self.vendors[row];
        [self didSelectVendor:vendor];
        
        if (self.mode == kCreateMode || self.mode == kAttachMode) {
            [Approver retrieveListForVendor:vendor.objectId andSmartData:YES];
        }
    } else {
        NSUInteger idx = (self.currentField.tag - [BillInfo count] * TAG_BASE) / 2;
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

- (void)doneSaveObject {
    [super doneSaveObject];
    
    // Save Approvers
    [Approver setList:self.modifiedApprovers forObject:self.shaddowBusObj.objectId andVendor:((Bill *)self.shaddowBusObj).vendorId];
}

- (void)didReadObject {
    self.totalAmount = [NSDecimalNumber zero];
    [super didReadObject];

    [self.shaddowBusObj cloneTo:self.busObj];
    ((Bill *)self.busObj).amount = ((Bill *)self.shaddowBusObj).amount;
    
    [self setActions];
    [self.actionMenuVC.tableView reloadData];
    
    [Approver setListDelegate:self];
    [Approver retrieveListForObject:self.shaddowBusObj.objectId];
}

- (void)didUpdateObject {
    [super didUpdateObject];
    
    NSDecimalNumber *amount = [NSDecimalNumber zero];
    for (APLineItem *item in ((Bill *)self.busObj).lineItems) {
        amount = [amount decimalNumberByAdding:item.amount];
    }
    
    ((Bill *)self.busObj).amount = amount;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.actionMenuVC.tableView reloadData];
    });
}

- (void)didSelectVendor:(Vendor *)vendor {
    Bill *shaddowBill = (Bill *)self.shaddowBusObj;
    shaddowBill.vendorId = vendor.objectId;
    shaddowBill.vendorName = vendor.name;
    self.billVendorInputAccessoryTextField.text = vendor.name;

    if (self.mode == kCreateMode || self.mode == kAttachMode) {
        [Approver retrieveListForVendor:vendor.objectId andSmartData:YES];
    }
    
    NSIndexPath *path = [NSIndexPath indexPathForRow:kBillVendor inSection:kBillInfo];
    [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    // load smart data from user defaults
    if (self.mode == kCreateMode || self.mode == kAttachMode) {
        path = [NSIndexPath indexPathForRow:4 inSection:kBillInfo];
        [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];

        //commented because I'm using smart data from server instead
//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//        NSArray *aidArr = [defaults arrayForKey:[NSString stringWithFormat:@"%@:%@", shaddowBill.vendorId, APPROVERS]];
//        NSMutableArray *approvers = [NSMutableArray array];
//        if (aidArr) {
//            for (NSString *aid in aidArr) {
//                Approver *approver = [Approver objectForKey:aid];
//                [approvers addObject:approver];
//            }
//            [self setApprovers:approvers];
//        }
    }
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
    if (![action isEqualToString:ACTION_PAY] && ![action isEqualToString:ACTION_APPROVE] && ![action isEqualToString:ACTION_DENY] && ![action isEqualToString:ACTION_SKIP]) {
        [super didSelectCrudAction:action];
    } else {
        
#ifdef LITE_VERSION
        [UIAppDelegate presentUpgrade];
#else
        self.userAction = action;
        
        // Use TouchID
        LAContext *context = [[LAContext alloc] init];
        if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil]) {
            [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                    localizedReason:[NSString stringWithFormat:@"Fingerprint needed for %@", action]
                              reply:^(BOOL success, NSError *authenticationError){
                if (success) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self performAction];
                    });
                } else {
                    if (authenticationError.code == LAErrorUserFallback) {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Security Check" message:@"Enter your Bill.com password:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
                        alertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
                        alertView.tag = ACTION_AUTH_ALERT_TAG;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [alertView show];
                        });
                    }
                    
                    Debug(@"Fingerprint validation failed: %@.", authenticationError.localizedDescription);
                }
            }];
        } else {
            [self performAction];
        }
#endif
    }
}

- (void)performAction {
    if ([self.userAction isEqualToString:ACTION_PAY]) {
        if ([((NSArray *)[BankAccount list]) count]) {
            [self performSegueWithIdentifier:BILL_PAY_BILL_SEGUE sender:self];
        }
    } else if ([self.userAction isEqualToString:ACTION_APPROVE]) {
        [self processApproval:kApproverApproved];
    } else if ([self.userAction isEqualToString:ACTION_DENY]) {
        [self processApproval:kApproverDenied];
    } else if ([self.userAction isEqualToString:ACTION_SKIP]) {
        [self processApproval:kApproverRerouted];
    }
}

#pragma mark - Pay Bill delegate

- (void)billPaid {
    // update payment status to scheduled
    NSIndexPath *path = [NSIndexPath indexPathForRow:kBillPaymentStatus inSection:kBillInfo];
    [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
    
    // prompt for Rate app
    [[RateAppManager sharedInstance] checkPromptForRate];
}

#pragma mark - Approver delegate

- (void)didGetApprovers:(NSArray *)theApprovers {
    self.approvers = theApprovers;
}

- (void)didSelectApprovers:(NSArray *)approvers {
    for (Approver *approver in approvers) {
        if (![self.approverSet containsObject:approver]) {
            [self.modifiedApprovers addObject:approver];
            [self.approverSet addObject:approver];
        }
    }
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kBillApprovers] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)didGetApprovers {}
- (void)failedToGetApprovers {}
- (void)didAddApprover:(Approver *)approver {}

#pragma mark - Approval delegate

- (void)didProcessApproval {
    self.forApproval = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.shaddowBusObj read];
        
        self.title = self.busObj.name;
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObject:self.navigationItem.rightBarButtonItems[0]];
    });
    
    // prompt for Rate app
    [[RateAppManager sharedInstance] checkPromptForRate];
}

- (void)failedToProcessApproval {
    
}

#pragma mark - Vendor Name delegate

- (void)didGetVendorName:(NSString *)name {
    dispatch_async(dispatch_get_main_queue(), ^{
        ((Bill*)self.busObj).vendorName = ((Bill*)self.shaddowBusObj).vendorName = name;
        NSIndexPath *path = [NSIndexPath indexPathForRow:kBillVendor inSection:kBillInfo];
        [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}


@end
