//
//  SlidingDetailsTableViewController.m
//  BDC
//
//  Created by Qinwei Gong on 4/11/13.
//
//

#import "SlidingDetailsTableViewController.h"
#import "Document.h"
#import "Bill.h"
#import "Constants.h"
#import "APIHandler.h"
#import "UIHelper.h"
#import "Uploader.h"
#import <QuartzCore/QuartzCore.h>


#define IMG_PADDING                     10
#define IMG_WIDTH                       CELL_WIDTH / 4
#define IMG_HEIGHT                      IMG_WIDTH - IMG_PADDING
#define NUM_ATTACHMENT_PER_PAGE         4

static const CGFloat KEYBOARD_ANIMATION_DURATION = 0.3;
static const CGFloat MINIMUM_SCROLL_FRACTION = 0.2;
static const CGFloat MAXIMUM_SCROLL_FRACTION = 0.8;
static const CGFloat PORTRAIT_KEYBOARD_HEIGHT = 216;
static double animatedDistance = 0;


@interface SlidingDetailsTableViewController()

- (void)doneSaveObject;

@end


@implementation SlidingDetailsTableViewController

@synthesize busObjClass;
@synthesize busObj = _busObj;
@synthesize shaddowBusObj;
@synthesize modeChanged;
@synthesize activityIndicator;
@synthesize inputAccessoryView;
@synthesize attachmentDict;
@synthesize docsUploading;
@synthesize attachmentScrollView;
@synthesize attachmentPageControl;
@synthesize currAttachment;
@synthesize previewController;


- (void)setBusObj:(BDCBusinessObjectWithAttachments *)busObj {
    _busObj = busObj;
    
    self.shaddowBusObj = [[[busObj class] alloc] init];
    [[busObj class] clone:busObj to:self.shaddowBusObj];
    
    self.attachmentDict = [NSMutableDictionary dictionaryWithDictionary:self.busObj.attachmentDict];
}

- (void)setMode:(ViewMode)mode {
    super.mode = mode;
    self.modeChanged = YES;
    
    if (mode == kViewMode) {
        self.isActive = self.busObj.isActive;
        self.crudActions = [NSArray arrayWithObjects:ACTION_UPDATE, ACTION_DELETE, nil];
        self.inactiveCrudActions = [NSArray arrayWithObjects:ACTION_UPDATE, ACTION_UNDELETE, nil];
        if (self.isActive) {
            self.actionMenuVC.crudActions = self.crudActions;
        } else {
            self.actionMenuVC.crudActions = self.inactiveCrudActions;
        }
        [self.actionMenuVC.tableView reloadData];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(toggleMenu:)];
        self.navigationItem.rightBarButtonItem.tag = 1;
        self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
        
        UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
        [refresh addTarget:self action:@selector(refreshView) forControlEvents:UIControlEventValueChanged];
        refresh.attributedTitle = PULL_TO_REFRESH;
        self.refreshControl = refresh;
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveBusObj:)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEdit:)];
        
        self.refreshControl = nil;
    }
    
    // retrieve attachments
    // clean up first
    @synchronized (self) {
        for (UIView *subview in [self.attachmentScrollView subviews]) {
            if ([subview isKindOfClass:[UIImageView class]]) {
                [subview removeFromSuperview];
            }
        }

        for (Document * doc in self.shaddowBusObj.attachments) {
            NSLog(@":: %@", doc.objectId);
            
            NSString *ext = [[doc.name pathExtension] lowercaseString];
            [self addAttachment:ext data:doc.data];
        }
    }
    
    [self layoutScrollImages:NO];
    
    [self.tableView reloadData];
}

- (void)cancelEdit:(UIBarButtonItem *)sender {
    if ([self tryTap]) {
        if (self.mode == kCreateMode || self.mode == kAttachMode) {
            [self navigateBack];
        } else {
            [self setBusObj:self.busObj];
            self.mode = kViewMode;
        }
    }
}

- (NSIndexPath *)getAttachmentPath {
    return nil;
}

// There's no way to call this method concurrently
// So no need to synchronize
- (void)addDocument:(Document *)document {
    if (!self.shaddowBusObj) {
        self.shaddowBusObj = [[self.busObjClass alloc] init];
    }
    
    if (!self.busObj) {
        self.busObj = [[self.busObjClass alloc] init];
    }
    
    if (!self.attachmentDict) {
        self.attachmentDict = [NSMutableDictionary dictionary];
    }
    
    if (document) {
        [self.shaddowBusObj.attachments addObject:document];
        [self.previewController reloadData];
    }
}

- (void)addAttachment:(NSString *)ext data:(NSData *)attachmentData {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[Document getIconForType:ext data:attachmentData]];
    
    CGRect rect = imageView.frame;
    rect.size.height = IMG_HEIGHT;
    rect.size.width = IMG_WIDTH - IMG_PADDING;
    imageView.frame = rect;
    imageView.tag = [self.shaddowBusObj.attachments count];
    imageView.layer.cornerRadius = 8.0f;
    imageView.layer.masksToBounds = YES;
    imageView.layer.borderColor = [[UIColor clearColor]CGColor];
    imageView.layer.borderWidth = 1.0f;
    
    imageView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    [imageView addGestureRecognizer:tap];
    
    if (self.mode != kViewMode) {
        UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(imagePressed:)];
        press.minimumPressDuration = 1.0;
        [imageView addGestureRecognizer:press];
    }
    
    [self.attachmentScrollView addSubview:imageView];
}

- (void)selectAttachment:(UIImageView *)imageView {
    self.currAttachment.layer.borderColor = [[UIColor clearColor]CGColor];
    self.currAttachment.layer.borderWidth = 0.0f;
    
    imageView.layer.borderColor = [[UIColor whiteColor]CGColor];
    imageView.layer.borderWidth = 2.0f;
    self.currAttachment = imageView;
}

- (void)imageTapped:(UITapGestureRecognizer *)gestureRecognizer {
    if ([self tryTap]) {
        UIImageView *imageView = (UIImageView *)gestureRecognizer.view;
        
        self.previewController.currentPreviewItemIndex = imageView.tag;
        [self presentModalViewController:self.previewController animated:YES];
        
        [self selectAttachment:imageView];
//        [self performSegueWithIdentifier:BILL_PREVIEW_ATTACHMENT_SEGUE sender:imageView];
    }
}

- (void)imagePressed:(UILongPressGestureRecognizer *)gestureRecognizer {
    if ([self tryTap]) {
        [self selectAttachment:(UIImageView *)gestureRecognizer.view];
        
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            int idx = self.currAttachment.tag;
            Document *doc = [self.shaddowBusObj.attachments objectAtIndex:idx];
            
            [UIView animateWithDuration:1.0
                             animations:^{
                                 self.currAttachment.alpha = 0.0;
                             }
                             completion:^ (BOOL finished) {
                                 if (finished) {
                                     @synchronized (self) {
                                         [self.shaddowBusObj.attachments removeObjectAtIndex:idx];
                                         [self.previewController reloadData];
                                         
                                         if (doc.objectId) {
                                             [self.attachmentDict removeObjectForKey:doc.objectId];
                                         }
                                         
                                         [self.currAttachment removeFromSuperview];
                                         [self layoutScrollImages:NO];
                                     }

                                     self.currAttachment = nil;
                                 }
                             }];
        }
    }
}

- (IBAction)saveBusObj:(UIBarButtonItem *)sender {
    self.navigationItem.rightBarButtonItem.customView = self.activityIndicator;
    [self.activityIndicator startAnimating];
}

- (void)retrieveDocAttachments {
    NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\"}", ID, self.busObj.objectId];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA, objStr, nil];
    
    [APIHandler asyncCallWithAction:RETRIEVE_DOCS_API Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSArray *jsonDocs = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            @synchronized (self) {
                if (!self.busObj.attachmentDict) {
                    self.busObj.attachmentDict = [NSMutableDictionary dictionary];
                }
                
                self.attachmentDict = [NSMutableDictionary dictionaryWithDictionary:self.busObj.attachmentDict];
                
                self.docsUploading = [NSMutableDictionary dictionary];
                for (Document *doc in self.shaddowBusObj.attachments) {
                    if (!doc.objectId) {
                        // Assumption: fileName is unique.
                        // This is a hack to work around the documentUploaded -> document/documentPage problem
                        [self.docsUploading setObject:doc forKey:doc.name];
                    }
                }
                            
                // reset scroll view first!
                [self resetScrollView];
                
                int i = 0;
                for (NSDictionary *dict in jsonDocs) {
                    NSString *docId = [dict objectForKey:ID];
                    
                    Document *doc;
                    if (![self.attachmentDict objectForKey:docId]) {
                        NSString *docName = [dict objectForKey:FILE_NAME];
                        doc = [self.docsUploading objectForKey:docName];
                        
                        if (doc) {
                            doc.objectId = docId;
                            [self.attachmentDict setObject:doc forKey:docId];
                            [self.shaddowBusObj.attachmentDict setObject:doc forKey:docId];
                            [self.busObj.attachmentDict setObject:doc forKey:docId];
                        } else {
                            doc = [[Document alloc] init];
                            doc.objectId = docId;
                            doc.name = docName;
                            doc.fileUrl = [dict objectForKey:@"fileUrl"];
                            doc.isPublic = [[dict objectForKey:@"isPublic"] intValue];
                            doc.page = [[dict objectForKey:@"page"] intValue];
                            
                            [self.busObj.attachmentDict setObject:doc forKey:docId];
                            [self.attachmentDict setObject:doc forKey:docId];
                            [self.busObj.attachments insertObject:doc atIndex:i];
                            [self.shaddowBusObj.attachments insertObject:doc atIndex:i];
                        }
                    } else {
                        doc = [self.attachmentDict objectForKey:docId];
                    }
                    
                    [self addAttachment:[[doc.name pathExtension] lowercaseString] data:nil];
                    [self layoutScrollImages:NO];
                    if (!doc.data) {
                        [self downloadDocument:doc forAttachmentAtIndex:i];
                    }
                    
                    i++;
                }
            }

            NSIndexPath *path = [self getAttachmentPath];
            if (path) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:YES];
                    [self.previewController reloadData];
                });
            }
        } else {
            NSLog(@"Failed to retrieve attachments for %@: %@", self.busObj.name, [err localizedDescription]);
        }
    }];
}

- (void)downloadDocument:(Document *)doc forAttachmentAtIndex:(int)idx {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", DOMAIN_URL, doc.fileUrl]];
    NSURLRequest *req = [NSURLRequest  requestWithURL:url
                                          cachePolicy:NSURLRequestUseProtocolCachePolicy
                                      timeoutInterval:API_TIMEOUT];
    
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               doc.data = data;
                               
                               if ([self.attachmentDict objectForKey:doc.objectId]) {
                                   NSString *ext = [[doc.name pathExtension] lowercaseString];
                                   
                                   if ([IMAGE_TYPE_SET containsObject:ext]) {
                                       UIImage *image = [UIImage imageWithData:data];
                                       
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           UIImageView *img = [self.attachmentScrollView.subviews objectAtIndex: idx];
                                           img.alpha = 0.0;
                                           img.image = image;
                                           [img setNeedsDisplay];
                                                                                      
                                           [UIView animateWithDuration:1.5
                                                            animations:^{
                                                                img.alpha = 1.0;
                                                            }
                                                            completion:^ (BOOL finished) {
                                                            }];
                                       });
                                   }
                               }
                           }];
}

- (void)layoutScrollImages:(BOOL)needChangePage {
    UIImageView *view = nil;
    NSArray *subviews = [self.attachmentScrollView subviews];
    
    // reposition all image subviews in a horizontal serial fashion
    CGFloat curXLoc = 0;
    NSInteger tag = 0;
    for (view in subviews) {
        CGRect frame = view.frame;
        frame.origin = CGPointMake(curXLoc, 0);
        view.frame = frame;
        view.tag = tag;
        tag++;
        curXLoc += IMG_WIDTH;
    }
    
    //    int numPages = ceil((float)[self.attachmentNames count] / INV_NUM_ATTACHMENT_PER_PAGE);
    int numPages = ceil((float)tag / NUM_ATTACHMENT_PER_PAGE);
    
    self.attachmentPageControl.numberOfPages = numPages;
    
    int spaces = numPages * NUM_ATTACHMENT_PER_PAGE;
    [self.attachmentScrollView setContentSize:CGSizeMake(spaces * IMG_WIDTH, [self.attachmentScrollView bounds].size.height)];
    
    if (needChangePage || self.attachmentPageControl.currentPage == numPages-1) {
        self.attachmentPageControl.currentPage = numPages - 1;
        
        CGPoint offset = CGPointMake(self.attachmentPageControl.currentPage * NUM_ATTACHMENT_PER_PAGE * IMG_WIDTH, 0);
        [self.attachmentScrollView setContentOffset:offset animated:YES];
    }
}

#pragma mark - view controller life cycle

- (void)viewWillAppear:(BOOL)animated {
    [self.view removeGestureRecognizer:self.tapRecognizer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.busObj.attachmentDelegate = self;
    
    self.attachmentPageControl = [[UIPageControl alloc] initWithFrame:ATTACHMENT_PV_RECT];
    self.attachmentPageControl.currentPage = 0;
    
    
    self.inputAccessoryView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, ToolbarHeight)];
    self.inputAccessoryView.barStyle = UIBarStyleBlackTranslucent;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:StrDone
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(inputAccessoryDoneAction:)];
    self.inputAccessoryView.items = [NSArray arrayWithObjects:flexibleSpace, doneButton, nil];
    
    self.previewController = [[QLPreviewController alloc] init];
    self.previewController.delegate = self;
    self.previewController.dataSource = self;
    
    self.title = self.shaddowBusObj.name;
    
    if (self.mode == kViewMode) {
        [self retrieveDocAttachments];
    }
}

- (void)resetScrollView {
    [self.attachmentScrollView removeFromSuperview];
    self.attachmentScrollView = [[UIScrollView alloc] initWithFrame:ATTACHMENT_RECT];
    self.attachmentScrollView.pagingEnabled = YES;
    self.attachmentScrollView.scrollEnabled = YES;
    self.attachmentScrollView.clipsToBounds = YES;
    self.attachmentScrollView.bounces = NO;
    self.attachmentScrollView.showsHorizontalScrollIndicator = NO;
    self.attachmentScrollView.showsVerticalScrollIndicator = NO;
    self.attachmentScrollView.delegate = self;
}

- (void)refreshView {
    self.refreshControl.attributedTitle = REFRESHING;
    [self.shaddowBusObj read];
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

#pragma mark - Scroll View delegate

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    // Update the page when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.attachmentScrollView.frame.size.width;
    
    int page = floor((self.attachmentScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.attachmentPageControl.currentPage = page;
}

#pragma mark - QuickLook Preview Controller Data Source

- (NSInteger) numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    if (controller == self.previewController) {
        NSLog(@"============== preview has %d", self.shaddowBusObj.attachments.count);
        return [self.shaddowBusObj.attachments count];
    } else {
        return 1;
    }
}

- (id<QLPreviewItem>) previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    
    Document *doc = self.shaddowBusObj.attachments[index];
    
    NSString *filePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:doc.name]];
    [doc.data writeToFile:filePath atomically:YES];
    
    return [NSURL fileURLWithPath:filePath];
}

#pragma mark - QuickLook Preview Controller Delegate

- (CGRect)previewController:(QLPreviewController *)controller frameForPreviewItem:(id <QLPreviewItem>)item inSourceView:(UIView **)view {
    *view = self.currAttachment;    //TODO: not called at all?
    return self.currAttachment.bounds;
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

// private
- (void)quitAttachMode {
    SlidingTableViewController *vc = self.navigationController.childViewControllers[0];
    [self.navigationController popToRootViewControllerAnimated:NO];
    
    [[ActionMenuViewController sharedInstance] performSegueForObject:self.busObj];
    [vc disappear];
    if ([vc isKindOfClass:[ScannerViewController class]]) {
        [((ScannerViewController *)vc) reset];
    }
}

- (void)handleRemovalForDocument:(Document *)doc {
}

- (void)transitToViewMode {
    @synchronized (self) {
        [self.busObjClass clone:self.shaddowBusObj to:self.busObj];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.mode == kAttachMode) {
            [self quitAttachMode];
        } else {
            self.mode = kViewMode;
            self.title = self.shaddowBusObj.name;
            [self.previewController reloadData];
        }
    });
}

- (void)doneSaveObject {
    @synchronized (self) {
        NSMutableArray *original = [NSMutableArray arrayWithArray:[self.busObj.attachmentDict allKeys]];
        NSMutableArray *current = [NSMutableArray arrayWithArray:[self.attachmentDict allKeys]];
        [original removeObjectsInArray:current];
        NSMutableArray *toBeDeleted = [NSMutableArray arrayWithArray:original];
        
        NSMutableArray *toBeAttached = [NSMutableArray array];
        NSMutableArray *toBeAdded = [NSMutableArray array];
        
        for (Document *doc in self.shaddowBusObj.attachments) {
            if (doc.objectId == nil) {
                if (![self.docsUploading objectForKey:doc.name]) {
                    [toBeAdded addObject:doc];
                }
            } else {
                if (![self.attachmentDict valueForKey:doc.objectId]) {
                    //                if (self.shaddowBusObj.class == [Bill class]) {     //TODO: for Vendor Credit also once implemented
                    [toBeAttached addObject:doc];
                    //                } else {
                    //                    [toBeAdded addObject:doc];
                    //                }
                }
            }
        }
        
        //    __block int numNotYetAdded = [toBeAdded count];
        
        // 1. upload new attachments
        if (toBeAdded.count > 0) {
            [UIHelper showInfo:@"Documents upload in progress." withStatus:kInfo];
        }
        
        for (Document *doc in toBeAdded) {
            [Uploader uploadFile:doc.name data:doc.data objectId:self.shaddowBusObj.objectId handler:^(NSURLResponse * response, NSData * data, NSError * err) {
                NSInteger response_status;
                NSString *info = [APIHandler getResponse:response data:data error:&err status:&response_status];
                
                if(response_status == RESPONSE_SUCCESS) {
                    if (![info isEqualToString:EMPTY_ID]) {
                        doc.objectId = info;
                        [self.shaddowBusObj.attachmentDict setObject:doc forKey:doc.objectId];
                    }
                    
                    [self.busObj.attachmentDelegate didUploadDocument:doc needUI:NO];
                    
                    //                    [doneLock lock];
                    //
                    //                    numNotYetAdded--;
                    //
                    //                    if (toBeDeleted.count == 0 && toBeAttached.count == 0) {
                    //                        [UIHelper showInfo:@"Done uploading all documents" withStatus:kInfo];
                    //                    }
                    //
                    //                    [doneLock unlock];
                    
                    NSLog(@"Successfully added attachment %@", doc.name);
                } else {
                    [UIHelper showInfo:[NSString stringWithFormat:@"Failed to upload %@", doc.name] withStatus:kFailure];
                }
            }];
        }
        
        if (toBeDeleted.count == 0 && toBeAttached.count == 0) {
            [self transitToViewMode];
        } else {
            NSLock *doneLock = [[NSLock alloc] init];
            
            // 2. remove deleted attachments
            for (NSString *docId in toBeDeleted) {
                Document *doc = [self.busObj.attachmentDict objectForKey:docId];
                NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\", \"objId\" : \"%@\", \"page\" : %d}", ID, docId, self.busObj.objectId, doc.page];
                NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA, objStr, nil];
                
                [APIHandler asyncCallWithAction:REMOVE_DOCS_API Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
                    NSInteger response_status;
                    [APIHandler getResponse:response data:data error:&err status:&response_status];
                    
                    if(response_status == RESPONSE_SUCCESS) {
                        [self.shaddowBusObj.attachmentDict removeObjectForKey:doc.objectId]; //TODO: needed?
                        [self handleRemovalForDocument:doc];
                        
                        [doneLock lock];
                        
                        [toBeDeleted removeObject:docId];
                        
                        if (toBeDeleted.count == 0 && toBeAttached.count == 0) {
                            [self transitToViewMode];
                        }
                        
                        [doneLock unlock];
                        
                        NSLog(@"Successfully deleted attachment %@", doc.name);
                    } else {
                        [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
                        NSLog(@"Failed to delete attachment %@: %@", docId, [err localizedDescription]);
                    }
                }];
            }
            
            // 3. attach documents
            for (Document *doc in toBeAttached) {
                NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\", \"name\" : \"%@\", \"objId\" : \"%@\"}", ID, doc.objectId, doc.name, self.shaddowBusObj.objectId];
                NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA, objStr, nil];
                
                [APIHandler asyncCallWithAction:ASSIGN_DOCS_API Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
                    NSInteger response_status;
                    NSString *info = [APIHandler getResponse:response data:data error:&err status:&response_status];
                    
                    if(response_status == RESPONSE_SUCCESS) {
                        if (![info isEqualToString:EMPTY_ID]) {
                            doc.objectId = info;    //could become an attachment id!
                            [self.shaddowBusObj.attachmentDict setObject:doc forKey:doc.objectId];
                        }
                        
                        [Document removeFromInbox:doc];
                        
                        [doneLock lock];
                        
                        [toBeAttached removeObject:doc];
                        
                        if (toBeDeleted.count == 0 && toBeAttached.count == 0) {
                            [self transitToViewMode];
                        }
                        
                        [doneLock unlock];
                        
                        NSLog(@"Successfully associate document %@", doc.name);
                    } else {
                        [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
                        NSLog(@"Failed to associate document %@: %@", doc.name, [err localizedDescription]);
                    }
                }];
            }
        }
    }
}

- (void)didCreateObject:(NSString *)newObjectId {
    self.busObj.objectId = newObjectId;
    self.shaddowBusObj.objectId = newObjectId;
    
    self.actionMenuVC.actionDelegate = self;
    
    [self doneSaveObject];
}

- (void)didReadObject {
    @synchronized (self) {
        self.shaddowBusObj.attachmentDict = [NSMutableDictionary dictionary];
        self.shaddowBusObj.attachments = [NSMutableArray array];
        [self.shaddowBusObj cloneTo:self.busObj];
    }
    
    [self retrieveDocAttachments];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];

        self.refreshControl.attributedTitle = LAST_REFRESHED;
        [self.refreshControl endRefreshing];
    });
}

- (void)failedToReadObject {
    [self.refreshControl endRefreshing];
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

#pragma mark - Text Field delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {    
    CGRect textFieldRect = [self.view convertRect:textField.bounds fromView:textField];
    CGRect viewRect = [self.view convertRect:self.view.bounds fromView:self.view];
    CGFloat midline = textFieldRect.origin.y + 0.5 * textFieldRect.size.height;
    CGFloat numerator = midline - viewRect.origin.y - MINIMUM_SCROLL_FRACTION * viewRect.size.height;
    CGFloat denominator = (MAXIMUM_SCROLL_FRACTION - MINIMUM_SCROLL_FRACTION) * viewRect.size.height;
    CGFloat heightFraction = numerator / denominator;
    
    if (heightFraction < 0.0) {
        heightFraction = 0.0;
    }else if (heightFraction > 1.0) {
        heightFraction = 1.0;
    }
    
    animatedDistance = floor(PORTRAIT_KEYBOARD_HEIGHT * heightFraction);
    
    CGRect viewFrame = self.view.frame;
    viewFrame.origin.y -= animatedDistance;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
    
    [self.view setFrame:viewFrame];
    
    [UIView commitAnimations];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    CGRect viewFrame = self.view.frame;
    viewFrame.origin.y += animatedDistance;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
    
    [self.view setFrame:viewFrame];
    
    [UIView commitAnimations];
}

#pragma mark - Scan View delegate

- (void)didScanPhoto:(NSData *)photoData name:(NSString *)photoName {
    Document *doc = [[Document alloc] init];
    doc.name = photoName;
    doc.data = photoData;
    [self addDocument:doc];
    @synchronized (self) {
        [self addAttachment:@"jpg" data:photoData];
    }
    [self layoutScrollImages:YES];
}

#pragma mark - Attachment delegate

- (void)didUploadDocument:(Document *)doc needUI:(BOOL)needUI {
    @synchronized(self) {
        if (doc.objectId && ![EMPTY_ID isEqualToString:doc.objectId]) {
            [self.shaddowBusObj.attachmentDict setObject:doc forKey:doc.objectId];
            [self.busObj.attachmentDict setObject:doc forKey:doc.objectId];
            [self.attachmentDict setObject:doc forKey:doc.objectId];
        } else {
            if (!self.docsUploading) {
                self.docsUploading = [NSMutableDictionary dictionary];
            }
            
            [self.docsUploading setObject:doc forKey:doc.name];
        }
        
        if (needUI) {
            [self.shaddowBusObj.attachments addObject:doc];
            [self addAttachment:[[doc.name pathExtension] lowercaseString] data:doc.data];
            [self layoutScrollImages:YES];
            [self.previewController reloadData];
        }
        
        [self.busObj.attachments addObject:doc];
    }
}

//- (void)didAttachDocument:(Document *)doc {
//    [self.shaddowBusObj.attachmentDict setObject:doc forKey:doc.objectId];
//    [self.busObj.attachmentDict setObject:doc forKey:doc.objectId];
//    [self.attachmentDict setObject:doc forKey:doc.objectId];
//    
//    [self.busObj.attachments insertObject:doc atIndex:0];
//    [self.shaddowBusObj.attachments insertObject:doc atIndex:0];
//    
//    [self addAttachment:[[doc.name pathExtension] lowercaseString] data:doc.data];
//    [self layoutScrollImages:NO];
//}

//- (void)didDetachDocument:(Document *)doc {
//    int idx = [self.shaddowBusObj.attachments indexOfObject:doc];
//    
//    [self.shaddowBusObj.attachments removeObject:doc];
//    [self.busObj.attachments removeObject:doc];
//    
//    if (doc.objectId) {
//        [self.attachmentDict removeObjectForKey:doc.objectId];
//        [self.busObj.attachmentDict removeObjectForKey:doc.objectId];
//        [self.shaddowBusObj.attachmentDict removeObjectForKey:doc.objectId];
//    }
//    
//    UIImageView *imgView = [self.attachmentScrollView.subviews objectAtIndex:idx];
//    [imgView removeFromSuperview];
//    [self layoutScrollImages:NO];
//}


@end
