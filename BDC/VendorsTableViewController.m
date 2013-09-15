//
//  VendorsTableViewController.m
//  BDC
//
//  Created by Qinwei Gong on 8/31/12.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "VendorsTableViewController.h"
#import "EditVendorViewController.h"
#import "Vendor.h"
#import "MapViewController.h"
#import "Util.h"

#define VENDOR_CELL_ID                  @"VendorItem"
#define VENDOR_VIEW_VENDOR_SEGUE        @"ViewVendor"
#define VENDOR_CREATE_VENDOR_SEGUE      @"CreateVendor"
#define VENDOR_LIST_MAP                 @"ViewVendorsMap"

#define ALL_INACTIVE_VENDORS            @"All Deleted Vendors"

@interface VendorsTableViewController () <VendorListDelegate, ListViewDelegate, SelectObjectProtocol>

@end


@implementation VendorsTableViewController

@synthesize vendors = _vendors;
@synthesize selectDelegate;

- (Class)busObjClass {
    return [Vendor class];
}

- (void)setVendors:(NSMutableArray *)vendors {
    _vendors = vendors;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)restoreEditButton:(UIBarButtonItem *)sender {
    [self.tableView setEditing:NO animated:YES];
    [sender setTitle:@"Edit"];
    [sender setStyle:UIBarButtonItemStylePlain];
}

- (IBAction)editVendors:(UIBarButtonItem *)sender {
    if (self.tableView.editing) {
        [self restoreEditButton:sender];
    } else {
        [self.tableView setEditing:YES animated:YES];
        [sender setTitle:@"Done"];
        [sender setStyle:UIBarButtonItemStyleDone];
    }
    [self.tableView reloadData];
}

- (void)navigateDone {
    if ([self tryTap]) {
        NSIndexPath *path = self.lastSelected; //self.tableView.indexPathForSelectedRow; //same
        [self.selectDelegate didSelectVendor:((Vendor *)[self.vendors objectAtIndex:path.row]).objectId];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)navigateAttach {
    [super navigateAttach];
    [self attachDocumentForObject:self.vendors[self.lastSelected.row]];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    self.sortAttribute = VENDOR_NAME;
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.mode == kSelectMode || self.mode == kAttachMode) {
        self.title = @"Select Vendor";
        [super viewWillAppear:animated];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    
    self.vendors = [Vendor listOrderBy:VENDOR_NAME ascending:YES active:YES];
    [Vendor setListDelegate:self];
    //    [Vendor retrieveList];
    
    if (self.mode != kSelectMode && self.mode != kAttachMode) {
        self.sortAttributes = [NSArray array];
        self.crudActions = [NSArray arrayWithObjects:ACTION_CREATE, ACTION_DELETE, ACTION_MAP, nil];
        self.inactiveCrudActions = [NSArray arrayWithObjects:ACTION_UNDELETE, nil];
    } else {
        self.crudActions = [NSArray arrayWithObjects:ACTION_CREATE, nil];
    }
    
    self.createNewSegue = VENDOR_CREATE_VENDOR_SEGUE;
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
    //    if (self.tableView.editing) {
    //        return [self.vendors count] + 1;
    //    } else {
    return [self.vendors count];
    //    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = VENDOR_CELL_ID;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.row >= [self.vendors count]) { // not used any more
        cell.textLabel.text = @"New Vendor";
        cell.detailTextLabel.text = @"";
        cell.textLabel.textColor = [UIColor grayColor];
        cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        Vendor *vendor = [self.vendors objectAtIndex:indexPath.row];
        
        cell.textLabel.text = vendor.name;
        cell.detailTextLabel.text = vendor.email;
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:13.0];
        
        if (self.mode == kSelectMode || self.mode == kAttachMode) {
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        }
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        Vendor *vendor = [self.vendors objectAtIndex:indexPath.row];
        [self.vendors removeObjectAtIndex:indexPath.row];
        if (vendor.isActive) {
            [vendor remove];
        } else {
            [vendor revive];
        }
        
        [self.listViewDelegate didDeleteObject:indexPath];
        //        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];      //TODO: move this to a delegate call
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isActive) {
        return @"Delete";
    } else {
        return @"Undelete";
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (!self.isActive) {
        return ALL_INACTIVE_VENDORS;
    }
    return nil;
}

#pragma mark - Table view delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(Vendor *)sender
{
    if ([segue.identifier isEqualToString:VENDOR_VIEW_VENDOR_SEGUE]) {
        [segue.destinationViewController setBusObj:sender];
        [segue.destinationViewController setMode:kViewMode];
    } else if ([segue.identifier isEqualToString:VENDOR_CREATE_VENDOR_SEGUE]) {
        [segue.destinationViewController setMode:kCreateMode];
    } else if ([segue.identifier isEqualToString:VENDOR_LIST_MAP]) {
        [segue.destinationViewController setAnnotations:[Vendor list]];
        [segue.destinationViewController setSelectObjDelegate:self];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if (self.mode == kSelectMode || self.mode == kAttachMode) {
        if (self.lastSelected != nil) {
            UITableViewCell *oldRow = [self.tableView cellForRowAtIndexPath:self.lastSelected];
            oldRow.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        }
        
        UITableViewCell *newRow = [self.tableView cellForRowAtIndexPath:indexPath];
        newRow.accessoryType = UITableViewCellAccessoryCheckmark;
        
        self.lastSelected = indexPath;
    } else {
        if (indexPath.row >= [self.vendors count]) {
            [self performSegueWithIdentifier:VENDOR_CREATE_VENDOR_SEGUE sender:nil];    // not used any more
        } else {
            if (!self.tableView.editing) {
                [self performSegueWithIdentifier:VENDOR_VIEW_VENDOR_SEGUE sender:[self.vendors objectAtIndex:indexPath.row]];
            }
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row >= [self.vendors count]) {   // not used any more
        return UITableViewCellEditingStyleInsert;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if ([self tryTap]) {
        [self performSegueWithIdentifier:VENDOR_VIEW_VENDOR_SEGUE sender:[self.vendors objectAtIndex:indexPath.row]];
    }
}

#pragma mark - model delegate

- (void)didReadObject {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)didGetVendors {
    self.tableView.editing = NO;
    
    if (!self.actionMenuVC) {
        self.vendors = [Vendor listOrderBy:VENDOR_NAME ascending:self.isAsc active:self.isActive];
    } else {
        self.vendors = [Vendor listOrderBy:[self.actionMenuVC.sortAttributes objectAtIndex:self.actionMenuVC.lastSortAttribute.row] ascending:self.actionMenuVC.ascSwitch.on active:self.actionMenuVC.activenessSwitch.selectedSegmentIndex == 0];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self restoreEditButton:self.navigationItem.rightBarButtonItem];
        
        self.refreshControl.attributedTitle = LAST_REFRESHED;
        [self.refreshControl endRefreshing];
    });
}

- (void)failedToGetVendors {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
    });
}

- (void)didDeleteObject {
    self.vendors = [Vendor listOrderBy:VENDOR_NAME ascending:YES active:self.isActive];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - Action Menu Delegate

- (void)didSelectSortAttribute:(NSString *)attribute ascending:(BOOL)ascending active:(BOOL)active {
    NSMutableArray *vendorList = self.vendors;
    
    if (active) {
        if (!self.isActive || !self.vendors) {
            vendorList = [Vendor listOrderBy:VENDOR_NAME ascending:self.isAsc active:YES];
            self.isActive = YES;
        }
    } else {
        if (self.isActive || !self.vendors) {
            vendorList = [Vendor listOrderBy:VENDOR_NAME ascending:self.isAsc active:NO];
            self.isActive = NO;
        }
    }
    
    self.vendors = vendorList;
}

- (void)didSelectCrudAction:(NSString *)action {
    [super didSelectCrudAction:action];
    
    if ([action isEqualToString:ACTION_MAP]) {
        [self performSegueWithIdentifier:VENDOR_LIST_MAP sender:self];
    }
}

#pragma mark - MapView SelectObject Delegate

- (void)selectObject:(id)obj {
    [self performSegueWithIdentifier:VENDOR_VIEW_VENDOR_SEGUE sender:obj];
}


@end
