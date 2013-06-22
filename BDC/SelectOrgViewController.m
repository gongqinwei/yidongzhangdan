//
//  SelectOrgViewController.m
//  BDC
//
//  Created by Qinwei Gong on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SelectOrgViewController.h"
#import "Constants.h"
#import "Organization.h"
#import "Util.h"
#import "APIHandler.h"
#import "UIHelper.h"

#define LOG_OUT_FROM_SELECT_ORGS_SEGUE      @"LogOutFromOrgSelect"

@interface SelectOrgViewController ()

@property (nonatomic, strong) NSArray *filteredOrgs;

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope;

@end

@implementation SelectOrgViewController

@synthesize orgs;
@synthesize filteredOrgs;
@synthesize isInitialLogin;

- (void)cancelSelect:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)logout {
    [self performSegueWithIdentifier:LOG_OUT_FROM_SELECT_ORGS_SEGUE sender:self];
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
    
//    NSData * imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@/%@?w=100&h=100&orgId=%@", DOMAIN_URL, ORG_LOGO_API, org.objectId]]];
    
    dispatch_async(dispatch_get_global_queue(0,0), ^{
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
    Organization *selectedOrg;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        selectedOrg = [self.filteredOrgs objectAtIndex:indexPath.row];
    } else {
        selectedOrg = [self.orgs objectAtIndex:indexPath.row];
    }
    
    NSMutableDictionary *info = [NSMutableDictionary dictionary];

    [info setObject:ORG_ID forKey:selectedOrg.objectId];
    [info setObject:USERNAME forKey:[Util URLEncode:[Util getUsername]]];
    [info setObject:PASSWORD forKey:[Util URLEncode:[Util getPassword]]];
    
    __weak SelectOrgViewController *weakSelf = self;
    
    [APIHandler asyncCallWithAction:LOGIN_API Info:info AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger status;
        NSDictionary *responseData = [APIHandler getResponse:response data:data error:&err status:&status];
        
        if (status == RESPONSE_SUCCESS) {
            // set cookie for session id
            NSString *sessionId = [responseData objectForKey:SESSION_ID_KEY];
            
            // randomly pick a cheap api to test API accessibility
            NSString *action = [LIST_API stringByAppendingString: ACCOUNT_API];
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA, LIST_INACTIVE_FILTER, nil];
            
            [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
                NSInteger response_status;
                [APIHandler getResponse:response data:data error:&err status:&response_status];
                                
                if(response_status == RESPONSE_SUCCESS) {
                    // persist
                    [Organization selectOrg:selectedOrg];
                    [Util setSession:sessionId];
                    
                    // redirect
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.searchDisplayController.active = NO;
                        [weakSelf performSegueWithIdentifier:@"GoToOrg" sender:weakSelf];
                    });
                } else if (response_status == RESPONSE_TIMEOUT) {
                    [UIHelper showInfo:SysTimeOut withStatus:kError];
                    NSLog(SysTimeOut);
                } else {
                    [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
                    NSLog(@"%@", [err localizedDescription]);
                }
            }];
        } else {
            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
            NSLog(@"%@", [err localizedDescription]);
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

@end
