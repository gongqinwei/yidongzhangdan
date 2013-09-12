//
//  Constants.h
//  BDC
//
//  Created by Qinwei Gong on 6/21/12.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#ifndef BDC_Constants_h
#define BDC_Constants_h

#import "Labels.h"

//#define LOCAL
//#define APPTEST
//#define APPSTAGE
#define PROD

#ifdef LOCAL
#define APP_KEY_VALUE       @"01ASGHUMYGIIBVXKYAU0"
#define ERR_DOMAIN          @"Local"
//#define DOMAIN_URL          @"http://10.1.9.101"
#define DOMAIN_URL          @"http://192.168.1.16"
#define APP_KEY             @"devKey"
#define DEBUG_MODE
#endif

#ifdef APPTEST
#define APP_KEY_VALUE       @"01AMCUQOJBJQDUXSFXB9"
#define ERR_DOMAIN          @"App Test"
#define DOMAIN_URL          @"https://app-test.cashview.com"
#define APP_KEY             @"devKey"
#define DEBUG_MODE
#endif

#ifdef APPSTAGE
#define APP_KEY_VALUE       @"01AHJMDLVJQRYYRHWUV4"
#define ERR_DOMAIN          @"App Stage"
#define DOMAIN_URL          @"https://app-stage.bill.com"
#define APP_KEY             @"devKey"
#define DEBUG_MODE
#endif

#ifdef PROD
#define APP_KEY_VALUE       @"01VWTMSCMXDIADIVY208"
#define ERR_DOMAIN          @"PROD"
#define DOMAIN_URL          @"https://app.bill.com"
#define APP_KEY             @"devKey"
#endif

#ifdef DEBUG_MODE
#define Debug( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define Debug( s, ... )
#endif

#define KEYCHAIN_ID         @"BDCLogin"

//API Params
#define ORG_ID              @"orgId"
#define USERNAME            @"userName"
#define PASSWORD            @"password"
#define DATA                @"data"
#define OBJ                 @"\"obj\""
#define BILL_ID             @"billId"
#define DOC_PG_ID           @"dpId"
#define Id                  @"Id"
#define PRESENT_TYPE        @"PresentationType"
#define FILE_NAME           @"fileName"
#define DOCUMENT            @"document"
#define ATTACH_ID           @"aid"
#define PAGE_NUMBER         @"pageNumber"
#define IMAGE_WIDTH         @"w"
#define IMAGE_HEIGHT        @"h"
#define DOCUMENT_CELL_DIMENTION     95

#define API_TIMEOUT         30
#define PDF_TYPE            @"PDF"
#define PNG_TYPE            @"PNG"
#define HTML_TYPE           @"HTML"

#define API_BASE            @"api/v2"
#define CRUD                @"Crud"
#define CREATE              @"Create"
#define READ                @"Read"
#define UPDATE              @"Update"
#define DELETE              @"Delete"
#define UNDELETE            @"Undelete"

#define INV_2_PDF_API       @"Invoice2PdfServlet"
#define ATTACH_DOWNLOAD_API @"AttachDownload"       // not used any more
#define DOC_DOWNLOAD_API    @"FileServlet"          // not used any more
#define DOC_IMAGE_API       @"ImageServlet"
#define ATTACH_IMAGE_API    @"AttachmentImageServlet"
#define ORG_LOGO_API        @"InvoiceLogoImage"
#define LOGIN_API           @"Login.json"
#define LIST_ORG_API        @"ListOrgs.json"
#define UPLOAD_API          @"UploadAttachment.json"
#define RETRIEVE_DOCS_API   @"RetrieveAttachment.json"
#define REMOVE_DOCS_API     @"RemoveAttachment.json"
#define ASSIGN_DOCS_API     @"AssignDocument.json"
#define LIST_API            @"List/"
#define BILL_API            @"Bill.json"
#define PAY_BILL_API        @"PayBill.json"
#define INVOICE_API         @"Invoice.json"
#define CUSTOMER_API        @"Customer.json"
#define VENDOR_API          @"Vendor.json"
#define ITEM_API            @"Item.json"
#define ACCOUNT_API         @"ChartOfAccount.json"
#define BANK_ACCOUNT_API    @"BankAccount.json"
#define ENUM_API            @"Enum.json"
#define ORG_PAY_NEED_APPROVAL_API   @"OrgBillPayNeedApproval.json"

#define ENTITY              @"entity"

#define LIST_ACTIVE_FILTER  @"{ \"start\" : 0, \
                                \"max\" : 999, \
                                \"filters\" : [{\"field\" : \"isActive\", \"op\" : \"=\", \"value\" : \"1\"}] \
                              }"

#define LIST_INACTIVE_FILTER    @"{ \"start\" : 0, \
                                    \"max\" : 999, \
                                    \"filters\" : [{\"field\" : \"isActive\", \"op\" : \"=\", \"value\" : \"2\"}] \
                                }"

//#define LIST_ACTIVE_FILTER  @"{ \"start\" : 0, \
//                                \"max\" : 999, \
//                                \"filters\" : [{\"field\" : \"isActive\", \"op\" : \"=\", \"value\" : \"1\"}], \
//                                \"sort\" : [{\"field\" : \"createdTime\", \"asc\" : \"false\"}, {\"field\" : \"id\", \"asc\" : \"true\"}] \
//                              }"

#define PAGE_BASE           @"p"
#define MOBILE_PAGE_BASE    @"m"
#define AP_PAGE             @"MyBills"              //deprecated
#define AR_PAGE             @"ReceivablesOverview"  //deprecated

#define EMPTY_ID            @"00000000000000000000"

#define RESPONSE_SUCCESS    0
#define RESPONSE_FALURE     1
#define RESPONSE_TIMEOUT    2
#define ORG_NO_API          @"BDC_1105"
#define INVALID_SESSION     @"BDC_1109"
#define RESPONSE_DATA_KEY   @"response_data"
#define RESPONSE_STATUS_KEY @"response_status"
#define RESPONSE_ERROR_CODE @"error_code"
#define RESPONSE_ERROR_MSG  @"error_message"
#define ID                  @"id"
#define OBJ_ID              @"objectId"
#define IS_ACTIVE           @"isActive"
#define SESSION_ID_KEY      @"sessionId"

#define StrDone             @"Done"
#define SysTimeOut          @"System timed out"

//temp: should grab from DB
#define VendorArray         [NSArray arrayWithObjects:@"Bill.com", @"Yahoo", @"Google", nil]
#define PaymentTermsArray   [NSArray arrayWithObjects:@"Due upon receipt", @"Net 10", @"Net 15", @"Net 30", nil]
#define AccountArray        [NSArray arrayWithObjects:@"Money In Clearing", @"Money Out Clearing", nil]

// UI related
#define APP_LABEL_FONT_SIZE             13
#define SCREEN_WIDTH                    320
#define STATUS_BAR_HEIGHT               20
#define NORMAL_SCREEN_HEIGHT            460
#define FULL_SCREEN_HEIGHT              NORMAL_SCREEN_HEIGHT + STATUS_BAR_HEIGHT

#define TAG_BASE                        100
#define PICKER_TAG_BASE                 TAG_BASE * 2

#define CELL_WIDTH                      300
#define CELL_HEIGHT                     44
#define INFO_INPUT_RECT                 CGRectMake(CELL_WIDTH - 170, 5, 170, CELL_HEIGHT - 10)
#define TABLE_CELL_DETAIL_TEXT_RECT     CGRectMake(85, 5, CELL_WIDTH - 100, CELL_HEIGHT - 10)
#define TABLE_CELL_DETAIL_TEXT_FONT     13.0

#define INVALID_OPTION                  -1

// doucment/attachment thumbnail
#define IMG_PADDING                     10
#define IMG_WIDTH                       CELL_WIDTH / 4
#define IMG_HEIGHT                      IMG_WIDTH - IMG_PADDING
#define ATTACHMENT_RECT                 CGRectMake(5, 0, CELL_WIDTH, IMG_HEIGHT)
#define ATTACHMENT_PV_HEIGHT            3
#define ATTACHMENT_PV_RECT              CGRectMake(0, IMG_HEIGHT + IMG_PADDING, CELL_WIDTH, ATTACHMENT_PV_HEIGHT)
#define NUM_ATTACHMENT_PER_PAGE         4

#define SLIDING_DISTANCE                270
#define SLIDING_DURATION                0.30
typedef void(^completionHandler)(BOOL);

#define SELECT_ONE                      @"Select one"

// Element sizes
#define ToolbarHeight                   44
#define TableViewShrinkSize             94
#define FrameDisclosureCell             CGRectMake(0, 0, 300, 36)
#define PICKER_RECT                     CGRectMake(0, 0, 320, 216)
#define TEXT_FIELD_RIGHT_PADDING_RECT   CGRectMake(0, 0, 10, 30)

// Bill info
#define BILL                @"Bill"
#define VENDOR              @"Vendor"
#define InvoiceNumber       @"Invoice #"
#define PaymentTerms        @"Payment Terms"
#define InvoiceDate         @"Invoice Date"
#define DueDate             @"Due Date"
#define Amount              @"Amount"
#define Account             @"Account"
#define ChartAccount        @"ChartOfAccount"
#define ALL_INACTIVE_BILLS  @"All Deleted Bills"
#define ALL_OPEN_BILLS       @"All Open Bills"
#define ALL_INACTIVE_VCS    @"All Deleted Vendor Credits"

// Invoice info
#define INVOICE             @"Invoice"
#define ALL_OPEN_INVS       @"All Open Invoices"
#define OVERDUE             @"Overdue"
#define DUE_IN_7            @"Due in Next 7 Days"
#define DUE_OVER_7          @"Due in 7+ Days"
#define ALL_INACTIVE_INVS   @"All Deleted Invoices"

#define INVOICE_EMAIL_TEMPLATE  @"\
Hi %@,<br> \
<br> \
To pay your invoice online and view your account history, log in below:<br> \
%@<br>\
<br> \
Please remit payment at your earliest convenience.<br> \
<br> \
Thank you for your business,<br> \
%@<br> \
<br>\
----------------<br> \
Invoice Summary:<br> \
<br> \
Invoice #: %@<br> \
Amount Due: %@<br> \
Due Date: %@<br> \
<br> \
A PDF version of this invoice is also attached for your records.<br>"


// Approval Status
#define APPROVAL_UNASSIGNED     @"0"
#define APPROVAL_ASSIGNED       @"1"
#define APPROVAL_APPROVED       @"3"
#define APPROVAL_APPROVING      @"4"
#define APPROVAL_DENIED         @"5"
#define APPROVAL_STATUSES       [NSDictionary dictionaryWithObjectsAndKeys:@"Unassigned", APPROVAL_UNASSIGNED, @"Assigned", APPROVAL_ASSIGNED, @"Approved", APPROVAL_APPROVED, @"Approving", APPROVAL_APPROVING, @"Denied", APPROVAL_DENIED, nil]

// Payment Status
#define PAYMENT_PAID            @"0"
#define PAYMENT_UNPAID          @"1"
#define PAYMENT_PARTIAL         @"2"
#define PAYMENT_SCHEDULED       @"4"
#define PAYMENT_PENDING         @"5"
#define PAYMENT_STATUSES        [NSDictionary dictionaryWithObjectsAndKeys:@"Paid", PAYMENT_PAID, @"Unpaid", PAYMENT_UNPAID, @"Partially Paid", PAYMENT_PARTIAL, @"Scheduled", PAYMENT_SCHEDULED, @"Pending", PAYMENT_PENDING, nil]

// Vendor Payment Type
#define VENDOR_PAYMENT_CHECK    @"0"
#define VENDOR_PAYMENT_ACH      @"1"
#define VENDOR_PAYMENT_RPPS     @"2"
#define VENDOR_PAYMENT_TYPES    [NSDictionary dictionaryWithObjectsAndKeys:@"Check", VENDOR_PAYMENT_CHECK, @"ACH", VENDOR_PAYMENT_ACH, @"RPPS", VENDOR_PAYMENT_RPPS, nil]

typedef enum {
    kSucceedLogin, kFailLogin, kFailListOrgs
} LoginStatus;

#define EMAIL_SENT              @"Email sent successfully"
#define EMAIL_FAILED            @"Failed to send email! Please try again."


typedef enum {
    kARTab, kAPTab, kScanTab, kInboxTab, kProfileTab, kCustomerTab, kVendorTab,
} TabOrder;

typedef enum {
    kListMode = 1,
    kSelectMode,
    kViewMode,
    kCreateMode,
    kUpdateMode,
    kModifyMode,    // only used for modifying invoice line item's price and qty
    kAttachMode
} ViewMode;

#define IMAGE_TYPE_SET      [NSSet setWithObjects:@"jpg", @"jpeg", @"png", @"gif", @"tiff", nil]
#define MIME_TYPE_DICT      [NSDictionary dictionaryWithObjectsAndKeys: @"csv", @"text/csv", \
                                                                        @"doc", @"application/msword", \
                                                                        @"docx", @"application/vnd.openxmlformats-officedocument.wordprocessingml.document", \
                                                                        @"ext", @"application/exe", \
                                                                        @"gif", @"image/gif", \
                                                                        @"jpg", @"image/jpeg", \
                                                                        @"jpeg", @"image/jpeg", \
                                                                        @"mov", @"image/mov", \
                                                                        @"mp3", @"audio/mpeg", \
                                                                        @"pdf", @"application/pdf", \
                                                                        @"png", @"image/png", \
                                                                        @"ppt", @"application/vnd.ms-powerpoint", \
                                                                        @"pptx", @"application/vnd.openxmlformats-officedocument.presentationml.presentation", \
                                                                        @"rar", @"application/x-rar-compressed", \
                                                                        @"tiff", @"image/tiff", \
                                                                        @"txt", @"text/plain", \
                                                                        @"wav", @"audio/vnd.wave", \
                                                                        @"wma", @"audio/x-ms-wma", \
                                                                        @"wmv", @"video/x-ms-wmv", \
                                                                        @"xls", @"application/vnd.ms-excel", \
                                                                        @"xlsx", @"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", \
                                                                        @"zip", @"application/zip", \
                                                                        nil]

// font
#define APP_BOLD_FONT          @"Arial-BoldMT"
#define APP_FONT               @"Arial"
#define APP_LABEL_BLUE_COLOR   [UIColor colorWithRed:81.0/255.0 green:102.0/255.0 blue:145.0/255.0 alpha:1.0]
#define APP_SYSTEM_BLUE_COLOR  [UIColor colorWithRed:0.298039 green:0.337255 blue:0.423529 alpha:1.0]

// API Handler typedef
typedef void(^Handler)(NSURLResponse * response, NSData * data, NSError * err);

#endif

