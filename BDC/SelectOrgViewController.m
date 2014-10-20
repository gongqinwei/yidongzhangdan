//
//  SelectOrgViewController.m
//  BDC
//
//  Created by Qinwei Gong on 7/9/12.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import "SelectOrgViewController.h"
#import "Constants.h"
#import "Organization.h"
#import "User.h"
#import "Util.h"
#import "APIHandler.h"
#import "UIHelper.h"
#import "Branch.h"
#import "Mixpanel.h"

#define LOG_OUT_FROM_SELECT_ORGS_SEGUE      @"LogOutFromOrgSelect"


@interface SelectOrgViewController () <OrgDelegate, ProfileDelegate>

@property (nonatomic, strong) NSArray *filteredOrgs;
@property Organization *selectedOrg;
@property NSString *sessionId;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) NSIndexPath *lastSelected;
@property (nonatomic, assign) BOOL orgChanged;

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope;

@end


@implementation SelectOrgViewController

@synthesize orgs;
@synthesize filteredOrgs;
@synthesize isInitialLogin;
@synthesize selectedOrg;
@synthesize sessionId;
@synthesize activityIndicator;
@synthesize lastSelected;
@synthesize orgChanged;


- (void)cancelSelect:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)logout {
    [self performSegueWithIdentifier:LOG_OUT_FROM_SELECT_ORGS_SEGUE sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:LOG_OUT_FROM_SELECT_ORGS_SEGUE]) {
        [Util logout];
    }
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
    self.navigationItem.hidesBackButton = YES;
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.orgs = [Organization list];
    if (!self.isInitialLogin) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelSelect:)];
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Log Out" style:UIBarButtonItemStylePlain target:self action:@selector(logout)];
    }
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.hidesWhenStopped = YES;
    [self.activityIndicator stopAnimating];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return self.filteredOrgs.count;
    } else {
        return orgs.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"OrgSelectionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(!cell || tableView == self.searchDisplayController.searchResultsTableView) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    Organization *org;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        org = (Organization*)[self.filteredOrgs objectAtIndex:indexPath.row];
    } else {
        org = (Organization*)[self.orgs objectAtIndex:indexPath.row];
    }
    
    UILabel *orgNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(45, 1, SCREEN_WIDTH - 150, CELL_HEIGHT - 2)];
    orgNameLabel.text = org.name;
    [cell addSubview:orgNameLabel];

//    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d bills overdue", indexPath.row + 1];
    
    NSString *imageName = @"CompanyIcon.png";
    UIImage *img = [UIImage imageNamed:imageName];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
        imgView.frame = CGRectMake(2, 2, 39, 39);
        [cell addSubview:imgView];
    } else {
        cell.imageView.image = img;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSData * imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@/%@?w=100&h=100&orgId=%@", DOMAIN_URL, ORG_LOGO_API, org.objectId]]];
        
        if (imageData != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([UIImage imageWithData: imageData]) {
                    UIImageView *orgLogo = [[UIImageView alloc] initWithImage:[UIImage imageWithData: imageData]];
                    orgLogo.frame = CGRectMake(2, 2, 39, 39);
                    [cell addSubview:orgLogo];
                }
            });
        }
    });
  
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.lastSelected) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.activityIndicator stopAnimating];
//        });
        
        UITableViewCell *previousCell = [self.tableView cellForRowAtIndexPath:self.lastSelected];
        previousCell.accessoryView = nil;
    }
    self.lastSelected = indexPath;
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryView = self.activityIndicator;
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    
//    Organization *selectedOrg;
    [Organization setDelegate:self];
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        self.selectedOrg = [self.filteredOrgs objectAtIndex:indexPath.row];
    } else {
        self.selectedOrg = [self.orgs objectAtIndex:indexPath.row];
    }
    
    NSMutableDictionary *info = [NSMutableDictionary dictionary];

    [info setObject:ORG_ID forKey:self.selectedOrg.objectId];
    [info setObject:USERNAME forKey:[Util URLEncode:[Util getUsername]]];
    [info setObject:PASSWORD forKey:[Util URLEncode:[Util getPassword]]];
    
//    __weak SelectOrgViewController *weakSelf = self;
    
    [APIHandler asyncCallWithAction:LOGIN_API Info:info AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger status;
        NSDictionary *responseData = [APIHandler getResponse:response data:data error:&err status:&status];
        
        if (status == RESPONSE_SUCCESS) {
            self.sessionId = [responseData objectForKey:SESSION_ID_KEY];
            NSString *userId = [responseData objectForKey:USER_ID];
            
            self.orgChanged = NO;
            if (![Util getUserId] || ![[Util getUserId] isEqualToString:userId]) {
                self.orgChanged = YES;
                [Util setUserId:userId];
            }
            
            [User GetLoginUser].profileDelegate = self;
            
            [User GetUserInfo:userId];
            
            [self.selectedOrg getOrgFeatures];
            
        } else {
            [UIHelper showInfo:[NSString stringWithFormat:@"Cannot switch to %@! %@", self.selectedOrg.name, [err localizedDescription]] withStatus:kError];
            Error(@"%@", [err localizedDescription]);
        }
    }];

}

#pragma mark - Search Display Controller delegate

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterContentForSearchText:searchString
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    return YES;
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    NSPredicate *filterPredicate = [NSPredicate
                                    predicateWithFormat:@"name BEGINSWITH[CD] %@",
                                    searchText];
    
    self.filteredOrgs = [self.orgs filteredArrayUsingPredicate:filterPredicate];
}

#pragma mark - Organization delegate

- (void)didGetOrgFeatures {
    if (self.lastSelected) {
        UITableViewCell *previousCell = [self.tableView cellForRowAtIndexPath:self.lastSelected];
        previousCell.accessoryView = nil;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicator stopAnimating];
    });
    
    if (self.selectedOrg.showAR || self.selectedOrg.showAP) {
        // persist
        [Organization selectOrg:self.selectedOrg];
        [Util setSession:self.sessionId];
        
        // redirect
        dispatch_async(dispatch_get_main_queue(), ^{
            self.searchDisplayController.active = NO;
            [self performSegueWithIdentifier:@"GoToOrg" sender:self];
        });
    }    
}

- (void)failedToGetOrgFeatures {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicator stopAnimating];
    });
    
    if (self.lastSelected) {
        UITableViewCell *previousCell = [self.tableView cellForRowAtIndexPath:self.lastSelected];
        previousCell.accessoryView = nil;
    }
    
//    [User useProfileToGetOrgFeatures];
}

#pragma mark - Profile delegate method
- (void)didFinishProfileCheckList {
    [self tracking];
}

- (void)tracking {
    if (self.orgChanged) {
        // Branch Metrics
        Branch *branch = [Branch getInstance:BNC_APP_KEY];
        [branch identifyUser:[Util getUserId]];
        
        NSDictionary *properties = [NSDictionary dictionaryWithObjects:@[[Util getUserId], [Util getUserFullName], [Util getUserEmail], self.selectedOrg.objectId, self.selectedOrg.name] forKeys:TRACKING_EVENT_KEYS];
        [branch userCompletedAction:@"Login" withState:properties];
        
        // Mixpanel
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel identify:[Util getUserId]];
        [mixpanel registerSuperProperties:properties];
        [mixpanel track:@"Login"];
    }
}

@end
