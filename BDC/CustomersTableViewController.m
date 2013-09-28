//
//  CustomersTableViewController.m
//  BDC
//
//  Created by Qinwei Gong on 8/31/12.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "CustomersTableViewController.h"
#import "EditCustomerViewController.h"
#import "Customer.h"
#import "MapViewController.h"
#import "Util.h"

#define CUSTOMER_CELL_ID                    @"CustomerItem"
#define CUSTOMER_VIEW_CUSTOMER_SEGUE        @"ViewCustomer"
#define CUSTOMER_CREATE_CUSTOMER_SEGUE      @"CreateCustomer"
#define CUSTOMER_LIST_MAP                   @"ViewCustomersMap"

#define ALL_INACTIVE_CUSTOMERS              @"All Deleted Customers"

@interface CustomersTableViewController () <CustomerListDelegate, ListViewDelegate, SelectObjectProtocol>

@end


@implementation CustomersTableViewController

@synthesize customers = _customers;
@synthesize selectDelegate;

- (Class)busObjClass {
    return [Customer class];
}

- (void)setCustomers:(NSMutableArray *)customers {
    _customers = [self sortAlphabeticallyForList:customers];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)restoreEditButton:(UIBarButtonItem *)sender {
    [self.tableView setEditing:NO animated:YES];
    [sender setTitle:@"Edit"];
    [sender setStyle:UIBarButtonItemStylePlain];
}

//- (void)exitEditMode {
//    [self.tableView setEditing:NO animated:YES];
//    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(toggleMenu:)];
//    actionButton.tag = 1;
//    [self.navigationItem setRightBarButtonItem:actionButton];
//}

- (IBAction)editCustomers:(UIBarButtonItem *)sender {
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
        [self.selectDelegate didSelectCustomer:((Customer *)self.customers[path.section][path.row]).objectId];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)navigateAttach {
    [super navigateAttach];
    [self attachDocumentForObject:self.customers[self.lastSelected.section][self.lastSelected.row]];
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
    
    self.sortAttribute = CUSTOMER_NAME;
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.mode == kSelectMode || self.mode == kAttachMode) {
        self.title = @"Select Customer";
        [super viewWillAppear:animated];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    
    self.customers = [Customer listOrderBy:CUSTOMER_NAME ascending:YES active:YES];
    [Customer setListDelegate:self];
//    [Customer retrieveList];
    
    Organization *org = [Organization getSelectedOrg];
    if (self.mode != kSelectMode && self.mode != kAttachMode) {
        self.sortAttributes = [NSArray array];
        
        if (org.enableAR) {
            self.crudActions = [NSArray arrayWithObjects:ACTION_CREATE, ACTION_DELETE, ACTION_MAP, nil];
            self.inactiveCrudActions = [NSArray arrayWithObjects:ACTION_UNDELETE, nil];
        }
    } else {
        if (org.enableAR) {
            self.crudActions = [NSArray arrayWithObjects:ACTION_CREATE, nil];
        }
    }
    
    self.createNewSegue = CUSTOMER_CREATE_CUSTOMER_SEGUE;
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
    return self.customers.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.customers[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = CUSTOMER_CELL_ID;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    Customer *customer = self.customers[indexPath.section][indexPath.row];
    
    cell.textLabel.text = customer.name;
    cell.detailTextLabel.text = customer.email;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:13.0];
    
    if (self.mode == kSelectMode || self.mode == kAttachMode) {
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
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
        Customer *customer = self.customers[indexPath.section][indexPath.row];
        
        [self.customers[indexPath.section] removeObjectAtIndex:indexPath.row];
        
        if (customer.isActive) {
            [customer remove];
        } else {
            [customer revive];
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
    return self.indice[section];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if ([title isEqualToString:@"#"]) {
        title = @"123";
    }
    return [self.indice indexOfObject:title];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return ALPHABETS;
}

#pragma mark - Table view delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(Customer *)sender
{
    if ([segue.identifier isEqualToString:CUSTOMER_VIEW_CUSTOMER_SEGUE]) {
        [segue.destinationViewController setBusObj:sender];
        [segue.destinationViewController setMode:kViewMode];
    } else if ([segue.identifier isEqualToString:CUSTOMER_CREATE_CUSTOMER_SEGUE]) {
//        [segue.destinationViewController setTitle:@"New Customer"];
        [segue.destinationViewController setMode:kCreateMode];
    } else if ([segue.identifier isEqualToString:CUSTOMER_LIST_MAP]) {
        [segue.destinationViewController setAnnotations:[Customer list]];
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
        if (!self.tableView.editing) {
            [self performSegueWithIdentifier:CUSTOMER_VIEW_CUSTOMER_SEGUE sender:self.customers[indexPath.section][indexPath.row]];
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if ([self tryTap]) {
        [self performSegueWithIdentifier:CUSTOMER_VIEW_CUSTOMER_SEGUE sender:self.customers[indexPath.section][indexPath.row]];
    }
}

#pragma mark - model delegate

- (void)didReadObject {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)didGetCustomers {
    self.tableView.editing = NO;
    
    if (!self.actionMenuVC) {
        self.customers = [Customer listOrderBy:CUSTOMER_NAME ascending:self.isAsc active:self.isActive];
    } else {
        self.customers = [Customer listOrderBy:[self.actionMenuVC.sortAttributes objectAtIndex:self.actionMenuVC.lastSortAttribute.row] ascending:self.actionMenuVC.ascSwitch.on active:self.actionMenuVC.activenessSwitch.selectedSegmentIndex == 0];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self restoreEditButton:self.navigationItem.rightBarButtonItem];
        
        self.refreshControl.attributedTitle = LAST_REFRESHED;
        [self.refreshControl endRefreshing];
    });
}

- (void)failedToGetCustomers {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
    });
}

- (void)didDeleteObject {
    self.customers = [Customer listOrderBy:CUSTOMER_NAME ascending:YES active:self.isActive];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - Action Menu Delegate

- (void)didSelectSortAttribute:(NSString *)attribute ascending:(BOOL)ascending active:(BOOL)active {
    if (active) {
        if (!self.isActive || !self.customers) {
            self.customers = [Customer listOrderBy:CUSTOMER_NAME ascending:self.isAsc active:YES];
            self.isActive = YES;
            self.title = @"Customers";
        }
    } else {
        if (self.isActive || !self.customers) {
            self.customers = [Customer listOrderBy:CUSTOMER_NAME ascending:self.isAsc active:NO];
            self.isActive = NO;
            self.title = @"Deleted Customers";
        }
    }
}

- (void)didSelectCrudAction:(NSString *)action {
    [super didSelectCrudAction:action];
    
    if ([action isEqualToString:ACTION_MAP]) {
        [self performSegueWithIdentifier:CUSTOMER_LIST_MAP sender:self];
    }
}

#pragma mark - MapView SelectObject Delegate

- (void)selectObject:(id)obj {
    [self performSegueWithIdentifier:CUSTOMER_VIEW_CUSTOMER_SEGUE sender:obj];
}

@end
