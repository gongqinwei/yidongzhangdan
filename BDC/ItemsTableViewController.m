//
//  ItemsTableViewController.m
//  BDC
//
//  Created by Qinwei Gong on 9/22/12.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "ItemsTableViewController.h"
#import "EditItemViewController.h"
#import "Item.h"
#import "Util.h"

#define ITEM_CELL_ID            @"ItemItem"
#define ITEM_VIEW_ITEM_SEGUE    @"ViewItem"
#define ITEM_CREATE_ITEM_SEGUE  @"CreateItem"
#define ITEM_MODIFY_ITEM_SEGUE  @"ModifyItem"

#define ALL_INACTIVE_ITEMS      @"All Deleted Items"

#define AMOUNT_COLOR            [UIColor colorWithRed:76.0/255.0 green:153.0/255.0 blue:0.0/255.0 alpha:1.0]

@interface ItemsTableViewController () <ItemListDelegate, LineItemDelegate>

@end


@implementation ItemsTableViewController

@synthesize items = _items;
@synthesize selectDelegate;

- (Class)busObjClass {
    return [Item class];
}

- (void)setItems:(NSMutableArray *)items {
    _items = items;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)navigateDone {
    if ([self tryTap]) {
        NSMutableArray *items = [NSMutableArray array];
        for (NSIndexPath *path in self.tableView.indexPathsForSelectedRows) {
            [items addObject:[self.items objectAtIndex:path.row]];
        }
        [self.selectDelegate didSelectItems:items];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)navigateAttach {
    [super navigateAttach];
    [self attachDocumentForObject:self.items[self.lastSelected.row]];
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
    
    self.sortAttribute = ITEM_NAME;
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.mode == kSelectMode || self.mode == kAttachMode) {
        self.title = @"Select Items";
        [super viewWillAppear:animated];
    }
}

- (void)restoreEditButton:(UIBarButtonItem *)sender {
    [self.tableView setEditing:NO animated:YES];
    [sender setTitle:@"Edit"];
    [sender setStyle:UIBarButtonItemStylePlain];
}

- (IBAction)editItems:(UIBarButtonItem *)sender {
    if (self.tableView.editing) {
        [self restoreEditButton:sender];
    } else {
        [self.tableView setEditing:YES animated:YES];
        [sender setTitle:@"Done"];
        [sender setStyle:UIBarButtonItemStyleDone];
    }
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = YES;
    
    [Item setListDelegate:self];
//    [Item retrieveList];
    
    Organization *org = [Organization getSelectedOrg];
    if (self.mode == kSelectMode) {
        // get a fresh copy
        NSMutableArray *arr = [NSMutableArray array];
        for (Item *item in [Item listOrderBy:ITEM_NAME ascending:YES active:YES]) {
            Item *copy = [[Item alloc] init];
            [Item clone:item to:copy];
            [arr addObject:copy];
        }
        self.items = arr;
        if (org.showAR) {
            self.crudActions = [NSArray arrayWithObjects:ACTION_CREATE, nil];
        }
    } else if(self.mode != kAttachMode) {
        self.items = [Item listOrderBy:ITEM_NAME ascending:YES active:YES];
        
        self.sortAttributes = [NSArray array];
        if (org.showAR) {
            self.crudActions = [NSArray arrayWithObjects:ACTION_CREATE, ACTION_DELETE, nil];
            self.inactiveCrudActions = [NSArray arrayWithObjects:ACTION_UNDELETE, nil];
        }
    }
    
    self.createNewSegue = ITEM_CREATE_ITEM_SEGUE;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    if (self.tableView.editing) {
//        return [self.items count] + 1;
//    } else {
        return [self.items count];
//    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = ITEM_CELL_ID;
    
    Item *item = [self.items objectAtIndex:indexPath.row];
    
    UITableViewCell *cell; // = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (self.mode == kSelectMode) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
        
        cell.detailTextLabel.text = item.name;
        cell.textLabel.text = [[Util formatCurrency:item.price] stringByAppendingFormat:@"  x  %lu", (unsigned long)item.qty];
        cell.textLabel.textColor = AMOUNT_COLOR;
        cell.detailTextLabel.font = [UIFont systemFontOfSize:14.0];
    } else {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        cell.textLabel.text = item.name;
        cell.detailTextLabel.text = [Util formatCurrency:item.price];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.textLabel.font = [UIFont systemFontOfSize:15.0];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:14.0];
        cell.detailTextLabel.textColor = AMOUNT_COLOR;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (self.mode == kSelectMode || self.mode == kAttachMode) {
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;           
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.editing) {
        return YES;
    } else {
        return NO;
    }
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        Item *item = [self.items objectAtIndex:indexPath.row];
        [self.items removeObjectAtIndex:indexPath.row];
        if (item.isActive) {
            [item remove];
        } else {
            [item revive];
        }

        [self.listViewDelegate didDeleteObject:indexPath];
//        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
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

#pragma mark - Table view delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:ITEM_VIEW_ITEM_SEGUE]) {
        [segue.destinationViewController setBusObj:sender];
        [segue.destinationViewController setMode:kViewMode];
    } else if ([segue.identifier isEqualToString:ITEM_CREATE_ITEM_SEGUE]) {
        [segue.destinationViewController setTitle:@"New Item"];
        [segue.destinationViewController setMode:kCreateMode];
    } else if ([segue.identifier isEqualToString:ITEM_MODIFY_ITEM_SEGUE]) {
        int index = [sender intValue];
        Item *item = [self.items objectAtIndex:index];
        [segue.destinationViewController setBusObj:item];
        [segue.destinationViewController setLineItemIndex:index];
        [segue.destinationViewController setMode:kModifyMode];
        ((EditItemViewController*)segue.destinationViewController).lineItemDelegate = self;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if (self.mode == kSelectMode || self.mode == kAttachMode) {
        UITableViewCell *row = [self.tableView cellForRowAtIndexPath:indexPath];
        row.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        if (!self.tableView.editing) {
            [self performSegueWithIdentifier:ITEM_VIEW_ITEM_SEGUE sender:[self.items objectAtIndex:indexPath.row]];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.mode == kSelectMode) {
        UITableViewCell *row = [self.tableView cellForRowAtIndexPath:indexPath];
        row.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    } else if (self.mode == kAttachMode) {
        if (self.lastSelected != nil) {
            UITableViewCell *oldRow = [self.tableView cellForRowAtIndexPath:self.lastSelected];
            oldRow.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        }
        
        UITableViewCell *newRow = [self.tableView cellForRowAtIndexPath:indexPath];
        newRow.accessoryType = UITableViewCellAccessoryCheckmark;
        
        self.lastSelected = indexPath;
    } else {
        if (!self.tableView.editing) {
            [self performSegueWithIdentifier:ITEM_VIEW_ITEM_SEGUE sender:[self.items objectAtIndex:indexPath.row]];
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if ([self tryTap]) {
        [self performSegueWithIdentifier:ITEM_MODIFY_ITEM_SEGUE sender:[NSNumber numberWithUnsignedInteger:indexPath.row]];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (!self.isActive) {
        return ALL_INACTIVE_ITEMS;
    }
    return nil;
}

#pragma mark - model delegate

- (void)didReadObject {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)didGetItems {
    if (self.mode != kSelectMode) {
        self.tableView.editing = NO;
        
        if (!self.actionMenuVC) {
            self.items = [Item listOrderBy:ITEM_NAME ascending:self.isAsc active:self.isActive];
        } else {
            self.items = [Item listOrderBy:[self.actionMenuVC.sortAttributes objectAtIndex:self.actionMenuVC.lastSortAttribute.row] ascending:self.actionMenuVC.ascSwitch.on active:self.actionMenuVC.activenessSwitch.selectedSegmentIndex == 0];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self restoreEditButton:self.navigationItem.rightBarButtonItem];
            
            self.refreshControl.attributedTitle = LAST_REFRESHED;
            [self.refreshControl endRefreshing];
        });
    }
}

- (void)didAddItem:(Item *)item {
//    if (self.mode == kSelectMode) {   //it only works for select mode anyway
        item.qty = 1;
        [self.items addObject:item];
        [self.tableView reloadData];
//    }
}

- (void)failedToGetItems {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
    });
}

- (void)didModifyItem:(Item *)item forIndex:(int)index {
    [Item clone:item to:[self.items objectAtIndex:index]];
    NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
        if (item.qty > 0) {
            UITableViewCell *row = [self.tableView cellForRowAtIndexPath:path];
            [self.tableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
            row.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    });
}

- (void)didDeleteObject {
    self.items = [Item listOrderBy:ITEM_NAME ascending:YES active:self.isActive];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - Action Menu delegate

- (void)didSelectSortAttribute:(NSString *)attribute ascending:(BOOL)ascending active:(BOOL)active {
    NSMutableArray *itemList = self.items;
    
    if (active) {
        if (!self.isActive || !self.items) {
            itemList = [Item listOrderBy:ITEM_NAME ascending:self.isAsc active:YES];
            self.isActive = YES;
        }
    } else {
        if (self.isActive || !self.items) {
            itemList = [Item listOrderBy:ITEM_NAME ascending:self.isAsc active:NO];
            self.isActive = NO;
        }
    }
    
    self.items = itemList;
}

@end
