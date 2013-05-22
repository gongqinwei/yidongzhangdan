//
//  EditBillViewController.m
//  BDC
//
//  Created by Qinwei Gong on 4/23/13.
//
//

#import "EditBillViewController.h"
#import "VendorsTableViewController.h"
#import "APLineItem.h"                              //temp
//#import "APLineItemsTableViewController.h"
#import "ScannerViewController.h"
#import "AttachmentPreviewViewController.h"
#import "EditVendorViewController.h"
//#import "EditAPLineItemViewController.h"
#import "Util.h"
#import "Constants.h"
#import "UIHelper.h"
#import "Vendor.h"
#import "BankAccount.h"
#import "Organization.h"
#import "Document.h"
#import "Uploader.h"
#import "APIHandler.h"

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

#define TAG_BASE                        100
#define CELL_WIDTH                      300
#define IMG_PADDING                     10
#define IMG_WIDTH                       CELL_WIDTH / 4
#define IMG_HEIGHT                      IMG_WIDTH - IMG_PADDING
#define BILL_INFO_CELL_ID               @"BillInfo"
#define BILL_ITEM_CELL_ID               @"BillLineItem"
#define BILL_ATTACH_CELL_ID             @"BillDocs"

#define BILL_SELECT_VENDOR_SEGUE        @"SelectVendorForBill"
#define BILL_SCAN_PHOTO_SEGUE           @"ScanMoreBillPhoto"
#define BILL_PREVIEW_ATTACHMENT_SEGUE   @"PreviewBillDoc"
#define BILL_VIEW_VENDOR_DETAILS_SEGUE  @"ViewVendorDetails"
#define BILL_PAY_BILL_SEGUE             @"PayBill"

#define BILL_LABEL_FONT_SIZE            13
#define BillInfo                 [NSArray arrayWithObjects:@"Vendor", @"Invoice #", @"Inv Date", @"Due Date", @"Approval Status", @"Payment Status", nil]
#define BILL_INFO_INPUT_RECT     CGRectMake(CELL_WIDTH - 190, 5, 190, CELL_HEIGHT - 10)
#define BILL_ITEM_ACCOUNT_RECT   CGRectMake(cell.viewForBaselineLayout.bounds.origin.x + 46, 6, 150, cell.viewForBaselineLayout.bounds.size.height - 10)
#define BILL_ITEM_AMOUNT_RECT    CGRectMake(cell.viewForBaselineLayout.bounds.size.width - 115, 6, 100, cell.viewForBaselineLayout.bounds.size.height - 10)
#define BILL_ATTACHMENT_RECT     CGRectMake(5, 0, CELL_WIDTH, IMG_HEIGHT)
#define BILL_ATTACHMENT_PV_HEIGHT       3
#define BILL_ATTACHMENT_PV_RECT  CGRectMake(0, IMG_HEIGHT + IMG_PADDING, CELL_WIDTH, BILL_ATTACHMENT_PV_HEIGHT)
#define BILL_NUM_ATTACHMENT_PER_PAGE    4

#define DELETE_BILL_ALERT_TAG           1
#define REMOVE_ATTACHMENT_ALERT_TAG     2

@interface EditBillViewController () <BillDelegate, VendorDelegate, VendorSelectDelegate, ScannerDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIScrollViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate>

@property (nonatomic, strong) Bill *shaddowBill;
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

@property (nonatomic, strong) NSMutableDictionary *attachmentDict;

@property (nonatomic, strong) UIScrollView *attachmentScrollView;
@property (nonatomic, strong) UIPageControl *attachmentPageControl;
@property (nonatomic, strong) UIImageView *currAttachment;

@property (nonatomic, strong) UIPickerView *accountPickerView;

@property (nonatomic, strong) MFMailComposeViewController *mailer;

@property (nonatomic, assign) BOOL modeChanged;

@property (nonatomic, strong) NSArray *chartOfAccounts;

@property (nonatomic, strong) UITextField *currentField;

@property (nonatomic, strong) QLPreviewController *previewController;

@end

@implementation EditBillViewController

@synthesize bill = _bill;
@synthesize shaddowBill;
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
@synthesize attachmentDict;
@synthesize attachmentScrollView;
@synthesize attachmentPageControl;
@synthesize currAttachment;
@synthesize accountPickerView;
@synthesize mailer;
@synthesize modeChanged;
@synthesize chartOfAccounts;
@synthesize currentField;
@synthesize previewController;


#pragma mark - public methods

- (void)setBill:(Bill *)bill {
    _bill = bill;
    
    self.shaddowBill = nil;
    self.shaddowBill = [[Bill alloc] init];
    [Bill clone:bill to:self.shaddowBill];
    
    self.attachmentDict = [NSMutableDictionary dictionaryWithDictionary:self.bill.attachmentDict];
}

- (void)addAttachmentData:(NSData *)attachmentData name:(NSString *)attachmentName {
    if (self.shaddowBill == nil) {
        self.shaddowBill = [[Bill alloc] init];
    }
    
    if (self.bill == nil) {
        self.bill = [[Bill alloc] init];
    }
    
    Document *doc = [[Document alloc] init];
    doc.name = attachmentName;
    doc.data = attachmentData;
    
    [self.shaddowBill.attachments addObject:doc];
}

- (void)setMode:(ViewMode)mode {
    super.mode = mode;
    self.modeChanged = YES;
    
    if (mode == kViewMode) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(toggleMenu:)];
        self.navigationItem.rightBarButtonItem.tag = 1;
        self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveBill:)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEdit:)];
    }
    
    self.totalAmount = [NSDecimalNumber zero];
    
    for (UIView *subview in [self.attachmentScrollView subviews]) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            [subview removeFromSuperview];
        }
    }
        
    [self.tableView reloadData];
}

#pragma mark - private methods

- (void)updateLineItems {
    self.totalAmount = [NSDecimalNumber zero];
    
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:kBillLineItems];
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)cancelEdit:(UIBarButtonItem *)sender {
    if (self.mode == kCreateMode || self.mode == kAttachMode) {
        [self navigateBack];
    } else {
        [self setBill:self.bill];        
        self.mode = kViewMode;
    }
}

- (void)setLineItems:(NSArray *)lineItems {    
    [self updateLineItems];
}

- (void)addMoreItems {
    [self.view findAndResignFirstResponder];
    
    APLineItem *newItem = [[APLineItem alloc] init];
    newItem.amount = [NSDecimalNumber zero];
    [self.shaddowBill.lineItems addObject: newItem];
    self.totalAmount = [NSDecimalNumber zero];
    
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:kBillLineItems];
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)addMoreAttachment {
    [self.view findAndResignFirstResponder];
    [self performSegueWithIdentifier:BILL_SCAN_PHOTO_SEGUE sender:self];
}

- (void)selectAttachment:(UIImageView *)imageView {
    self.currAttachment.layer.borderColor = [[UIColor clearColor]CGColor];
    self.currAttachment.layer.borderWidth = 0.0f;
    
    imageView.layer.borderColor = [[UIColor whiteColor]CGColor];
    imageView.layer.borderWidth = 2.0f;
    self.currAttachment = imageView;
}

- (void)imageTapped:(UITapGestureRecognizer *)gestureRecognizer {
    if ([self tryTap]) {
        UIImageView *imageView = (UIImageView *)gestureRecognizer.view;
        
        self.previewController.currentPreviewItemIndex = imageView.tag;
        [self presentModalViewController:self.previewController animated:YES];
        
        [self selectAttachment:imageView];
//        [self performSegueWithIdentifier:BILL_PREVIEW_ATTACHMENT_SEGUE sender:imageView];
    }
}

- (void)imagePressed:(UILongPressGestureRecognizer *)gestureRecognizer {
    if ([self tryTap]) {
        [self selectAttachment:(UIImageView *)gestureRecognizer.view];
        
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            int idx = self.currAttachment.tag;
            Document *doc = [self.shaddowBill.attachments objectAtIndex:idx];
            
            [UIView animateWithDuration:1.0
                             animations:^{
                                 self.currAttachment.alpha = 0.0;
                             }
                             completion:^ (BOOL finished) {
                                 if (finished) {
                                     [self.shaddowBill.attachments removeObjectAtIndex:idx];
                                     
                                     if (doc.objectId) {
                                         [self.attachmentDict removeObjectForKey:doc.objectId];
                                     }
                                     [self.currAttachment removeFromSuperview];
                                     [self layoutScrollImages:NO];
                                     self.currAttachment = nil;
                                 }
                             }];
        }
    }
}

- (void)addAttachment:(NSString *)ext data:(NSData *)attachmentData {
    UIImage *image;
    
    if (attachmentData && [IMAGE_TYPE_SET containsObject:ext]) {
        image = [UIImage imageWithData:attachmentData];
    } else {
        NSString *iconFileName = [NSString stringWithFormat:@"%@_icon.png", ext];
        image = [UIImage imageNamed:iconFileName];
        
        if (!image) {
            image = [UIImage imageNamed:@"unknown_file_icon.png"];
        }
    }
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    
    CGRect rect = imageView.frame;
    rect.size.height = IMG_HEIGHT;
    rect.size.width = IMG_WIDTH - IMG_PADDING;
    imageView.frame = rect;
    imageView.tag = [self.shaddowBill.attachments count];
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

//- (void)retrieveDocAttachments {
//    NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\"}", ID, self.bill.objectId];
//    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA, objStr, nil];
//        
//    [APIHandler asyncCallWithAction:RETRIEVE_DOCS_API Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
//        NSInteger response_status;
//        NSArray *jsonBills = [APIHandler getResponse:response data:data error:&err status:&response_status];
//                
//        if(response_status == RESPONSE_SUCCESS) {
//            NSLog(@"%@", jsonBills);
//        } else {
//            NSLog(@"Failed to retrieve documents/attachments for bill %@: %@", self.bill.name, [err localizedDescription]);
//        }
//    }];
//}


#pragma mark - Target Action

- (IBAction)saveBill:(UIBarButtonItem *)sender {
    self.navigationItem.rightBarButtonItem.customView = self.activityIndicator;
    [self.activityIndicator startAnimating];
    [self.view findAndResignFirstResponder];
        
    if (self.shaddowBill.vendorId == nil) {
        [UIHelper showInfo:@"No vendor chosen" withStatus:kError];
        return;
    }
    
    if (self.shaddowBill.invoiceNumber == nil) {
        [UIHelper showInfo:@"No invoice number" withStatus:kError];
        return;
    }
    
    if ([self.shaddowBill.lineItems count] == 0) {
        [UIHelper showInfo:@"No amount" withStatus:kError];
        return;
    }
    
    if (self.mode == kCreateMode || self.mode == kAttachMode) {
        [self.shaddowBill create];
    } else if (self.mode == kUpdateMode){
        [self.shaddowBill update];
    }
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
    if (!self.bill) {
        self.bill = [[Bill alloc] init];
        self.shaddowBill = [[Bill alloc] init];
    }
    
    self.busObj = self.bill;
    [super viewDidLoad];
    
    if (self.mode == kViewMode) {
        self.modeChanged = NO;
        if (![self.shaddowBill.paymentStatus isEqualToString:PAYMENT_UNPAID]) {
            self.crudActions = [NSArray arrayWithObjects:ACTION_UPDATE, nil];
        }
        
        //TODO: also allow pay if no need for approval
        if (([self.shaddowBill.approvalStatus isEqualToString:APPROVAL_UNASSIGNED] || [self.shaddowBill.approvalStatus isEqualToString:APPROVAL_APPROVED])
            && ([self.shaddowBill.paymentStatus isEqualToString:PAYMENT_UNPAID] || [self.shaddowBill.paymentStatus isEqualToString:PAYMENT_PARTIAL])) {
            self.crudActions = [@[ACTION_PAY] arrayByAddingObjectsFromArray:self.crudActions];
        }
    } else {
        self.crudActions = nil;
        
        if (self.mode == kCreateMode) {
            self.title = @"New Bill";
        }
    }
        
    self.totalAmount = [NSDecimalNumber zero];
    
    self.bill.editDelegate = self;
    self.shaddowBill.editDelegate = self;
    
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
//    self.billApprovalStatusLabel.textAlignment = UITextAlignmentRight;
//    
//    self.billPaymentStatusLabel = [[UILabel alloc] initWithFrame:BILL_INFO_INPUT_RECT];
//    self.billPaymentStatusLabel.font = [UIFont fontWithName:APP_FONT size:BILL_LABEL_FONT_SIZE];
//    self.billPaymentStatusLabel.textColor = APP_LABEL_BLUE_COLOR;
//    self.billPaymentStatusLabel.textAlignment = UITextAlignmentRight;

    self.billPaidAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(CELL_WIDTH - 100, 24, 100, 20)];
    self.billPaidAmountLabel.font = [UIFont fontWithName:APP_FONT size:14];
    self.billPaidAmountLabel.textColor = APP_LABEL_BLUE_COLOR;
    self.billPaidAmountLabel.textAlignment = UITextAlignmentRight;
    self.billPaidAmountLabel.backgroundColor = [UIColor clearColor];

    self.billAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(CELL_WIDTH - 100, 3, 100, 20)];
    self.billAmountLabel.textAlignment = UITextAlignmentRight;
    self.billAmountLabel.font = [UIFont fontWithName:APP_FONT size:15];
    self.billAmountLabel.backgroundColor = [UIColor clearColor];
    
    self.attachmentScrollView = [[UIScrollView alloc] initWithFrame:BILL_ATTACHMENT_RECT]; // CGRectMake(IMG_PADDING, IMG_PADDING, CELL_WIDTH, IMG_HEIGHT)];
    self.attachmentScrollView.pagingEnabled = YES;
    self.attachmentScrollView.scrollEnabled = YES;
    self.attachmentScrollView.clipsToBounds = YES;
    self.attachmentScrollView.bounces = NO;
    self.attachmentScrollView.showsHorizontalScrollIndicator = NO;
    self.attachmentScrollView.showsVerticalScrollIndicator = NO;
    self.attachmentScrollView.delegate = self;
    
    self.attachmentPageControl = [[UIPageControl alloc] initWithFrame:BILL_ATTACHMENT_PV_RECT];
    self.attachmentPageControl.currentPage = 0;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activityIndicator.hidesWhenStopped = YES;
    
    self.accountPickerView = [[UIPickerView alloc] initWithFrame:PICKER_RECT];
    self.accountPickerView.delegate = self;
    self.accountPickerView.dataSource = self;
    self.accountPickerView.showsSelectionIndicator = YES;
        
    self.chartOfAccounts = [ChartOfAccount listOrderBy:ACCOUNT_NAME ascending:YES active:YES];
    
    if (self.mode == kViewMode) {
        // retrieve attachments
        [self retrieveDocAttachments];
        
        self.previewController = [[QLPreviewController alloc] init];
        self.previewController.delegate = self;
        self.previewController.dataSource = self;
    }
}

- (void)retrieveDocAttachments {
    NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\"}", ID, self.bill.objectId];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA, objStr, nil];
    
    [APIHandler asyncCallWithAction:RETRIEVE_DOCS_API Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSArray *jsonDocs = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            if (!self.bill.attachmentDict) {
                self.bill.attachmentDict = [NSMutableDictionary dictionary];
            }
            
            self.attachmentDict = [NSMutableDictionary dictionaryWithDictionary:self.bill.attachmentDict];
            
            int i = 0;
            for (NSDictionary *dict in jsonDocs) {
                NSString *docId = [dict objectForKey:ID];
                
                if (![self.attachmentDict objectForKey:docId]) {
                    NSString *docName = [dict objectForKey:@"fileName"];
                    
                    Document *doc = [[Document alloc] init];
                    doc.objectId = docId;
                    doc.name = docName;
                    doc.fileUrl = [dict objectForKey:@"fileUrl"];
                    doc.isPublic = [[dict objectForKey:@"isPublic"] intValue];
                    doc.page = [[dict objectForKey:@"page"] intValue];
                    NSLog(@"name: %@", docName);
                    NSLog(@"page: %d", doc.page);
                    
                    [self.bill.attachmentDict setObject:doc forKey:docId];
                    [self.attachmentDict setObject:doc forKey:docId];
                    [self.bill.attachments insertObject:doc atIndex:i];
                    
                    [self.shaddowBill.attachments insertObject:doc atIndex:i];
                    
                    [self downloadDocument:doc forAttachmentAtIndex:i];
                }
                i++;
            }
            
            NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:kBillDocs];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
            });
        } else {
            NSLog(@"Failed to retrieve attachments for %@: %@", self.bill.name, [err localizedDescription]);
        }
    }];
}

- (void)downloadDocument:(Document *)doc forAttachmentAtIndex:(int)idx {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", DOMAIN_URL, doc.fileUrl]];
    NSURLRequest *req = [NSURLRequest  requestWithURL:url
                                          cachePolicy:NSURLRequestUseProtocolCachePolicy
                                      timeoutInterval:API_TIMEOUT];
    
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               doc.data = data;
                               
                               UIImageView *img = [self.attachmentScrollView.subviews objectAtIndex: idx];
                               NSString *ext = [[doc.name pathExtension] lowercaseString];
                               
                               if ([IMAGE_TYPE_SET containsObject:ext]) {
                                   UIImage *image = [UIImage imageWithData:data];
                                   
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       img.alpha = 0.0;
                                       img.image = image;
                                       [img setNeedsDisplay];
                                       
                                       [UIView animateWithDuration:2.0
                                                        animations:^{
                                                            img.alpha = 1.0;
                                                        }
                                                        completion:^ (BOOL finished) {
                                                        }];
                                   });
                               }
                           }];
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
    } else if ([segue.identifier isEqualToString:BILL_PREVIEW_ATTACHMENT_SEGUE]) {
        NSInteger idx = ((UIImageView *)sender).tag;
        if (self.mode != kCreateMode && self.mode != kAttachMode) {
            idx--;
        }
        NSString *attachmentName = ((Document *)[self.shaddowBill.attachments objectAtIndex:idx]).name;
        NSData *attachmentData = ((Document *)[self.shaddowBill.attachments objectAtIndex:idx]).data;
        [segue.destinationViewController setPhotoName:attachmentName];
        [segue.destinationViewController setPhotoData:attachmentData];
    } else if ([segue.identifier isEqualToString:BILL_VIEW_VENDOR_DETAILS_SEGUE]) {
        [segue.destinationViewController setVendor:sender];
        [segue.destinationViewController setMode:kViewMode];
    } else if ([segue.identifier isEqualToString:BILL_PAY_BILL_SEGUE]) {
        [segue.destinationViewController setBill:self.shaddowBill];
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
        return [BillInfo count];
    } else if (section == kBillLineItems) {
        return [self.shaddowBill.lineItems count];
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
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
                        if (self.shaddowBill.vendorId != nil) {
                            cell.detailTextLabel.text = [Vendor objectForKey:self.shaddowBill.vendorId].name;
                        } else {
                            cell.detailTextLabel.text = nil;
                        }
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    } else {
                        if (self.shaddowBill.vendorId != nil) {
                            cell.detailTextLabel.text = [Vendor objectForKey:self.shaddowBill.vendorId].name;
                        } else {
                            cell.detailTextLabel.text = @"Select one";
                        }
                        
                        if ([self.shaddowBill.paymentStatus isEqualToString:PAYMENT_UNPAID]) {
                            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        }
                    }
                    
                    break;
                case kBillNumber:
                    if (self.mode == kViewMode) {
                        if (self.shaddowBill.invoiceNumber != nil) {
                            cell.detailTextLabel.text = self.shaddowBill.invoiceNumber;
                        } else {
                            cell.detailTextLabel.text = nil;
                        }
                    } else {
                        if (self.shaddowBill.invoiceNumber != nil) {
                            self.billNumTextField.text = self.shaddowBill.invoiceNumber;
                        }
                        self.billNumTextField.backgroundColor = cell.backgroundColor;
                        
                        [cell addSubview:self.billNumTextField];
                    }
                    break;
                case kBillDate:
                    if (self.mode == kViewMode) {
                        if (self.shaddowBill.invoiceDate != nil) {
                            cell.detailTextLabel.text = [Util formatDate:self.shaddowBill.invoiceDate format:nil];
                        } else {
                            cell.detailTextLabel.text = nil;
                        }
                    } else {
                        if (self.shaddowBill.invoiceDate != nil) {
                            self.billDatePicker.date = self.shaddowBill.invoiceDate;
                            self.billDateTextField.text = [Util formatDate:self.shaddowBill.invoiceDate format:nil];
                        } else {
                            self.billDatePicker.date = [NSDate date];
                            self.billDateTextField.text = [Util formatDate:[NSDate date] format:nil];
                            self.shaddowBill.invoiceDate = [NSDate date];
                        }
                        self.billDateTextField.backgroundColor = cell.backgroundColor;
                        
                        [cell addSubview:self.billDateTextField];
                    }
                    break;
                case kBillDueDate:
                    if (self.mode == kViewMode) {
                        if (self.shaddowBill.dueDate != nil) {
                            cell.detailTextLabel.text = [Util formatDate:self.shaddowBill.dueDate format:nil];
                        } else {
                            cell.detailTextLabel.text = nil;
                        }
                    } else {
                        if (self.shaddowBill.dueDate != nil) {
                            self.dueDatePicker.date = self.shaddowBill.dueDate;
                            self.billDueDateTextField.text = [Util formatDate:self.shaddowBill.dueDate format:nil];
                        } else {
                            self.dueDatePicker.date = [NSDate date];
                            self.billDueDateTextField.text = [Util formatDate:[NSDate date] format:nil];
                            self.shaddowBill.dueDate = [NSDate date];
                        }
                        self.billDueDateTextField.backgroundColor = cell.backgroundColor;
                        
                        [cell addSubview:self.billDueDateTextField];
                    }
                    break;
                case kBillApprovalStatus:
                    cell.textLabel.numberOfLines = 2;
                    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
                    
                    if (self.shaddowBill.approvalStatus != nil) {
                        cell.detailTextLabel.text = [APPROVAL_STATUSES objectForKey:self.shaddowBill.approvalStatus];
                    } else {
                        cell.detailTextLabel.text = @"Unassigned";
                    }
                    break;
                case kBillPaymentStatus:
                    cell.textLabel.numberOfLines = 2;
                    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
                    
                    if (self.shaddowBill.paymentStatus != nil) {
                        cell.detailTextLabel.text = [PAYMENT_STATUSES objectForKey:self.shaddowBill.paymentStatus];
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
            if (self.modeChanged) {
                if (self.mode == kViewMode) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:BILL_ITEM_CELL_ID];
                } else {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:BILL_ITEM_CELL_ID];
//                    cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:BILL_ITEM_CELL_ID];
                if (!cell) {
                    if (self.mode == kViewMode) {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:BILL_ITEM_CELL_ID];
                    } else {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:BILL_ITEM_CELL_ID];
//                        cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    }
                }
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.numberOfLines = 2;
            cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
            
            APLineItem *item = [self.shaddowBill.lineItems objectAtIndex:indexPath.row];
            
            if (self.mode == kViewMode) {
                cell.textLabel.text = item.account.name ? item.account.name : @" ";
//                cell.textLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:BILL_LABEL_FONT_SIZE];
                [cell.textLabel sizeToFit];
                
                cell.detailTextLabel.text = [Util formatCurrency:item.amount];
                cell.detailTextLabel.font = [UIFont fontWithName:APP_FONT size:BILL_LABEL_FONT_SIZE];
            } else {
                UITextField *itemAccountField = [[UITextField alloc] initWithFrame:BILL_ITEM_ACCOUNT_RECT];
                itemAccountField.text = item.account.name ? item.account.name : @"Select One";
                [self initializeTextField:itemAccountField];
                itemAccountField.textAlignment = UITextAlignmentCenter;
                itemAccountField.inputView = self.accountPickerView;
                itemAccountField.rightViewMode = UITextFieldViewModeAlways;
                itemAccountField.delegate = self;
                itemAccountField.tag = [BillInfo count] * TAG_BASE + indexPath.row * 2;
                itemAccountField.objectTag = item;
                
                [cell addSubview:itemAccountField];
                
                UITextField *itemAmountTextField = [[UITextField alloc] initWithFrame:BILL_ITEM_AMOUNT_RECT];
                itemAmountTextField.text = [Util formatCurrency:item.amount];
                [self initializeTextField:itemAmountTextField];
                itemAmountTextField.keyboardType = UIKeyboardTypeDecimalPad;
                itemAmountTextField.objectTag = item;
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
            
            // clean up first
            for (UIView *subview in [self.attachmentScrollView subviews]) {
                if ([subview isKindOfClass:[UIImageView class]]) {
                    [subview removeFromSuperview];
                }
            }
            
            for (Document * doc in self.shaddowBill.attachments) {
                NSString *ext = [[doc.name pathExtension] lowercaseString];
                [self addAttachment:ext data:doc.data];
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
        CGRect frame = view.frame;
        frame.origin = CGPointMake(curXLoc, 0);
        view.frame = frame;
        view.tag = tag;
        tag++;
        curXLoc += IMG_WIDTH;
    }
    
//    int numPages = ceil((float)[self.photoNames count] / BILL_NUM_ATTACHMENT_PER_PAGE);
    int numPages = ceil((float)tag / BILL_NUM_ATTACHMENT_PER_PAGE);
    
    self.attachmentPageControl.numberOfPages = numPages;
    
    int spaces = numPages * BILL_NUM_ATTACHMENT_PER_PAGE;
    [self.attachmentScrollView setContentSize:CGSizeMake(spaces * IMG_WIDTH, [self.attachmentScrollView bounds].size.height)];
    
    if (needChangePage || self.attachmentPageControl.currentPage == numPages - 1) {
        self.attachmentPageControl.currentPage = numPages - 1;
        
        CGPoint offset = CGPointMake(self.attachmentPageControl.currentPage * BILL_NUM_ATTACHMENT_PER_PAGE * IMG_WIDTH, 0);
        [self.attachmentScrollView setContentOffset:offset animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kBillInfo) {
        return CELL_HEIGHT;
    } else if (indexPath.section == kBillLineItems) {
        return CELL_HEIGHT;
    } else {
        return IMG_HEIGHT + IMG_PADDING + BILL_ATTACHMENT_PV_HEIGHT;
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
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 200, 20)];
        label.text = @"Document & Attachment";
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
        amoutLabel.textAlignment = UITextAlignmentRight;
        [footerView addSubview:amoutLabel];
        
        self.billAmountLabel.text = [Util formatCurrency:self.totalAmount];        
        self.shaddowBill.amount = self.totalAmount;
        [footerView addSubview:self.billAmountLabel];
        
        UILabel *paidAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 24, 85, 20)];
        paidAmountLabel.text = @"Paid:";
        paidAmountLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:13];
        paidAmountLabel.backgroundColor = [UIColor clearColor];
        paidAmountLabel.textColor = APP_LABEL_BLUE_COLOR;
        paidAmountLabel.textAlignment = UITextAlignmentRight;
        [footerView addSubview:paidAmountLabel];

        self.billPaidAmountLabel.text = [Util formatCurrency:self.shaddowBill.paidAmount];
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
            [self.shaddowBill.lineItems removeObjectAtIndex:indexPath.row];
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
                        if ([self.shaddowBill.paymentStatus isEqualToString:PAYMENT_UNPAID]) {
                            [self performSegueWithIdentifier:BILL_SELECT_VENDOR_SEGUE sender:self];
                        }
                        
                        break;
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
                        Vendor *vendor = [Vendor objectForKey: self.shaddowBill.vendorId];
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
        self.shaddowBill.invoiceNumber = [Util trim:textField.text];
    } else {
        int idx = (textField.tag - [BillInfo count] * TAG_BASE) / 2;
        APLineItem * item = [self.shaddowBill.lineItems objectAtIndex:idx];
        
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
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self textFieldDoneEditing:textField];
    self.currentField = nil;
}

#pragma mark - Date Picker target action

- (void)selectBillDateFromPicker:(UIDatePicker *)sender {
    self.billDateTextField.text = [Util formatDate:sender.date format:nil];
    self.shaddowBill.invoiceDate = sender.date;
}

- (void)selectDueDateFromPicker:(UIDatePicker *)sender {
    self.billDueDateTextField.text = [Util formatDate:sender.date format:nil];
    self.shaddowBill.dueDate = sender.date;
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
        case DELETE_BILL_ALERT_TAG:
            if (buttonIndex == 1) {
                [self.bill remove];
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
                    
                    [self.shaddowBill.attachments removeObjectAtIndex:idx];
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
    return [self.chartOfAccounts count];
}

- (NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return ((ChartOfAccount *)[self.chartOfAccounts objectAtIndex: row]).name;
}

#pragma mark - UIPickerView Delegate

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.currentField.text = ((ChartOfAccount *)[self.chartOfAccounts objectAtIndex:row]).name;
    
    int idx = (self.currentField.tag - [BillInfo count] * TAG_BASE) / 2;
    APLineItem * item = [self.shaddowBill.lineItems objectAtIndex:idx];    
    item.account = [self.chartOfAccounts objectAtIndex:row];
}

#pragma mark - QuickLook Preview Controller Data Source

- (NSInteger) numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    if (controller == self.previewController) {
        return [self.shaddowBill.attachments count];
    } else {
        return 1;
    }
}

- (id<QLPreviewItem>) previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    
    Document *doc = self.shaddowBill.attachments[index];
    
    NSString *filePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:doc.name]];
    [doc.data writeToFile:filePath atomically:YES];
    
    return [NSURL fileURLWithPath:filePath];
}

#pragma mark - model delegate

- (void)doneSaveObject {
    // 1. remove deleted attachments
    for (NSString *docId in [self.bill.attachmentDict allKeys]) {
        if (![self.attachmentDict objectForKey:docId]) {
            Document *doc = [self.bill.attachmentDict objectForKey:docId];
            NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\", \"objId\" : \"%@\", \"page\" : %d}", ID, docId, self.bill.objectId, doc.page];
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA, objStr, nil];
            
            [APIHandler asyncCallWithAction:REMOVE_DOCS_API Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
                NSInteger response_status;
                [APIHandler getResponse:response data:data error:&err status:&response_status];
                
                if(response_status == RESPONSE_SUCCESS) {
                    
                } else {
                    [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
                    NSLog(@"Failed to delete attachment %@: %@", docId, [err localizedDescription]);
                }
            }];
        }
    }
    
    // 2. add new attachments
    for (Document *doc in self.shaddowBill.attachments) {
        if (doc.objectId == nil) {
            [Uploader uploadFile:doc.name data:doc.data objectId:self.shaddowBill.objectId handler:^(NSURLResponse * response, NSData * data, NSError * err) {
                NSInteger response_status;
                NSString *info = [APIHandler getResponse:response data:data error:&err status:&response_status];
                
                if(response_status == RESPONSE_SUCCESS) {
                    doc.objectId = info;
                    [self.bill.attachmentDict setObject:doc forKey:doc.objectId];
                } else {
                    [UIHelper showInfo:[NSString stringWithFormat:@"Failed to save %@", doc.name] withStatus:kFailure];
                }
            }];
        }
    }
    
    [Bill clone:self.shaddowBill to:self.bill];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.mode = kViewMode;
        self.title = self.shaddowBill.name;
    });
    
    //    self.navigationItem.rightBarButtonItem.customView = nil;
}

- (void)didCreateBill:(NSString *)newBillId {
    self.bill.objectId = newBillId;
    self.shaddowBill.objectId = newBillId;
    [self doneSaveObject];
}

- (void)didSelectVendor:(NSString *)vendorId {
    self.shaddowBill.vendorId = vendorId;
    
    NSIndexPath *path = [NSIndexPath indexPathForRow:kBillVendor inSection:kBillInfo];
    [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)didSelectItems:(NSArray *)items {
    for (APLineItem *item in items) {
        [self.shaddowBill.lineItems addObject:item];
    }
    
    [self updateLineItems];
}

- (void)didScanPhoto:(NSData *)photoData name:(NSString *)photoName {
    [self addAttachmentData:photoData name:photoName];
    [self addAttachment:@"jpg" data:photoData];
    [self layoutScrollImages:YES];
}

- (void)didUpdateVendor {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath *path = [NSIndexPath indexPathForRow:kBillVendor inSection:kBillInfo];
        [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:YES];
    });
}

- (void)didModifyItem:(APLineItem *)item forIndex:(int)index {
    [APLineItem clone:item to:[self.shaddowBill.lineItems objectAtIndex:index]];
    
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
