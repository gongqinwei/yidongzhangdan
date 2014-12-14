//
//  EditInvoiceViewController.m
//  BDC
//
//  Created by Qinwei Gong on 9/21/12.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "EditInvoiceViewController.h"
#import "InvoiceDetailsViewController.h"
#import "CustomersTableViewController.h"
#import "ItemsTableViewController.h"
#import "ScannerViewController.h"
#import "AttachmentPreviewViewController.h"
#import "EditCustomerViewController.h"
#import "EditItemViewController.h"
#import "Util.h"
#import "Constants.h"
#import "UIHelper.h"
#import "Invoice.h"
#import "Customer.h"
#import "CustomerContact.h"
#import "Organization.h"
#import "Document.h"
#import "BDCAppDelegate.h"

#import <QuartzCore/QuartzCore.h>
#import <MessageUI/MessageUI.h>
#import <QuickLook/QuickLook.h>

enum InvoiceSections {
    kInvoiceInfo,
    kInvoiceLineItems,
    kInvoiceAttachments
};

enum InfoType {
    kInvoiceCustomer,
    kInvoiceNumber,
    kInvoiceDate,
    kInvoiceDueDate,
};

typedef enum {
    kEditInvoice, kEmailInvoice, kDeleteInvoice, kCancelInvoiceAction
} InvoiceActionIndice;

#define INVOICE_ACTIONS     [NSArray arrayWithObjects:@"Edit invoice", @"Email Invoice", @"Delete invoice", @"Cancel", nil]
#define ACTION_EMAIL        @"Email to Customer"

#define INV_INFO_CELL_ID                @"InvoiceInfo"
#define INV_ITEM_CELL_ID                @"InvoiceLineItem"
#define INV_ATTACH_CELL_ID              @"InvoiceAttachment"

#define INV_SELECT_CUSTOMER_SEGUE       @"SelectCustomerForInvoice"
#define INV_SELECT_ITEMS_SEGUE          @"SelectItemsForInvoice"
#define INV_SCAN_PHOTO_SEGUE            @"ScanMoreInvoicePhoto"
#define INV_PREVIEW_ATTACHMENT_SEGUE    @"PreviewAttachment"
#define INV_VIEW_PDF_SEGUE              @"ViewInvoicePDF"
#define INV_MODIFY_ITEM_DETAILS_SEGUE   @"ModifyItemDetails"
#define INV_VIEW_CUSTOMER_DETAILS_SEGUE @"ViewCustomerDetails"

#define INV_LABEL_FONT_SIZE             13
#define InvoiceInfo             [NSArray arrayWithObjects:@"Customer", @"Invoice #", @"Issue Date", @"Due Date", nil]
#define INV_INFO_INPUT_RECT     CGRectMake(CELL_WIDTH - 190, 5, 190, CELL_HEIGHT - 10)
#define INV_ITEM_AMOUNT_RECT    CGRectMake(cell.viewForBaselineLayout.bounds.size.width - 130, 5, 90, cell.viewForBaselineLayout.bounds.size.height-10)
#define INV_ITEM_QTY_RECT       CGRectMake(cell.viewForBaselineLayout.bounds.size.width - 180, 10, 60, cell.viewForBaselineLayout.bounds.size.height-20)

#define DELETE_INV_ALERT_TAG            1
#define REMOVE_ATTACHMENT_ALERT_TAG     2


@interface EditInvoiceViewController () <CustomerSelectDelegate, ItemSelectDelegate, LineItemDelegate, InvoiceMailDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate>


@property (nonatomic, strong) NSDecimalNumber *totalAmount;
@property (nonatomic, strong) UIDatePicker *invoiceDatePicker;
@property (nonatomic, strong) UIDatePicker *dueDatePicker;

@property (nonatomic, strong) UITextField *invoiceNumTextField;
@property (nonatomic, strong) UITextField *invoiceDateTextField;
@property (nonatomic, strong) UITextField *invoiceDueDateTextField;

@property (nonatomic, strong) NSMutableData *invoicePDFData;
@property (nonatomic, strong) MFMailComposeViewController *mailer;

@property (nonatomic, assign) BOOL pdfReady;
@property (nonatomic, strong) UIImageView *pdfView;

@end


@implementation EditInvoiceViewController

@synthesize totalAmount;
@synthesize invoiceDatePicker;
@synthesize dueDatePicker;
@synthesize invoiceNumTextField;
@synthesize invoiceDateTextField;
@synthesize invoiceDueDateTextField;
@synthesize invoicePDFData;
@synthesize mailer;
@synthesize pdfReady;
@synthesize pdfView;

- (Class)busObjClass {
    return [Invoice class];
}

- (BOOL)isAR {
    return YES;
}

- (NSIndexPath *)getAttachmentPath {
    return [NSIndexPath indexPathForRow:1 inSection:kInvoiceAttachments];
}

- (NSIndexSet *)getNonAttachmentSections {
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(kInvoiceInfo, kInvoiceLineItems)];
}

- (NSString *)getDocImageAPI {
    return ATTACH_IMAGE_API;
}

- (NSString *)getDocIDParam {
    return ATTACH_ID;
}

- (void)setMode:(ViewMode)mode {
    self.totalAmount = [NSDecimalNumber zero];
    
    [super setMode:mode];
    
    [self setActions];
}

- (void)setActions {
    if (self.mode == kViewMode && [Organization getSelectedOrg].showAR) {
        self.crudActions = nil;

        if (self.isActive) {
            self.crudActions = [NSArray arrayWithObjects:ACTION_UPDATE, ACTION_DELETE, ACTION_BNC_SHARE, nil];
            if (self.pdfReady) {
                self.crudActions = [@[ACTION_EMAIL] arrayByAddingObjectsFromArray:self.crudActions];
            }
        } else {
            self.crudActions = [NSArray arrayWithObjects:ACTION_UPDATE, ACTION_UNDELETE, ACTION_BNC_SHARE, nil];
        }
    }
}

#pragma mark - private methods

- (void)updateLineItems {
    self.totalAmount = [NSDecimalNumber zero];
    
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:kInvoiceLineItems];
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)sendInvoiceEmail {
    if ([MFMailComposeViewController canSendMail]) {
        self.mailer = [[MFMailComposeViewController alloc] init];
        self.mailer.mailComposeDelegate = self;
        
        Organization *org = [Organization getSelectedOrg];
        [self.mailer setSubject:[NSString stringWithFormat:@"You have an invoice from %@ due on %@", org.name, [Util formatDate:((Invoice *)self.busObj).dueDate format:nil]]];
        
        Customer *customer = [Customer objectForKey:((Invoice *)self.busObj).customerId];
        
        NSArray *contacts = [CustomerContact listContactsForCustomer:customer];
        NSMutableArray *toRecipients = [NSMutableArray arrayWithObject:customer.email];
        for (CustomerContact *contact in contacts) {
            [toRecipients addObject:contact.email];
        }
        
        [self.mailer setToRecipients:toRecipients];
        
        NSString *encodedEmail = [Util URLEncode:customer.email];
        NSString *linkUrl = [NSString stringWithFormat:@"%@/%@/%@?email=%@&id=%@", DOMAIN_URL, PORTAL_BASE, org.objectId, encodedEmail, customer.objectId];
        NSString *invLink = [NSString stringWithFormat:@"<a href='%@'>%@</a>", linkUrl, linkUrl];
        
        NSString *emailBody = [NSString stringWithFormat:INVOICE_EMAIL_TEMPLATE, customer.name, invLink, org.name, ((Invoice *)self.busObj).invoiceNumber, [Util formatCurrency:((Invoice *)self.busObj).amountDue], [Util formatDate:((Invoice *)self.busObj).dueDate format:nil], nil];
        [self.mailer setMessageBody:emailBody isHTML:YES];
        [self.mailer addAttachmentData:self.invoicePDFData mimeType:@"application/pdf" fileName:[NSString stringWithFormat:@"%@.pdf", ((Invoice *)self.busObj).invoiceNumber]];
        
        for (Document *attachment in self.busObj.attachments) {
            if (attachment.isPublic) {
                NSString *ext = [[attachment.name pathExtension] lowercaseString];
                if (![ext isEqualToString:@"exe"]) {
                    [self.mailer addAttachmentData:attachment.data mimeType:[MIME_TYPE_DICT objectForKey:ext] fileName:attachment.name];
                }
            }
        }
        
        [self presentViewController:self.mailer animated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failure"
                                                        message:@"Your device doesn't support the composer sheet"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        [alert show];
    }
}

- (void)setLineItems:(NSArray *)lineItems {
//    _lineItems = lineItems; //TODO: handle addition?
    
    [self updateLineItems];
}

- (void)addMoreItems {
    if ([self tryTap]) {
        [self.view findAndResignFirstResponder];
        [self performSegueWithIdentifier:INV_SELECT_ITEMS_SEGUE sender:self];
    }
}

- (void)addMoreAttachment {
    if ([self tryTap]) {
#ifdef LITE_VERSION
        [UIAppDelegate presentUpgrade];
#else
        [self.view findAndResignFirstResponder];
        [self performSegueWithIdentifier:INV_SCAN_PHOTO_SEGUE sender:self];
#endif
    }
}

- (void)pdfTapped:(UITapGestureRecognizer *)gestureRecognizer {
    if ([self tryTap]) {
        UIImageView *imageView = (UIImageView *)gestureRecognizer.view;
        [self selectAttachment:imageView];
        [self performSegueWithIdentifier:INV_VIEW_PDF_SEGUE sender:self.busObj];
    }
}

- (void)addPDFAttachment {
    UIImage *image = [UIImage imageNamed:@"pdf_icon.png"];
    self.pdfView = [[UIImageView alloc] initWithImage:image];
    
    CGRect rect = self.pdfView.frame;
    rect.size.height = IMG_HEIGHT;
    rect.size.width = IMG_WIDTH - IMG_PADDING;
    self.pdfView.frame = rect;
    self.pdfView.tag = 0;
    self.pdfView.layer.cornerRadius = 8.0f;
    self.pdfView.layer.masksToBounds = YES;
    self.pdfView.layer.borderColor = [[UIColor clearColor]CGColor];
    self.pdfView.layer.borderWidth = 1.0f;
    
    self.pdfView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pdfTapped:)];
    [self.pdfView addGestureRecognizer:tap];
    
//    [self.attachmentScrollView addSubview:imageView];
}


- (UIToolbar *)inputAccessoryViewForTag:(NSInteger)tag {
    UIToolbar *tlbControls = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, ToolbarHeight)];
    tlbControls.barStyle = UIBarStyleBlackTranslucent;
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:StrDone
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(inputAccessoryDoneAction:)];
    doneButton.tag = tag * TAG_BASE;
    tlbControls.items = [NSArray arrayWithObjects:flexibleSpace, doneButton, nil];
    
    return tlbControls;
}

#pragma mark - Target Action

- (IBAction)saveBusObj:(UIBarButtonItem *)sender {
    if ([self tryTap]) {
        [self.view findAndResignFirstResponder];
        
        Invoice *shaddowInvoice = (Invoice *)self.shaddowBusObj;
        
        if (shaddowInvoice.customerId == nil) {
            [UIHelper showInfo:@"No customer chosen" withStatus:kError];
            return;
        }
        
        if (shaddowInvoice.invoiceNumber == nil) {
            [UIHelper showInfo:@"No invoice number" withStatus:kError];
            return;
        }
        
        if ([shaddowInvoice.lineItems count] == 0) {
            [UIHelper showInfo:@"No line item" withStatus:kError];
            return;
        }
        
        [super saveBusObj:sender];
        
        if (self.mode == kCreateMode || self.mode == kAttachMode) {
            [shaddowInvoice create];
        } else if (self.mode == kUpdateMode){
            [shaddowInvoice update];
        }
    }
}

#pragma mark - Deprecated: action sheet replaced by action menu view
- (void)invoiceActions:(UIBarButtonItem *)sender {
    UIActionSheet *actions = [[UIActionSheet alloc] init];
    actions.title = @"Select an Action";
    actions.delegate = self;
    
    [actions addButtonWithTitle:[INVOICE_ACTIONS objectAtIndex:kEditInvoice]];
    [actions addButtonWithTitle:[INVOICE_ACTIONS objectAtIndex:kEmailInvoice]];
    [actions addButtonWithTitle:[INVOICE_ACTIONS objectAtIndex:kDeleteInvoice]];
    [actions addButtonWithTitle:[INVOICE_ACTIONS objectAtIndex:kCancelInvoiceAction]];
    
    actions.destructiveButtonIndex = kDeleteInvoice;
    actions.cancelButtonIndex = kCancelInvoiceAction;
    
//    UIActionSheet *actions = [[UIActionSheet alloc] initWithTitle:@"Select an Action" delegate:self cancelButtonTitle:[INVOICE_ACTIONS objectAtIndex:kCancelInvoiceAction] destructiveButtonTitle:[INVOICE_ACTIONS objectAtIndex:kDeleteInvoice] otherButtonTitles:[INVOICE_ACTIONS objectAtIndex:kEditInvoice], [INVOICE_ACTIONS objectAtIndex:kEmailInvoice], [INVOICE_ACTIONS objectAtIndex:kNote], nil];
    
    [actions showFromBarButtonItem:sender animated:YES];
}

#pragma mark - Life Cycle

- (void)viewDidLoad
{
    if (!self.busObj) {
        self.busObj = [[Invoice alloc] init];
        self.shaddowBusObj = [[Invoice alloc] init];
    }
        
    [super viewDidLoad];
    
    if (self.mode != kViewMode) {
        self.crudActions = nil;
        
        if (self.mode == kCreateMode || self.mode == kAttachMode) {
            self.title = @"New Invoice";
        }
    }
    
    self.pdfReady = NO;
    
    self.totalAmount = [NSDecimalNumber zero];
    
    self.busObj.editDelegate = self;
    self.shaddowBusObj.editDelegate = self;
    
    self.invoiceDatePicker = [[UIDatePicker alloc] initWithFrame:PICKER_RECT];
    self.invoiceDatePicker.datePickerMode = UIDatePickerModeDate;
    [self.invoiceDatePicker addTarget:self action:@selector(selectInvoiceDateFromPicker:) forControlEvents:UIControlEventValueChanged];
    
    self.dueDatePicker = [[UIDatePicker alloc] initWithFrame:PICKER_RECT];
    self.dueDatePicker.datePickerMode = UIDatePickerModeDate;
    [self.dueDatePicker addTarget:self action:@selector(selectDueDateFromPicker:) forControlEvents:UIControlEventValueChanged];

    self.invoiceNumTextField = [[UITextField alloc] initWithFrame:INV_INFO_INPUT_RECT];
    [self initializeTextField:self.invoiceNumTextField];
    self.invoiceNumTextField.tag = kInvoiceNumber * TAG_BASE;
    self.invoiceNumTextField.delegate = self;
    self.invoiceNumTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    self.invoiceDateTextField = [[UITextField alloc] initWithFrame:INV_INFO_INPUT_RECT];
    [self initializeTextField:self.invoiceDateTextField];
    self.invoiceDateTextField.tag = kInvoiceDate * TAG_BASE;
    self.invoiceDateTextField.clearButtonMode = UITextFieldViewModeNever;
    self.invoiceDateTextField.inputView = self.invoiceDatePicker;
    self.invoiceDateTextField.inputAccessoryView = [self inputAccessoryViewForTag:kInvoiceDate];
    
    self.invoiceDueDateTextField = [[UITextField alloc] initWithFrame:INV_INFO_INPUT_RECT];
    [self initializeTextField:self.invoiceDueDateTextField];
    self.invoiceDueDateTextField.tag = kInvoiceDueDate * TAG_BASE;
    self.invoiceDueDateTextField.clearButtonMode = UITextFieldViewModeNever;
    self.invoiceDueDateTextField.inputView = self.dueDatePicker;
    self.invoiceDueDateTextField.inputAccessoryView = [self inputAccessoryViewForTag:kInvoiceDueDate];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activityIndicator.hidesWhenStopped = YES;
    
    [self addPDFAttachment];
    
    if (self.mode == kViewMode) {
        [self downloadPDF];
    }
}

- (void)downloadPDF {
    // retrieve PDF in view mode
    self.pdfReady = NO;
    self.invoicePDFData = [NSMutableData data];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@?%@=%@&%@=%@", DOMAIN_URL, INV_2_PDF_API, Id, self.busObj.objectId, PRESENT_TYPE, PDF_TYPE]];
    NSURLRequest *req = [NSURLRequest  requestWithURL:url
                                          cachePolicy:NSURLRequestUseProtocolCachePolicy
                                      timeoutInterval:API_TIMEOUT];
    
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               self.pdfReady = YES;                               
                               self.crudActions = [@[ACTION_EMAIL] arrayByAddingObjectsFromArray:self.crudActions];
                               Debug(@"Succeeded! Received %lu bytes of data for PDF", (unsigned long)[self.invoicePDFData length]);
                           }];
}

- (void)downloadPDF_Deprecated {
    // retrieve PDF in view mode
    self.invoicePDFData = [NSMutableData data];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@?%@=%@&%@=%@", DOMAIN_URL, INV_2_PDF_API, Id, self.busObj.objectId, PRESENT_TYPE, PDF_TYPE]];
    NSURLRequest *req = [NSURLRequest  requestWithURL:url
                                          cachePolicy:NSURLRequestUseProtocolCachePolicy
                                      timeoutInterval:API_TIMEOUT];
    
    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    
    if (!theConnection) {
        Debug(@"Failed to establish URL connection to retrieve PDF");
    } else {
        [self addPDFAttachment];
    }
}

//- (void)viewWillAppear:(BOOL)animated {
//    [self.view removeGestureRecognizer:self.tapRecognizer];
//}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:INV_SELECT_CUSTOMER_SEGUE]) {
        [segue.destinationViewController setMode:kSelectMode];
        ((CustomersTableViewController *)segue.destinationViewController).selectDelegate = self;
    } else if ([segue.identifier isEqualToString:INV_SELECT_ITEMS_SEGUE]) {
        [segue.destinationViewController setMode:kSelectMode];
        ((ItemsTableViewController *)segue.destinationViewController).selectDelegate = self;
    } else if ([segue.identifier isEqualToString:INV_SCAN_PHOTO_SEGUE]) {
        ((ScannerViewController *)segue.destinationViewController).delegate = self;
        [segue.destinationViewController setMode:kAttachMode];
    } else if ([segue.identifier isEqualToString:INV_PREVIEW_ATTACHMENT_SEGUE]) {   //deprecated
        NSInteger idx = ((UIImageView *)sender).tag;
        if (self.mode != kCreateMode && self.mode != kAttachMode) {
            idx--;
        }
        [segue.destinationViewController setDocument:[self.shaddowBusObj.attachments objectAtIndex:idx]];
    } else if ([segue.identifier isEqualToString:INV_VIEW_PDF_SEGUE]) {
        [segue.destinationViewController setInvoice:sender];
    } else if ([segue.identifier isEqualToString:INV_VIEW_CUSTOMER_DETAILS_SEGUE]) {
        [segue.destinationViewController setBusObj:sender];
        [segue.destinationViewController setMode:kViewMode];
    } else if ([segue.identifier isEqualToString:INV_MODIFY_ITEM_DETAILS_SEGUE]) {
        int index = [sender intValue];
        Item *item = [((Invoice *)self.shaddowBusObj).lineItems objectAtIndex:index];
        [segue.destinationViewController setBusObj:item];
        [segue.destinationViewController setLineItemIndex:index];
        [segue.destinationViewController setMode:kModifyMode];
        ((EditItemViewController*)segue.destinationViewController).lineItemDelegate = self;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kInvoiceInfo) {
        return [InvoiceInfo count];
    } else if (section == kInvoiceLineItems) {
        return [((Invoice *)self.shaddowBusObj).lineItems count];
    } else if (section == kInvoiceAttachments) {
        if (self.mode == kAttachMode || self.mode == kCreateMode) {
            return 1;
        } else {
            return 2;
        }
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    UITableViewCell *cell;
    Invoice *shaddowInvoice = (Invoice *)self.shaddowBusObj;
    
    switch (indexPath.section) {
        case kInvoiceInfo:
        {
            if (self.modeChanged) {
                if (self.mode == kViewMode) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:INV_INFO_CELL_ID];
                } else {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:INV_INFO_CELL_ID];
                }
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:INV_INFO_CELL_ID];
                if (!cell) {
                    if (self.mode == kViewMode) {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:INV_INFO_CELL_ID];
                    } else {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:INV_INFO_CELL_ID];
                    }
                }
            }
            
            cell.textLabel.text = [InvoiceInfo objectAtIndex:indexPath.row];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if (/* DISABLES CODE */ (NO) && self.mode == kAttachMode) {               // not in use
                cell.backgroundColor = [UIColor clearColor];
                cell.textLabel.textColor = [UIColor yellowColor];
                cell.detailTextLabel.textColor = [UIColor yellowColor];
                cell.textLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:INV_LABEL_FONT_SIZE + 2];
                cell.detailTextLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:INV_LABEL_FONT_SIZE + 2];
            } else {
                cell.textLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:INV_LABEL_FONT_SIZE];
                cell.detailTextLabel.font = [UIFont fontWithName:APP_FONT size:INV_LABEL_FONT_SIZE];
            }
            cell.accessoryType = UITableViewCellAccessoryNone;
            
            switch (indexPath.row) {
                case kInvoiceCustomer:                    
                    if (self.mode == kViewMode) {
                        if (shaddowInvoice.customerId != nil) {
                            cell.detailTextLabel.text = [Customer objectForKey:shaddowInvoice.customerId].name;
                        } else {
                            cell.detailTextLabel.text = nil;
                        }                        
                    } else {
                        if (shaddowInvoice.customerId != nil) {
                            cell.detailTextLabel.text = [Customer objectForKey:shaddowInvoice.customerId].name;
                        } else {
                            cell.detailTextLabel.text = @"Select one";
                        }
                    }
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                case kInvoiceNumber:
                {
                    if (self.mode == kViewMode) {
                        if (shaddowInvoice.invoiceNumber != nil) {
                            cell.detailTextLabel.text = shaddowInvoice.invoiceNumber;
                        } else {
                            cell.detailTextLabel.text = nil;
                        }                        
                    } else {
                        if (shaddowInvoice.invoiceNumber != nil) {
                            self.invoiceNumTextField.text = shaddowInvoice.invoiceNumber;
                        }
                        self.invoiceNumTextField.backgroundColor = cell.backgroundColor;
                        
                        [cell addSubview:self.invoiceNumTextField];                        
                    }
                }
                    break;
                case kInvoiceDate:
                {
                    if (self.mode == kViewMode) {
                        if (shaddowInvoice.invoiceDate != nil) {
                            cell.detailTextLabel.text = [Util formatDate:shaddowInvoice.invoiceDate format:nil];
                        } else {
                            cell.detailTextLabel.text = nil;
                        }
                    } else {
                        if (shaddowInvoice.invoiceDate != nil) {
                            self.invoiceDatePicker.date = shaddowInvoice.invoiceDate;
                            self.invoiceDateTextField.text = [Util formatDate:shaddowInvoice.invoiceDate format:nil];
                        } else {
                            self.invoiceDatePicker.date = [NSDate date];
                            self.invoiceDateTextField.text = [Util formatDate:[NSDate date] format:nil];
                            shaddowInvoice.invoiceDate = [NSDate date];
                        }
                        self.invoiceDateTextField.backgroundColor = cell.backgroundColor;
                        
                        [cell addSubview:self.invoiceDateTextField];                        
                    }
                }
                    break;
                case kInvoiceDueDate:
                {
                    if (self.mode == kViewMode) {
                        if (shaddowInvoice.dueDate != nil) {
                            cell.detailTextLabel.text = [Util formatDate:shaddowInvoice.dueDate format:nil];
                        } else {
                            cell.detailTextLabel.text = nil;
                        }                        
                    } else {
                        if (shaddowInvoice.dueDate != nil) {
                            self.dueDatePicker.date = shaddowInvoice.dueDate;
                            self.invoiceDueDateTextField.text = [Util formatDate:shaddowInvoice.dueDate format:nil];
                        } else {
                            self.dueDatePicker.date = [NSDate date];
                            self.invoiceDueDateTextField.text = [Util formatDate:[NSDate date] format:nil];
                            shaddowInvoice.dueDate = [NSDate date];
                        }
                        self.invoiceDueDateTextField.backgroundColor = cell.backgroundColor;
                        
                        [cell addSubview:self.invoiceDueDateTextField];                        
                    }
                }
                    break;
                default:
                    break;
            }

        }
            break;
        case kInvoiceLineItems:
        {
//            cell = [tableView dequeueReusableCellWithIdentifier:INV_ITEM_CELL_ID];
//            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:INV_ITEM_CELL_ID];
                if (self.mode != kViewMode) {
                    cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
//            }
            
//            NSString *itemId = [self.lineItems objectAtIndex:indexPath.row];
//            Item *item = [((Invoice *)self.shaddowBusObj).lineItems objectForKey:itemId];
            Item *item = [shaddowInvoice.lineItems objectAtIndex:indexPath.row];

//            item.objectId = itemId;
            item.name = [Item objectForKey:item.objectId].name;
            
//            NSInteger qty;
//            Item *item = [Item objectForKey:itemId];
//            id quantity = [((Invoice *)self.shaddowBusObj).lineItems objectForKey:itemId];
//            if (quantity == nil) {
//                qty = 1;
//            } else {
//                qty = [quantity integerValue];
//            }

            NSDecimalNumber *amount = [item.price decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithDecimal:[[NSNumber numberWithUnsignedInteger:item.qty] decimalValue]]];
            cell.textLabel.text = item.name;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if (/* DISABLES CODE */ (NO) && self.mode == kAttachMode) {               // not in use
                cell.backgroundColor = [UIColor clearColor];
                cell.textLabel.textColor = [UIColor yellowColor];
                cell.detailTextLabel.textColor = [UIColor yellowColor];
                cell.textLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:INV_LABEL_FONT_SIZE + 2];
                cell.detailTextLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:INV_LABEL_FONT_SIZE + 2];
            } else {
                cell.textLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:INV_LABEL_FONT_SIZE];
                cell.detailTextLabel.font = [UIFont fontWithName:APP_FONT size:INV_LABEL_FONT_SIZE];
            }
            
            if (self.mode == kViewMode) {
//                for (UIView *view in cell.subviews) {
//                    if ([view isKindOfClass:[UITextField class]]) {
//                        [view removeFromSuperview];
//                    }
//                }
                cell.detailTextLabel.text = [[Util formatCurrency:amount] stringByAppendingFormat:@"  (%lu pcs)", (unsigned long)item.qty];
            } else {
                UITextField *itemAmountTextField = [[UITextField alloc] initWithFrame:INV_ITEM_AMOUNT_RECT];
                itemAmountTextField.text = [Util formatCurrency:amount];
                if (/* DISABLES CODE */ (NO) && self.mode == kAttachMode) {           // not in use
                    itemAmountTextField.font = [UIFont fontWithName:APP_BOLD_FONT size:INV_LABEL_FONT_SIZE + 2];
                    itemAmountTextField.textColor = [UIColor yellowColor];
                } else {
                    itemAmountTextField.font = [UIFont fontWithName:APP_FONT size:INV_LABEL_FONT_SIZE];
                    itemAmountTextField.textColor = [UIColor blackColor];
                }
                itemAmountTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
                itemAmountTextField.backgroundColor = cell.backgroundColor;
                itemAmountTextField.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support
                itemAmountTextField.autocapitalizationType = UITextAutocapitalizationTypeNone; // no auto capitalization support
                itemAmountTextField.textAlignment = NSTextAlignmentRight;
                itemAmountTextField.enabled = NO;
                itemAmountTextField.borderStyle = UITextBorderStyleNone;
                [cell addSubview:itemAmountTextField];
                
//                UITextField *itemQtytField = [[UITextField alloc] initWithFrame:INV_ITEM_QTY_RECT];
//                itemQtytField.text = [NSString stringWithFormat:@"%d", qty];
//                itemQtytField.keyboardType = UIKeyboardTypeNumberPad;
//                itemQtytField.font = [UIFont fontWithName:APP_FONT size:INV_LABEL_FONT_SIZE];
//                itemQtytField.textColor = [UIColor blackColor];
//                itemQtytField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
//                itemQtytField.backgroundColor = cell.backgroundColor;
//                itemQtytField.autocorrectionType = UITextAutocorrectionTypeNo;
//                itemQtytField.autocapitalizationType = UITextAutocapitalizationTypeNone;
//                itemQtytField.textAlignment = NSTextAlignmentRight;
//                itemQtytField.tag = indexPath.row + [InvoiceInfo count] * TAG_BASE;
//                            
//                itemQtytField.delegate = self;
//                itemQtytField.enabled = YES;
//                itemQtytField.layer.cornerRadius = 8.0f;
//                itemQtytField.layer.masksToBounds = YES;
//                itemQtytField.layer.borderColor = [[UIColor grayColor]CGColor];
//                itemQtytField.layer.borderWidth = 0.5f;
//                itemQtytField.inputAccessoryView = [self inputAccessoryViewForTag:indexPath.row + [InvoiceInfo count] * TAG_BASE];
//                
//                [cell addSubview:itemQtytField];
                [self.tableView setEditing:YES animated:YES];
            }
            
            self.totalAmount = [self.totalAmount decimalNumberByAdding:amount];
        }
            break;
        case kInvoiceAttachments:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:INV_ATTACH_CELL_ID];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:INV_ATTACH_CELL_ID];
            }

            cell.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
            cell.backgroundColor = [UIColor clearColor];
            
            if (indexPath.row == 0) {
                if (self.mode != kCreateMode && self.mode != kAttachMode) {
                    [cell.contentView addSubview:self.pdfView];
                } else {
                    [cell.contentView addSubview:self.attachmentScrollView];
                    [cell.contentView addSubview:self.attachmentPageControl];
                }
            } else {
                [cell.contentView addSubview:self.attachmentScrollView];
                [cell.contentView addSubview:self.attachmentPageControl];
            }
        }
            break;
        default:
            break;
    }

    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kInvoiceInfo) {
        return CELL_HEIGHT;
    } else if (indexPath.section == kInvoiceLineItems) {
        return CELL_HEIGHT;
    } else if (indexPath.section == kInvoiceAttachments) {
        if (indexPath.row == 0) {
            return IMG_HEIGHT + IMG_PADDING;
        } else {
            return IMG_HEIGHT + IMG_PADDING + ATTACHMENT_PV_HEIGHT + (SYSTEM_VERSION_LESS_THAN(@"7.0") ? 0 : 10);
        }
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == kInvoiceInfo) {
        return 0;
    } else if (section == kInvoiceLineItems) {
        return 30;
    } else {
        return 30;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == kInvoiceInfo) {
        return 20;
    } else if (section == kInvoiceLineItems) {
        return 35;
    } else {
        return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == kInvoiceInfo) {
        return nil;
    } else if (section == kInvoiceLineItems) {
        return [self initializeSectionHeaderViewWithLabel:@"Line Items" needAddButton:(self.mode != kViewMode) addAction:@selector(addMoreItems)];
        
//        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 360, 40)];
//        headerView.backgroundColor = [UIColor clearColor];
//        
//        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 100, 20)];
//        label.text = @"Line Items";
//        label.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
//        label.backgroundColor = [UIColor clearColor];
//        if (NO && self.mode == kAttachMode) {               // not in use
//            label.textColor = [UIColor yellowColor];
//        } else {
//            label.textColor = APP_SYSTEM_BLUE_COLOR;
//            label.shadowColor = [UIColor whiteColor];
//            label.shadowOffset = CGSizeMake(0, 1);
//        }
//
//        [headerView addSubview:label];
//        
//        if (self.mode != kViewMode) {
//            UIButton *addButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
//            CGRect frame = CGRectMake(265, -10, 40, 40);
//            addButton.frame = frame;
//            addButton.backgroundColor = [UIColor clearColor];
//            [addButton addTarget:self action:@selector(addMoreItems) forControlEvents:UIControlEventTouchUpInside];
//            
//            [headerView addSubview:addButton];
//        }
//        
//        return headerView;
    } else {
        return [self initializeSectionHeaderViewWithLabel:@"Documents" needAddButton:(self.mode != kViewMode) addAction:@selector(addMoreAttachment)];
        
//        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 360, 30)];
//        headerView.backgroundColor = [UIColor clearColor];
//        
//        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 100, 20)];
//        label.text = @"Documents";
//        label.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
//        label.backgroundColor = [UIColor clearColor];
//        if (NO && self.mode == kAttachMode) {
//            label.textColor = [UIColor yellowColor];
//        } else {
//            label.textColor = APP_SYSTEM_BLUE_COLOR;
//            label.shadowColor = [UIColor whiteColor];
//            label.shadowOffset = CGSizeMake(0, 1);
//        }
//        
//        [headerView addSubview:label];
//        
//        if (self.mode != kViewMode) {
//            UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
//            CGRect frame = CGRectMake(265, -10, 40, 40);
//            cameraButton.frame = frame;
//            cameraButton.backgroundColor = [UIColor clearColor];
//            [cameraButton addTarget:self action:@selector(addMoreAttachment) forControlEvents:UIControlEventTouchUpInside];
//            
//            //        UIImage *btnImage = [UIImage imageNamed:@"camera_icon.jpg"];
//            //        UIButton *cameraButton = [[UIButton alloc] initWithFrame:CGRectMake(265, -10, 40, 40)];
//            //        [cameraButton setImage:btnImage forState:UIControlStateNormal];
//            //        cameraButton.backgroundColor = [UIColor clearColor];
//            //        [cameraButton addTarget:self action:@selector(addMoreItems) forControlEvents:UIControlEventTouchUpInside];
//            
//            [headerView addSubview:cameraButton];
//        }
//        
//        return headerView;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == kInvoiceLineItems) {
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 360, 30)];
        footerView.backgroundColor = [UIColor clearColor];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 3, 100, 20)];
        label.text = @"Amount";
        label.font = [UIFont fontWithName:APP_BOLD_FONT size:14];
        label.backgroundColor = [UIColor clearColor];
        if (/* DISABLES CODE */ (NO) && self.mode == kAttachMode) {           // not in use
            label.textColor = [UIColor yellowColor];
        } else {
            label.textColor = APP_LABEL_BLUE_COLOR;
        }
        
        [footerView addSubview:label];
        
        UILabel *amount = [[UILabel alloc] initWithFrame:CGRectMake(CELL_WIDTH - 100, 3, 100, 20)];
        amount.text = [Util formatCurrency:self.totalAmount];
        amount.textAlignment = NSTextAlignmentRight;
        amount.font = [UIFont fontWithName:APP_FONT size:15];
        amount.backgroundColor = [UIColor clearColor];
        if (/* DISABLES CODE */ (NO) && self.mode == kAttachMode) {           // not in use
            amount.textColor = [UIColor yellowColor];
        }
        
        ((Invoice *)self.shaddowBusObj).amount = self.totalAmount;
        ((Invoice *)self.shaddowBusObj).amountDue = self.totalAmount;
        
        [footerView addSubview:amount];
        
        return footerView;
    }
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kInvoiceLineItems && self.mode != kViewMode) {
        return YES;
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kInvoiceLineItems) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            // Delete the row from the data source
            [((Invoice *)self.shaddowBusObj).lineItems removeObjectAtIndex:indexPath.row];
//            NSString *itemId = [self.lineItems objectAtIndex:indexPath.row];
//            [((Invoice *)self.shaddowBusObj).lineItems removeObjectForKey:itemId];
            [self updateLineItems];
            
//            NSMutableArray *tempArr = [NSMutableArray arrayWithArray:self.lineItems];
//            [tempArr removeObjectAtIndex:indexPath.row];
//            self.lineItems = [NSArray arrayWithArray:tempArr];
            
//            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
//        else if (editingStyle == UITableViewCellEditingStyleInsert) {
//            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    
    if (self.mode != kViewMode) {
        switch (indexPath.section) {
            case kInvoiceInfo:
                switch (indexPath.row) {
                    case kInvoiceCustomer:
//                        [self.editingField resignFirstResponder];
//                        self.editingField = nil;
                        [self performSegueWithIdentifier:INV_SELECT_CUSTOMER_SEGUE sender:self];
                        break;
                    default:
                        break;
                }
                break;
            case kInvoiceLineItems:
            {
//                item.editInvoiceDelegate = self;
                [self performSegueWithIdentifier:INV_MODIFY_ITEM_DETAILS_SEGUE sender:[NSNumber numberWithUnsignedInteger:indexPath.row]];
            }
                break;
            default:
                break;
        }
    } else {
        switch (indexPath.section) {
            case kInvoiceInfo:
                switch (indexPath.row) {
                    case kInvoiceCustomer:
                    {
                        Customer *customer = [Customer objectForKey: ((Invoice *)self.shaddowBusObj).customerId];
                        customer.editInvoiceDelegate = self;
                        [self performSegueWithIdentifier:INV_VIEW_CUSTOMER_DETAILS_SEGUE sender:customer];
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
    if (textField.tag == kInvoiceNumber * TAG_BASE) {
        ((Invoice *)self.shaddowBusObj).invoiceNumber = [Util trim:textField.text];
    } else {
        // unused now
        int qty = textField.text.intValue;
        NSNumber *quantity = [NSNumber numberWithInt:qty];
        Item *item = [((Invoice *)self.shaddowBusObj).lineItems objectAtIndex: textField.tag - [InvoiceInfo count] * TAG_BASE];
        item.qty = [quantity intValue];
        
        [self updateLineItems];
//        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:1];
//        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    [self textFieldDoneEditing:textField];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self textFieldDoneEditing:textField];
    
    [super textFieldDidEndEditing:textField];
}

#pragma mark - Date Picker target action

- (void)selectInvoiceDateFromPicker:(UIDatePicker *)sender {
    self.invoiceDateTextField.text = [Util formatDate:sender.date format:nil];
    ((Invoice *)self.shaddowBusObj).invoiceDate = sender.date;
}

- (void)selectDueDateFromPicker:(UIDatePicker *)sender {
    self.invoiceDueDateTextField.text = [Util formatDate:sender.date format:nil];
    ((Invoice *)self.shaddowBusObj).dueDate = sender.date;
}

#pragma mark - Alert delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case DELETE_INV_ALERT_TAG:
            if (buttonIndex == 1) {
                [self.busObj remove];
            }
            break;
        case REMOVE_ATTACHMENT_ALERT_TAG:   // deprecated
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
                    
                    [((Invoice *)self.shaddowBusObj).attachments removeObjectAtIndex:idx];
                    [imageView removeFromSuperview];
                    [self layoutScrollImages:NO];
                    
                    self.currAttachment = nil;
                }
            }
            break;
        default:
            [super alertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
    }
}

#pragma mark - Action sheet delegate

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    for (UIView* view in [actionSheet subviews]) {
        if ([view respondsToSelector:@selector(title)]) {
            NSString* title = [view performSelector:@selector(title)];
            if ([title isEqualToString:[INVOICE_ACTIONS objectAtIndex:kEmailInvoice]] && [view respondsToSelector:@selector(setEnabled:)]) {
                if (self.pdfReady) {
                    [view performSelector:@selector(setEnabled:) withObject:[NSNumber numberWithBool:YES]];
                } else {
                    [view performSelector:@selector(setEnabled:) withObject:[NSNumber numberWithBool:NO]];
                }
            }
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case kDeleteInvoice:
        {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle: @"Delete Confirmation"
                                  message: @"Are you sure to delete this invoice?"
                                  delegate: self
                                  cancelButtonTitle:@"No"
                                  otherButtonTitles:@"Yes", nil];
            alert.tag = DELETE_INV_ALERT_TAG;
            [alert show];
        }
            break;
        case kEmailInvoice:
            [self sendInvoiceEmail];
            break;
        case kEditInvoice:
            self.mode = kUpdateMode;
            break;
        default:
            break;
    }
}

#pragma mark - NSURLConnection delegate - All Deprecated!

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.invoicePDFData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.invoicePDFData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.pdfReady = YES;
    self.crudActions = [@[ACTION_EMAIL] arrayByAddingObjectsFromArray:self.crudActions];
    
    Debug(@"Succeeded! Received %lu bytes of data for PDF", (unsigned long)[self.invoicePDFData length]);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.pdfReady = NO;
    
    Debug(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}

#pragma mark - MailComposer delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    switch (result){
        case MFMailComposeResultSent:
            [UIHelper showInfo: EMAIL_SENT withStatus:kSuccess];
            break;
        case MFMailComposeResultCancelled:
            break;
        case MFMailComposeResultSaved:
            break;
        case MFMailComposeResultFailed:
            [UIHelper showInfo: EMAIL_FAILED withStatus:kFailure];
            break;
        default:
            [UIHelper showInfo: EMAIL_FAILED withStatus:kError];
            break;
    }
    
    // Remove the mail view
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - model delegate

- (void)didReadObject {
    self.totalAmount = [NSDecimalNumber zero];
    [super didReadObject];
    [self.shaddowBusObj cloneTo:self.busObj];
}

- (void)didUpdateObject {
    [self downloadPDF];
    [super didUpdateObject];
}

- (void)didSelectCustomer:(NSString *)customerId {
    ((Invoice *)self.shaddowBusObj).customerId = customerId;
    
    NSIndexPath *path = [NSIndexPath indexPathForRow:kInvoiceCustomer inSection:kInvoiceInfo];
    [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)didSelectItems:(NSArray *)items {
    for (Item *item in items) {
        [((Invoice *)self.shaddowBusObj).lineItems addObject:item];
    }
    
    [self updateLineItems];
}

- (void)didUpdateCustomer {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath *path = [NSIndexPath indexPathForRow:kInvoiceCustomer inSection:kInvoiceInfo];
        [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:YES];
    });
}

- (void)didModifyItem:(Item *)item forIndex:(int)index {
    [Item clone:item to:[((Invoice *)self.shaddowBusObj).lineItems objectAtIndex:index]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateLineItems];
    });
}

#pragma mark - Action Menu delegate

- (void)didSelectCrudAction:(NSString *)action {
    if ([action isEqualToString:ACTION_EMAIL]) {
#ifdef LITE_VERSION
        [UIAppDelegate presentUpgrade];
#else
        Invoice *inv = (Invoice *)self.busObj;
        inv.mailDelegate = self;
        [inv sendInvoice];
#endif
    } else {
        [super didSelectCrudAction:action];
    }
}

#pragma mark - Invoice Mail delegate

- (void)didSendInvoice {
//    Customer *customer = [Customer objectForKey:((Invoice *)self.shaddowBusObj).customerId];
//    if (customer.email) {
//        [self sendInvoiceEmail];
//    } else {
//        [UIHelper showInfo:@"Fill in an email for this customer before you send them the invoice." withStatus:kInfo];
//        [self performSegueWithIdentifier:INV_VIEW_CUSTOMER_DETAILS_SEGUE sender:customer];
//    }
}

@end
