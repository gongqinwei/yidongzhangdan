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
#import "Util.h"
#import "UIHelper.h"
#import <MessageUI/MessageUI.h>

#define ROOT_MENU_SECTION_HEADER_HEIGHT     22
#define ROOT_MENU_CELL_ID                   @"RootMenuItem"

@interface RootMenuViewController () <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) Organization *currentOrg;
@property (nonatomic, strong) NSMutableArray *rootMenu;

@end


@implementation RootMenuViewController

@synthesize currentOrg;
@synthesize rootMenu;
@synthesize menuTableView;
@synthesize currVC;
@synthesize menuItems;

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
    
    self.currentOrg = [Organization getSelectedOrg];
    
    self.rootMenu = [NSMutableArray array];
    [self.rootMenu addObject:[ROOT_MENU objectAtIndex:kRootProfile]];   // always + Profile/ChangeOrg section
        
    if (!self.currentOrg.showAR && !self.currentOrg.enableAP) {
        // Profile + More (theoretically should never happen - can't login)
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
    
    [self.rootMenu addObject:[ROOT_MENU objectAtIndex:kRootMore]];      // always + More section
    
    
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
    
    if (self.currentOrg.enableAP) {
        [Bill retrieveListForActive:YES reload:YES];
        [Vendor retrieveListForActive:YES];
        [ChartOfAccount retrieveListForActive:YES];
        [Approver retrieveList];
        [Bill retrieveListForApproval];
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
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.backgroundColor = [UIColor clearColor];
    
    if (indexPath.section == kRootProfile) {
        if (indexPath.row == kProfileUser) {    // temporarily same as profile org. will change to user name/email once BDC API implemented
            cell.textLabel.text = self.currentOrg.name;
            cell.textLabel.font = [UIFont boldSystemFontOfSize:20.0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if ([Organization count] > 1) {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.userInteractionEnabled = YES;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
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
            cell.accessoryType = UITableViewCellAccessoryNone;
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
    } else {
        cell.textLabel.text = [[self.rootMenu objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        NSString *menuName = [[self.rootMenu objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        menuName = [menuName stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSString *imageName = [menuName stringByAppendingString:@"Icon.png"];
        cell.imageView.image = [UIImage imageNamed:imageName];
        cell.textLabel.font = [UIFont systemFontOfSize:17.0];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.userInteractionEnabled = YES;
        
        UIView *bgColorView = [[UIView alloc] init];
        [bgColorView setBackgroundColor:[UIColor colorWithRed:100/255.f green:100/255.f blue:100/255.f alpha:0.75]];
        cell.selectedBackgroundView = bgColorView;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kRootProfile && indexPath.row == kProfileUser && [Organization count] > 1) {
        [self performSegueWithIdentifier:[[self.rootMenu objectAtIndex:indexPath.section] objectAtIndex:indexPath.row + 1] sender:self];  // temp hack
    } else if ((indexPath.section == kRootProfile && indexPath.row == kProfileOrg) || (indexPath.section == self.rootMenu.count - 1 && indexPath.row == kMoreLogout)) {
        [self performSegueWithIdentifier:[[self.rootMenu objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] sender:self];
    } else if (indexPath.section == self.rootMenu.count - 1 && indexPath.row == kMoreFeedback) {
        SlidingViewController *currentVC = (SlidingViewController*)[RootMenuViewController sharedInstance].currVC;
        [currentVC slideOutOnly];
        [self sendFeedbackEmail];
    } else {
        [self showView:[[self.rootMenu objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];
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

@end
