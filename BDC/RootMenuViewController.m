//
//  RootMenuViewController.m
//  BDC
//
//  Created by Qinwei Gong on 10/16/12.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "RootMenuViewController.h"
#import "SelectOrgViewController.h"
//#import "AROverViewController.h"
#import "InvoicesTableViewController.h"
#import "CustomersTableViewController.h"
#import "EditCustomerViewController.h"
#import "Organization.h"

#import "Approver.h"
#import "ChartOfAccount.h"

#import "BankAccount.h"

#import "Util.h"
#import "UIHelper.h"
#import "TutorialControl.h"
#import "BDCAppDelegate.h"
#import "Branch.h"
#import <MessageUI/MessageUI.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>
//#import <FacebookSDK/FacebookSDK.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>

#define ROOT_MENU_SECTION_HEADER_HEIGHT     22
#define ROOT_MENU_CELL_ID                   @"RootMenuItem"
#define ROOT_MENU_TUTORIAL                  @"ROOT_MENU_TUTORIAL"
#define SWIPE_UP_TUTORIAL_Y                 (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0") ? 95 : 75)
#define SWIPE_UP_TUTORIAL_RECT              CGRectMake((SCREEN_WIDTH - 300) / 2, SWIPE_UP_TUTORIAL_Y, 300, 65)
#define SWIPE_UP_ARROW_Y                    (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0") ? 40 : 20)
#define SWIPE_UP_ARROW_RECT                 CGRectMake((SCREEN_WIDTH - 23) / 2, SWIPE_UP_ARROW_Y, 23, 50)
#define CELL_DISCLOSURE_TAG                 7

typedef enum {
    kEmailShare, kMessageShare, kLinkedInShare, kFacebookShare, kTwitterShare
} ShareOption;

@interface RootMenuViewController () <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>

@property (nonatomic, strong) Organization *currentOrg;
@property (nonatomic, strong) NSMutableArray *rootMenu;
@property (nonatomic, strong) TutorialControl *rootMenuTutorialOverlay;

@property (nonatomic, assign) BOOL isInit;  // no slided vc edge on root menu: show build-in disclosure indicator
@property (nonatomic, strong) NSIndexPath *lastSelected;
@property (nonatomic, assign) BOOL showShareOptions;
@property (nonatomic, assign) ShareOption shareOption;

@property (nonatomic, strong) UIActivityIndicatorView *retrieveImageActivityIndicator;

@property (nonatomic, assign) BOOL gotBills;
@property (nonatomic, assign) BOOL gotInvoices;
@property (nonatomic, assign) BOOL gotVendors;
@property (nonatomic, assign) BOOL gotCustomers;
@property (nonatomic, assign) BOOL gotItems;
@property (nonatomic, assign) BOOL gotContacts;

@end


@implementation RootMenuViewController

@synthesize currentOrg;
@synthesize rootMenu;
@synthesize menuTableView;
@synthesize currVC;
@synthesize menuItems;
@synthesize rootMenuTutorialOverlay;
@synthesize isInit;
@synthesize numBillsToApproveLabel;
@synthesize lastSelected;
@synthesize showShareOptions;
@synthesize shareOption;
@synthesize retrieveImageActivityIndicator;
@synthesize gotBills;
@synthesize gotInvoices;
@synthesize gotVendors;
@synthesize gotCustomers;
@synthesize gotItems;
@synthesize gotContacts;


static RootMenuViewController * _sharedInstance = nil;

+ (RootMenuViewController *)sharedInstance {
    return _sharedInstance;
}

- (void)switchFrom:(UIViewController *)orig To:(NSString *)identifier {
//    [orig disappear];
    [self showView:identifier];
}

- (UINavigationController *)showView:(NSString *)identifier {
    identifier = [identifier stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (!self.currVC) {
        UINavigationController *navVC = [self.menuItems objectForKey:identifier];
        self.currVC = [navVC.childViewControllers objectAtIndex:0];
        self.currVC.navigation = navVC;
        self.currVC.navigationId = identifier;
        [self.currVC slideIn];
    } else if ([self.currVC.navigationId isEqualToString:identifier] && SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        [self.currVC toggleMenu:self];        
    } else {
        [self.currVC slideOut];
        
        UINavigationController *navVC = [self.menuItems objectForKey:identifier];
        self.currVC = [navVC.childViewControllers objectAtIndex:0];
        self.currVC.navigation = navVC;
        self.currVC.navigationId = identifier;
    }
    
    return self.currVC.navigationController;
}

#pragma mark - View Controller Life Cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //fb test code
//    FBLoginView *loginView = [[FBLoginView alloc] init];
//    loginView.center = self.view.center;
//    [self.view addSubview:loginView];
    
    [User setUserDelegate:self];
    
    self.currentOrg = [Organization getSelectedOrg];
    
    self.rootMenu = [NSMutableArray array];
    [self.rootMenu addObject:[ROOT_MENU objectAtIndex:kRootProfile]];   // always + Profile/ChangeOrg section
        
    if (!self.currentOrg.showAR && !self.currentOrg.enableAP && !self.currentOrg.canApprove) {
        // Profile + More (theoretically should never happen - can't login)
        [UIHelper showInfo:@"This company has no AR and disabled AP!\n\nPlease enable them in Bill.com first." withStatus:kWarning];
    } else {
        if (self.currentOrg.enableAP || self.currentOrg.enableAR) {
            [self.rootMenu addObject:[NSMutableArray arrayWithArray:[ROOT_MENU objectAtIndex:kRootTool]]];  // + Documents section
        } else {
//            [self.rootMenu addObject:[NSMutableArray arrayWithObjects:[ROOT_MENU objectAtIndex:kRootTool][kToolScanner], [ROOT_MENU objectAtIndex:kRootTool][2], nil]];
        }
        
        if (self.currentOrg.enableAP && self.currentOrg.canApprove) {
            [self.rootMenu addObject:[NSMutableArray arrayWithArray:[ROOT_MENU objectAtIndex:kRootAP]]];    // + AP section
        } else if (self.currentOrg.enableAP) {
            [self.rootMenu addObject:[NSMutableArray arrayWithObjects:[ROOT_MENU objectAtIndex:kRootAP][kAPBill], [ROOT_MENU objectAtIndex:kRootAP][kAPVendor], [ROOT_MENU objectAtIndex:kRootAP][3], nil]];
        } else if (self.currentOrg.canApprove) {
            [self.rootMenu addObject:[NSMutableArray arrayWithObjects:[ROOT_MENU objectAtIndex:kRootAP][kAPApprove], [ROOT_MENU objectAtIndex:kRootAP][3], nil]];
        }
        
        if (self.currentOrg.showAR) {
            [self.rootMenu addObject:[NSMutableArray arrayWithArray:[ROOT_MENU objectAtIndex:kRootAR]]];    // + AR section
        }
    }
    
    [self.rootMenu addObject:[ROOT_MENU objectAtIndex:kRootMore]];          // always + More section
    
    self.menuTableView.dataSource = self;
    self.menuTableView.delegate = self;
    
    self.menuItems = [NSMutableDictionary dictionary];
    
    for (int i = 1; i < ROOT_MENU.count; i++) {
        for (int j = 0; j < [ROOT_MENU[i] count] - 1; j++) {
            if (i != kRootMore || j == kMoreLegal) {
                NSString *vcID = [[ROOT_MENU objectAtIndex:i] objectAtIndex:j];
                vcID = [vcID stringByReplacingOccurrencesOfString:@" " withString:@""];
                UINavigationController *navVC = [self.storyboard instantiateViewControllerWithIdentifier:vcID];
                [self.menuItems setObject:navVC forKey:vcID];
                if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
                    [UIHelper adjustScreen:navVC];
                }
            }
        }
    }
    
    [Bill setListDelegate:self];
    [Invoice setListDelegate:self];
    [Vendor setListDelegate:self];
    [Customer setListDelegate:self];
    [Item setListDelegate:self];
    [CustomerContact setListDelegate:self];
    [Document setDocumentListDelegate:self];
    [ChartOfAccount setListDelegate:self];
    
    [Bill resetList];
    [Invoice resetList];
    [Vendor resetList];
    [Customer resetList];
    [Item resetList];
    [Document resetList];
    [CustomerContact resetList];
    [ChartOfAccount resetList];
    [BankAccount resetList];
    
    
    if (self.currentOrg.enableAP || self.currentOrg.canApprove) {
        [Bill retrieveListForActive:YES reload:YES];
        [Bill retrieveListForApproval:nil];
        [Vendor retrieveListForActive:YES];
        [ChartOfAccount retrieveListForActive:YES];
        [Approver retrieveList];
        [self.currentOrg getOrgPrefs];
    }

    if (self.currentOrg.showAR) {
        [Invoice retrieveListForActive:YES reload:YES];
        [Customer retrieveListForActive:YES];
        [CustomerContact retrieveListForActive:YES];
        [Item retrieveList];
    }
    
    if (self.currentOrg.hasInbox || self.currentOrg.enableAP || self.currentOrg.enableAR) {
        [Document retrieveListForCategory:FILE_CATEGORY_DOCUMENT];
    }
    
    if (self.currentOrg.showAR) {
        [Invoice retrieveListForActive:NO reload:NO];
        [Customer retrieveListForActive:NO];
    }
    
    if (self.currentOrg.enableAP || self.currentOrg.canApprove) {
        [BankAccount retrieveList];
        [Bill retrieveListForActive:NO reload:NO];
        [Vendor retrieveListForActive:NO];
    }
    
//    [Document retrieveListForCategory:FILE_CATEGORY_ATTACHMENT]; // for future
    
    _sharedInstance = self;
    
//    CGRect tempFrame = self.view.frame;
//    tempFrame.size.width = SLIDING_DISTANCE;
//    [UIView beginAnimations:@"" context:nil];
//    [UIView setAnimationDuration:0.2];
//    self.view.frame = tempFrame;
//    [UIView commitAnimations];
    
//    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Background_linen.jpg"]];
    
    
    // one time tutorial
    if ([Organization count] > 1) {
        BOOL tutorialValue = [[NSUserDefaults standardUserDefaults] boolForKey:ROOT_MENU_TUTORIAL];
        if (!tutorialValue) {
            self.rootMenuTutorialOverlay = [[TutorialControl alloc] init];
            [self.rootMenuTutorialOverlay addText:@"Always click here to switch company" at:SWIPE_UP_TUTORIAL_RECT];
            [self.rootMenuTutorialOverlay addImageNamed:@"arrow_up.png" at:SWIPE_UP_ARROW_RECT];
            [self.view addSubview:self.rootMenuTutorialOverlay];
            
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:ROOT_MENU_TUTORIAL];
        }
    }
    
    self.isInit = YES;
    self.showShareOptions = NO;
    
    self.numBillsToApproveLabel = [[UILabel alloc] initWithFrame:CGRectMake(140, 13, 50, 20)];
    self.numBillsToApproveLabel.backgroundColor = [UIColor clearColor];
    self.numBillsToApproveLabel.textColor = [UIColor whiteColor];
    self.numBillsToApproveLabel.font = [UIFont fontWithName:APP_FONT size:15];
}

- (SlidingTableViewController *)slideInListViewIdentifier:(NSString *)identifier {
    UINavigationController *navVC = [self.menuItems objectForKey:identifier];
    SlidingTableViewController *vc = [navVC.childViewControllers objectAtIndex:0];
    
    self.currVC = vc;
    self.currVC.navigation = navVC;
    self.currVC.navigationId = identifier;
    
    [vc.view removeGestureRecognizer:vc.tapRecognizer];
    [navVC popToRootViewControllerAnimated:NO];
    
    return vc;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:MENU_ORG]) {
        [(SelectOrgViewController *)segue.destinationViewController setIsInitialLogin:NO];
    } else if ([segue.identifier isEqualToString:MENU_LOGOUT]) {
        [Util logout];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.rootMenu.count;
    
//    if (!self.currentOrg.showAR && !self.currentOrg.enableAP) {
//        return 2; // Profile + More (theoretically should never happen - can't login)
//    } else if (!self.currentOrg.enableAP) {
//        if (!self.currentOrg.enableAR) {
//            return 3; // Profile + AR(read-only) + More
//        } else {
//            return 4; // Profile + Documents + AR + More
//        }
//    } else {
//        return [ROOT_MENU count];
//    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kRootProfile) {
        return [[self.rootMenu objectAtIndex:section] count] - 2;
    } else {
        return [[self.rootMenu objectAtIndex:section] count] - 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = ROOT_MENU_CELL_ID;
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    
    cell.backgroundColor = [UIColor clearColor];
    if (!self.isInit) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.text = nil;
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    
    if (indexPath.section == kRootProfile) {
        if (indexPath.row == kProfileUser) {    // temporarily same as profile org. will change to user name/email once BDC API implemented
            cell.textLabel.text = self.currentOrg.name;
            cell.textLabel.font = [UIFont boldSystemFontOfSize:18.0];
            
            NSString *fname = [Util getUserFirstName];
            NSString *lname = [Util getUserLastName];
            if (fname && lname) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", fname, lname];
            }
            
//            cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:14.0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if ([Organization count] > 1) {
                if (self.isInit) {
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                } else {
                    [self addDisclosureIndicatorToCell:cell highlight:NO];
                }
                cell.userInteractionEnabled = YES;
            } else {
                if (self.isInit) {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                } else {
                    [self removeDisclosureIndicatorFromCell:cell];
                }
                cell.userInteractionEnabled = NO;
            }
        
            NSString *imageName = @"ProfileIcon.png";
            cell.imageView.image = [UIImage imageNamed:imageName];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@/is/%@?w=100&h=100", DOMAIN_URL, ORG_LOGO_API]]];
                
                if (data != nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIImage *logo = [UIImage imageWithData: data];
                        if (logo) {
                            cell.imageView.image = [UIImage imageWithData: data];
                            cell.imageView.frame = CGRectMake(3, 3, 37, 37);
                        }
                    });
                }
            });
        } else if (indexPath.row == kProfileOrg) {  // temporarily never show. in future, clicking the profileUser will toggle this cell
            cell.textLabel.text = self.currentOrg.name;
            cell.textLabel.font = [UIFont boldSystemFontOfSize:20.0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            if (self.isInit) {
                cell.accessoryType = UITableViewCellAccessoryNone;
            } else {
                [self removeDisclosureIndicatorFromCell:cell];
            }
            cell.userInteractionEnabled = NO;
            
            NSString *imageName = @"ProfileIcon.png";
            cell.imageView.image = [UIImage imageNamed:imageName];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@/is/%@?w=100&h=100", DOMAIN_URL, ORG_LOGO_API]]];            
                
                if (data != nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIImage *logo = [UIImage imageWithData: data];
                        if (logo) {
                            cell.imageView.image = [UIImage imageWithData: data];
                            cell.imageView.frame = CGRectMake(3, 3, 37, 37);
                        }
                    });
                }
            });
        }
    } else if (indexPath.section == self.rootMenu.count - 1) {
        NSString *menuName = [[self.rootMenu objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        menuName = [menuName stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSString *imageName = [menuName stringByAppendingString:@"Icon.png"];
        cell.imageView.image = [UIImage imageNamed:imageName];

        UIView *bgColorView = [[UIView alloc] init];
        [bgColorView setBackgroundColor:[UIColor colorWithRed:100/255.f green:100/255.f blue:100/255.f alpha:0.75]];
        cell.selectedBackgroundView = bgColorView;
        
        switch (indexPath.row) {
            case kMoreLogout:
            case kMoreLegal:
                cell.textLabel.text = [[self.rootMenu objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
                cell.textLabel.font = [UIFont systemFontOfSize:16.0];
                cell.userInteractionEnabled = YES;
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                
                if (self.isInit) {
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                } else {
                    [self addDisclosureIndicatorToCell:cell highlight:NO];
                }
                
                break;
            case kMoreShare:
            {
                if (!showShareOptions) {
                    cell.textLabel.text = [[self.rootMenu objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
                    cell.textLabel.font = [UIFont systemFontOfSize:16.0];
                } else {
                    cell.textLabel.text = nil;
                    
                    UIButton *emailShare = [[UIButton alloc] initWithFrame:CGRectMake(55.0, cell.frame.size.height/2 - 16.0, 32.0, 32.0)];
                    [emailShare setImage:[UIImage imageNamed:@"EmailShare.png"] forState:UIControlStateNormal];
                    [emailShare addTarget:self action:@selector(shareViaEmail:) forControlEvents:UIControlEventTouchUpInside];
                    emailShare.tag = kEmailShare;
                    [cell addSubview:emailShare];
                    
                    UIButton *messageShare = [[UIButton alloc] initWithFrame:CGRectMake(105.0, cell.frame.size.height/2 - 16.0, 32.0, 32.0)];
                    [messageShare setImage:[UIImage imageNamed:@"SMS.png"] forState:UIControlStateNormal];
                    [messageShare addTarget:self action:@selector(shareViaMessage:) forControlEvents:UIControlEventTouchUpInside];
                    messageShare.tag = kMessageShare;
                    [cell addSubview:messageShare];
                    
//                    UIButton *linkedInShare = [[UIButton alloc] initWithFrame:CGRectMake(135.0, cell.frame.size.height/2 - 15.0, 30.0, 30.0)];
//                    [linkedInShare setImage:[UIImage imageNamed:@"LinkedIn.png"] forState:UIControlStateNormal];
//                    [linkedInShare addTarget:self action:@selector(genBNCLink:) forControlEvents:UIControlEventTouchUpInside];
//                    linkedInShare.tag = kLinkedInShare;
//                    [cell addSubview:linkedInShare];
                    
                    UIButton *facebookShare = [[UIButton alloc] initWithFrame:CGRectMake(155.0, cell.frame.size.height/2 - 16.0, 32.0, 32.0)];
                    [facebookShare setImage:[UIImage imageNamed:@"Facebook.png"] forState:UIControlStateNormal];
                    [facebookShare addTarget:self action:@selector(shareViaFacebook:) forControlEvents:UIControlEventTouchUpInside];
                    facebookShare.tag = kFacebookShare;
                    [cell addSubview:facebookShare];
                    
                    UIButton *twitterShare = [[UIButton alloc] initWithFrame:CGRectMake(205.0, cell.frame.size.height/2 - 16.0, 32.0, 32.0)];
                    [twitterShare setImage:[UIImage imageNamed:@"Twitter.png"] forState:UIControlStateNormal];
                    [twitterShare addTarget:self action:@selector(shareViaTwitter:) forControlEvents:UIControlEventTouchUpInside];
                    twitterShare.tag = kTwitterShare;
                    [cell addSubview:twitterShare];
                }
                
                cell.userInteractionEnabled = YES;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
                break;
            case kMoreFeedback:
                cell.textLabel.text = [[self.rootMenu objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
                cell.textLabel.font = [UIFont systemFontOfSize:16.0];
                cell.userInteractionEnabled = YES;
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                
                if (self.isInit) {
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                } else {
                    [self addDisclosureIndicatorToCell:cell highlight:NO];
                }
                
                break;
            case kMoreVersion:
            {
                NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
                NSString* version = [infoDict objectForKey:@"CFBundleVersion"];
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(70, cell.frame.size.height/2 - 15.0, 200.0, 30.0)];
                label.text = [NSString stringWithFormat:self.rootMenu[indexPath.section][indexPath.row], version];
                label.textColor = [UIColor lightGrayColor];
                label.font = [UIFont systemFontOfSize:11.0];
                [cell addSubview:label];
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.userInteractionEnabled = NO;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
                break;
#ifdef LITE_VERSION
            case kMoreUpgrade:
                cell.textLabel.text = [[self.rootMenu objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
                cell.textLabel.font = [UIFont systemFontOfSize:15.0];
                cell.userInteractionEnabled = YES;
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                break;
#endif
            default:
                cell.userInteractionEnabled = NO;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                break;
        }
    } else {
//        if (indexPath.section != kRootMore - 1 || indexPath.row != kMoreVersion) {
            cell.textLabel.text = [[self.rootMenu objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            cell.textLabel.font = [UIFont systemFontOfSize:16.0];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            
            NSString *menuName = [[self.rootMenu objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            menuName = [menuName stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSString *imageName = [menuName stringByAppendingString:@"Icon.png"];
            cell.imageView.image = [UIImage imageNamed:imageName];
        
            if (self.isInit) {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            } else {
                [self addDisclosureIndicatorToCell:cell highlight:NO];
            }
            cell.userInteractionEnabled = YES;
            
            if ([[self.rootMenu[indexPath.section] lastObject] isEqualToString:CATEGORY_AP]) {
                if ([self.rootMenu[indexPath.section][indexPath.row] isEqualToString:MENU_APPROVE]) {
                    [cell addSubview:self.numBillsToApproveLabel];
                }
            }
//        }
        
        UIView *bgColorView = [[UIView alloc] init];
        [bgColorView setBackgroundColor:[UIColor colorWithRed:100/255.f green:100/255.f blue:100/255.f alpha:0.75]];
        cell.selectedBackgroundView = bgColorView;
    }
    
    return cell;
}

- (void)reloadShareRow {
    NSIndexPath *sharedRowIndexpath = [NSIndexPath indexPathForRow:kMoreShare inSection:self.rootMenu.count - 1];
    [self.menuTableView reloadRowsAtIndexPaths:@[sharedRowIndexpath] withRowAnimation:UITableViewRowAnimationLeft];
}

//- (void)genBNCLink:(UIButton *)sender {
//    __block RootMenuViewController *blockSafeSelf = self;
//    
//    Branch * branch = [Branch getInstance];
//    [branch getShortURLWithParams:[NSDictionary dictionaryWithObject:[Util getUserFullName]forKey:@"referrer"] andChannel:nil andFeature:nil andCallback:^(NSString *url, NSError *err) {
//        if (!err) {
//            switch (sender.tag) {
//                case kEmailShare:
//                    [blockSafeSelf shareViaEmail:url];
//                    break;
//                case kMessageShare:
//                    [blockSafeSelf shareViaMessage:url];
//                    break;
//                case kLinkedInShare:
//                    [blockSafeSelf shareViaLinkedIn:url];
//                    break;
//                case kFacebookShare:
//                    [blockSafeSelf shareViaFacebook:url];
//                    break;
//                case kTwitterShare:
//                    [blockSafeSelf shareViaTwitter:url];
//                    break;
//                default:
//                    break;
//            }
//        } else {
//            [UIHelper showInfo:err.localizedDescription withStatus:kError];
//            Error(@"%@", err.localizedDescription);
//        }
//    }];
//}

- (void)shareViaEmail:(UIButton *)sender {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailer = [UIAppDelegate getMailer];
        mailer.mailComposeDelegate = self;
        [mailer setSubject:[NSString stringWithFormat:@"%@ invites you to use Mobill iPhone app", [Util getUserFullName]]];

        NSString *emailBody = [NSString stringWithFormat:BNC_SHARE_MOBILL_EMAIL_TEMPLATE, @"https://itunes.apple.com/us/app/mobill-mobile-app-for-bill.com/id696521463?ls=1&mt=8", [Util getUserFirstName]];
        [mailer setMessageBody:emailBody isHTML:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:mailer animated:YES completion:nil];
        });
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failure"
                                                        message:@"Your device doesn't support the composer sheet"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        [alert show];
    }
    
//    [self reloadShareRow];
}

- (void)shareViaMessage:(UIButton *)sender {
    if ([MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController *sms = [[MFMessageComposeViewController alloc] init];
        sms.messageComposeDelegate = self;
        sms.body = [NSString stringWithFormat:BNC_SHARE_MOBILL_SMS_TEMPLATE, @"https://itunes.apple.com/us/app/mobill-mobile-app-for-bill.com/id696521463?ls=1&mt=8", [Util getUserFirstName]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:sms animated:YES completion:nil];
        });
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failure"
                                                        message:@"Your device doesn't support the SMS"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        [alert show];
    }
    
//    [self reloadShareRow];
}

- (void)shareViaLinkedIn:(UIButton *)sender {
    NSLog(@"=== share via linkedin");
    [self reloadShareRow];
}

- (void)shareViaFacebook:(UIButton *)sender {
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = [NSURL URLWithString:@"https://itunes.apple.com/us/app/mobill-mobile-app-for-bill.com/id696521463?ls=1&mt=8"];
    content.contentTitle = BNC_SHARE_SOCIAL_NAME;
    content.imageURL = [NSURL URLWithString:BNC_SHARE_SOCIAL_IMAGE_URL];
    content.contentDescription = BNC_SHARE_SOCIAL_DESCRIPTION;
    [FBSDKShareDialog showFromViewController:self
                                 withContent:content
                                    delegate:nil];
    
    
//    FBLinkShareParams *params = [[FBLinkShareParams alloc] init];
//    params.link = [NSURL URLWithString:url];
//    params.name = BNC_SHARE_SOCIAL_NAME;
//    params.caption = BNC_SHARE_SOCIAL_CAPTION;
//    params.picture = [NSURL URLWithString:BNC_SHARE_SOCIAL_IMAGE_URL];
//    
//    if ([FBDialogs canPresentShareDialogWithParams:params]) {
//        [FBDialogs presentShareDialogWithLink:params.link name:params.name
//                                      caption:params.caption
//                                  description:[NSString stringWithFormat:@"%@ %@", BNC_SHARE_SOCIAL_CAPTION, BNC_SHARE_SOCIAL_DESCRIPTION]
//                                      picture:params.picture clientState:nil
//                                      handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
//                                          if(error) {
//                                              Error(@"FB error publishing story: %@", error.description);
//                                          } else {
//                                              Debug(@"FB result %@", results);
//                                              [UIHelper showInfo:@"Shared to Facebook successfully. Thanks a lot!" withStatus:kSuccess];
//                                              [Util track:@"shared_app_via_facebook"];
//                                          }
//                                      }];
//    } else {
//        NSMutableDictionary *param = [NSMutableDictionary dictionaryWithObjectsAndKeys:
//                                           BNC_SHARE_SOCIAL_NAME, @"name",
//                                           BNC_SHARE_SOCIAL_CAPTION, @"caption",
//                                           BNC_SHARE_SOCIAL_DESCRIPTION, @"description",
//                                           url, @"link",
//                                           BNC_SHARE_SOCIAL_IMAGE_URL, @"picture",
//                                           nil];
//        
//        [FBWebDialogs presentFeedDialogModallyWithSession:nil
//                                               parameters:param
//                                                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
//                                                      if (error) {
//                                                          // An error occurred, we need to handle the error
//                                                          // See: https://developers.facebook.com/docs/ios/errors
//                                                          Error(@"Error publishing story: %@", error.description);
//                                                      } else {
//                                                          if (result == FBWebDialogResultDialogNotCompleted) {
//                                                              // User cancelled.
//                                                              Debug(@"User cancelled.");
//                                                          } else {
//                                                              // Handle the publish feed callback
//                                                              NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
//                                                              
//                                                              if (![urlParams valueForKey:@"post_id"]) {
//                                                                  // User cancelled.
//                                                                  Debug(@"User cancelled.");
//                                                                  
//                                                              } else {
//                                                                  // User clicked the Share button
//                                                                  [UIHelper showInfo:@"Shared to Facebook successfully. Thanks a lot!" withStatus:kSuccess];
//                                                                  [Util track:@"shared_app_via_facebook"];
//                                                              }
//                                                          }
//                                                      }
//                                                  }];
//    }
    
//    [self reloadShareRow];
}

// A function for parsing URL parameters returned by Facebook Feed Dialog.
- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return params;
}

- (void)initializeActivityIndicator {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.retrieveImageActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.retrieveImageActivityIndicator.frame = CGRectMake((SCREEN_WIDTH - 32) / 2, (SCREEN_HEIGHT - 32) / 2, 32, 32);
        self.retrieveImageActivityIndicator.hidesWhenStopped = YES;
    });
}

- (void)shareViaTwitter:(UIButton *)sender {
    SLComposeViewController *twitterController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        SLComposeViewControllerCompletionHandler completionHandler = ^(SLComposeViewControllerResult result) {
            [twitterController dismissViewControllerAnimated:YES completion:nil];
            switch(result){
                case SLComposeViewControllerResultDone:
                    [UIHelper showInfo:@"Shared to Twitter successfully. Thanks a lot!" withStatus:kSuccess];
                    [Util track:@"shared_app_via_twitter"];
                    break;
                case SLComposeViewControllerResultCancelled:
                default:
                    break;
            }
        };
        
        [self initializeActivityIndicator];
        [self.view addSubview:retrieveImageActivityIndicator];
        [self.retrieveImageActivityIndicator startAnimating];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString:BNC_SHARE_SOCIAL_FULL_IMG_URL]];
            if (data != nil) {
                UIImage *logo = [UIImage imageWithData: data];
                if (logo) {
                    [twitterController addImage:logo];
                }
            }
            
            [twitterController setInitialText:[NSString stringWithFormat:@"Mobill - an iPhone app to manage your Bill.com account\nGo mobile! Go Mobill~"]];
            [twitterController addURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/mobill-mobile-app-for-bill.com/id696521463?ls=1&mt=8"]];
            [twitterController setCompletionHandler:completionHandler];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.retrieveImageActivityIndicator stopAnimating];
                [self presentViewController:twitterController animated:YES completion:nil];
            });
        });
    } else {
        UIAlertView *alert_Dialog = [[UIAlertView alloc] initWithTitle:@"No Twitter Account"
                                                               message:@"Please install and login to Twitter app on this device."
                                                              delegate:nil cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil];
        [alert_Dialog show];
        alert_Dialog = nil;
    }
    
//    [self reloadShareRow];
}

- (void)addDisclosureIndicatorToCell:(UITableViewCell *)cell highlight:(BOOL)selected {
    UIView *oldIndicator;
    while((oldIndicator = [cell viewWithTag:CELL_DISCLOSURE_TAG]) != nil) {
        [oldIndicator removeFromSuperview];
    }
    
    NSString *imageName;
    if (selected) {
        imageName = @"disclosure_white.png";
    } else {
        imageName = @"disclosure_grey.png";
    }
    UIImageView *disclosure = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    disclosure.frame = CGRectMake(SLIDING_DISTANCE - 30, (cell.frame.size.height - 16) / 2, 16, 16);
    disclosure.tag = CELL_DISCLOSURE_TAG;
    [cell addSubview:disclosure];
}

- (void)removeDisclosureIndicatorFromCell:(UITableViewCell *)cell {
    for (UIView *view in cell.subviews) {
        if (view.tag == CELL_DISCLOSURE_TAG) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [view removeFromSuperview];
            });
            break;
        }
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL needRefreshDisclosureIndicator = YES;
    
    if (indexPath.section == kRootProfile && indexPath.row == kProfileUser && [Organization count] > 1) {
        [self performSegueWithIdentifier:[[self.rootMenu objectAtIndex:indexPath.section] objectAtIndex:indexPath.row + 1] sender:self];  // temp hack
    } else if ((indexPath.section == kRootProfile && indexPath.row == kProfileOrg) || (indexPath.section == self.rootMenu.count - 1 && indexPath.row == kMoreLogout)) {
        [self performSegueWithIdentifier:[[self.rootMenu objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] sender:self];
    } else if (indexPath.section == self.rootMenu.count - 1 && indexPath.row != kMoreLegal) {
//        SlidingViewController *currentVC = (SlidingViewController*)[RootMenuViewController sharedInstance].currVC;
//        [currentVC slideOutOnly];
        
        if (indexPath.row == kMoreShare) {
            self.showShareOptions = !self.showShareOptions;
            [self.menuTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
            needRefreshDisclosureIndicator = NO;
        } else if (indexPath.row == kMoreFeedback) {
            [self sendFeedbackEmail];
            needRefreshDisclosureIndicator = NO;
#ifdef LITE_VERSION
        } else if (indexPath.row == kMoreUpgrade) {
            [UIAppDelegate nagivateToAppStore];
            needRefreshDisclosureIndicator = NO;
#endif
        }
    } else {
        if (self.currentOrg.hasInbox || ![self.rootMenu[indexPath.section][indexPath.row] isEqualToString:MENU_INBOX]) {
            [self showView:[[self.rootMenu objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];
        } else {
            [UIHelper showInfo:@"You don't have permission to access Inbox." withStatus:kWarning];
            needRefreshDisclosureIndicator = NO;
            
            [self.rootMenu[kRootTool] removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(kToolInbox, 1)]];
            NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:kRootTool];
            [self.menuTableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
    
    if (needRefreshDisclosureIndicator) {
        UITableViewCell *cell;
        if (self.isInit) {
            self.isInit = NO;
            [self.menuTableView reloadData];
        } else {
            cell = [self.menuTableView cellForRowAtIndexPath:self.lastSelected];
            [self addDisclosureIndicatorToCell:cell highlight:NO];
        }
        
        cell = [self.menuTableView cellForRowAtIndexPath:indexPath];
        [self addDisclosureIndicatorToCell:cell highlight:YES];
        self.lastSelected = indexPath;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == kRootProfile) {
        return 0;
    } else {
        return ROOT_MENU_SECTION_HEADER_HEIGHT;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == kRootProfile) {
        return nil;
    } else {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, ROOT_MENU_SECTION_HEADER_HEIGHT)];
        headerView.backgroundColor = [UIColor darkGrayColor];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 3, 250, 15)];
        label.text = [[self.rootMenu objectAtIndex:section] lastObject];
        [UIHelper initializeHeaderLabel:label];
        
        [headerView addSubview:label];
        return headerView;
    }
}

#pragma mark - Sliding View delegate

- (void)viewDidSlideOut {
    [self.currVC slideIn];
}

#pragma mark - Feedback email

- (void)sendFeedbackEmail {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        mailer.mailComposeDelegate = self;
        
//        Organization *org = [Organization getSelectedOrg];
        NSString *subject;
#ifndef LITE_VERSION
        subject = @"Feedback on Mobill from %@";
#else
        subject = @"Feedback on Mobill Lite from %@";
#endif
        [mailer setSubject:[NSString stringWithFormat:subject, self.currentOrg.name]];
        
        NSArray *toRecipients = [NSArray arrayWithObjects:@"customer.mobill@gmail.com", nil];
        [mailer setToRecipients:toRecipients];
        
        [self presentViewController:mailer animated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failure"
                                                        message:@"Your device doesn't support the composer sheet"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        [alert show];
    }
}

#pragma mark - MailComposer delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    switch (result){
        case MFMailComposeResultSent:
            [UIHelper showInfo:@"Email sent successfully. Thanks a lot!" withStatus:kSuccess];
            [Util track:@"shared_app_via_email"];
            break;
        case MFMailComposeResultCancelled:
            break;
        case MFMailComposeResultSaved:
            break;
        case MFMailComposeResultFailed:
            [UIHelper showInfo: EMAIL_FAILED withStatus:kFailure];
            break;
        default:
            break;
    }
    
    // Remove the mail view
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

#pragma mark - MessageComposer delegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    switch (result) {
        case MessageComposeResultSent:
            [UIHelper showInfo:@"Message sent successfully. Thanks a lot!" withStatus:kSuccess];
            [Util track:@"shared_app_via_sms"];
            break;
        case MessageComposeResultCancelled:
            break;
        case MessageComposeResultFailed:
        default:
            [UIHelper showInfo:SMS_FAILED withStatus:kFailure];
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - User delegate

- (void)didGetUserInfo {
    NSIndexPath *path = [NSIndexPath indexPathForRow:kProfileUser inSection:kRootProfile];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.menuTableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

#pragma mark - List delegates

- (void)deeplinkRedirect {
    if (UIAppDelegate.bncDeeplinkObjId && [UIAppDelegate.bncDeeplinkObjId length] > 3) {
        NSString *prefix = [UIAppDelegate.bncDeeplinkObjId substringToIndex:3];
        if ([@"00n" isEqualToString:prefix]) {
            if (self.gotBills) {
                [self didGetBills:nil]; //nil argument doesn't matter here
            } else {
                [Bill setListDelegate:self];
            }
        } else if ([@"00e" isEqualToString:prefix]) {
            if (self.gotInvoices) {
                [self didGetInvoices:nil];
            } else {
                [Invoice setListDelegate:self];
            }
        } else if ([@"009" isEqualToString:prefix]) {
            if (self.gotVendors) {
                [self didGetVendors];
            } else {
                [Vendor setListDelegate:self];
            }
        } else if ([@"0cu" isEqualToString:prefix]) {
            if (self.gotCustomers) {
                [self didGetCustomers];
            } else {
                [Customer setListDelegate:self];
            }
        } else if ([@"0ii" isEqualToString:prefix]) {
            if (self.gotItems) {
                [self didGetItems];
            } else {
                [Item setListDelegate:self];
            }
        } else if ([@"cpu" isEqualToString:prefix]) {
            if (self.gotContacts) {
                [self didGetContacts];
            } else {
                [CustomerContact setListDelegate:self];
            }
        }
    }
}

- (void)didGetBills:(NSArray *)billList {
    self.gotBills = YES;
    BDCBusinessObject *busObj = [Bill loadWithId:UIAppDelegate.bncDeeplinkObjId];
    if (busObj) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showView:MENU_BILLS];
            [[self slideInListViewIdentifier:MENU_BILLS] performSegueWithIdentifier:@"ViewBill" sender:(Bill *)busObj];
        });
    }
    
    UIAppDelegate.bncDeeplinkObjId = nil;
}

- (void)didGetInvoices:(NSArray *)invoiceList {
    self.gotInvoices = YES;
    BDCBusinessObject *busObj = [Invoice loadWithId:UIAppDelegate.bncDeeplinkObjId];
    if (busObj) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showView:MENU_INVOICES];
            [[self slideInListViewIdentifier:MENU_INVOICES] performSegueWithIdentifier:@"ViewInvoice" sender:(Invoice *)busObj];
        });
    }
    
    UIAppDelegate.bncDeeplinkObjId = nil;
}

- (void)didGetVendors {
    self.gotVendors = YES;
    BDCBusinessObject *busObj = [Vendor loadWithId:UIAppDelegate.bncDeeplinkObjId];
    if (busObj) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showView:MENU_VENDORS];
            [[self slideInListViewIdentifier:MENU_VENDORS] performSegueWithIdentifier:@"ViewVendor" sender:(Vendor *)busObj];
        });
    }
    
    UIAppDelegate.bncDeeplinkObjId = nil;
}

- (void)didGetCustomers {
    self.gotCustomers = YES;
    BDCBusinessObject *busObj = [Customer loadWithId:UIAppDelegate.bncDeeplinkObjId];
    if (busObj) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showView:MENU_CUSTOMERS];
            [[self slideInListViewIdentifier:MENU_CUSTOMERS] performSegueWithIdentifier:@"ViewCustomer" sender:(Customer *)busObj];
        });
    }
    
    UIAppDelegate.bncDeeplinkObjId = nil;
}

- (void)didGetItems {
    self.gotItems = YES;
    BDCBusinessObject *busObj = [Item loadWithId:UIAppDelegate.bncDeeplinkObjId];
    if (busObj) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showView:MENU_ITEMS];
            [[self slideInListViewIdentifier:MENU_ITEMS] performSegueWithIdentifier:@"ViewItem" sender:(Item *)busObj];
        });
    }
    
    UIAppDelegate.bncDeeplinkObjId = nil;
}

- (void)didGetContacts {
    self.gotContacts = YES;
    CustomerContact *contact = (CustomerContact*)[CustomerContact loadWithId:UIAppDelegate.bncDeeplinkObjId];
    if (contact) {
        Customer *customer = (Customer *)[Customer loadWithId:contact.customerId];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showView:MENU_CUSTOMERS];
            CustomersTableViewController *customerListVC = (CustomersTableViewController*)[self slideInListViewIdentifier:MENU_CUSTOMERS];
            [customerListVC navigateToCustomer:customer contact:contact];
        });
    }
    
    UIAppDelegate.bncDeeplinkObjId = nil;
}

- (void)didGetDocuments {
    //TODO
}

- (void)didGetAccounts {}

- (void)failedToGetBills {}
- (void)didGetBillsToApprove:(NSMutableArray *)bills {}
- (void)failedToGetBillsToApprove {}
- (void)failedToGetVendors {}
- (void)failedToGetAccounts {}
- (void)failedToGetInvoices {}
- (void)failedToGetCustomers {}
- (void)failedToGetItems {}
- (void)failedToGetContacts {}
- (void)failedToGetDocuments {}

- (void)deniedPermissionForBills {
//    @synchronized(self.rootMenu) {
//        self.currentOrg.showAP = NO;
//        self.currentOrg.enableAP = NO;
//        self.currentOrg.canPay = NO;
//        [self.rootMenu[kRootAP] removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(kAPBill, 2)]];
//        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:kRootAP];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.menuTableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
//        });
//    }
}

- (void)deniedPermissionForInvoices {
//    @synchronized(self.rootMenu) {
//        self.currentOrg.showAR = NO;
//        self.currentOrg.enableAR = NO;
//        [self.rootMenu[kRootAR] removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.currentOrg.enableAR ? 3 : 2)]];
//        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:kRootAR];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.menuTableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
//        });
//    }
}

- (void)deniedPermissionForApproval {
    self.currentOrg.canApprove = NO;
    
//    @synchronized(self.rootMenu) {
//        self.currentOrg.canApprove = NO;
//        NSUInteger idx;
//        if ([self.rootMenu[kRootAR] count] > 1) {
//            idx = kAPApprove;
//        } else {
//            idx = 0;
//        }
//        [self.rootMenu[kRootAP] removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(idx, 1)]];
//        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:kRootAP];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.menuTableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
//        });
//    }
}

- (void)deniedPermissionForInbox {
    self.currentOrg.hasInbox = NO;
    
//    if ([self.rootMenu[kRootTool][kToolInbox] isEqualToString:MENU_INBOX]) {
//        [self.rootMenu[kRootTool] removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(kToolInbox, 1)]];
//        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:kRootTool];
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.menuTableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
//        });
//    }
}

- (void)deniedPermissionForAttachments {
    
}

@end
