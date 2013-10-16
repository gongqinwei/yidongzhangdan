//
//  ApproversTableViewController.m
//  Mobill
//
//  Created by Qinwei Gong on 10/10/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "ApproversTableViewController.h"

#define APPROVER_CELL_ID                    @"ApproverItem"
#define APPROVER_CREATE_APPROVER_SEGUE      @"CreateNewApprover"


@interface ApproversTableViewController () <ApproverListDelegate>

@property (nonatomic, strong) NSMutableSet *newlyApproverSet;

@end


@implementation ApproversTableViewController

@synthesize approverLists = _approverLists;
@synthesize vendor;
@synthesize selectDelegate;
@synthesize newlyApproverSet;


- (Class)busObjClass {
    return [Approver class];
}

- (void)setApproverList:(NSMutableArray *)approvers {
    _approverLists = [self sortAlphabeticallyForList:approvers];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)refreshView {
    if (self.vendor && self.vendor.objectId) {
        self.refreshControl.attributedTitle = REFRESHING;
        [Approver retrieveListForVendor:self.vendor.objectId andSmartData:NO];
    } else {
        [super refreshView];
    }
}

- (void)navigateDone {
    if ([self tryTap]) {
        NSMutableArray *selectedApprovers = [NSMutableArray array];
        for (NSIndexPath *path in self.tableView.indexPathsForSelectedRows) {
            [selectedApprovers addObject:self.approverLists[path.section][path.row]];
        }
        
        [self.selectDelegate didSelectApprovers:selectedApprovers];
        self.newlyApproverSet = [NSMutableSet set];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    self.sortAttribute = APPROVER_NAME;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    
    self.approverList = [Approver list];
    [Approver setListDelegate:self];
    
    self.crudActions = [NSArray arrayWithObjects:ACTION_CREATE, nil];
    
    self.mode = kSelectMode;
    self.createNewSegue = APPROVER_CREATE_APPROVER_SEGUE;
    
    if (!self.newlyApproverSet) {
        self.newlyApproverSet = [NSMutableSet set];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.approverLists.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.approverLists[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = APPROVER_CELL_ID;
    UITableViewCell *cell;// = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
//    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
//    }
    
    Approver *approver = self.approverLists[indexPath.section][indexPath.row];
    
    UILabel *approverNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(55, 1, 200, CELL_HEIGHT - 2)];
    approverNameLabel.text = approver.name;
    approverNameLabel.font = [UIFont fontWithName:APP_FONT size:15];
    approverNameLabel.backgroundColor = [UIColor clearColor];
    [cell addSubview:approverNameLabel];
    
    if (approver.profilePicData) {
        UIImageView *approverPic = [[UIImageView alloc] initWithImage:[UIImage imageWithData: approver.profilePicData]];
        approverPic.frame = CGRectMake(12, 2, 39, 39);
        [cell addSubview:approverPic];
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@/%@", DOMAIN_URL, approver.profilePicUrl]]];
            
            if (data != nil) {
                approver.profilePicData = data;
                
                if ([UIImage imageWithData: data]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIImageView *approverPic = [[UIImageView alloc] initWithImage:[UIImage imageWithData: data]];
                        approverPic.frame = CGRectMake(12, 2, 39, 39);
                        [cell addSubview:approverPic];
                    });
                }
            }
        });
    }
    if ([self.newlyApproverSet containsObject:approver]) {
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.indice[section];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if ([title isEqualToString:@"#"]) {
        title = @"123";
    }
    return [self.indice indexOfObject:title];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.alphabets;
}

#pragma mark - Table view delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(Approver *)sender
{
    if ([segue.identifier isEqualToString:APPROVER_CREATE_APPROVER_SEGUE]) {
        [segue.destinationViewController setMode:kCreateMode];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *row = [self.tableView cellForRowAtIndexPath:indexPath];
    row.accessoryType = UITableViewCellAccessoryCheckmark;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *row = [self.tableView cellForRowAtIndexPath:indexPath];
    row.accessoryType = UITableViewCellAccessoryNone;
}


#pragma mark - model delegate

- (void)didGetApprovers {
    self.tableView.editing = NO;
    [self setApproverList:[Approver list]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.refreshControl.attributedTitle = LAST_REFRESHED;
        [self.refreshControl endRefreshing];
    });
}

- (void)failedToGetApprovers {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
    });
}

- (void)didGetApprovers:(NSArray *)approvers {
    
}

- (void)didAddApprover:(Approver *)approver {
    [self.newlyApproverSet addObject:approver];
    
    [self setApproverList:[Approver list]];
}

@end
