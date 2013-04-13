//
//  SlidingListTableViewController.m
//  BDC
//
//  Created by Qinwei Gong on 4/11/13.
//
//

#import "SlidingListTableViewController.h"

@implementation SlidingListTableViewController

@synthesize createNewSegue;
@synthesize listViewDelegate;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.listViewDelegate = self;
}

#pragma mark - Action Menu delegate

- (void)didSelectCrudAction:(NSString *)action {
    if ([action isEqualToString:ACTION_CREATE]) {
        [self.view removeGestureRecognizer:self.tapRecognizer];
        [self performSegueWithIdentifier:self.createNewSegue sender:nil];
    } else if ([action isEqualToString:ACTION_DELETE] || [action isEqualToString:ACTION_UNDELETE]) {
        [self enterEditMode];
    }
}

#pragma mark - Overriding methods

- (void)enterEditMode {
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(exitEditMode)];
    [self.navigationItem setRightBarButtonItem:doneButton];
    
    [self.tableView setEditing:YES animated:YES];
}

- (void)exitEditMode {
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(toggleMenu:)];
    actionButton.tag = 1;
    [self.navigationItem setRightBarButtonItem:actionButton];
    
    [self.tableView setEditing:NO animated:YES];
}

#pragma mark - Model Delegate methods

- (void)didDeleteObject:(NSIndexPath *)indexPath {
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

@end
