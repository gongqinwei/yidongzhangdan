//
//  SlidingListTableViewController.m
//  BDC
//
//  Created by Qinwei Gong on 4/11/13.
//
//

#import "SlidingListTableViewController.h"
#import "APIHandler.h"
#import "Uploader.h"
#import "UIHelper.h"


@implementation SlidingListTableViewController

@synthesize document;
@synthesize createNewSegue;
@synthesize listViewDelegate;


- (void)navigateDone {}

- (void)navigateAttach {}

- (void)navigateCancel {
    if ([self tryTap]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.listViewDelegate = self;
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
                                       style: UIBarButtonItemStyleBordered
                                       target: self action:@selector(navigateDone)];
        
        self.navigationItem.rightBarButtonItem = doneButton;
    } else if (self.mode == kAttachMode) {
        UIBarButtonItem *attachButton = [[UIBarButtonItem alloc]
                                         initWithTitle: @"Attach"
                                         style: UIBarButtonItemStyleBordered
                                         target: self action:@selector(navigateAttach)];
        
        self.navigationItem.rightBarButtonItem = attachButton;
    }
}

// private
- (void)performSegueForObject:(BDCBusinessObject *)obj {
    SlidingTableViewController *vc = self.navigationController.childViewControllers[0];
    [self.navigationController popToRootViewControllerAnimated:NO];
    
    [[ActionMenuViewController sharedInstance] performSegueForObject:obj];
    [vc disappear];
}

- (void)handleAttachSuccess:(NSString *)info forObject:(BDCBusinessObject *)obj {
    if (![info isEqualToString:EMPTY_ID]) {
        self.document.objectId = info;
    }
    
    [Document removeFromInbox:self.document];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueForObject:obj];
    });
    
    NSLog(@"Successfully associate document %@ with %@", self.document.name, obj.name);
}

- (void)handleAttachFailure:(NSError *)err forObject:(BDCBusinessObject *)obj {
    [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
    NSLog(@"Failed to associate document %@ with %@: %@", self.document.name, obj.name, [err localizedDescription]);
}

- (void)attachDocumentForObject:(BDCBusinessObject *)obj {
    if (self.document.data && self.document.name) {
        if (self.document.objectId) {
            NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\", \"name\" : \"%@\", \"objId\" : \"%@\"}", ID, self.document.objectId, self.document.name, obj.objectId];
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA, objStr, nil];
            
            [APIHandler asyncCallWithAction:ASSIGN_DOCS_API Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
                NSInteger response_status;
                NSString *info = [APIHandler getResponse:response data:data error:&err status:&response_status];
                
                if(response_status == RESPONSE_SUCCESS) {
                    [self handleAttachSuccess:info forObject:obj];
                } else {
                    [self handleAttachFailure:err forObject:obj];
                }
            }];
        } else {
            [Uploader uploadFile:self.document.name data:self.document.data objectId:obj.objectId handler:^(NSURLResponse * response, NSData * data, NSError * err) {
                NSInteger status;
                NSString *info = [APIHandler getResponse:response data:data error:&err status:&status];
                
                if(status == RESPONSE_SUCCESS) {
                    [self handleAttachSuccess:info forObject:obj];
                } else {
                    [self handleAttachFailure:err forObject:obj];
                }
            }];
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
