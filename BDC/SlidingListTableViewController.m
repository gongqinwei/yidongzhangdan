//
//  SlidingListTableViewController.m
//  BDC
//
//  Created by Qinwei Gong on 4/11/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "SlidingListTableViewController.h"
#import "ScannerViewController.h"
#import "BDCBusinessObjectWithAttachments.h"
#import "APIHandler.h"
#import "Uploader.h"
#import "UIHelper.h"
#import "TutorialControl.h"


#define LIST_VC_TUTORIAL             @"LIST_VC_TUTORIAL"

@interface SlidingListTableViewController()

@property (nonatomic, strong) TutorialControl *listVCTutorialOverlay;

@end


@implementation SlidingListTableViewController

@synthesize busObjClass;
@synthesize document;
@synthesize createNewSegue;
@synthesize listViewDelegate;
@synthesize lastSelected;
@synthesize activityIndicator;
@synthesize indice;
@synthesize alphabets;

@synthesize listVCTutorialOverlay;


- (NSMutableArray *)sortAlphabeticallyForList:(NSArray *)list {
    NSMutableDictionary *buckets = [NSMutableDictionary dictionary];
    
    NSMutableArray *bucket;
    for (BDCBusinessObject *obj in list) {
        NSString *firstChar = [[obj.name substringToIndex:1] uppercaseString];
        if (![buckets objectForKey:firstChar]) {
            bucket = [NSMutableArray array];
            [buckets setObject:bucket forKey:firstChar];
        } else {
            bucket = [buckets objectForKey:firstChar];
        }
        [bucket addObject:obj];
    }
    
    NSMutableArray *alphabeticLists = [NSMutableArray array];	
    self.indice = [NSMutableArray array];
    
    for (NSString *alphabet in ALPHABETS) {
        if ([buckets objectForKey:alphabet]) {
            [alphabeticLists addObject:[buckets objectForKey:alphabet]];
            [self.indice addObject:alphabet];
            
            [buckets removeObjectForKey:alphabet];
        }
    }
    
    NSMutableArray *elseList = [NSMutableArray array];
    
    for (NSArray *subList in [buckets allValues]) {
        [elseList addObjectsFromArray:subList];
    }
    
    if (elseList.count > 0) {
        [alphabeticLists addObject:elseList];
        [self.indice addObject:@"123"];
    }
    
    return alphabeticLists;
}

- (void)toggleMenu:(id)sender {
    [self.listVCTutorialOverlay removeFromSuperview];
    
    float origX = self.navigationController.view.frame.origin.x;
    
    [super toggleMenu:sender];

    float destX = self.navigationController.view.frame.origin.x;
    
    if (destX < 0) {
        self.alphabets = nil;
        [self.tableView reloadData];
    } else if (destX == 0 && origX < 0) {
        self.alphabets = ALPHABETS;
        [self.tableView reloadData];
    }
}

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
    
    self.alphabets = ALPHABETS;
    
    // one time tutorial
    BOOL tutorialValue = [[NSUserDefaults standardUserDefaults] boolForKey:LIST_VC_TUTORIAL];
    if (!tutorialValue) {
        self.listVCTutorialOverlay = [[TutorialControl alloc] init];
        [self.listVCTutorialOverlay addText:@"Swipe right to reveal menu" at:SWIPE_RIGHT_TUTORIAL_RECT];
        [self.listVCTutorialOverlay addImageNamed:@"arrow_right.png" at:SWIPE_RIGHT_ARROW_RECT];
        [self.listVCTutorialOverlay addText:@"Swipe left to reveal actions" at:SWIPE_LEFT_TUTORIAL_RECT];
        [self.listVCTutorialOverlay addImageNamed:@"arrow_left.png" at:SWIPE_LEFT_ARROW_RECT];
        [self.view addSubview:self.listVCTutorialOverlay];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:LIST_VC_TUTORIAL];
    }
}

- (void)setupBarButtons {
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
    } else {
        if (self == self.navigationController.viewControllers[0]) {
            [self setSlidingMenuLeftBarButton];
        }

        [self setActionMenuRightBarButton];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self setupBarButtons];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self setupBarButtons];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self setupBarButtons];
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
    [UIHelper showInfo:[NSString stringWithFormat:@"Failed to associate document %@ with %@: %@", self.document.name, obj.name, [err localizedDescription]] withStatus:kFailure];
    Debug(@"Failed to associate document %@ with %@: %@", self.document.name, obj.name, [err localizedDescription]);
}

- (void)attachDocumentForObject:(BDCBusinessObjectWithAttachments *)obj {
    if (self.document.objectId) {
        NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\", \"name\" : \"%@\", \"objId\" : \"%@\"}", _ID, self.document.objectId, self.document.name, obj.objectId];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA_, objStr, nil];
        
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
                NSDictionary *info = [APIHandler getResponse:response data:data error:&err status:&status];
                NSString *documentUploadedId = info[@"documentUploadedId"];
                
                if(status == RESPONSE_SUCCESS) {
                    if (![documentUploadedId isEqualToString:EMPTY_ID]) {
                        self.document.objectId = documentUploadedId;
                    }
                    [obj.attachmentDelegate didUploadDocument:self.document needUI:YES];
                } else {
                    [self handleAttachFailure:err forObject:obj];
                }
            }];
            
            [UIHelper showInfo:@"Upload in progress. It'll show up once uploaded." withStatus:kSuccess];
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
