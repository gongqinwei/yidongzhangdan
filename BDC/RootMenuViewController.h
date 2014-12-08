//
//  RootMenuViewController.h
//  BDC
//
//  Created by Qinwei Gong on 10/16/12.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+Sliding.h"
#import "Invoice.h"
#import "Customer.h"
#import "CustomerContact.h"
#import "Bill.h"
#import "Vendor.h"
#import "Item.h"
#import "Document.h"
#import "ChartOfAccount.h"
#import "User.h"

#define CATEGORY_PROFILE    @""
#define MENU_USER           @"User"
#define MENU_ORG            @"My Company"

#define CATEGORY_TOOL       @"Documents"
#define MENU_INBOX          @"Inbox"
#define MENU_SCANNER        @"Scanner"

#define CATEGORY_AP         @"Account Payables"
#define MENU_BILLS          @"Bills"
#define MENU_VENDORS        @"Vendors"
#define MENU_APPROVE        @"Approve"

#define CATEGORY_AR         @"Account Receivables"
#define CATEGORY_AR_READONLY    @"Account Receivables (read only)"
#define MENU_INVOICES       @"Invoices"
#define MENU_CUSTOMERS      @"Customers"
#define MENU_ITEMS          @"Items"

#define CATEGORY_MORE       @"More"
#define MENU_SHARE          @"Share"
#define MENU_FEEDBACK       @"Feedback"
#define MENU_LEGAL          @"Term of Service"
#define MENU_LOGOUT         @"Log Out"
#define MENU_UPGRADE        @"Upgrade to Mobill Unlimited"
#define MENU_VERSION        @"© 2012-2014 Mobill %@"

#ifdef LITE_VERSION
#define ROOT_MENU       [NSArray arrayWithObjects: \
                            [NSArray arrayWithObjects:MENU_USER, MENU_ORG,                                              CATEGORY_PROFILE, nil], \
                            [NSArray arrayWithObjects:MENU_SCANNER, MENU_INBOX,                                         CATEGORY_TOOL, nil], \
                            [NSArray arrayWithObjects:MENU_BILLS, MENU_VENDORS, MENU_APPROVE,                           CATEGORY_AP, nil], \
                            [NSArray arrayWithObjects:MENU_INVOICES, MENU_CUSTOMERS, MENU_ITEMS,                        CATEGORY_AR, nil], \
                            [NSArray arrayWithObjects:MENU_UPGRADE, MENU_SHARE, MENU_FEEDBACK, MENU_LEGAL, MENU_LOGOUT, MENU_VERSION,  CATEGORY_MORE, nil], \
                        nil]
#else
#define ROOT_MENU       [NSArray arrayWithObjects: \
                            [NSArray arrayWithObjects:MENU_USER, MENU_ORG,                                              CATEGORY_PROFILE, nil], \
                            [NSArray arrayWithObjects:MENU_SCANNER, MENU_INBOX,                                         CATEGORY_TOOL, nil], \
                            [NSArray arrayWithObjects:MENU_BILLS, MENU_VENDORS, MENU_APPROVE,                           CATEGORY_AP, nil], \
                            [NSArray arrayWithObjects:MENU_INVOICES, MENU_CUSTOMERS, MENU_ITEMS,                        CATEGORY_AR, nil], \
                            [NSArray arrayWithObjects:MENU_SHARE, MENU_FEEDBACK, MENU_LEGAL, MENU_LOGOUT, MENU_VERSION, CATEGORY_MORE, nil], \
                        nil]
#endif

enum RootMenuSections {
    kRootProfile,
    kRootTool,
    kRootAP,
    kRootAR,
    kRootMore
};

enum RootProfileItems {
    kProfileUser,
    kProfileOrg,
};

enum RootToolItems {
    kToolScanner,
    kToolInbox
};

enum RootAPItems {
    kAPBill,
    kAPVendor,
    kAPApprove
};

enum RootARItems {
    kARInvoice,
    kARCustomer,
    kARItem
};

enum RootMoreItems {
#ifdef LITE_VERSION
    kMoreUpgrade,
#endif
    kMoreShare,
    kMoreFeedback,
    kMoreLegal,
    kMoreLogout,
    kMoreVersion
};

@interface RootMenuViewController : UIViewController <SlideDelegate, UserDelegate, BillListDelegate, InvoiceListDelegate, VendorListDelegate, CustomerListDelegate, ItemListDelegate, ContactListDelegate, DocumentListDelegate, AccountListDelegate>

@property (weak, nonatomic) IBOutlet UITableView *menuTableView;
@property (nonatomic, strong) UIViewController *currVC;
@property (nonatomic, strong) NSMutableDictionary *menuItems;
@property (nonatomic, strong) UILabel *numBillsToApproveLabel;

+ (RootMenuViewController *)sharedInstance;
- (UINavigationController *)showView:(NSString *)identifier;
- (void)switchFrom:(UIViewController *)orig To:(NSString *)identifier;
- (SlidingTableViewController *)slideInListViewIdentifier:(NSString *)identifier;
- (void)deeplinkRedirect;

@end
