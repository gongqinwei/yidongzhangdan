//
//  SlidingDetailsTableViewController.m
//  BDC
//
//  Created by Qinwei Gong on 4/11/13.
//
//

#import "SlidingDetailsTableViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface SlidingDetailsTableViewController()

- (void)doneSaveObject;

@end


@implementation SlidingDetailsTableViewController

@synthesize busObj;
@synthesize activityIndicator;
@synthesize inputAccessoryView;

- (void)viewWillAppear:(BOOL)animated {
    [self.view removeGestureRecognizer:self.tapRecognizer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.mode == kViewMode) {
        self.isActive = self.busObj.isActive;
        self.crudActions = [NSArray arrayWithObjects:ACTION_UPDATE, ACTION_DELETE, nil];
        self.inactiveCrudActions = [NSArray arrayWithObjects:ACTION_UPDATE, ACTION_UNDELETE, nil];
    } 
    
    self.inputAccessoryView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, ToolbarHeight)];
    self.inputAccessoryView.barStyle = UIBarStyleBlackTranslucent;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:StrDone
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(inputAccessoryDoneAction:)];
    self.inputAccessoryView.items = [NSArray arrayWithObjects:flexibleSpace, doneButton, nil];
}

- (void)inputAccessoryDoneAction:(UIBarButtonItem *)button {
    [self.view findAndResignFirstResponder];
}

- (void)navigateBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)initializeTextField:(UITextField *)textField {
    textField.font = [UIFont fontWithName:APP_FONT size:APP_LABEL_FONT_SIZE];
    textField.textColor = APP_LABEL_BLUE_COLOR;
    textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    textField.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone; // no auto capitalization support
    textField.textAlignment = UITextAlignmentRight;
    textField.enabled = YES;
    textField.layer.cornerRadius = 8.0f;
    textField.layer.masksToBounds = YES;
    textField.layer.borderColor = [[UIColor grayColor]CGColor];
    textField.layer.borderWidth = 0.5f;
    textField.rightView = [[UIView alloc] initWithFrame:TEXT_FIELD_RIGHT_PADDING_RECT];
    textField.inputAccessoryView = self.inputAccessoryView;
}

#pragma mark - Action Menu delegate

- (void)toggleActiveness {
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

- (void)didSelectCrudAction:(NSString *)action {
    if ([action isEqualToString:ACTION_UPDATE]) {
        self.mode = kUpdateMode;
    } else if ([action isEqualToString:ACTION_DELETE]) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle: @"Delete Confirmation"
                              message: [NSString stringWithFormat:@"Are you sure to delete this %@?", [self.busObj class]]
                              delegate: self
                              cancelButtonTitle:@"No"
                              otherButtonTitles:@"Yes", nil];
//        alert.tag = DELETE_INV_ALERT_TAG;
        [alert show];
    } else if ([action isEqualToString:ACTION_UNDELETE]) {
        [self toggleActiveness];        
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
        self.navigationItem.rightBarButtonItem.customView = nil;
    });
}

- (void)didDeleteObject {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
    });
}

#pragma mark - Alert delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self toggleActiveness];
    }
}

@end
