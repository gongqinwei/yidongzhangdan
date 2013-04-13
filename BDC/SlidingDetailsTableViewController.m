//
//  SlidingDetailsTableViewController.m
//  BDC
//
//  Created by Qinwei Gong on 4/11/13.
//
//

#import "SlidingDetailsTableViewController.h"

@interface SlidingDetailsTableViewController()

- (void)doneSaveObject;

@end


@implementation SlidingDetailsTableViewController

@synthesize busObj;
@synthesize activityIndicator;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.mode == kViewMode) {
        self.isActive = self.busObj.isActive;
        self.crudActions = [NSArray arrayWithObjects:ACTION_UPDATE, ACTION_DELETE, nil];
        self.inactiveCrudActions = [NSArray arrayWithObjects:ACTION_UPDATE, ACTION_UNDELETE, nil];
    }
}

- (void)navigateBack {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Action Menu delegate

- (void)didSelectCrudAction:(NSString *)action {
    if ([action isEqualToString:ACTION_UPDATE]) {
        self.mode = kUpdateMode;
    } else if ([action isEqualToString:ACTION_DELETE] || [action isEqualToString:ACTION_UNDELETE]) {
        if (self.busObj) {            
            if (self.busObj.isActive) {
                [self.busObj remove];
                self.actionMenuVC.crudActions = self.inactiveCrudActions;
                self.isActive = NO;
//                [[self.busObj class] retrieveListForActive:YES];
            } else {
                [self.busObj revive];
                self.actionMenuVC.crudActions = self.crudActions;
                self.isActive = YES;
//                [[self.busObj class] retrieveListForActive:NO];
            }
            
            [self.actionMenuVC.tableView reloadData];
        }
    }
}

#pragma mark - Model Delegate methods

- (void)doneSaveObject {
    // to be overridden
}

- (void)didUpdateObject {
    [self doneSaveObject];
}

- (void)failedToSaveObject {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicator stopAnimating];
//        self.navigationItem.rightBarButtonItem.customView = nil;
    });
}

- (void)didDeleteObject {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
    });
}

@end
