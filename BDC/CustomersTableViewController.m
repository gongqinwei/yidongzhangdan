//
//  CustomersTableViewController.m
//  BDC
//
//  Created by Qinwei Gong on 8/31/12.
//
//

#import "CustomersTableViewController.h"
#import "EditCustomerViewController.h"
#import "Customer.h"
#import "Util.h"

#define CUSTOMER_CELL_ID                    @"CustomerItem"
#define CUSTOMER_VIEW_CUSTOMER_SEGUE        @"ViewCustomer"
#define CUSTOMER_CREATE_CUSTOMER_SEGUE      @"CreateCustomer"

#define ALL_INACTIVE_CUSTOMERS              @"All Deleted Customers"

@interface CustomersTableViewController () <CustomerListDelegate, ListViewDelegate>

@property (nonatomic, strong) NSIndexPath *lastSelected;

@end

@implementation CustomersTableViewController

@synthesize lastSelected;
@synthesize customers = _customers;
@synthesize selectDelegate;

- (void)setCustomers:(NSMutableArray *)customers {
    _customers = customers;
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
        [self.selectDelegate didSelectCustomer:((Customer *)[self.customers objectAtIndex:path.row]).objectId];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)navigateCancel {
    if ([self tryTap]) {
        [self.navigationController popViewControllerAnimated:YES];
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

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    self.sortAttribute = CUSTOMER_NAME;
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.mode == kSelectMode) {
        self.title = @"Select Customer";

        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]
                                       initWithTitle: @"Cancel"
                                       style: UIBarButtonItemStyleBordered
                                       target: self action:@selector(navigateCancel)];
        
        self.navigationItem.leftBarButtonItem = cancelButton;

        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
                                       initWithTitle: @"Done"
                                       style: UIBarButtonItemStyleBordered
                                       target: self action:@selector(navigateDone)];
        
        self.navigationItem.rightBarButtonItem = doneButton;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    
    self.customers = [Customer listOrderBy:CUSTOMER_NAME ascending:YES active:YES];
    [Customer setListDelegate:self];
//    [Customer retrieveList];
    
    if (self.mode != kSelectMode) {        
        UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
        [refresh addTarget:self action:@selector(refreshView) forControlEvents:UIControlEventValueChanged];
        refresh.attributedTitle = PULL_TO_REFRESH;
        self.refreshControl = refresh;
        
        self.sortAttributes = [NSArray array];
        self.crudActions = [NSArray arrayWithObjects:ACTION_CREATE, ACTION_DELETE, nil];
        self.inactiveCrudActions = [NSArray arrayWithObjects:ACTION_UNDELETE, nil];
    } else {
        self.crudActions = [NSArray arrayWithObjects:ACTION_CREATE, nil];
    }
    
    self.createNewSegue = CUSTOMER_CREATE_CUSTOMER_SEGUE;
}

- (void)refreshView {
    self.refreshControl.attributedTitle = REFRESHING;
    [Customer retrieveList];

    [self exitEditMode];
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
//        return [self.customers count] + 1;
//    } else {
        return [self.customers count];
//    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = CUSTOMER_CELL_ID;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.row >= [self.customers count]) { // not used any more
        cell.textLabel.text = @"New Customer";
        cell.detailTextLabel.text = @"";
        cell.textLabel.textColor = [UIColor grayColor];
        cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        Customer *customer = [self.customers objectAtIndex:indexPath.row];
        
        cell.textLabel.text = customer.name;
        cell.detailTextLabel.text = customer.email;
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:13.0];
        
        if (self.mode == kSelectMode) {
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
        Customer *customer = [self.customers objectAtIndex:indexPath.row];
        [self.customers removeObjectAtIndex:indexPath.row];
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
    if (!self.isActive) {
        return ALL_INACTIVE_CUSTOMERS;
    }
    return nil;
}

#pragma mark - Table view delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(Customer *)sender
{
    if ([segue.identifier isEqualToString:CUSTOMER_VIEW_CUSTOMER_SEGUE]) {
        [segue.destinationViewController setCustomer:sender];
        [segue.destinationViewController setMode:kViewMode];
    } else if ([segue.identifier isEqualToString:CUSTOMER_CREATE_CUSTOMER_SEGUE]) {
//        [segue.destinationViewController setTitle:@"New Customer"];
        [segue.destinationViewController setMode:kCreateMode];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.mode == kSelectMode) {
        if (self.lastSelected != nil) {
            UITableViewCell *oldRow = [self.tableView cellForRowAtIndexPath:self.lastSelected];
            oldRow.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        }

        UITableViewCell *newRow = [self.tableView cellForRowAtIndexPath:indexPath];
        newRow.accessoryType = UITableViewCellAccessoryCheckmark;
        
        self.lastSelected = indexPath;
    } else {
        if (indexPath.row >= [self.customers count]) {
            [self performSegueWithIdentifier:CUSTOMER_CREATE_CUSTOMER_SEGUE sender:nil];    // not used any more
        } else {
            if (!self.tableView.editing) {
                [self performSegueWithIdentifier:CUSTOMER_VIEW_CUSTOMER_SEGUE sender:[self.customers objectAtIndex:indexPath.row]];
            }
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row >= [self.customers count]) {   // not used any more
        return UITableViewCellEditingStyleInsert;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if ([self tryTap]) {
        [self performSegueWithIdentifier:CUSTOMER_VIEW_CUSTOMER_SEGUE sender:[self.customers objectAtIndex:indexPath.row]];
    }
}

#pragma mark - model delegate

- (void)didGetCustomers {
    self.tableView.editing = NO;
    self.customers = [Customer listOrderBy:CUSTOMER_NAME ascending:self.isAsc active:self.isActive];
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

#pragma mark - Action Menu delegate

- (void)didSelectSortAttribute:(NSString *)attribute ascending:(BOOL)ascending active:(BOOL)active {
    NSMutableArray *customerList = self.customers;
    
    if (active) {
        if (!self.isActive || !self.customers) {
            customerList = [Customer listOrderBy:CUSTOMER_NAME ascending:self.isAsc active:YES];
            self.isActive = YES;
        }
    } else {
        if (self.isActive || !self.customers) {
            customerList = [Customer listOrderBy:CUSTOMER_NAME ascending:self.isAsc active:NO];
            self.isActive = NO;
        }
    }
    
    self.customers = customerList;
}


@end
