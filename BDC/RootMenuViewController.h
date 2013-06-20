//
//  RootMenuViewController.h
//  BDC
//
//  Created by Qinwei Gong on 10/16/12.
//
//

#import <UIKit/UIKit.h>
#import "UIViewController+Sliding.h"

#define CATEGORY_NIL    @""
#define CATEGORY_TOOL   @"Tools"
#define CATEGORY_MORE   @"More"
#define MENU_PROFILE    @"Profile"
#define MENU_ORGS       @"Organizations"
#define MENU_INBOX      @"Inbox"
#define MENU_SCANNER    @"Scanner"

#define CATEGORY_AR     @"Account Receivables"
#define MENU_INVOICES   @"Invoices"
#define MENU_CUSTOMERS  @"Customers"
#define MENU_ITEMS      @"Items"

#define CATEGORY_AP     @"Account Payables"
#define MENU_BILLS      @"Bills"
#define MENU_VENDORS    @"Vendors"

#define MENU_LOGOUT     @"LogOut"

#define ROOT_MENU       [NSArray arrayWithObjects: \
                            [NSArray arrayWithObjects:MENU_PROFILE,                                     CATEGORY_NIL, nil], \
                            [NSArray arrayWithObjects:MENU_SCANNER, MENU_INBOX,                         CATEGORY_TOOL, nil], \
                            [NSArray arrayWithObjects:MENU_INVOICES, MENU_CUSTOMERS, MENU_ITEMS,        CATEGORY_AR, nil], \
                            [NSArray arrayWithObjects:MENU_BILLS, MENU_VENDORS,                         CATEGORY_AP, nil], \
                            [NSArray arrayWithObjects:MENU_ORGS, MENU_LOGOUT,                           CATEGORY_MORE, nil], \
                        nil]

enum RootMenuSections {
    kRootProfile,
    kRootTool,
    kRootAR,
    kRootAP,
    kRootMore
};

enum RootToolItems {
    kToolScanner,
    kToolInbox
};

enum RootARItems {
    kARInvoice,
    kARCustomer,
    kARItem
};

enum RootAPItems {
    kAPBill,
    kAPVendor
};

@interface RootMenuViewController : UIViewController <SlideDelegate>

@property (weak, nonatomic) IBOutlet UITableView *menuTableView;
@property (nonatomic, strong) UIViewController *currVC;
@property (nonatomic, strong) NSMutableDictionary *menuItems;

+ (RootMenuViewController *)sharedInstance;
- (UINavigationController *)showView:(NSString *)identifier;

@end
