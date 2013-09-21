//
//  ContactsTableViewController.m
//  Mobill
//
//  Created by Qinwei Gong on 9/16/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "ContactsTableViewController.h"
#import "CustomerContact.h"


#define CONTACTS_CREATE_CONTACT_SEGUE       @"CreateContact"
#define CONTACTS_VIEW_CONTACT_SEGUE         @"ViewContact"
#define CONTACT_CELL_ID                     @"ContactItem"


@interface ContactsTableViewController () <ContactListDelegate>

@property (nonatomic, strong) NSMutableArray *contacts;

@end


@implementation ContactsTableViewController

@synthesize customer;
@synthesize contacts = _contacts;


- (Class)busObjClass {
    return [CustomerContact class];
}

- (void)setContacts:(NSMutableArray *)contacts {
    _contacts = contacts;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

//- (void)restoreEditButton:(UIBarButtonItem *)sender {
//    [self.tableView setEditing:NO animated:YES];
//    [sender setTitle:@"Edit"];
//    [sender setStyle:UIBarButtonItemStylePlain];
//}
//
//- (IBAction)editContacts:(UIBarButtonItem *)sender {
//    if (self.tableView.editing) {
//        [self restoreEditButton:sender];
//    } else {
//        [self.tableView setEditing:YES animated:YES];
//        [sender setTitle:@"Done"];
//        [sender setStyle:UIBarButtonItemStyleDone];
//    }
//    [self.tableView reloadData];
//}

//- (void)navigateDone {
//    if ([self tryTap]) {        
//        [self.navigationController popViewControllerAnimated:YES];
//    }
//}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    self.sortAttribute = CONTACT_FNAME;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.crudActions = [NSArray arrayWithObjects:ACTION_CREATE, ACTION_DELETE, nil];
    
    self.title = @"Contacts";
    self.navigationItem.leftBarButtonItem  = nil;
    
    self.clearsSelectionOnViewWillAppear = NO;
    
    [CustomerContact setListDelegate:self];
    self.contacts = [CustomerContact listContactsForCustomer:self.customer];
    
    self.createNewSegue = CONTACTS_CREATE_CONTACT_SEGUE;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.contacts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = CONTACT_CELL_ID;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    CustomerContact *contact = [self.contacts objectAtIndex:indexPath.row];
    
    cell.textLabel.text = contact.name;
    cell.detailTextLabel.text = contact.email;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:13.0];
    
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
        CustomerContact *contact = [self.contacts objectAtIndex:indexPath.row];
        [self.contacts removeObjectAtIndex:indexPath.row];
        [contact remove];
        
        [self.listViewDelegate didDeleteObject:indexPath];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Delete";
}

#pragma mark - Table view delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(CustomerContact *)sender
{
    if ([segue.identifier isEqualToString:CONTACTS_VIEW_CONTACT_SEGUE]) {
        [segue.destinationViewController setBusObj:sender];
        [segue.destinationViewController setMode:kViewMode];
    } else if ([segue.identifier isEqualToString:CONTACTS_CREATE_CONTACT_SEGUE]) {
        [segue.destinationViewController setCustomer:self.customer];
        [segue.destinationViewController setMode:kCreateMode];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.tableView.editing) {
        [self performSegueWithIdentifier:CONTACTS_VIEW_CONTACT_SEGUE sender:[self.contacts objectAtIndex:indexPath.row]];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

//- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
//    if ([self tryTap]) {
//        [self performSegueWithIdentifier:CUSTOMER_VIEW_CUSTOMER_SEGUE sender:[self.contacts objectAtIndex:indexPath.row]];
//    }
//}

- (void)refreshView {
    self.refreshControl.attributedTitle = REFRESHING;
    
    [CustomerContact retrieveListForCustomer:self.customer.objectId];
    
    [self exitEditMode];
}

#pragma mark - model delegate

- (void)didReadObject {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)didGetContacts {
    self.tableView.editing = NO;
    
    self.contacts = [CustomerContact listContactsForCustomer:self.customer];
    
    dispatch_async(dispatch_get_main_queue(), ^{        
        self.refreshControl.attributedTitle = LAST_REFRESHED;
        [self.refreshControl endRefreshing];
    });
}

- (void)failedToGetContacts {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
    });
}

- (void)didDeleteObject {
    self.contacts = [CustomerContact listContactsForCustomer:self.customer];
}

#pragma mark - Action Menu Delegate

//- (void)didSelectSortAttribute:(NSString *)attribute ascending:(BOOL)ascending active:(BOOL)active {
//    NSMutableArray *contactList = self.contacts;
//    
//    if (active) {
//        if (!self.isActive || !self.contacts) {
//            contactList = [CustomerContact listOrderBy:CUSTOMER_NAME ascending:self.isAsc active:YES];
//            self.isActive = YES;
//        }
//    } else {
//        if (self.isActive || !self.contacts) {
//            contactList = [CustomerContact listOrderBy:CUSTOMER_NAME ascending:self.isAsc active:NO];
//            self.isActive = NO;
//        }
//    }
//    
//    self.contacts = contactList;
//}


@end
