//
//  ActionMenuViewController.m
//  BDC
//
//  Created by Qinwei Gong on 3/14/13.
//
//

#import "ActionMenuViewController.h"
#import "Constants.h"
#import "UIHelper.h"
#import "Util.h"
#import "Invoice.h"
#import "Customer.h"
#import "Item.h"
#import "Bill.h"
#import "Vendor.h"
#import "ChartOfAccount.h"
#import "BankAccount.h"
#import "InvoicesTableViewController.h"
#import "BillsTableViewController.h"
#import "EditBillViewController.h"
#import "RootMenuViewController.h"


#define ACTION_MENU_SECTION_HEADER_HEIGHT       28
#define ASCENDING                               @"Asc"
#define DESCENDIDNG                             @"Desc"


@interface ActionMenuViewController () <UISearchBarDelegate, UISearchDisplayDelegate>

@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) NSMutableArray *searchResultTypes;

@property (nonatomic, strong) UILabel *ascLabel;

- (SlidingTableViewController *)slideInListViewIdentifier:(NSString *)identifier;

@end

@implementation ActionMenuViewController

@synthesize targetViewController;
@synthesize actionDelegate;
@synthesize lastSortAttribute;
@synthesize searchBar;
@synthesize searchResults;
@synthesize searchResultTypes;
@synthesize activenessSwitch;
@synthesize ascSwitch;
@synthesize ascLabel;
@synthesize crudActions;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.targetViewController.isActive) {
        self.crudActions = self.targetViewController.crudActions;
    } else {
        self.crudActions = self.targetViewController.inactiveCrudActions;
    }
    
    if ((self.targetViewController.sortAttributes == nil || self.targetViewController.sortAttributes.count == 0)
        && (self.crudActions == nil || self.crudActions.count == 0)) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    } else {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.frame = CGRectMake(self.view.frame.size.width - SLIDING_DISTANCE,
                                 self.view.frame.origin.y,
                                 SLIDING_DISTANCE,
                                 self.view.frame.size.height);
    
    [self.searchDisplayController.searchBar setScopeBarButtonTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor lightTextColor], UITextAttributeTextColor, nil]
                                                                        forState:UIControlStateNormal];
    [self.searchDisplayController.searchBar setScopeBarButtonTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], UITextAttributeTextColor, nil]
                                                                        forState:UIControlStateSelected];
    
    self.activenessSwitch = [[UISegmentedControl alloc] initWithItems:@[@"Active", @"Inactive"]];
    self.activenessSwitch.frame = CGRectMake(1.0, 0.0, SLIDING_DISTANCE - 2.0, 30.0);
    self.activenessSwitch.segmentedControlStyle = UISegmentedControlStyleBar;
    [self.activenessSwitch addTarget:self action:@selector(switchActiveness) forControlEvents:UIControlEventValueChanged];
    
    if (self.targetViewController.isActive) {
        self.activenessSwitch.selectedSegmentIndex = 0;
        self.crudActions = self.targetViewController.crudActions;
    } else {
        self.activenessSwitch.selectedSegmentIndex = 1;
        self.crudActions = self.targetViewController.inactiveCrudActions;
    }
    
    if ((self.targetViewController.sortAttributes == nil || self.targetViewController.sortAttributes.count == 0)
        && (self.crudActions == nil || self.crudActions.count == 0)) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    } else {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        
        self.actionDelegate = self.targetViewController;
        
        self.ascSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(SLIDING_DISTANCE - 108.0, 1.0, 40.0, ACTION_MENU_SECTION_HEADER_HEIGHT)];
        self.ascSwitch.transform = CGAffineTransformMakeScale(0.8, 0.8);
        [self.ascSwitch addTarget:self action:@selector(switchAscending) forControlEvents:UIControlEventValueChanged];
        
        self.ascLabel = [[UILabel alloc] initWithFrame:CGRectMake(SLIDING_DISTANCE - 37.0, 9.0, 37.0, 15.0)];
        [UIHelper initializeHeaderLabel:self.ascLabel];
        
        if (self.targetViewController.isAsc) {
            self.ascSwitch.on = YES;
            self.ascLabel.text = ASCENDING;
        } else {
            self.ascSwitch.on = NO;
            self.ascLabel.text = DESCENDIDNG;
        }
        
        if (self.targetViewController.sortAttribute) {
            NSInteger row = [self.targetViewController.sortAttributes indexOfObject:self.targetViewController.sortAttribute];
            if (row != NSNotFound) {
                self.lastSortAttribute = [NSIndexPath indexPathForItem:row inSection:1];
            }
        }
    }
}

- (void)viewDidUnload {
    [self setSearchBar:nil];
    [self setActivenessSwitch:nil];
    [self setAscSwitch:nil];
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.searchResults count];
    } else {
        if (!self.targetViewController.sortAttributes && !self.crudActions) {
            return 0;
        } else {
            int numSections = 0;
            if (self.targetViewController.sortAttributes) {
                numSections += self.targetViewController.sortAttributes.count == 0 ? 1 : 2;
            }
            if (self.crudActions && self.crudActions.count > 0) {
                numSections ++;
            }
            return numSections;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [[self.searchResults objectAtIndex:section] count];
    } else {
        if (self.targetViewController.sortAttributes) {
            if (section == 0) {
                return 1;
            } else {
                if (section == 1) {
                    if (self.targetViewController.sortAttributes.count > 0) {
                        return self.targetViewController.sortAttributes.count;
                    } else {
                        return self.crudActions.count;
                    }
                } else {
                    return self.crudActions.count;
                }
            }
        } else {
            return self.crudActions.count;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier1 = @"ActionMenuActivenessItem";
    static NSString *CellIdentifier2 = @"ActionMenuItem";
    
    UITableViewCell *cell;
    
    if (tableView != self.searchDisplayController.searchResultsTableView && self.targetViewController.sortAttributes && indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier1];
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier2];
        }
    }
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        cell.textLabel.text = ((BDCBusinessObject *)[[self.searchResults objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]).name;
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont systemFontOfSize:17.0f];
        cell.indentationLevel = 1;
        cell.indentationWidth = 10;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
//        if (indexPath.section == 0) {
//            [cell addSubview:self.activenessSwitch];
//        } else {
//            cell.textLabel.text = [self.targetViewController.sortAttributeLabels objectForKey:[self.targetViewController.sortAttributes objectAtIndex:indexPath.row]];
//            
//            if ([indexPath isEqual:self.lastSortAttribute]) {
//                cell.accessoryType = UITableViewCellAccessoryCheckmark;
//            }
//        }
        
        if (self.targetViewController.sortAttributes) {
            if (indexPath.section == 0) {
                [cell addSubview:self.activenessSwitch];
            } else {
                if (indexPath.section == 1) {
                    if (self.targetViewController.sortAttributes.count > 0) {
                        cell.textLabel.text = [self.targetViewController.sortAttributeLabels objectForKey:[self.targetViewController.sortAttributes objectAtIndex:indexPath.row]];

                        if ([indexPath isEqual:self.lastSortAttribute]) {
                            cell.accessoryType = UITableViewCellAccessoryCheckmark;
                        }
                    } else {
                        cell.textLabel.text = [self.crudActions objectAtIndex:indexPath.row];
                    }
                } else {
                    cell.textLabel.text = [self.crudActions objectAtIndex:indexPath.row];
                }
            }
        } else {
            NSString *action = [self.crudActions objectAtIndex:indexPath.row];
            cell.textLabel.text = action;
            
            if ([action isEqualToString:ACTION_PAY]) {
//                UITextField *payAmountTextField = [[UITextField alloc] initWithFrame:CGRectMake(120, 5, 100, cell.viewForBaselineLayout.bounds.size.height - 12)];
//                payAmountTextField.text = @"100"; // [Util formatCurrency:item.amount];
//                payAmountTextField.keyboardType = UIKeyboardTypeDecimalPad;
//              itemAmountTextField.objectTag = item;
//              itemAmountTextField.delegate = self;
//              itemAmountTextField.tag = [BillInfo count] * TAG_BASE + indexPath.row * 2 + 1;
                
//                payAmountTextField.font = [UIFont fontWithName:APP_FONT size:16];
//                payAmountTextField.textColor = APP_SYSTEM_BLUE_COLOR;
//                payAmountTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
//                payAmountTextField.textAlignment = UITextAlignmentRight;
//                payAmountTextField.enabled = YES;
//                payAmountTextField.layer.cornerRadius = 8.0f;
//                payAmountTextField.layer.masksToBounds = NO;
//                payAmountTextField.layer.borderColor = [[UIColor whiteColor]CGColor];
//                payAmountTextField.layer.borderWidth = 0.5f;
//                payAmountTextField.backgroundColor = [UIColor lightGrayColor];
//                payAmountTextField.rightView = [[UIView alloc] initWithFrame:TEXT_FIELD_RIGHT_PADDING_RECT];
                
                UILabel *payAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 7, 170, cell.viewForBaselineLayout.bounds.size.height - 12)];
                payAmountLabel.textAlignment = UITextAlignmentRight;
                
                if ([((NSArray *)[BankAccount list]) count]) {
                    Bill *bill = ((EditBillViewController *)self.targetViewController).bill;
                    NSDecimalNumber *payAmount = [bill.amount decimalNumberBySubtracting:bill.paidAmount];
                    payAmountLabel.text = [Util formatCurrency:payAmount];
                    payAmountLabel.textColor = [UIColor whiteColor];
                    payAmountLabel.font = [UIFont fontWithName:APP_FONT size:16];
                    
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                } else {
                    payAmountLabel.text = @"No bank account for Paybles";
                    payAmountLabel.font = [UIFont systemFontOfSize:13.0f];
                    payAmountLabel.textColor = [UIColor orangeColor];
                    
                    cell.textLabel.textColor = [UIColor lightGrayColor];
                }
                
                payAmountLabel.backgroundColor = [UIColor clearColor];
                
                [cell addSubview:payAmountLabel];
                
            }
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (SlidingTableViewController *)slideInListViewIdentifier:(NSString *)identifier {
    UINavigationController *navVC = [[RootMenuViewController sharedInstance].menuItems objectForKey:identifier];
    SlidingTableViewController *vc = [navVC.childViewControllers objectAtIndex:0];
    
    [RootMenuViewController sharedInstance].currVC = vc;
    [RootMenuViewController sharedInstance].currVC.navigation = navVC;
    [RootMenuViewController sharedInstance].currVC.navigationId = identifier;
    
    [vc.view removeGestureRecognizer:vc.tapRecognizer];
    
    [navVC popToRootViewControllerAnimated:NO];
    
    return vc;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        [self.searchDisplayController setActive:NO animated:YES];
        [self.targetViewController slideOut];
        
        BDCBusinessObject * obj = (BDCBusinessObject *)[[self.searchResults objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        
        if ([obj isKindOfClass:[Invoice class]]) {            
            InvoicesTableViewController *listVC = (InvoicesTableViewController *)[self slideInListViewIdentifier:MENU_INVOICES];
            self.actionDelegate = listVC;

            [self.actionDelegate didSelectSortAttribute:[listVC.actionMenuVC.sortAttributes objectAtIndex:listVC.actionMenuVC.lastSortAttribute.row]
                                            ascending:listVC.actionMenuVC.ascSwitch.on
                                               active:!listVC.actionMenuVC.activenessSwitch.selectedSegmentIndex];
            
            [listVC performSegueWithIdentifier:@"ViewInvoice" sender:(Invoice *)obj];
        } else if ([obj isKindOfClass:[Bill class]]) {
            BillsTableViewController *listVC = (BillsTableViewController *)[self slideInListViewIdentifier:MENU_BILLS];
            self.actionDelegate = listVC;
            
            [self.actionDelegate didSelectSortAttribute:[listVC.actionMenuVC.sortAttributes objectAtIndex:listVC.actionMenuVC.lastSortAttribute.row]
                                              ascending:listVC.actionMenuVC.ascSwitch.on
                                                 active:!listVC.actionMenuVC.activenessSwitch.selectedSegmentIndex];
            
            [listVC performSegueWithIdentifier:@"ViewBill" sender:(Bill *)obj];
        } else if ([obj isKindOfClass:[Customer class]]) {
            [[self slideInListViewIdentifier:MENU_CUSTOMERS] performSegueWithIdentifier:@"ViewCustomer" sender:(Customer *)obj];
        } else if ([obj isKindOfClass:[Item class]]) {
            [[self slideInListViewIdentifier:MENU_ITEMS] performSegueWithIdentifier:@"ViewItem" sender:(Item *)obj];
        } else if ([obj isKindOfClass:[Vendor class]]) {
            [[self slideInListViewIdentifier:MENU_VENDORS] performSegueWithIdentifier:@"ViewVendor" sender:(Vendor *)obj];
        }
    } else {
        if (self.targetViewController.sortAttributes) {
            if (indexPath.section == 1) {
                if (self.targetViewController.sortAttributes.count > 0) {
                    [self.tableView cellForRowAtIndexPath:self.lastSortAttribute].accessoryType = UITableViewCellAccessoryNone;
                    self.lastSortAttribute = indexPath;
                    [self.tableView cellForRowAtIndexPath:self.lastSortAttribute].accessoryType = UITableViewCellAccessoryCheckmark;
                    
                    [self.actionDelegate didSelectSortAttribute:[self.targetViewController.sortAttributes objectAtIndex:self.lastSortAttribute.row]
                                                    ascending:self.ascSwitch.on
                                                       active:!self.activenessSwitch.selectedSegmentIndex];
                } else {
                    [self.actionDelegate didSelectCrudAction:[self.crudActions objectAtIndex:indexPath.row]];
                }
            } else if (indexPath.section == 2) {
                [self.actionDelegate didSelectCrudAction:[self.crudActions objectAtIndex:indexPath.row]];
            }
        } else {
            [self.actionDelegate didSelectCrudAction:[self.crudActions objectAtIndex:indexPath.row]];
        }
 
        [self.targetViewController toggleMenu:self];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView != self.searchDisplayController.searchResultsTableView && self.targetViewController.sortAttributes && indexPath.section == 0) {
        return 31.0;
    } else {
        return CELL_HEIGHT;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return ACTION_MENU_SECTION_HEADER_HEIGHT;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, ACTION_MENU_SECTION_HEADER_HEIGHT)];
    headerView.backgroundColor = [UIColor darkGrayColor];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 7, 100, 15)];
    [UIHelper initializeHeaderLabel:label];

    if (tableView == self.searchDisplayController.searchResultsTableView) {
        label.text = [self.searchResultTypes objectAtIndex:section];
    } else {
        if (self.targetViewController.sortAttributes) {
            if (section == 0) {
                label.text = ACTION_LIST;
            } else {
                if (section == 1) {
                    if (self.targetViewController.sortAttributes.count > 0) {
                        label.text = ACTION_ORDER;
                        
                        [headerView addSubview:self.ascLabel];
                        [headerView addSubview:self.ascSwitch];
                    } else {
                        label.text = ACTION_CRUD;
                    }
                } else {
                    label.text = ACTION_CRUD;
                }
            }
        } else {
            label.text = ACTION_CRUD;
        }
    }
    
    [headerView addSubview:label];
    return headerView;
}


#pragma mark - Search Display Controller delegate

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSInteger)scope {
    NSPredicate *resultPredicate = [NSPredicate
                                    predicateWithFormat:@"name BEGINSWITH[CD] %@",
                                    searchText];
    
    NSArray *filteredInvs;
    NSArray *filteredCustomers;
    NSArray *filteredItems;
    NSArray *filteredBills;
    NSArray *filteredVendors;
    
    if (scope == 0) {
        filteredInvs = [[Invoice list] filteredArrayUsingPredicate:resultPredicate];
        filteredCustomers = [[Customer list] filteredArrayUsingPredicate:resultPredicate];
        filteredItems = [[Item list] filteredArrayUsingPredicate:resultPredicate];
        filteredBills = [[Bill list] filteredArrayUsingPredicate:resultPredicate];
        filteredVendors = [[Vendor list] filteredArrayUsingPredicate:resultPredicate];
    } else {
        filteredInvs = [[Invoice listInactive] filteredArrayUsingPredicate:resultPredicate];
        filteredCustomers = [[Customer listInactive] filteredArrayUsingPredicate:resultPredicate];
        filteredItems = [[Item listInactive] filteredArrayUsingPredicate:resultPredicate];
        filteredBills = [[Bill listInactive] filteredArrayUsingPredicate:resultPredicate];
        filteredVendors = [[Vendor listInactive] filteredArrayUsingPredicate:resultPredicate];
    }
    
    self.searchResults = [NSMutableArray array];
    self.searchResultTypes = [NSMutableArray array];
    
    if ([filteredInvs count]) {
        [self.searchResults addObject:filteredInvs];
        [self.searchResultTypes addObject:@"Invoices"];
    }
    if ([filteredBills count]) {
        [self.searchResults addObject:filteredBills];
        [self.searchResultTypes addObject:@"Bills"];
    }
    if ([filteredCustomers count]) {
        [self.searchResults addObject:filteredCustomers];
        [self.searchResultTypes addObject:@"Customers"];
    }
    if ([filteredItems count]) {
        [self.searchResults addObject:filteredItems];
        [self.searchResultTypes addObject:@"Items"];
    }
    if ([filteredVendors count]) {
        [self.searchResults addObject:filteredVendors];
        [self.searchResultTypes addObject:@"Vendors"];
    }
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterContentForSearchText:searchString scope:self.searchDisplayController.searchBar.selectedScopeButtonIndex];
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text scope:searchOption];
    return YES;
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    // Re-style the search controller's table view
    UITableView *tableView = controller.searchResultsTableView;
    tableView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    tableView.separatorColor = [UIColor darkGrayColor];
}

#pragma mark - UISwitch target action

- (void)switchAscending {
    if (self.ascSwitch.on) {
        self.ascLabel.text = ASCENDING;
    } else {
        self.ascLabel.text = DESCENDIDNG;
    }
}

#pragma mark - UISegmented Control action

- (void)switchActiveness {
    if (self.crudActions) {
        if (self.activenessSwitch.selectedSegmentIndex == 0) {
            self.crudActions = self.targetViewController.crudActions;
        } else {
            self.crudActions = self.targetViewController.inactiveCrudActions;
        }
        
        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:[self.tableView numberOfSections] - 1];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    [self.targetViewController exitEditMode];
}

@end
