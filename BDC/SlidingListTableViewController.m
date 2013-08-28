//
//  SlidingListTableViewController.m
//  BDC
//
//  Created by Qinwei Gong on 4/11/13.
//
//

#import "SlidingListTableViewController.h"
#import "ScannerViewController.h"
#import "BDCBusinessObjectWithAttachments.h"
#import "APIHandler.h"
#import "Uploader.h"
#import "UIHelper.h"


@implementation SlidingListTableViewController

@synthesize busObjClass;
@synthesize document;
@synthesize createNewSegue;
@synthesize listViewDelegate;
@synthesize lastSelected;
@synthesize activityIndicator;


- (void)navigateDone {}

- (void)navigateAttach {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.lastSelected];
    cell.accessoryView = self.activityIndicator;
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
}

- (void)navigateCancel {
    if ([self tryTap]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.listViewDelegate = self;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.hidesWhenStopped = YES;
    [self.activityIndicator stopAnimating];
    
    if (self.mode != kSelectMode && self.mode != kAttachMode) {
        UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
        [refresh addTarget:self action:@selector(refreshView) forControlEvents:UIControlEventValueChanged];
        refresh.attributedTitle = PULL_TO_REFRESH;
        self.refreshControl = refresh;
    }
    
    [self setSlidingMenuLeftBarButton];
    [self setActionMenuRightBarButton];
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.mode == kSelectMode || self.mode == kAttachMode) {        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]
                                         initWithTitle: @"Cancel"
                                         style: UIBarButtonItemStyleBordered
                                         target: self action:@selector(navigateCancel)];
        
        self.navigationItem.leftBarButtonItem = cancelButton;
    }
    
    if (self.mode == kSelectMode) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
                                       initWithTitle: @"Done"
                                       style: UIBarButtonItemStyleDone
                                       target: self action:@selector(navigateDone)];
        
        self.navigationItem.rightBarButtonItem = doneButton;
    } else if (self.mode == kAttachMode) {
        UIBarButtonItem *attachButton = [[UIBarButtonItem alloc]
                                         initWithTitle: @"Attach"
                                         style: UIBarButtonItemStyleDone
                                         target: self action:@selector(navigateAttach)];
        
        self.navigationItem.rightBarButtonItem = attachButton;
    }
}

// private
- (void)performSegueForObject:(BDCBusinessObject *)obj {
    UIViewController *vc = self.navigationController.childViewControllers[0];
    [self.navigationController popToRootViewControllerAnimated:NO];
    
    [[ActionMenuViewController sharedInstance] performSegueForObject:obj];
    [vc disappear];
    if ([vc isKindOfClass:[ScannerViewController class]]) {
        [((ScannerViewController *)vc) reset];
    }
}

- (void)handleAttachFailure:(NSError *)err forObject:(BDCBusinessObject *)obj {
    [self.activityIndicator stopAnimating];
    [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
    NSLog(@"Failed to associate document %@ with %@: %@", self.document.name, obj.name, [err localizedDescription]);
}

- (void)attachDocumentForObject:(BDCBusinessObjectWithAttachments *)obj {
    if (self.document.objectId) {
        NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\", \"name\" : \"%@\", \"objId\" : \"%@\"}", ID, self.document.objectId, self.document.name, obj.objectId];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA, objStr, nil];
        
        [APIHandler asyncCallWithAction:ASSIGN_DOCS_API Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
            NSInteger response_status;
            [APIHandler getResponse:response data:data error:&err status:&response_status];
            
            if(response_status == RESPONSE_SUCCESS) {
                [Document removeFromInbox:self.document];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.activityIndicator stopAnimating];
                    [self performSegueForObject:obj];
                });
            } else {
                [self handleAttachFailure:err forObject:obj];
            }
        }];
    } else {
        if (self.document.data && self.document.name) {
            [Uploader uploadFile:self.document.name data:self.document.data objectId:obj.objectId handler:^(NSURLResponse * response, NSData * data, NSError * err) {
                NSInteger status;
                NSString *info = [APIHandler getResponse:response data:data error:&err status:&status];
                
                if(status == RESPONSE_SUCCESS) {
                    if (![info isEqualToString:EMPTY_ID]) {
                        self.document.objectId = info;
                    }
                    [obj.attachmentDelegate didUploadDocument:self.document needUI:YES];
                } else {
                    [self handleAttachFailure:err forObject:obj];
                }
            }];
            
            [UIHelper showInfo:@"Documents upload in progress.\n\nIt'll show up once uploaded." withStatus:kInfo];
            [self.activityIndicator stopAnimating];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSegueForObject:obj];
            });
        }
    }
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
//    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(toggleMenu:)];
//    actionButton.tag = 1;
//    [self.navigationItem setRightBarButtonItem:actionButton];

    [self setActionMenuRightBarButton];
    [self.tableView setEditing:NO animated:YES];
}

- (void)refreshView {
    self.refreshControl.attributedTitle = REFRESHING;
    
    if (!self.actionMenuVC || !self.actionMenuVC.activenessSwitch || self.actionMenuVC.activenessSwitch.selectedSegmentIndex == 0) {
        [[self busObjClass] retrieveListForActive:YES];
    } else {
        [[self busObjClass] retrieveListForActive:NO];
    }
    
    [self exitEditMode];
}

#pragma mark - Model Delegate methods

- (void)didDeleteObject:(NSIndexPath *)indexPath {
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

@end
