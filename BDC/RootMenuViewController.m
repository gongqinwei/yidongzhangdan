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
#import "Organization.h"
#import "Invoice.h"
#import "Customer.h"
#import "CustomerContact.h"
#import "Item.h"
#import "Bill.h"
#import "Vendor.h"
#import "Approver.h"
#import "ChartOfAccount.h"
#import "Document.h"
#import "BankAccount.h"
#import "User.h"
#import "Util.h"
#import "UIHelper.h"
#import "TutorialControl.h"
#import "BDCAppDelegate.h"
#import "Branch.h"
#import <MessageUI/MessageUI.h>
#import <FacebookSDK/FacebookSDK.h>

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

@interface RootMenuViewController () <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, BillListDelegate, UserDelegate>

@property (nonatomic, strong) Organization *currentOrg;
@property (nonatomic, strong) NSMutableArray *rootMenu;
@property (nonatomic, strong) TutorialControl *rootMenuTutorialOverlay;

@property (nonatomic, assign) BOOL isInit;  // no slided vc edge on root menu: show build-in disclosure indicator
@property (nonatomic, strong) NSIndexPath *lastSelected;
@property (nonatomic, assign) BOOL showShareOptions;
@property (nonatomic, assign) ShareOption shareOption;

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
        
    if (!self.currentOrg.showAR && !self.currentOrg.enableAP) {
        // Profile + More (theoretically should never happen - can't login)
        [UIHelper showInfo:@"This company has no AR and disabled AP!\n\nPlease enable them in Bill.com first." withStatus:kWarning];
    } else {
        if (self.currentOrg.enableAP || self.currentOrg.enableAR) {
            [self.rootMenu addObject:[ROOT_MENU objectAtIndex:kRootTool]];  // + Documents section
        }
        
        if (self.currentOrg.enableAP) {
            [self.rootMenu addObject:[ROOT_MENU objectAtIndex:kRootAP]];    // + AP section
        }
        
        if (self.currentOrg.enableAR) {
            [self.rootMenu addObject:[ROOT_MENU objectAtIndex:kRootAR]];    // + AR section
        } else {
            [self.rootMenu addObject:[ROOT_MENU objectAtIndex:kRootARReadonly]];    // + AR Readonly section
        }
    }
    
    [self.rootMenu addObject:[ROOT_MENU objectAtIndex:kRootMore]];          // always + More section
    
    self.menuTableView.dataSource = self;
    self.menuTableView.delegate = self;
    
    self.menuItems = [NSMutableDictionary dictionary];
    
    for (int i = 1; i < [ROOT_MENU count]; i++) {
        for (int j = 0; j < [[ROOT_MENU objectAtIndex:i] count] - 1; j++) {
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
    
    
    [Bill resetList];
    [Invoice resetList];
    [Vendor resetList];
    [Customer resetList];
    [Item resetList];
    [Document resetList];
    [CustomerContact resetList];
    [ChartOfAccount resetList];
    [BankAccount resetList];
    
    
//    [Bill setListForApprovalDelegate:self];
    
    
    if (self.currentOrg.enableAP) {
        [Bill retrieveListForActive:YES reload:YES];
        [Vendor retrieveListForActive:YES];
        [ChartOfAccount retrieveListForActive:YES];
        [Approver retrieveList];
        [Bill retrieveListForApproval:nil];
        [self.currentOrg getOrgPrefs];
    }

    [Invoice retrieveListForActive:YES reload:YES];
    [Customer retrieveListForActive:YES];
    
    if (self.currentOrg.enableAP || self.currentOrg.enableAR) {
        [Item retrieveList];
    }
    
    [CustomerContact retrieveListForActive:YES];
    
    if (self.currentOrg.enableAP || self.currentOrg.enableAR) {
        [Document retrieveListForCategory:FILE_CATEGORY_DOCUMENT];
    }
    
    [Invoice retrieveListForActive:NO reload:NO];
    [Customer retrieveListForActive:NO];
    
    if (self.currentOrg.enableAP) {
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
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@/%@?w=100&h=100", DOMAIN_URL, ORG_LOGO_API]]];
                
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
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@/%@?w=100&h=100", DOMAIN_URL, ORG_LOGO_API]]];            
                
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
    } else if (indexPath.section == kRootMore - 1) {        //kRootMore - 1 is for skipping ARRootReadOnly
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
                    showShareOptions = YES;
                } else {
                    cell.textLabel.text = nil;
                    
                    UIButton *emailShare = [[UIButton alloc] initWithFrame:CGRectMake(55.0, cell.frame.size.height/2 - 15.0, 30.0, 30.0)];
                    [emailShare setImage:[UIImage imageNamed:@"ImailShare.png"] forState:UIControlStateNormal];
                    [emailShare addTarget:self action:@selector(genBNCLink:) forControlEvents:UIControlEventTouchUpInside];
                    emailShare.tag = kEmailShare;
                    [cell addSubview:emailShare];
                    
                    UIButton *messageShare = [[UIButton alloc] initWithFrame:CGRectMake(95.0, cell.frame.size.height/2 - 15.0, 30.0, 30.0)];
                    [messageShare setImage:[UIImage imageNamed:@"MessageShare.png"] forState:UIControlStateNormal];
                    [messageShare addTarget:self action:@selector(genBNCLink:) forControlEvents:UIControlEventTouchUpInside];
                    messageShare.tag = kMessageShare;
                    [cell addSubview:messageShare];
                    
                    UIButton *linkedInShare = [[UIButton alloc] initWithFrame:CGRectMake(135.0, cell.frame.size.height/2 - 15.0, 30.0, 30.0)];
                    [linkedInShare setImage:[UIImage imageNamed:@"LinkedInShare.png"] forState:UIControlStateNormal];
                    [linkedInShare addTarget:self action:@selector(genBNCLink:) forControlEvents:UIControlEventTouchUpInside];
                    linkedInShare.tag = kLinkedInShare;
                    [cell addSubview:linkedInShare];
                    
                    UIButton *facebookShare = [[UIButton alloc] initWithFrame:CGRectMake(175.0, cell.frame.size.height/2 - 15.0, 30.0, 30.0)];
                    [facebookShare setImage:[UIImage imageNamed:@"FacebookShare.png"] forState:UIControlStateNormal];
                    [facebookShare addTarget:self action:@selector(genBNCLink:) forControlEvents:UIControlEventTouchUpInside];
                    facebookShare.tag = kFacebookShare;
                    [cell addSubview:facebookShare];
                    
                    UIButton *twitterShare = [[UIButton alloc] initWithFrame:CGRectMake(215.0, cell.frame.size.height/2 - 15.0, 30.0, 30.0)];
                    [twitterShare setImage:[UIImage imageNamed:@"TwitterShare.png"] forState:UIControlStateNormal];
                    [twitterShare addTarget:self action:@selector(genBNCLink:) forControlEvents:UIControlEventTouchUpInside];
                    twitterShare.tag = kTwitterShare;
                    [cell addSubview:twitterShare];
                    
                    showShareOptions = NO;
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
        if (indexPath.section != kRootMore - 1 || indexPath.row != kMoreVersion) {
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
            
            if (indexPath.section == kRootAP && indexPath.row == kAPApprove) {
                [cell addSubview:self.numBillsToApproveLabel];
            }
        }
        
        UIView *bgColorView = [[UIView alloc] init];
        [bgColorView setBackgroundColor:[UIColor colorWithRed:100/255.f green:100/255.f blue:100/255.f alpha:0.75]];
        cell.selectedBackgroundView = bgColorView;
    }
    
    return cell;
}

- (void)reloadShareRow {
    NSIndexPath *sharedRowIndexpath = [NSIndexPath indexPathForRow:kMoreShare inSection:kRootMore - 1];
    [self.menuTableView reloadRowsAtIndexPaths:@[sharedRowIndexpath] withRowAnimation:UITableViewRowAnimationLeft];
}

- (void)genBNCLink:(UIButton *)sender {
    __block RootMenuViewController *blockSafeSelf = self;
    
    Branch * branch = [Branch getInstance];
    [branch getShortURLWithParams:[NSDictionary dictionaryWithObject:[Util getUserFullName]forKey:@"referrer"] andChannel:nil andFeature:nil andCallback:^(NSString *url) {
        switch (sender.tag) {
            case kEmailShare:
                [blockSafeSelf shareViaEmail:url];
                break;
            case kMessageShare:
                [blockSafeSelf shareViaMessage:url];
                break;
            case kLinkedInShare:
                [blockSafeSelf shareViaLinkedIn:url];
                break;
            case kFacebookShare:
                [blockSafeSelf shareViaFacebook:url];
                break;
            case kTwitterShare:
                [blockSafeSelf shareViaTwitter:url];
                break;
            default:
                break;
        }
    }];
}

- (void)shareViaEmail:(NSString *)url {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailer = [UIAppDelegate getMailer];
        mailer.mailComposeDelegate = self;
        [mailer setSubject:[NSString stringWithFormat:@"%@ invites you to use Mobill iPhone app", [Util getUserFullName]]];

        NSString *emailBody = [NSString stringWithFormat:BNC_SHARE_MOBILL_EMAIL_TEMPLATE, url, [Util getUserFirstName]];
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
    
    [self reloadShareRow];
}

- (void)shareViaMessage:(NSString *)url {
    if ([MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController *sms = [[MFMessageComposeViewController alloc] init];
        sms.messageComposeDelegate = self;
        sms.body = [NSString stringWithFormat:BNC_SHARE_MOBILL_SMS_TEMPLATE, url, [Util getUserFirstName]];
        
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
    
    [self reloadShareRow];
}

- (void)shareViaLinkedIn:(NSString *)url {
    NSLog(@"=== share via linkedin");
    [self reloadShareRow];
}

- (void)shareViaFacebook:(NSString *)url {
    FBLinkShareParams *params = [[FBLinkShareParams alloc] init];
    params.link = [NSURL URLWithString:url];
    params.name = @"Mobill - mobile app for Bill.com";
    params.caption = @"Mobill - mobile app for Bill.com";
    params.picture = [NSURL URLWithString:@"https://www.dropbox.com/s/wv8l5g2cojq7fst/Mobill_logo120.png?dl=1"];
    
    if ([FBDialogs canPresentShareDialogWithParams:params]) {
//        [FBDialogs presentShareDialogWithParams:params clientState:nil
        [FBDialogs presentShareDialogWithLink:params.link name:params.name caption:params.caption description:BNC_SHARE_SOCIAL_DESCRIPTION picture:params.picture clientState:nil
                                      handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                          if(error) {
                                              Error(@"FB error publishing story: %@", error.description);
                                          } else {
                                              Debug(@"FB result %@", results);
                                          }
                                      }];
    } else {
        NSMutableDictionary *param = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           @"Mobill - mobile app for Bill.com", @"name",
                                           @"Mobill - mobile app for Bill.com.", @"caption",
                                           BNC_SHARE_SOCIAL_DESCRIPTION, @"description",
                                           url, @"link",
                                           @"https://www.dropbox.com/s/wv8l5g2cojq7fst/Mobill_logo120.png?dl=1", @"picture",
                                           nil];
        
        [FBWebDialogs presentFeedDialogModallyWithSession:nil
                                               parameters:param
                                                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                      if (error) {
                                                          // An error occurred, we need to handle the error
                                                          // See: https://developers.facebook.com/docs/ios/errors
                                                          Error(@"Error publishing story: %@", error.description);
                                                      } else {
                                                          if (result == FBWebDialogResultDialogNotCompleted) {
                                                              // User cancelled.
                                                              Debug(@"User cancelled.");
                                                          } else {
//                                                              // Handle the publish feed callback
//                                                              NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
//                                                              
//                                                              if (![urlParams valueForKey:@"post_id"]) {
//                                                                  // User cancelled.
//                                                                  NSLog(@"User cancelled.");
//                                                                  
//                                                              } else {
//                                                                  // User clicked the Share button
//                                                                  NSString *result = [NSString stringWithFormat: @"Posted story, id: %@", [urlParams valueForKey:@"post_id"]];
//                                                                  NSLog(@"result %@", result);
//                                                              }
                                                          }
                                                      }
                                                  }];
    }
    
    [self reloadShareRow];
}

- (void)shareViaTwitter:(NSString *)url {
    NSLog(@"=== share via twitter");
    [self reloadShareRow];
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
            [self.menuTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
            needRefreshDisclosureIndicator = NO;
        } else if (indexPath.row == kMoreFeedback) {
            [self sendFeedbackEmail];
#ifdef LITE_VERSION
        } else if (indexPath.row == kMoreUpgrade) {
            [UIAppDelegate nagivateToAppStore];
            needRefreshDisclosureIndicator = NO;
#endif
        }
    } else {
        [self showView:[[self.rootMenu objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];
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
        [mailer setSubject:[NSString stringWithFormat:@"Feedback on Mobill app from %@", self.currentOrg.name]];
        
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
            [UIHelper showInfo:SMS_SENT withStatus:kSuccess];
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

@end
