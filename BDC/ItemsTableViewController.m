//
//  ItemsTableViewController.m
//  BDC
//
//  Created by Qinwei Gong on 9/22/12.
//
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

@interface ItemsTableViewController () <ItemListDelegate, LineItemDelegate>

@end

@implementation ItemsTableViewController

@synthesize items = _items;
@synthesize selectDelegate;

- (void)setItems:(NSMutableArray *)items {
    _items = items;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)navigateDone {
    NSMutableArray *items = [NSMutableArray array];
    for (NSIndexPath *path in self.tableView.indexPathsForSelectedRows) {
        [items addObject:[self.items objectAtIndex:path.row]];
    }
    [self.selectDelegate didSelectItems:items];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)navigateCancel {
    [self.navigationController popViewControllerAnimated:YES];
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
    if (self.mode == kSelectMode) {
        self.title = @"Select Items";
        
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
    self.clearsSelectionOnViewWillAppear = NO;
    
    [Item setListDelegate:self];
    
    if (self.mode == kSelectMode) {
        // get a fresh copy
        NSMutableArray *arr = [NSMutableArray array];
        for (Item *item in [Item listOrderBy:ITEM_NAME ascending:YES active:YES]) {
            Item *copy = [[Item alloc] init];
            [Item clone:item to:copy];
            [arr addObject:copy];
        }
        self.items = arr;
        self.crudActions = [NSArray arrayWithObjects:ACTION_CREATE, nil];
    } else {
//        [Item setListDelegate:self];
        self.items = [Item listOrderBy:ITEM_NAME ascending:YES active:YES];
        
        UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
        [refresh addTarget:self action:@selector(refreshView) forControlEvents:UIControlEventValueChanged];
        refresh.attributedTitle = PULL_TO_REFRESH;
        self.refreshControl = refresh;
        
        self.sortAttributes = [NSArray array];
        self.crudActions = [NSArray arrayWithObjects:ACTION_CREATE, ACTION_DELETE, nil];
        self.inactiveCrudActions = [NSArray arrayWithObjects:ACTION_UNDELETE, nil];        
    }
    
    self.createNewSegue = ITEM_CREATE_ITEM_SEGUE;
}

- (void)refreshView {
    self.refreshControl.attributedTitle = REFRESHING;
    [Item retrieveList];
    [self exitEditMode];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.row >= [self.items count]) { // not used any more
        cell.textLabel.text = @"New Item";
        cell.detailTextLabel.text = @"";
        cell.textLabel.textColor = [UIColor grayColor];
        cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        Item *item = [self.items objectAtIndex:indexPath.row];
        
        cell.textLabel.text = item.name;
        if (self.mode == kSelectMode) {
            cell.detailTextLabel.text = [[Util formatCurrency:item.price] stringByAppendingFormat:@"  x  %d", item.qty];
        } else {
            cell.detailTextLabel.text = [Util formatCurrency:item.price];
        }
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
        Item *item = [self.items objectAtIndex:indexPath.row];
        [self.items removeObjectAtIndex:indexPath.row];
        if (item.isActive) {
            [item remove];
        } else {
            [item revive];
        }

        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//        self.tableView.editing = NO;
//        [self restoreEditButton:self.navigationItem.rightBarButtonItem];
//        [self.tableView reloadData];
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
        [segue.destinationViewController setItem:sender];
        [segue.destinationViewController setMode:kViewMode];
    } else if ([segue.identifier isEqualToString:ITEM_CREATE_ITEM_SEGUE]) {
        [segue.destinationViewController setTitle:@"New Item"];
        [segue.destinationViewController setMode:kCreateMode];
    } else if ([segue.identifier isEqualToString:ITEM_MODIFY_ITEM_SEGUE]) {
        int index = [sender intValue];
        Item *item = [self.items objectAtIndex:index];
        [segue.destinationViewController setItem:item];
        [segue.destinationViewController setLineItemIndex:index];
        [segue.destinationViewController setMode:kModifyMode];
        ((EditItemViewController*)segue.destinationViewController).lineItemDelegate = self;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.mode == kSelectMode) {
        UITableViewCell *row = [self.tableView cellForRowAtIndexPath:indexPath];
        row.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        if (indexPath.row >= [self.items count]) {
            [self performSegueWithIdentifier:ITEM_CREATE_ITEM_SEGUE sender:nil];
        } else {
            if (!self.tableView.editing) {
                [self performSegueWithIdentifier:ITEM_VIEW_ITEM_SEGUE sender:[self.items objectAtIndex:indexPath.row]];
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.mode == kSelectMode) {
        UITableViewCell *row = [self.tableView cellForRowAtIndexPath:indexPath];
        row.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    } else {
        if (!self.tableView.editing) {
            [self performSegueWithIdentifier:ITEM_VIEW_ITEM_SEGUE sender:[self.items objectAtIndex:indexPath.row]];
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row == [self.items count]) {
        return UITableViewCellEditingStyleInsert;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:ITEM_MODIFY_ITEM_SEGUE sender:[NSNumber numberWithInt:indexPath.row]];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (!self.isActive) {
        return ALL_INACTIVE_ITEMS;
    }
    return nil;
}

#pragma mark - model delegate

- (void)didGetItems {
    if (self.mode != kSelectMode) {
        self.tableView.editing = NO;
        self.items = [Item listOrderBy:ITEM_NAME ascending:self.isAsc active:self.isActive];
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
