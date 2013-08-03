//
//  RootMenuViewController.m
//  BDC
//
//  Created by Qinwei Gong on 10/16/12.
//
//

#import "RootMenuViewController.h"
#import "SelectOrgViewController.h"
//#import "AROverViewController.h"
#import "InvoicesTableViewController.h"
#import "Organization.h"
#import "Invoice.h"
#import "Customer.h"
#import "Item.h"
#import "Bill.h"
#import "Vendor.h"
#import "ChartOfAccount.h"
#import "Document.h"
#import "Util.h"
#import "UIHelper.h"
#import <MessageUI/MessageUI.h>

#define ROOT_MENU_SECTION_HEADER_HEIGHT     22
#define ROOT_MENU_CELL_ID                   @"RootMenuItem"

@interface RootMenuViewController () <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate>

@end


@implementation RootMenuViewController

@synthesize menuTableView;
@synthesize currVC;
@synthesize menuItems;

static RootMenuViewController * _sharedInstance = nil;

+ (RootMenuViewController *)sharedInstance {
    return _sharedInstance;
}

- (UINavigationController *)showView:(NSString *)identifier {
    identifier = [identifier stringByReplacingOccurrencesOfString:@" " withString:@""];
        
    if (!self.currVC) {
        UINavigationController *navVC = [self.menuItems objectForKey:identifier];
        self.currVC = [navVC.childViewControllers objectAtIndex:0];
        self.currVC.navigation = navVC;
        self.currVC.navigationId = identifier;
        [self.currVC slideIn];
    } else if ([self.currVC.navigationId isEqualToString:identifier]) {
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
        
    self.menuTableView.dataSource = self;
    self.menuTableView.delegate = self;
    
    self.menuItems = [NSMutableDictionary dictionary];
    
    for (int i = 0; i < [ROOT_MENU count]; i++) {
        for (int j = 0; j < [[ROOT_MENU objectAtIndex:i] count] - 1; j++) {
            if (i != kRootMore || j == kMoreLegal) {
                NSString *vcID = [[ROOT_MENU objectAtIndex:i] objectAtIndex:j];
                vcID = [vcID stringByReplacingOccurrencesOfString:@" " withString:@""];
                UINavigationController *navVC = [self.storyboard instantiateViewControllerWithIdentifier:vcID];
                [self.menuItems setObject:navVC forKey:vcID];
                [UIHelper adjustScreen:navVC];
            }
        }
    }
    
    //start with Invoices view
//    NSString *startingVCId = MENU_INVOICES;
//    UINavigationController *navVC = [self.menuItems objectForKey:startingVCId];
//    [self.view addSubview:navVC.view];
//    
//    self.currVC = [navVC.childViewControllers objectAtIndex:0];
//    self.currVC.navigation = navVC;
//    self.currVC.navigationId = startingVCId;
//    
//    NSIndexPath * initIndexPath = [NSIndexPath indexPathForRow:kARInvoice inSection:kRootAR];
//    [self.menuTableView selectRowAtIndexPath:initIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    
////    [Invoice setARDelegate:(AROverViewController *)self.currVC];  //assumption: currVC is AROverViewController.
    
    [Invoice retrieveListForActive:YES reload:YES];
    [ChartOfAccount retrieveList];
    [Bill retrieveListForActive:YES reload:YES];
    [Customer retrieveList];
    [Vendor retrieveList];
    [Document retrieveListForCategory:FILE_CATEGORY_DOCUMENT];
    [Item retrieveList];
    [Invoice retrieveListForActive:NO reload:NO];
    [Bill retrieveListForActive:NO reload:NO];
//    [Document retrieveListForCategory:FILE_CATEGORY_ATTACHMENT];
    
    _sharedInstance = self;
    
//    CGRect tempFrame = self.view.frame;
//    tempFrame.size.width = SLIDING_DISTANCE;
//    [UIView beginAnimations:@"" context:nil];
//    [UIView setAnimationDuration:0.2];
//    self.view.frame = tempFrame;
//    [UIView commitAnimations];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:MENU_ORGS]) {
        [(SelectOrgViewController *)segue.destinationViewController setIsInitialLogin:NO];
    } else if ([segue.identifier isEqualToString:MENU_LOGOUT]) {
        [Util logout];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [ROOT_MENU count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[ROOT_MENU objectAtIndex:section] count] - 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = ROOT_MENU_CELL_ID;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        cell.textLabel.text = [Organization getSelectedOrg].name;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:20.0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.userInteractionEnabled = NO;
        
        NSString *imageName = @"ProfileIcon.png";
        cell.imageView.image = [UIImage imageNamed:imageName];

        dispatch_async(dispatch_get_global_queue(0,0), ^{
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
    } else {
        cell.textLabel.text = [[ROOT_MENU objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        NSString *menuName = [[ROOT_MENU objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
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
    if (indexPath.section == kRootMore) {
        if (indexPath.row == kMoreOrgs || indexPath.row == kMoreLogout) {
            [self performSegueWithIdentifier:[[ROOT_MENU objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] sender:self];
        } else if (indexPath.row == kMoreLegal) {
            [self showView:[[ROOT_MENU objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];
        } else if (indexPath.row == kMoreFeedback) {
            [self sendFeedbackEmail];
        }
    } else if (indexPath.section != 0 || indexPath.row != 0) {
        [self showView:[[ROOT_MENU objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];
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
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 3, 200, 15)];
        label.text = [[ROOT_MENU objectAtIndex:section] lastObject];
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
        
        Organization *org = [Organization getSelectedOrg];
        [mailer setSubject:[NSString stringWithFormat:@"Feedback on MoBill iPhone app from %@", org.name]];
        
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
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
