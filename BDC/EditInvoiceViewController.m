//
//  EditInvoiceViewController.m
//  BDC
//
//  Created by Qinwei Gong on 9/21/12.
//
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
#import "Customer.h"
#import "Organization.h"
#import "Uploader.h"
#import "APIHandler.h"

#import <QuartzCore/QuartzCore.h>
#import <MessageUI/MessageUI.h>

enum InvoiceSections {
    kInvoiceInfo,
    kInvoiceLineItems,
    kInvoiceAttachment
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
#define ACTION_EMAIL        @"Email Invoice"

#define TAG_BASE                        100
#define CELL_WIDTH                      300
//#define CELL_HEIGHT                     45
#define IMG_PADDING                     10
#define IMG_WIDTH                       CELL_WIDTH / 4
#define IMG_HEIGHT                      IMG_WIDTH - IMG_PADDING
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
//#define INV_INFO_INPUT_RECT     CGRectMake(93, 5, CELL_WIDTH - 100, CELL_HEIGHT - 10)
#define INV_INFO_INPUT_RECT     CGRectMake(CELL_WIDTH - 190, 5, 190, CELL_HEIGHT - 10)
#define INV_ITEM_AMOUNT_RECT    CGRectMake(cell.viewForBaselineLayout.bounds.size.width - 130, 5, 90, cell.viewForBaselineLayout.bounds.size.height-10)
#define INV_ITEM_QTY_RECT       CGRectMake(cell.viewForBaselineLayout.bounds.size.width - 180, 10, 60, cell.viewForBaselineLayout.bounds.size.height-20)
#define INV_ATTACHMENT_RECT     CGRectMake(5, 0, CELL_WIDTH, IMG_HEIGHT)
#define INV_ATTACHMENT_PV_HEIGHT        3
#define INV_ATTACHMENT_PV_RECT  CGRectMake(0, IMG_HEIGHT + IMG_PADDING, CELL_WIDTH, INV_ATTACHMENT_PV_HEIGHT)
#define INV_NUM_ATTACHMENT_PER_PAGE     4

#define DELETE_INV_ALERT_TAG            1
#define REMOVE_ATTACHMENT_ALERT_TAG     2

@interface EditInvoiceViewController () <InvoiceDelegate, CustomerDelegate, CustomerSelectDelegate, ItemSelectDelegate, ScannerDelegate, LineItemDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIScrollViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) Invoice *shaddowInvoice;
@property (nonatomic, strong) NSDecimalNumber *totalAmount;
@property (nonatomic, strong) UIDatePicker *invoiceDatePicker;
@property (nonatomic, strong) UIDatePicker *dueDatePicker;

//@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) UITextField *invoiceNumTextField;
@property (nonatomic, strong) UITextField *invoiceDateTextField;
@property (nonatomic, strong) UITextField *invoiceDueDateTextField;

//@property (nonatomic, strong) NSMutableDictionary *photos;
@property (nonatomic, strong) NSMutableArray *photoNames;

@property (nonatomic, strong) UIScrollView *attachmentScrollView;
@property (nonatomic, strong) UIPageControl *attachmentPageControl;
@property (nonatomic, strong) UIImageView *currAttachment;

@property (nonatomic, strong) NSMutableData *invoicePDFData;
@property (nonatomic, strong) MFMailComposeViewController *mailer;

@property (nonatomic, assign) BOOL modeChanged;
@property (nonatomic, assign) BOOL pdfReady;

//@property (nonatomic, weak) id<InvoiceDelegate> 

- (void)addMoreItems;
- (void)addMorePhoto;
- (void)layoutScrollImages:(BOOL)needChangePage;
- (void)addNewAttachment:(NSData *)photoData;

@end

@implementation EditInvoiceViewController

@synthesize invoice = _invoice;
@synthesize shaddowInvoice;
@synthesize totalAmount;
@synthesize invoiceDatePicker;
@synthesize dueDatePicker;
@synthesize invoiceNumTextField;
@synthesize invoiceDateTextField;
@synthesize invoiceDueDateTextField;
//@synthesize photos;
@synthesize photoNames;
@synthesize attachmentScrollView;
@synthesize attachmentPageControl;
@synthesize currAttachment;
@synthesize invoicePDFData;
@synthesize mailer;
@synthesize modeChanged;
@synthesize pdfReady;

#pragma mark - public methods

- (void)setInvoice:(Invoice *)invoice {
    _invoice = invoice;
    
    self.shaddowInvoice = nil;
    self.shaddowInvoice = [[Invoice alloc] init];
    [Invoice clone:invoice to:self.shaddowInvoice];
//    self.lineItems = [self.shaddowInvoice.lineItems allKeys];
}

- (void)addPhotoData:(NSData *)photoData name:(NSString *)photoName {
    if (self.shaddowInvoice == nil) {
        self.shaddowInvoice = [[Invoice alloc] init];
    }
    
    if (self.invoice == nil) {
        self.invoice = [[Invoice alloc] init];
    }

    if (self.photoNames == nil) {
        self.photoNames = [NSMutableArray array];
    }
    
    [self.shaddowInvoice.attachments setObject:photoData forKey:photoName];
    [self.photoNames addObject:photoName];
}

- (void)setMode:(ViewMode)mode {
    super.mode = mode;
    self.modeChanged = YES;
    
    if (mode == kViewMode) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(toggleMenu:)];
        self.navigationItem.rightBarButtonItem.tag = 1;
        self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;        
    } else {
//        self.tableView.allowsSelectionDuringEditing = YES;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveInvoice:)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEdit:)];
    }
    
    self.totalAmount = [NSDecimalNumber zero];
    
    for (UIView *subview in [self.attachmentScrollView subviews]) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            [subview removeFromSuperview];
        }
    }
    
    self.photoNames = [NSMutableArray arrayWithArray:[self.shaddowInvoice.attachments allKeys]];
    
    [self.tableView reloadData];
}

#pragma mark - private methods

- (void)updateLineItems {
    self.totalAmount = [NSDecimalNumber zero];
    
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:kInvoiceLineItems];
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)cancelEdit:(UIBarButtonItem *)sender {
    if (self.mode == kCreateMode || self.mode == kAttachMode) {
        [self navigateBack];
    } else {
        [self setInvoice:self.invoice];
        [self.photoNames removeAllObjects];

        self.mode = kViewMode;
    }
}

- (void)sendInvoiceEmail {
    if ([MFMailComposeViewController canSendMail]) {
        self.mailer = [[MFMailComposeViewController alloc] init];
        self.mailer.mailComposeDelegate = self;
        
        Organization *org = [Organization getSelectedOrg];
        [self.mailer setSubject:[NSString stringWithFormat:@"You have an invoice from %@ due on %@", org.name, [Util formatDate:self.invoice.dueDate format:nil]]];
        
        Customer *customer = [Customer objectForKey:self.invoice.customerId];
        NSArray *toRecipients = [NSArray arrayWithObjects:customer.email, nil];
        [self.mailer setToRecipients:toRecipients];
        
        //        UIImage *myImage = [UIImage imageNamed:@"mobiletuts-logo.png"];
        //        NSData *imageData = UIImagePNGRepresentation(myImage);
        //        [self.mailer addAttachmentData:imageData mimeType:@"image/png" fileName:@"mobiletutsImage"];
        
        NSString *encodedEmail = [Util URLEncode:customer.email];
        NSString *linkUrl = [NSString stringWithFormat:@"%@/%@/%@?email=%@&id=%@", DOMAIN_URL, PAGE_BASE, org.objectId, encodedEmail, customer.objectId];
        NSString *invLink = [NSString stringWithFormat:@"<a href='%@'>%@</a>", linkUrl, linkUrl];
        
        NSString *emailBody = [NSString stringWithFormat:INVOICE_EMAIL_TEMPLATE, customer.name, invLink, org.name, self.invoice.invoiceNumber, [Util formatCurrency:self.invoice.amountDue], [Util formatDate:self.invoice.dueDate format:nil], nil];
        [self.mailer setMessageBody:emailBody isHTML:YES];
        
        [self.mailer addAttachmentData:self.invoicePDFData mimeType:@"application/pdf" fileName:[NSString stringWithFormat:@"Invoice %@.pdf", self.invoice.invoiceNumber]];
        [self presentModalViewController:self.mailer animated:YES];
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
    [self.view findAndResignFirstResponder];
    [self performSegueWithIdentifier:INV_SELECT_ITEMS_SEGUE sender:self];
}

- (void)addMorePhoto {
    [self.view findAndResignFirstResponder];
    [self performSegueWithIdentifier:INV_SCAN_PHOTO_SEGUE sender:self];
}

- (void)selectAttachment:(UIImageView *)imageView {
    self.currAttachment.layer.borderColor = [[UIColor clearColor]CGColor];
    self.currAttachment.layer.borderWidth = 0.0f;

    imageView.layer.borderColor = [[UIColor whiteColor]CGColor];
    imageView.layer.borderWidth = 2.0f;
    self.currAttachment = imageView;
}

- (void)addPDFAttachment {
//    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@?%@=%@&%@=%@", DOMAIN_URL, INV_2_PDF_API, Id, self.invoice.objectId, PRESENT_TYPE, PNG_TYPE]];
//    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
    
    UIImage *image = [UIImage imageNamed:@"pdf_icon.png"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    
    CGRect rect = imageView.frame;
    rect.size.height = IMG_HEIGHT;
    rect.size.width = IMG_WIDTH - IMG_PADDING;
    imageView.frame = rect;
    imageView.tag = 0;
    imageView.layer.cornerRadius = 8.0f;
    imageView.layer.masksToBounds = YES;
    imageView.layer.borderColor = [[UIColor clearColor]CGColor];
    imageView.layer.borderWidth = 1.0f;
    
    imageView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pdfTapped:)];
    [imageView addGestureRecognizer:tap];
    
    [self.attachmentScrollView addSubview:imageView];
}

- (void)pdfTapped:(UITapGestureRecognizer *)gestureRecognizer {
    if ([self tryTap]) {
        UIImageView *imageView = (UIImageView *)gestureRecognizer.view;
        [self selectAttachment:imageView];
        [self performSegueWithIdentifier:INV_VIEW_PDF_SEGUE sender:self.invoice];
    }
}

- (void)imageTapped:(UITapGestureRecognizer *)gestureRecognizer {
    if ([self tryTap]) {
        UIImageView *imageView = (UIImageView *)gestureRecognizer.view;
        [self selectAttachment:imageView];
        [self performSegueWithIdentifier:INV_PREVIEW_ATTACHMENT_SEGUE sender:imageView];
    }
}

- (void)imagePressed:(UILongPressGestureRecognizer *)gestureRecognizer {
    if ([self tryTap]) {
        [self selectAttachment:(UIImageView *)gestureRecognizer.view];
        
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle: @"Delete Confirmation"
                                  message: @"Are you sure to delete this attachment?"
                                  delegate: self
                                  cancelButtonTitle:@"No"
                                  otherButtonTitles:@"Yes", nil];
            alert.tag = REMOVE_ATTACHMENT_ALERT_TAG;
            [alert show];
        }
    }
}

- (void)addNewAttachment:(NSData *)photoData {
    UIImage *image = [UIImage imageWithData:photoData];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    
    CGRect rect = imageView.frame;
    rect.size.height = IMG_HEIGHT;
    rect.size.width = IMG_WIDTH - IMG_PADDING;
    imageView.frame = rect;
    imageView.tag = [self.shaddowInvoice.attachments count] - 1;
    imageView.layer.cornerRadius = 8.0f;
    imageView.layer.masksToBounds = YES;
    imageView.layer.borderColor = [[UIColor clearColor]CGColor];
    imageView.layer.borderWidth = 1.0f;
    
    imageView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    [imageView addGestureRecognizer:tap];
    
    if (self.mode != kViewMode) {
        UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(imagePressed:)];
        press.minimumPressDuration = 1.0;
        [imageView addGestureRecognizer:press];
    }
    
    [self.attachmentScrollView addSubview:imageView];
}

//- (void)inputAccessoryDoneAction:(UIBarButtonItem *)button {
//    switch (button.tag) {
//        case kInvoiceDate * TAG_BASE:
//            [self.invoiceDateTextField resignFirstResponder];
//            break;
//        case kInvoiceDueDate * TAG_BASE:
//            [self.invoiceDueDateTextField resignFirstResponder];
//            break;
//        default:
//            break;
//    }
//}

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

- (IBAction)saveInvoice:(UIBarButtonItem *)sender {
    self.navigationItem.rightBarButtonItem.customView = self.activityIndicator;
    [self.activityIndicator startAnimating];
    [self.view findAndResignFirstResponder];
    
//    [Invoice clone:self.shaddowInvoice to:self.invoice];
    
    if (self.shaddowInvoice.customerId == nil) {
        [UIHelper showInfo:@"No customer chosen" withStatus:kError];
        return;
    }
    
    if (self.shaddowInvoice.invoiceNumber == nil) {
        [UIHelper showInfo:@"No invoice number" withStatus:kError];
        return;
    }
    
    if ([self.shaddowInvoice.lineItems count] == 0) {
        [UIHelper showInfo:@"No line item" withStatus:kError];
        return;
    }
    
    if (self.mode == kCreateMode || self.mode == kAttachMode) {
        [self.shaddowInvoice create];
    } else if (self.mode == kUpdateMode){
        [self.shaddowInvoice update];
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

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    if (!self.invoice) {
        self.invoice = [[Invoice alloc] init];
        self.shaddowInvoice = [[Invoice alloc] init];
    }
    
    self.busObj = self.invoice;
    [super viewDidLoad];
    
    if (self.mode == kViewMode) {
        self.modeChanged = NO;
    } else {
        self.crudActions = nil;
        
        if (self.mode == kCreateMode) {
            self.title = @"New Invoice";
        }
    }
    
    self.pdfReady = NO;
    
    self.totalAmount = [NSDecimalNumber zero];
    
//    if (!self.lineItems) {
//        self.lineItems = [NSArray array];
//    }
    
    self.invoice.editDelegate = self;
    self.shaddowInvoice.editDelegate = self;
    
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
        
    self.attachmentScrollView = [[UIScrollView alloc] initWithFrame:INV_ATTACHMENT_RECT]; // CGRectMake(IMG_PADDING, IMG_PADDING, CELL_WIDTH, IMG_HEIGHT)];
    self.attachmentScrollView.pagingEnabled = YES;
    self.attachmentScrollView.scrollEnabled = YES;
    self.attachmentScrollView.clipsToBounds = YES;
    self.attachmentScrollView.bounces = NO;
    self.attachmentScrollView.showsHorizontalScrollIndicator = NO;
    self.attachmentScrollView.showsVerticalScrollIndicator = NO;
    self.attachmentScrollView.delegate = self;
    
    self.attachmentPageControl = [[UIPageControl alloc] initWithFrame:INV_ATTACHMENT_PV_RECT];
    self.attachmentPageControl.currentPage = 0;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activityIndicator.hidesWhenStopped = YES;
    
    // retrieve PDF in view mode
    if (self.mode == kViewMode) {
        self.invoicePDFData = [NSMutableData data];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@?%@=%@&%@=%@", DOMAIN_URL, INV_2_PDF_API, Id, self.invoice.objectId, PRESENT_TYPE, PDF_TYPE]];
        NSURLRequest *req = [NSURLRequest  requestWithURL:url
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                          timeoutInterval:API_TIMEOUT];
        
        NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:req delegate:self];
        if (!theConnection) {
            NSLog(@"Failed to establish URL connection to retrieve PDF");
        }
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
    } else if ([segue.identifier isEqualToString:INV_PREVIEW_ATTACHMENT_SEGUE]) {
        NSInteger idx = ((UIImageView *)sender).tag;
        if (self.mode != kCreateMode && self.mode != kAttachMode) {
            idx--;
        }
        NSString *photoName = [self.photoNames objectAtIndex:idx];
        NSData *photoData = [self.shaddowInvoice.attachments objectForKey:photoName];
        [segue.destinationViewController setPhotoName:photoName];
        [segue.destinationViewController setPhotoData:photoData];
    } else if ([segue.identifier isEqualToString:INV_VIEW_PDF_SEGUE]) {
        [segue.destinationViewController setInvoice:sender];
    } else if ([segue.identifier isEqualToString:INV_VIEW_CUSTOMER_DETAILS_SEGUE]) {
        [segue.destinationViewController setCustomer:sender];
        [segue.destinationViewController setMode:kViewMode];
    } else if ([segue.identifier isEqualToString:INV_MODIFY_ITEM_DETAILS_SEGUE]) {
        int index = [sender intValue];
        Item *item = [self.shaddowInvoice.lineItems objectAtIndex:index];
        [segue.destinationViewController setItem:item];
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
        return [self.shaddowInvoice.lineItems count];
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    UITableViewCell *cell;
    
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
            cell.textLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:INV_LABEL_FONT_SIZE];
            cell.detailTextLabel.font = [UIFont fontWithName:APP_FONT size:INV_LABEL_FONT_SIZE];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            switch (indexPath.row) {
                case kInvoiceCustomer:                    
                    if (self.mode == kViewMode) {
                        if (self.shaddowInvoice.customerId != nil) {
                            cell.detailTextLabel.text = [Customer objectForKey:self.shaddowInvoice.customerId].name;
                        } else {
                            cell.detailTextLabel.text = nil;
                        }                        
                    } else {
                        if (self.shaddowInvoice.customerId != nil) {
                            cell.detailTextLabel.text = [Customer objectForKey:self.shaddowInvoice.customerId].name;
                        } else {
                            cell.detailTextLabel.text = @"Select one";
                        }
                    }
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                case kInvoiceNumber:
                {
                    if (self.mode == kViewMode) {
                        if (self.shaddowInvoice.invoiceNumber != nil) {
                            cell.detailTextLabel.text = self.shaddowInvoice.invoiceNumber;
                        } else {
                            cell.detailTextLabel.text = nil;
                        }                        
                    } else {
                        if (self.shaddowInvoice.invoiceNumber != nil) {
                            self.invoiceNumTextField.text = self.shaddowInvoice.invoiceNumber;
                        }
                        self.invoiceNumTextField.backgroundColor = cell.backgroundColor;
                        
                        [cell addSubview:self.invoiceNumTextField];                        
                    }
                }
                    break;
                case kInvoiceDate:
                {
                    if (self.mode == kViewMode) {
                        if (self.shaddowInvoice.invoiceDate != nil) {
                            cell.detailTextLabel.text = [Util formatDate:self.shaddowInvoice.invoiceDate format:nil];
                        } else {
                            cell.detailTextLabel.text = nil;
                        }
                    } else {
                        if (self.shaddowInvoice.invoiceDate != nil) {
                            self.invoiceDatePicker.date = self.shaddowInvoice.invoiceDate;
                            self.invoiceDateTextField.text = [Util formatDate:self.shaddowInvoice.invoiceDate format:nil];
                        } else {
                            self.invoiceDatePicker.date = [NSDate date];
                            self.invoiceDateTextField.text = [Util formatDate:[NSDate date] format:nil];
                            self.shaddowInvoice.invoiceDate = [NSDate date];
                        }
                        self.invoiceDateTextField.backgroundColor = cell.backgroundColor;
                        
                        [cell addSubview:self.invoiceDateTextField];                        
                    }
                }
                    break;
                case kInvoiceDueDate:
                {
                    if (self.mode == kViewMode) {
                        if (self.shaddowInvoice.dueDate != nil) {
                            cell.detailTextLabel.text = [Util formatDate:self.shaddowInvoice.dueDate format:nil];
                        } else {
                            cell.detailTextLabel.text = nil;
                        }                        
                    } else {
                        if (self.shaddowInvoice.dueDate != nil) {
                            self.dueDatePicker.date = self.shaddowInvoice.dueDate;
                            self.invoiceDueDateTextField.text = [Util formatDate:self.shaddowInvoice.dueDate format:nil];
                        } else {
                            self.dueDatePicker.date = [NSDate date];
                            self.invoiceDueDateTextField.text = [Util formatDate:[NSDate date] format:nil];
                            self.shaddowInvoice.dueDate = [NSDate date];
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
            if (self.modeChanged) {
                if (self.mode == kViewMode) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:INV_ITEM_CELL_ID];
                } else {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:INV_ITEM_CELL_ID];
                    cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:INV_ITEM_CELL_ID];
                if (!cell) {
                    if (self.mode == kViewMode) {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:INV_ITEM_CELL_ID];
                    } else {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:INV_ITEM_CELL_ID];
                        cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    }
                }
            }
            
//            NSString *itemId = [self.lineItems objectAtIndex:indexPath.row];
//            Item *item = [self.shaddowInvoice.lineItems objectForKey:itemId];
            Item *item = [self.shaddowInvoice.lineItems objectAtIndex:indexPath.row];

//            item.objectId = itemId;
            item.name = [Item objectForKey:item.objectId].name;
            
//            NSInteger qty;
//            Item *item = [Item objectForKey:itemId];
//            id quantity = [self.shaddowInvoice.lineItems objectForKey:itemId];
//            if (quantity == nil) {
//                qty = 1;
//            } else {
//                qty = [quantity integerValue];
//            }

            NSDecimalNumber *amount = [item.price decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithDecimal:[[NSNumber numberWithInt:item.qty] decimalValue]]];
            cell.textLabel.text = item.name;
            cell.textLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:INV_LABEL_FONT_SIZE];            
            cell.detailTextLabel.font = [UIFont fontWithName:APP_FONT size:INV_LABEL_FONT_SIZE];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = [[Util formatCurrency:amount] stringByAppendingFormat:@"  (%d pcs)", item.qty];
            } else {
                UITextField *itemAmountTextField = [[UITextField alloc] initWithFrame:INV_ITEM_AMOUNT_RECT];
                itemAmountTextField.text = [Util formatCurrency:amount];
                itemAmountTextField.font = [UIFont fontWithName:APP_FONT size:INV_LABEL_FONT_SIZE];
                itemAmountTextField.textColor = [UIColor blackColor];
                itemAmountTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
                itemAmountTextField.backgroundColor = cell.backgroundColor;
                itemAmountTextField.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support
                itemAmountTextField.autocapitalizationType = UITextAutocapitalizationTypeNone; // no auto capitalization support
                itemAmountTextField.textAlignment = UITextAlignmentRight;
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
//                itemQtytField.textAlignment = UITextAlignmentRight;
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
        case kInvoiceAttachment:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:INV_ATTACH_CELL_ID];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:INV_ATTACH_CELL_ID];
            }

            // clean up first
            for (UIView *subview in [self.attachmentScrollView subviews]) {
                if ([subview isKindOfClass:[UIImageView class]]) {
                    [subview removeFromSuperview];
                }
            }
            
            if (self.mode != kCreateMode && self.mode != kAttachMode) {
                [self addPDFAttachment];
            }
            
            for (NSString * photoName in self.photoNames) {
                NSData *photoData = [self.shaddowInvoice.attachments objectForKey:photoName];
                [self addNewAttachment:photoData];
            }
            
            [self layoutScrollImages:NO];
            
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

//private
- (void)layoutScrollImages:(BOOL)needChangePage {
    UIImageView *view = nil;
    NSArray *subviews = [self.attachmentScrollView subviews];
    
    // reposition all image subviews in a horizontal serial fashion
    CGFloat curXLoc = 0;
    NSInteger tag = 0;
    for (view in subviews) {
        if ([view isKindOfClass:[UIImageView class]]) {
            CGRect frame = view.frame;
            frame.origin = CGPointMake(curXLoc, 0);
            view.frame = frame;
            view.tag = tag;
            tag++;
            curXLoc += IMG_WIDTH;
        }
    }
    
//    int numPages = ceil((float)[self.photoNames count] / INV_NUM_ATTACHMENT_PER_PAGE);
    int numPages = ceil((float)tag / INV_NUM_ATTACHMENT_PER_PAGE);

    self.attachmentPageControl.numberOfPages = numPages;
    
    if (needChangePage || self.attachmentPageControl.currentPage == numPages-1) {
        int spaces = numPages * INV_NUM_ATTACHMENT_PER_PAGE;
        [self.attachmentScrollView setContentSize:CGSizeMake(spaces * IMG_WIDTH, [self.attachmentScrollView bounds].size.height)];
        self.attachmentPageControl.currentPage = numPages - 1;

        CGPoint offset = CGPointMake(self.attachmentPageControl.currentPage * INV_NUM_ATTACHMENT_PER_PAGE * IMG_WIDTH, 0);
        [self.attachmentScrollView setContentOffset:offset animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kInvoiceInfo) {
        return CELL_HEIGHT;
    } else if (indexPath.section == kInvoiceLineItems) {
        return CELL_HEIGHT;
    } else {
        return IMG_HEIGHT + IMG_PADDING + INV_ATTACHMENT_PV_HEIGHT;
    }
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
    } else if (section == kInvoiceLineItems) { // && [self.shaddowInvoice.lineItems count] > 0) {
        return 35;
    } else {
        return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == kInvoiceInfo) {
        return nil;
    } else if (section == kInvoiceLineItems) {
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
        
        if (self.mode != kViewMode) {
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
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 100, 20)];
        label.text = @"Attachment";
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
            [cameraButton addTarget:self action:@selector(addMorePhoto) forControlEvents:UIControlEventTouchUpInside];
            
            //        UIImage *btnImage = [UIImage imageNamed:@"camera_icon.jpg"];
            //        UIButton *cameraButton = [[UIButton alloc] initWithFrame:CGRectMake(265, -10, 40, 40)];
            //        [cameraButton setImage:btnImage forState:UIControlStateNormal];
            //        cameraButton.backgroundColor = [UIColor clearColor];
            //        [cameraButton addTarget:self action:@selector(addMoreItems) forControlEvents:UIControlEventTouchUpInside];
            
            [headerView addSubview:cameraButton];
        }
        
        return headerView;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == kInvoiceLineItems) { // && [self.shaddowInvoice.lineItems count] > 0) {
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 360, 30)];
        footerView.backgroundColor = [UIColor clearColor];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 3, 100, 20)];
        label.text = @"Balance Due";
        label.font = [UIFont fontWithName:APP_BOLD_FONT size:14];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = APP_LABEL_BLUE_COLOR;
        
        [footerView addSubview:label];
        
        UILabel *amount = [[UILabel alloc] initWithFrame:CGRectMake(CELL_WIDTH - 100, 3, 100, 20)];
        amount.text = [Util formatCurrency:self.totalAmount];
        amount.textAlignment = UITextAlignmentRight;
        amount.font = [UIFont fontWithName:APP_FONT size:15];
        amount.backgroundColor = [UIColor clearColor];
        
        self.shaddowInvoice.amount = self.totalAmount;
        self.shaddowInvoice.amountDue = self.totalAmount;
        
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
            [self.shaddowInvoice.lineItems removeObjectAtIndex:indexPath.row];
//            NSString *itemId = [self.lineItems objectAtIndex:indexPath.row];
//            [self.shaddowInvoice.lineItems removeObjectForKey:itemId];
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
                [self performSegueWithIdentifier:INV_MODIFY_ITEM_DETAILS_SEGUE sender:[NSNumber numberWithInt:indexPath.row]];
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
                        Customer *customer = [Customer objectForKey: self.shaddowInvoice.customerId];
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
        self.shaddowInvoice.invoiceNumber = [Util trim:textField.text];
    } else {
        // unused now
        int qty = textField.text.intValue;
        NSNumber *quantity = [NSNumber numberWithInt:qty];
        Item *item = [self.shaddowInvoice.lineItems objectAtIndex: textField.tag - [InvoiceInfo count] * TAG_BASE];
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
}

#pragma mark - Date Picker target action

- (void)selectInvoiceDateFromPicker:(UIDatePicker *)sender {
    self.invoiceDateTextField.text = [Util formatDate:sender.date format:nil];
    self.shaddowInvoice.invoiceDate = sender.date;
}

- (void)selectDueDateFromPicker:(UIDatePicker *)sender {
    self.invoiceDueDateTextField.text = [Util formatDate:sender.date format:nil];
    self.shaddowInvoice.dueDate = sender.date;
}

#pragma mark - Scroll View delegate

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    // Update the page when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.attachmentScrollView.frame.size.width;
    
    int page = floor((self.attachmentScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.attachmentPageControl.currentPage = page;
}

#pragma mark - Alert delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case DELETE_INV_ALERT_TAG:
            if (buttonIndex == 1) {
                [self.invoice remove];
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
                    NSString *photoName = [self.photoNames objectAtIndex:idx];
                    [self.photoNames removeObjectAtIndex:idx];
                    [self.shaddowInvoice.attachments removeObjectForKey:photoName];
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

#pragma mark - Action sheet delegate

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    for (UIView* view in [actionSheet subviews]) {
        if ([view respondsToSelector:@selector(title)]) {
            NSString* title = [view performSelector:@selector(title)];
            if ([title isEqualToString:[INVOICE_ACTIONS objectAtIndex:kEmailInvoice]] && [view respondsToSelector:@selector(setEnabled:)]) {
                if (self.pdfReady) {
                    [view performSelector:@selector(setEnabled:) withObject:[NSNumber numberWithBool:YES]];
                } else {
                    [view performSelector:@selector(setEnabled:) withObject:NO];
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

#pragma mark - NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.invoicePDFData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.invoicePDFData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.pdfReady = YES;
    
    self.crudActions = [@[ACTION_EMAIL] arrayByAddingObjectsFromArray:self.crudActions];
    
    NSLog(@"Succeeded! Received %d bytes of data for PDF",[self.invoicePDFData length]);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.pdfReady = NO;
    
    NSLog(@"Connection failed! Error - %@ %@",
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
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - model delegate

- (void)doneSaveObject {
//    [Invoice retrieveList];

    if (self.photoNames != nil && [self.photoNames count] > 0) {
        for (NSString *photoName in self.photoNames) {
            if ([self.invoice.attachments objectForKey:photoName] == nil) {
                NSData *photoData = [self.shaddowInvoice.attachments objectForKey:photoName];
                
                [Uploader uploadFile:photoName data:photoData objectId:self.shaddowInvoice.objectId handler:^(NSURLResponse * response, NSData * data, NSError * err) {
                    NSInteger status;
                    [APIHandler getResponse:response data:data error:&err status:&status];
                    
                    if(status == RESPONSE_SUCCESS) {
                        [UIHelper showInfo:[NSString stringWithFormat:@"Attachment %@ saved", photoName] withStatus:kSuccess];
                    } else {
                        [UIHelper showInfo:[NSString stringWithFormat:@"Failed to save %@", photoName] withStatus:kFailure];
                    }
                }];
            }
        }
    }
    
    [Invoice clone:self.shaddowInvoice to:self.invoice];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.mode = kViewMode;
        self.title = self.shaddowInvoice.name;
    });

//    self.navigationItem.rightBarButtonItem.customView = nil;
}

- (void)didCreateInvoice:(NSString *)newInvoiceId {
    self.invoice.objectId = newInvoiceId;
    self.shaddowInvoice.objectId = newInvoiceId;
    [self doneSaveObject];
}

//- (void)didUpdateInvoice {
//    [self doneSaveObject];
//}
//
//- (void)didDeleteInvoice {
//    __weak EditInvoiceViewController *weakSelf = self;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [weakSelf.navigationController popViewControllerAnimated:YES];
//    });
//}
//
//- (void)failedToSaveInvoice {
//    __weak EditInvoiceViewController *weakSelf = self;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [weakSelf.activityIndicator stopAnimating];
//        self.navigationItem.rightBarButtonItem.customView = nil;
//    });
//}

- (void)didSelectCustomer:(NSString *)customerId {
    self.shaddowInvoice.customerId = customerId;
    
    NSIndexPath *path = [NSIndexPath indexPathForRow:kInvoiceCustomer inSection:kInvoiceInfo];
    [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)didSelectItems:(NSArray *)items {
    for (Item *item in items) {
        [self.shaddowInvoice.lineItems addObject:item];
    }
    
    [self updateLineItems];
}

- (void)didScanPhoto:(NSData *)photoData name:(NSString *)photoName {
    [self addPhotoData:photoData name:photoName];
    [self addNewAttachment:photoData];
    [self layoutScrollImages:YES];
}

- (void)didUpdateCustomer {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath *path = [NSIndexPath indexPathForRow:kInvoiceCustomer inSection:kInvoiceInfo];
        [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:YES];
    });
}

//- (void)didUpdateItem {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self updateLineItems];
//        [self.shaddowInvoice update];
//    });
//}

- (void)didModifyItem:(Item *)item forIndex:(int)index {
    [Item clone:item to:[self.shaddowInvoice.lineItems objectAtIndex:index]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateLineItems];
    });
}

#pragma mark - Action Menu delegate

- (void)didSelectCrudAction:(NSString *)action {
    [super didSelectCrudAction:action];
    
    if ([action isEqualToString:ACTION_EMAIL]) {
        [self sendInvoiceEmail];
    }
}

@end
