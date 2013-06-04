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

#define ROOT_MENU_SECTION_HEADER_HEIGHT     22
#define ROOT_MENU_CELL_ID                   @"RootMenuItem"

@interface RootMenuViewController () <UITableViewDataSource, UITableViewDelegate>

//- (void)showView:(NSString *)identifier;

@end

@implementation RootMenuViewController

@synthesize menuTableView;
@synthesize currVC;
@synthesize menuItems;

static RootMenuViewController * _sharedInstance = nil;

+ (RootMenuViewController *)sharedInstance
{
    return _sharedInstance;
}

- (UINavigationController *)showView:(NSString *)identifier {
    if ([self.currVC.navigationId isEqualToString:identifier]) {
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
    
    //start with Invoices view
    NSString *startingVCId = MENU_INVOICES;
    
    for (int i = 0; i < [ROOT_MENU count] - 1; i++) {
        for (int j = 0; j < [[ROOT_MENU objectAtIndex:i] count] - 1; j++) {
            NSString *vcID = [[ROOT_MENU objectAtIndex:i] objectAtIndex:j];
            UINavigationController *navVC = [self.storyboard instantiateViewControllerWithIdentifier:vcID];
            [self.menuItems setObject:navVC forKey:vcID];
            
//            if (![vcID isEqualToString:startingVCId]) {
                [UIHelper adjustScreen:navVC];
//            }
        }
    }
    
    UINavigationController *navVC = [self.menuItems objectForKey:startingVCId];
    [self.view addSubview:navVC.view];
    
    self.currVC = [navVC.childViewControllers objectAtIndex:0];
    self.currVC.navigation = navVC;
    self.currVC.navigationId = startingVCId;
    
    NSIndexPath * initIndexPath = [NSIndexPath indexPathForRow:0 inSection:2];
    [self.menuTableView selectRowAtIndexPath:initIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            
//    [Invoice setARDelegate:(AROverViewController *)self.currVC];  //assumption: currVC is AROverViewController.
    
    [Invoice retrieveListForActive:YES];
    [Customer retrieveList];
    [Item retrieveList];
    
    [Bill retrieveList];
    [Vendor retrieveList];
    [ChartOfAccount retrieveList];
    
    [Document retrieveListForCategory:FILE_CATEGORY_DOCUMENT];
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
    if ([segue.identifier isEqualToString:@"Organizations"]) {
        [(SelectOrgViewController *)segue.destinationViewController setIsInitialLogin:NO];
    } else if ([segue.identifier isEqualToString:@"LogOut"]) {
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
        cell.selectionStyle = UITableViewCellEditingStyleNone;
        cell.userInteractionEnabled = NO;
        
        NSString *imageName = @"ProfileIcon.png";               //TODO: use a default org icon to replace
        cell.imageView.image = [UIImage imageNamed:imageName];
        
//        NSData * imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@/%@?w=100&h=100", DOMAIN_URL, ORG_LOGO_API]]];
//        cell.imageView.image = [UIImage imageWithData: imageData];

        dispatch_async(dispatch_get_global_queue(0,0), ^{
            NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@/%@?w=100&h=100", DOMAIN_URL, ORG_LOGO_API]]];

            if (data != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    cell.imageView.image = [UIImage imageWithData: data];
                    cell.imageView.frame = CGRectMake(3, 3, 37, 37);
                });
            }
        });
    } else {
        cell.textLabel.text = [[ROOT_MENU objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        NSString *imageName = [[[ROOT_MENU objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] stringByAppendingString:@"Icon.png"];
        cell.imageView.image = [UIImage imageNamed:imageName];
        
        UIView *bgColorView = [[UIView alloc] init];
        [bgColorView setBackgroundColor:[UIColor colorWithRed:100/255.f green:100/255.f blue:100/255.f alpha:0.75]];
//        [cell setSelectedBackgroundView:bgColorView];
        cell.selectedBackgroundView = bgColorView;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 4) { // && indexPath.row == [[ROOT_MENU objectAtIndex:3] indexOfObject:MENU_LOGOUT])
//        || (indexPath.section == 0 && indexPath.row == [[ROOT_MENU objectAtIndex:0] indexOfObject:MENU_ORGS])) {
        [self performSegueWithIdentifier:[[ROOT_MENU objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] sender:self];
    } else if (indexPath.section != 0 || indexPath.row != 0) {
        [self showView:[[ROOT_MENU objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    //    if ([[[ROOT_MENU objectAtIndex:section] objectAtIndex:0] length] == 0) {
    if (section == 0) {
        return 0;
    } else {
        return ROOT_MENU_SECTION_HEADER_HEIGHT;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    //    if ([[[ROOT_MENU objectAtIndex:section] objectAtIndex:0] length] == 0) {
    if (section == 0) {
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


@end
