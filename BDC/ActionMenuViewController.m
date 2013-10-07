//
//  ActionMenuViewController.m
//  BDC
//
//  Created by Qinwei Gong on 3/14/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
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
#define ACTION_MENU_CELL_HEIGHT                 40
#define ASCENDING                               @"Asc"
#define DESCENDIDNG                             @"Desc"
#define SECTION_HEADER_LABEL_RECT               CGRectMake(15, 7, 70, 15)
#define TOGGLE_ARROW_RECT                       CGRectMake(80, 10, 10, 10)
#define TOGGLE_ARROW_CENTER                     CGPointMake(85, 15)


@interface ActionMenuViewController () <UISearchBarDelegate, UISearchDisplayDelegate>

@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) NSMutableArray *searchResultTypes;
@property (nonatomic, strong) UILabel *ascLabel;
@property (nonatomic, strong) UILabel *payAmountLabel;
@property (nonatomic, strong) UIImageView *orderSectionToggleImage;
@property (nonatomic, strong) UIButton *orderSectionToggleButton;
@property (nonatomic, assign) BOOL orderSectionCollapsed;

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
@synthesize payAmountLabel;
@synthesize crudActions;
@synthesize orderSectionToggleImage;
@synthesize orderSectionToggleButton;
@synthesize orderSectionCollapsed;


static ActionMenuViewController * _sharedInstance = nil;

+ (ActionMenuViewController *)sharedInstance {
    if (!_sharedInstance) {
        _sharedInstance = [[ActionMenuViewController alloc] init];
    }
    return _sharedInstance;
}

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
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = YES;

    self.view.frame = CGRectMake(self.view.frame.size.width - SLIDING_DISTANCE,
                                 self.view.frame.origin.y,
                                 SLIDING_DISTANCE,
                                 self.view.frame.size.height);
    
    [self.searchDisplayController.searchBar setScopeBarButtonTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor lightTextColor], UITextAttributeTextColor, nil]
                                                                        forState:UIControlStateNormal];
    [self.searchDisplayController.searchBar setScopeBarButtonTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], UITextAttributeTextColor, nil]
                                                                        forState:UIControlStateSelected];
    self.searchDisplayController.searchBar.placeholder = @"Search Bill.com";
    
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
    
    self.orderSectionCollapsed = YES;
    
    self.orderSectionToggleImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:TOGGLE_ARROW_IMG_NAME]];
    self.orderSectionToggleImage.frame = TOGGLE_ARROW_RECT;
    self.orderSectionToggleImage.center = TOGGLE_ARROW_CENTER;
    self.orderSectionToggleImage.transform = CGAffineTransformMakeRotation(-M_PI_2);
    
    self.orderSectionToggleButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, SLIDING_DISTANCE - 110, ACTION_MENU_SECTION_HEADER_HEIGHT)];
    self.orderSectionToggleButton.alpha = 0.1;
    [self.orderSectionToggleButton addTarget:self action:@selector(toggleOrderSection:) forControlEvents:UIControlEventTouchUpInside];
    
    _sharedInstance = self;
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

- (void)toggleOrderSection:(UIButton *)sender {
    self.orderSectionCollapsed = !self.orderSectionCollapsed;
    self.orderSectionToggleImage.transform = CGAffineTransformMakeRotation(- M_PI_2 * self.orderSectionCollapsed);

    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:1];
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];    
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
                        return self.orderSectionCollapsed ? 1 : self.targetViewController.sortAttributes.count;
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

- (void)addSelectedBackGroundForCell:(UITableViewCell *)cell {
    UIView *bgColorView = [[UIView alloc] init];
    [bgColorView setBackgroundColor:[UIColor colorWithRed:100/255.f green:100/255.f blue:100/255.f alpha:0.75]];
    cell.selectedBackgroundView = bgColorView;
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
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            } else {
                if (indexPath.section == 1) {
                    if (self.targetViewController.sortAttributes.count > 0) {
                        if (self.orderSectionCollapsed) {
                            cell.textLabel.text = [self.targetViewController.sortAttributeLabels objectForKey:[self.targetViewController.sortAttributes objectAtIndex:self.lastSortAttribute.row]];
                            cell.accessoryType = UITableViewCellAccessoryCheckmark;
                        } else {
                            cell.textLabel.text = [self.targetViewController.sortAttributeLabels objectForKey:[self.targetViewController.sortAttributes objectAtIndex:indexPath.row]];

                            if ([indexPath isEqual:self.lastSortAttribute]) {
                                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                            } else {
                                cell.accessoryType = UITableViewCellAccessoryNone;
                            }
                        }
                    } else {
                        cell.textLabel.text = [self.crudActions objectAtIndex:indexPath.row];
                        [self addSelectedBackGroundForCell:cell];
                    }
                } else {
                    cell.textLabel.text = [self.crudActions objectAtIndex:indexPath.row];
                    [self addSelectedBackGroundForCell:cell];
                }
            }
        } else {
            NSString *action = [self.crudActions objectAtIndex:indexPath.row];
            cell.textLabel.text = action;
            cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
            if ([action isEqualToString:ACTION_BDC_PROCESSING] || [action isEqualToString:ACTION_BDC_PROCESSING2]) {
                cell.textLabel.numberOfLines = 3;
                cell.textLabel.font = [UIFont systemFontOfSize:14];
            } else {
                cell.textLabel.numberOfLines = 1;
                cell.textLabel.adjustsFontSizeToFitWidth = YES;
                cell.textLabel.minimumScaleFactor = 10;
            }
            
            [self addSelectedBackGroundForCell:cell];
            
            if ([action isEqualToString:ACTION_PAY]) {
                [self.payAmountLabel removeFromSuperview];
                self.payAmountLabel = nil;
                self.payAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 7, 185, cell.viewForBaselineLayout.bounds.size.height - 12)];
                self.payAmountLabel.textAlignment = NSTextAlignmentRight;
                
                if ([((NSArray *)[BankAccount list]) count]) {
                    Bill *bill = (Bill *)((EditBillViewController *)self.targetViewController).busObj;
                    NSDecimalNumber *payAmount = [bill.amount decimalNumberBySubtracting:bill.paidAmount];
                    self.payAmountLabel.text = [Util formatCurrency:payAmount];
                    self.payAmountLabel.textColor = [UIColor whiteColor];
                    self.payAmountLabel.font = [UIFont fontWithName:APP_FONT size:16];
                    
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                } else {
                    self.payAmountLabel.text = @"No bank account for Payables";
                    self.payAmountLabel.font = [UIFont systemFontOfSize:13.0f];
                    self.payAmountLabel.textColor = [UIColor orangeColor];
                    
                    cell.textLabel.textColor = [UIColor lightGrayColor];
                }
                
                self.payAmountLabel.backgroundColor = [UIColor clearColor];
                
                [cell addSubview:self.payAmountLabel];
            }
        }
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

- (void)performSegueForObject:(BDCBusinessObject *)obj {
    if ([obj isKindOfClass:[Invoice class]]) {
        InvoicesTableViewController *listVC = (InvoicesTableViewController *)[self slideInListViewIdentifier:MENU_INVOICES];
        self.actionDelegate = listVC;
        
        [self.actionDelegate didSelectSortAttribute:[listVC.actionMenuVC.sortAttributes objectAtIndex:listVC.actionMenuVC.lastSortAttribute.row]
                                          ascending:(listVC.actionMenuVC) ? listVC.actionMenuVC.ascSwitch.on : YES
                                             active:!listVC.actionMenuVC.activenessSwitch.selectedSegmentIndex];
        
        [listVC performSegueWithIdentifier:@"ViewInvoice" sender:(Invoice *)obj];
        [[RootMenuViewController sharedInstance].menuTableView selectRowAtIndexPath:[NSIndexPath indexPathForItem:kARInvoice inSection:kRootAR] animated:NO scrollPosition:UITableViewScrollPositionNone];
    } else if ([obj isKindOfClass:[Bill class]]) {
        BillsTableViewController *listVC = (BillsTableViewController *)[self slideInListViewIdentifier:MENU_BILLS];
        self.actionDelegate = listVC;
        
        [self.actionDelegate didSelectSortAttribute:[listVC.actionMenuVC.sortAttributes objectAtIndex:listVC.actionMenuVC.lastSortAttribute.row]
                                          ascending:(listVC.actionMenuVC) ? listVC.actionMenuVC.ascSwitch.on : YES
                                             active:!listVC.actionMenuVC.activenessSwitch.selectedSegmentIndex];
        
        [listVC performSegueWithIdentifier:@"ViewBill" sender:(Bill *)obj];
        [[RootMenuViewController sharedInstance].menuTableView selectRowAtIndexPath:[NSIndexPath indexPathForItem:kAPBill inSection:kRootAP] animated:NO scrollPosition:UITableViewScrollPositionNone];
    } else if ([obj isKindOfClass:[Customer class]]) {
        [[self slideInListViewIdentifier:MENU_CUSTOMERS] performSegueWithIdentifier:@"ViewCustomer" sender:(Customer *)obj];
        [[RootMenuViewController sharedInstance].menuTableView selectRowAtIndexPath:[NSIndexPath indexPathForItem:kARCustomer inSection:kRootAR] animated:NO scrollPosition:UITableViewScrollPositionNone];
    } else if ([obj isKindOfClass:[Item class]]) {
        [[self slideInListViewIdentifier:MENU_ITEMS] performSegueWithIdentifier:@"ViewItem" sender:(Item *)obj];
        [[RootMenuViewController sharedInstance].menuTableView selectRowAtIndexPath:[NSIndexPath indexPathForItem:kARItem inSection:kRootAR] animated:NO scrollPosition:UITableViewScrollPositionNone];
    } else if ([obj isKindOfClass:[Vendor class]]) {
        [[self slideInListViewIdentifier:MENU_VENDORS] performSegueWithIdentifier:@"ViewVendor" sender:(Vendor *)obj];
        [[RootMenuViewController sharedInstance].menuTableView selectRowAtIndexPath:[NSIndexPath indexPathForItem:kAPVendor inSection:kRootAP] animated:NO scrollPosition:UITableViewScrollPositionNone];
    } else if ([obj isKindOfClass:[Document class]]) {
        [self slideInListViewIdentifier:MENU_INBOX];
        [[RootMenuViewController sharedInstance].menuTableView selectRowAtIndexPath:[NSIndexPath indexPathForItem:kToolInbox inSection:kRootTool] animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        [self.searchDisplayController setActive:NO animated:YES];
        [self.targetViewController slideOut];
        
        BDCBusinessObject * obj = (BDCBusinessObject *)[[self.searchResults objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        
        [self performSegueForObject:obj];
        
//        if ([obj isKindOfClass:[Invoice class]]) {            
//            InvoicesTableViewController *listVC = (InvoicesTableViewController *)[ActionMenuViewController slideInListViewIdentifier:MENU_INVOICES];
//            self.actionDelegate = listVC;
//            
//            [self.actionDelegate didSelectSortAttribute:[listVC.actionMenuVC.sortAttributes objectAtIndex:listVC.actionMenuVC.lastSortAttribute.row]
//                                              ascending:(listVC.actionMenuVC) ? listVC.actionMenuVC.ascSwitch.on : YES
//                                                 active:!listVC.actionMenuVC.activenessSwitch.selectedSegmentIndex];
//            
//            [listVC performSegueWithIdentifier:@"ViewInvoice" sender:(Invoice *)obj];
//        } else if ([obj isKindOfClass:[Bill class]]) {
//            BillsTableViewController *listVC = (BillsTableViewController *)[ActionMenuViewController slideInListViewIdentifier:MENU_BILLS];
//            self.actionDelegate = listVC;
//            
//            [self.actionDelegate didSelectSortAttribute:[listVC.actionMenuVC.sortAttributes objectAtIndex:listVC.actionMenuVC.lastSortAttribute.row]
//                                              ascending:(listVC.actionMenuVC) ? listVC.actionMenuVC.ascSwitch.on : YES
//                                                 active:!listVC.actionMenuVC.activenessSwitch.selectedSegmentIndex];
//            
//            [listVC performSegueWithIdentifier:@"ViewBill" sender:(Bill *)obj];
//        } else if ([obj isKindOfClass:[Customer class]]) {
//            [[ActionMenuViewController slideInListViewIdentifier:MENU_CUSTOMERS] performSegueWithIdentifier:@"ViewCustomer" sender:(Customer *)obj];
//        } else if ([obj isKindOfClass:[Item class]]) {
//            [[ActionMenuViewController slideInListViewIdentifier:MENU_ITEMS] performSegueWithIdentifier:@"ViewItem" sender:(Item *)obj];
//        } else if ([obj isKindOfClass:[Vendor class]]) {
//            [[ActionMenuViewController slideInListViewIdentifier:MENU_VENDORS] performSegueWithIdentifier:@"ViewVendor" sender:(Vendor *)obj];
//        }
    } else {
        if (self.targetViewController.sortAttributes) {
            if (indexPath.section == 1) {
                if (self.targetViewController.sortAttributes.count > 0) {
                    if (!self.orderSectionCollapsed) {
                        [self.tableView cellForRowAtIndexPath:self.lastSortAttribute].accessoryType = UITableViewCellAccessoryNone;
                        self.lastSortAttribute = indexPath;
                        [self.tableView cellForRowAtIndexPath:self.lastSortAttribute].accessoryType = UITableViewCellAccessoryCheckmark;
                        
                        [self.actionDelegate didSelectSortAttribute:[self.targetViewController.sortAttributes objectAtIndex:self.lastSortAttribute.row]
                                                          ascending:self.ascSwitch.on
                                                             active:!self.activenessSwitch.selectedSegmentIndex];
                    }
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
        return ACTION_MENU_CELL_HEIGHT;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return ACTION_MENU_SECTION_HEADER_HEIGHT;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, ACTION_MENU_SECTION_HEADER_HEIGHT)];
    headerView.backgroundColor = [UIColor darkGrayColor];
    
    UILabel *label = [[UILabel alloc] initWithFrame:SECTION_HEADER_LABEL_RECT];
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
                        [headerView addSubview:self.orderSectionToggleImage];
                        [headerView addSubview:self.orderSectionToggleButton];
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
                                    predicateWithFormat:@"name BEGINSWITH[CD] %@ OR name CONTAINS[CD] %@",
                                    searchText, [NSString stringWithFormat:@" %@", searchText]];
    
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
    
    if ([filteredBills count]) {
        [self.searchResults addObject:filteredBills];
        [self.searchResultTypes addObject:@"Bills"];
    }
    if ([filteredInvs count]) {
        [self.searchResults addObject:filteredInvs];
        [self.searchResultTypes addObject:@"Invoices"];
    }
    if ([filteredVendors count]) {
        [self.searchResults addObject:filteredVendors];
        [self.searchResultTypes addObject:@"Vendors"];
    }
    if ([filteredCustomers count]) {
        [self.searchResults addObject:filteredCustomers];
        [self.searchResultTypes addObject:@"Customers"];
    }
    if ([filteredItems count]) {
        [self.searchResults addObject:filteredItems];
        [self.searchResultTypes addObject:@"Items"];
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
