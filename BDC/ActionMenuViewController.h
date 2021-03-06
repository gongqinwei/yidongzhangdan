//
//  ActionMenuViewController.h
//  BDC
//
//  Created by Qinwei Gong on 3/14/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+Sliding.h"
#import "BDCBusinessObject.h"

@class SlidingTableViewController;

@protocol ActionMenuDelegate;

@interface ActionMenuViewController : UITableViewController

@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) UIViewController *targetViewController;
@property (nonatomic, strong) UISegmentedControl *activenessSwitch;
@property (nonatomic, strong) UISwitch *ascSwitch;

@property (nonatomic, weak) id<ActionMenuDelegate> actionDelegate;
@property (nonatomic, strong) NSIndexPath *lastSortAttribute;

@property (nonatomic, strong) NSArray *crudActions;

- (void)performSegueForObject:(BDCBusinessObject *)obj;

+ (ActionMenuViewController *)sharedInstance;

@end
