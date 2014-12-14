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

//#define LITE_VERSION
#define FULL_VERSION_ID     696521463

//#define LOCAL
//#define APPTEST
//#define APPSTAGE
#define PROD


#ifdef LOCAL
#define APP_KEY_VALUE       @"01MDUVHZTMMHTDOVCCV0"
#define ERR_DOMAIN          @"Local"
#define DOMAIN_URL          @"http://10.0.0.14"
//#define DOMAIN_URL          @"http://192.168.1.12"
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

#define BNC_APP_KEY         @"45988591431582341"
#define MP_TOKEN            @"7813b39597fc0555eed85e7d1ca90259"
#define TRACKING_EVENT_KEYS @[@"UserId", @"UserName", @"UserEmail", @"OrgId", @"OrgName"]

#ifdef DEBUG_MODE
#define Debug( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define Debug( s, ... )
#endif

#define Error( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )

#define KEYCHAIN_ID         @"BDCLogin"

// Version
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

// Color
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define HTTP_GET            @"GET"
#define HTTP_POST           @"POST"

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
#define LIST_API            @"List/"

#define INV_2_PDF_API       @"Invoice2PdfServlet"
#define ATTACH_DOWNLOAD_API @"AttachDownload"           // not used any more
#define DOC_DOWNLOAD_API    @"FileServlet"              // not used any more
#define DOC_IMAGE_API       @"ImageServlet"
#define ATTACH_IMAGE_API    @"AttachmentImageServlet"
#define ORG_LOGO_API        @"InvoiceLogoImage"
#define LOGIN_API           @"Login.json"
#define LIST_ORG_API        @"ListOrgs.json"
#define UPLOAD_API          @"UploadAttachment.json"
#define RETRIEVE_DOCS_API   @"RetrieveAttachment.json"
#define GET_DOCS_API        @"GetDocuments.json"
#define GET_ATTACHMENTS_API @"GetAttachments.json"
#define REMOVE_DOCS_API     @"RemoveAttachment.json"
#define DEL_DOC_API         @"DeleteDocument.json"
#define DEL_ATTACHMENT_API  @"DeleteAttachment.json"
#define ASSIGN_DOCS_API     @"AssignDocument.json"
#define USER_API            @"User.json"
#define PROFILE_API         @"Profile.json"
#define ORGANIZATION_API    @"Organization.json"        // read-only
#define ORG_PREF_API        @"GetOrgPreferences.json"   // read-only
#define ORG_FEATURE_API     @"GetOrgFeatures.json"      // read-only
#define BILL_API            @"Bill.json"
#define PAY_BILL_API        @"PayBills.json"
#define INVOICE_API         @"Invoice.json"
#define CUSTOMER_API        @"Customer.json"
#define CONTACT_API         @"CustomerContact.json"
#define VENDOR_API          @"Vendor.json"
#define ITEM_API            @"Item.json"
#define ACCOUNT_API         @"ChartOfAccount.json"
#define BANK_ACCOUNT_API    @"BankAccount.json"
#define APPROVER_LIST_API   @"ui/ApproverList.json"
#define APPROVERS_GET_API   @"ListApprovers.json"
#define APPROVERS_SET_API   @"SetApprovers.json"
#define APPROVER_CREATE_API @"ui/CreateBillApprover.json"
#define LIST_APPROVALS_API  @"ListUserApprovals.json"
#define APPROVE_API         @"Approve.json"
#define DENY_API            @"Deny.json"
#define SKIP_API            @"Skip.json"
#define INVOICE_SEND_API    @"SendInvoice.json"
#define VENDOR_INVITE_API   @"SendVendorInvite.json"
#define ENUM_API            @"Enum.json"

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

#define PORTAL_BASE         @"p"
#define MOBILE_PAGE_BASE    @"m"
#define AP_PAGE             @"MyBills"              //deprecated
#define AR_PAGE             @"ReceivablesOverview"  //deprecated

#define EMPTY_ID            @"00000000000000000000"

#define RESPONSE_SUCCESS    0
#define RESPONSE_FALURE     1
#define RESPONSE_TIMEOUT    2
#define ORG_LOCKED_OUT      @"BDC_1107"
#define INVALID_SESSION     @"BDC_1109"
#define INVALID_PERMISSION  @"BDC_1145"
#define RESPONSE_DATA_KEY   @"response_data"
#define RESPONSE_STATUS_KEY @"response_status"
#define RESPONSE_ERROR_CODE @"error_code"
#define RESPONSE_ERROR_MSG  @"error_message"
#define _ID                 @"id"
#define OBJ_ID              @"objectId"
#define IS_ACTIVE           @"isActive"
#define SESSION_ID_KEY      @"sessionId"

#define StrDone             @"Done"
#define SysTimeOut          @"System timed out"

// User
#define USER_EMAIL          @"UserEmail"
#define USER_ID             @"usersId"
#define USER_PROFILE_ID     @"UserProfileId"
#define USER_FNAME          @"UserFname"
#define USER_LNAME          @"UserLname"

// Profile
#define PROFILE_ADMIN       @"Administrator"
#define PROFILE_ACCOUNTANT  @"Accountant"
#define PROFILE_PAYER       @"Payer"
#define PROFILE_APPROVER    @"Approver"
#define PROFILE_CLERK       @"Clerk"


//temp: should grab from DB
#define VendorArray         [NSArray arrayWithObjects:@"Bill.com", @"Yahoo", @"Google", nil]
#define PaymentTermsArray   [NSArray arrayWithObjects:@"Due upon receipt", @"Net 10", @"Net 15", @"Net 30", nil]
#define AccountArray        [NSArray arrayWithObjects:@"Money In Clearing", @"Money Out Clearing", nil]

// UI related
#define APP_LABEL_FONT_SIZE             13
#define SCREEN_WIDTH                    [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT                   [UIScreen mainScreen].bounds.size.height
#define STATUS_BAR_HEIGHT               20
#define NORMAL_SCREEN_HEIGHT            460
#define FULL_SCREEN_HEIGHT              NORMAL_SCREEN_HEIGHT + STATUS_BAR_HEIGHT

#define TAG_BASE                        100
#define PICKER_TAG_BASE                 TAG_BASE * 2

#define CELL_WIDTH                      300
#define CELL_HEIGHT                     44
#define INFO_INPUT_RECT                 CGRectMake(CELL_WIDTH - 170, 5, 170, CELL_HEIGHT - 10)
#define TABLE_CELL_DETAIL_TEXT_RECT     CGRectMake(85, 5, CELL_WIDTH - 100, CELL_HEIGHT - 10)
#define TABLE_CELL_DETAIL_TEXT_RECT_7   CGRectMake(107, 6, CELL_WIDTH - 100, CELL_HEIGHT - 10)
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
#define PORTRAIT_KEYBOARD_HEIGHT        216
#define FrameDisclosureCell             CGRectMake(0, 0, 300, 36)
#define PICKER_RECT                     CGRectMake(0, 0, 320, PORTRAIT_KEYBOARD_HEIGHT)
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

#define INVOICE_BNC_EMAIL_TEMPLATE  @"\
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

#define RECOMMEND_MOBILL_EMAIL  @" \
Hi %@,<br> \
<br> \
As you know, we are using Bill.com to manage our bills and invoices. It's awesome.<br><br> \
We just want to share something even more awesome: there is a native iPhone app called \"Mobill\" for Bill.com now!<br><br> \
It's sleek, easy to use, and pretty useful! A perfect mobile app for Bill.com, and we highly recommend it. Check it out!<br> \
%@<br><br> \
And if you want to try it out first before paying for it, you can download its free edition.<br> \
%@<br><br> \
We love it very much, and we hope you will like it too!<br><br> \
Best regards,<br> \
<br> \
%@<br> \
<br>"

#define BNC_SHARE_OBJ_EMAIL_TEMPLATE    @"\
Hi,<br> \
<br> \
I have this %@, \"%@,\" in my Bill.com account, and I am reviewing it via my Mobill iPhone app.<br> \
I'd like to share it with you. Please take a look.<br> \
<br> \
%@<br> \
<br> \
Best regards,<br> \
<br> \
%@<br>"

#define BNC_SHARE_OBJ_SMS_TEMPLATE    @"\
I am reviewing my Bill.com %@, \"%@\", via my Mobill iPhone app: %@ \n \
I'd like to share it with you. Please take a look.\n  -- %@"

#define BNC_SHARE_MOBILL_EMAIL_TEMPLATE    @"\
Hi,<br> \
<br> \
I'd like to share something cool with you: I am using a native iPhone app, \"Mobill\", to manage my Bill.com account now!<br><br> \
It's sleek, easy to use, and pretty useful! A perfect mobile app for Bill.com, and I highly recommend it. Check it out!<br> \
<br> \
%@<br> \
<br> \
Best,<br> \
<br> \
%@<br>"

#define BNC_SHARE_MOBILL_SMS_TEMPLATE    @"\
Bravo! I am using a native iPhone app, \"Mobill\", to manage my Bill.com account now!\n \
It's sleek, easy to use, and pretty useful! I highly recommend it. Check it out! %@\n \
  -- %@"

#define BNC_SHARE_SOCIAL_NAME           @"Mobill - mobile app for Bill.com"

#define BNC_SHARE_SOCIAL_IMAGE_URL      @"https://www.dropbox.com/s/wv8l5g2cojq7fst/Mobill_logo120.png?dl=1"
#define BNC_SHARE_SOCIAL_FULL_IMG_URL   @"https://www.dropbox.com/s/gxk9vogaucrg9py/Mobill200.png?dl=1"

#define BNC_SHARE_SOCIAL_CAPTION        @"Bill.com easily managed in your palm!"

#define BNC_SHARE_SOCIAL_DESCRIPTION    @"\
Mobill can be used to pay or approve bills, or send invoices to customers, and even better - \
you can use Mobill to scan documents into your Bill.com account! Go mobile. Go Mobill."

#define MOBILL_APP_STORE_LINK       @"http://itunes.apple.com/us/app/id696521463"
#define MOBILL_LITE_APP_STORE_LINK  @"http://itunes.apple.com/us/app/id765927170"


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
#define VENDOR_PAYMENT_TYPES    [NSDictionary dictionaryWithObjectsAndKeys:@"Check", VENDOR_PAYMENT_CHECK, @"ePayment", VENDOR_PAYMENT_ACH, @"RPPS", VENDOR_PAYMENT_RPPS, nil]

typedef enum {
    kSucceedLogin, kFailLogin, kFailListOrgs
} LoginStatus;

#define EMAIL_SENT              @"Email sent successfully"
#define EMAIL_FAILED            @"Failed to send email! Please try again."

#define SMS_SENT                @"SMS sent successfully"
#define SMS_FAILED              @"Failed to send SMS! Please try again."

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
    kAttachMode,
    kApprovalMode
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
#define APP_BUTTON_BLUE_COLOR  [UIColor colorWithRed:50.0/255.0 green:135.0/255.0 blue:225.0/255.0 alpha:1.0]

// API Handler typedef
typedef void(^Handler)(NSURLResponse * response, NSData * data, NSError * err);

#endif

