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
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(toggleMenu:)];
        self.navigationItem.rightBarButtonItem.tag = 1;
        self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveBusObj:)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEdit:)];
    }
    
    // retrieve attachments
    // clean up first
    for (UIView *subview in [self.attachmentScrollView subviews]) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            NSLog(@"-------------- deleting attachment view from scroll view ================");
            [subview removeFromSuperview];
        }
    }
    
    [self.tableView reloadData];
    NSLog(@"---- shaddow.attachments: %d", [self.shaddowBusObj.attachments count]);
    NSLog(@"---- shaddow.attachmentDict: %d", [self.shaddowBusObj.attachmentDict count]);
    
    for (Document * doc in self.shaddowBusObj.attachments) {
        NSLog(@":: %@", doc.objectId);
        
        NSString *ext = [[doc.name pathExtension] lowercaseString];
        [self addAttachment:ext data:doc.data];
    }
    
    [self layoutScrollImages:NO];
    
    if (mode != kAttachMode) {
        [self retrieveDocAttachments];
    }
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

- (void)addDocument:(Document *)document {
    if (self.shaddowBusObj == nil) {
        self.shaddowBusObj = [[self.busObjClass alloc] init];
    }
    
    if (self.busObj == nil) {
        self.busObj = [[self.busObjClass alloc] init];
    }
    
    if (document) {
        [self.shaddowBusObj.attachments addObject:document];
                NSLog(@"shaddow obj's attachment: %@", self.shaddowBusObj.attachments);
    }
}

// deprecated
//- (void)addAttachmentData:(NSData *)attachmentData name:(NSString *)attachmentName {
//    if (self.shaddowBusObj == nil) {
//        self.shaddowBusObj = [[self.busObjClass alloc] init];
//    }
//    
//    if (self.busObj == nil) {
//        self.busObj = [[self.busObjClass alloc] init];
//    }
//    
//    Document *doc = [[Document alloc] init];
//    doc.name = attachmentName;
//    doc.data = attachmentData;
//    
//    [self.shaddowBusObj.attachments addObject:doc];
//}

- (void)addAttachment:(NSString *)ext data:(NSData *)attachmentData {
//    UIImage *image;
//    
//    if (attachmentData && [IMAGE_TYPE_SET containsObject:ext]) {
//        image = [UIImage imageWithData:attachmentData];
//    } else {
//        NSString *iconFileName = [NSString stringWithFormat:@"%@_icon.png", ext];
//        image = [UIImage imageNamed:iconFileName];
//        
//        if (!image) {
//            image = [UIImage imageNamed:@"unknown_file_icon.png"];
//        }
//    }
    
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
                                     [self.shaddowBusObj.attachments removeObjectAtIndex:idx];
                                     
                                     if (doc.objectId) {
                                         [self.attachmentDict removeObjectForKey:doc.objectId];
                                     }
                                     [self.currAttachment removeFromSuperview];
                                     [self layoutScrollImages:NO];
                                     self.currAttachment = nil;
                                 }
                             }];
        }
    }
}

- (IBAction)saveBusObj:(UIBarButtonItem *)sender {
    self.navigationItem.rightBarButtonItem.customView = self.activityIndicator;
    [self.activityIndicator startAnimating];
    [self.view findAndResignFirstResponder];
}

- (void)retrieveDocAttachments {
    NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\"}", ID, self.busObj.objectId];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA, objStr, nil];
    
    [APIHandler asyncCallWithAction:RETRIEVE_DOCS_API Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSArray *jsonDocs = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            if (!self.busObj.attachmentDict) {
                self.busObj.attachmentDict = [NSMutableDictionary dictionary];
            }
            
            self.attachmentDict = [NSMutableDictionary dictionaryWithDictionary:self.busObj.attachmentDict];
            
            NSMutableDictionary *docsWithoutId = [NSMutableDictionary dictionary];
            for (Document *doc in self.shaddowBusObj.attachments) {
//                if (![self.attachmentDict objectForKey:doc.objectId]) {
                if (!doc.objectId) {
                    [docsWithoutId setObject:doc forKey:doc.name];
                    NSLog(@"-- doc w/ no id: %@", doc.name);
                }
            }
            
            NSLog(@"docs w/ no id size: %d", docsWithoutId.count);
            
            int i = 0;
            for (NSDictionary *dict in jsonDocs) {
                NSString *docId = [dict objectForKey:ID];
                
                if (![self.attachmentDict objectForKey:docId]) {
                    Document *doc;
                    
                    NSString *docName = [dict objectForKey:@"fileName"];    //Assumption: fileNames are unique. this is a hack to work around the documentUploaded -> document/documentPage problem
                    NSLog(@"== new doc: %@, %@", docId, docName);
                    
                    if ([docsWithoutId objectForKey:docName]) {
                        doc = [docsWithoutId objectForKey:docName];
                        doc.objectId = docId;
                        [self.attachmentDict setObject:doc forKey:docId];
                        [self.shaddowBusObj.attachmentDict setObject:doc forKey:docId];
                        [self.busObj.attachmentDict setObject:doc forKey:docId];
                        NSLog(@"adding...%@", docId);
                        continue;
                    }
                    
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

                    [self addAttachment:[[doc.name pathExtension] lowercaseString] data:nil];
                    [self layoutScrollImages:NO];
                    
                    [self downloadDocument:doc forAttachmentAtIndex:i];
                }
                i++;
            }

            NSIndexPath *path = [self getAttachmentPath];
            if (path) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:YES];
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
                               
                               UIImageView *img = [self.attachmentScrollView.subviews objectAtIndex: idx];
                               NSString *ext = [[doc.name pathExtension] lowercaseString];
                               
                               if ([IMAGE_TYPE_SET containsObject:ext]) {
                                   UIImage *image = [UIImage imageWithData:data];
                                   
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       img.alpha = 0.0;
                                       img.image = image;
                                       [img setNeedsDisplay];
                                       
                                       [UIView animateWithDuration:2.0
                                                        animations:^{
                                                            img.alpha = 1.0;
                                                        }
                                                        completion:^ (BOOL finished) {
                                                        }];
                                   });
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
    
    self.inputAccessoryView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, ToolbarHeight)];
    self.inputAccessoryView.barStyle = UIBarStyleBlackTranslucent;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:StrDone
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(inputAccessoryDoneAction:)];
    self.inputAccessoryView.items = [NSArray arrayWithObjects:flexibleSpace, doneButton, nil];
    
//    if (self.mode == kViewMode) {
//        self.isActive = self.busObj.isActive;
//        self.crudActions = [NSArray arrayWithObjects:ACTION_UPDATE, ACTION_DELETE, nil];
//        self.inactiveCrudActions = [NSArray arrayWithObjects:ACTION_UPDATE, ACTION_UNDELETE, nil];
//    }
    
    self.previewController = [[QLPreviewController alloc] init];
    self.previewController.delegate = self;
    self.previewController.dataSource = self;
    
    self.title = self.shaddowBusObj.name;
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
}

- (void)doneSaveObject {
    NSMutableArray *original = [NSMutableArray arrayWithArray:[self.busObj.attachmentDict allKeys]];
    NSMutableArray *current = [NSMutableArray arrayWithArray:[self.attachmentDict allKeys]];
    [original removeObjectsInArray:current];
    NSMutableArray *toBeDeleted = [NSMutableArray arrayWithArray:original];
    
    NSMutableArray *toBeAttached = [NSMutableArray array];
    NSMutableArray *toBeAdded = [NSMutableArray array];
    
    for (Document *doc in self.shaddowBusObj.attachments) {
        if (doc.objectId == nil) {
            [toBeAdded addObject:doc];
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
    __block int numNotYetAdded = [toBeAdded count];
    
    if ([toBeDeleted count] == 0 && numNotYetAdded == 0 && toBeAttached.count == 0) {
        [self.busObjClass clone:self.shaddowBusObj to:self.busObj];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.mode = kViewMode;
            self.title = self.shaddowBusObj.name;
        });
    } else {
        NSLock *doneLock = [[NSLock alloc] init];
        
        // 1. remove deleted attachments
        for (NSString *docId in toBeDeleted) {
            Document *doc = [self.busObj.attachmentDict objectForKey:docId];
            NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\", \"objId\" : \"%@\", \"page\" : %d}", ID, docId, self.busObj.objectId, doc.page];
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA, objStr, nil];
            
            [APIHandler asyncCallWithAction:REMOVE_DOCS_API Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
                NSInteger response_status;
                [APIHandler getResponse:response data:data error:&err status:&response_status];
                
                if(response_status == RESPONSE_SUCCESS) {
                    [doneLock lock];
                    
                    [toBeDeleted removeObject:docId];
                    
                    if (toBeDeleted.count == 0 && numNotYetAdded == 0 && toBeAttached.count == 0) {
                        [self.busObjClass clone:self.shaddowBusObj to:self.busObj];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (self.mode == kAttachMode) {
                                [self quitAttachMode];
                            } else {
                                self.mode = kViewMode;
                                self.title = self.shaddowBusObj.name;
                            }
                        });
                    }
                    
                    [doneLock unlock];
                    
                    NSLog(@"Successfully deleted attachment %@", doc.name);
                } else {
                    [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
                    NSLog(@"Failed to delete attachment %@: %@", docId, [err localizedDescription]);
                }
            }];
        }
        
        // 2. add new attachments
        for (Document *doc in toBeAdded) {
            [Uploader uploadFile:doc.name data:doc.data objectId:self.shaddowBusObj.objectId handler:^(NSURLResponse * response, NSData * data, NSError * err) {
                NSInteger response_status;
                NSString *info = [APIHandler getResponse:response data:data error:&err status:&response_status];
                
                if(response_status == RESPONSE_SUCCESS) {                    
                    if (![info isEqualToString:EMPTY_ID]) {
                        doc.objectId = info;
                        [self.shaddowBusObj.attachmentDict setObject:doc forKey:doc.objectId];
                    }
                    
                    [doneLock lock];
                    
                    numNotYetAdded--;
                    
                    if (toBeDeleted.count == 0 && numNotYetAdded == 0 && toBeAttached.count == 0) {
                        [self.busObjClass clone:self.shaddowBusObj to:self.busObj];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (self.mode == kAttachMode) {
                                [self quitAttachMode];
                            } else {
                                self.mode = kViewMode;
                                self.title = self.shaddowBusObj.name;
                            }
                        });
                    }
                    
                    [doneLock unlock];
                    
                    NSLog(@"Successfully added attachment %@", doc.name);
                } else {
                    [UIHelper showInfo:[NSString stringWithFormat:@"Failed to save %@", doc.name] withStatus:kFailure];
                }
            }];
        }
        
        // 3. attach documents
        for (Document *doc in toBeAttached) {
//            Document *doc = [self.shaddowBusObj.attachmentDict objectForKey:docId];
            NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\", \"name\" : \"%@\", \"objId\" : \"%@\"}", ID, doc.objectId, doc.name, self.shaddowBusObj.objectId];
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA, objStr, nil];
            
            [APIHandler asyncCallWithAction:ASSIGN_DOCS_API Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
                NSInteger response_status;
                NSString *info = [APIHandler getResponse:response data:data error:&err status:&response_status];
                
                if(response_status == RESPONSE_SUCCESS) {
                    if (![info isEqualToString:EMPTY_ID]) {
                        doc.objectId = info;
                        [self.shaddowBusObj.attachmentDict setObject:doc forKey:doc.objectId];
                    }
                    
                    [doneLock lock];
                    
                    [toBeAttached removeObject:doc];
                    
                    if (toBeDeleted.count == 0 && numNotYetAdded == 0 && toBeAttached.count == 0) {
                        [self.busObjClass clone:self.shaddowBusObj to:self.busObj];
                        [Document removeFromInbox:doc];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (self.mode == kAttachMode) {
                                [self quitAttachMode];
                            } else {
                                self.mode = kViewMode;
                                self.title = self.shaddowBusObj.name;
                            }
                        });
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
    
    //    self.navigationItem.rightBarButtonItem.customView = nil;
}

- (void)didCreateObject:(NSString *)newObjectId {
    self.busObj.objectId = newObjectId;
    self.shaddowBusObj.objectId = newObjectId;
    [self doneSaveObject];
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

#pragma mark - Scan View delegate

- (void)didScanPhoto:(NSData *)photoData name:(NSString *)photoName {
    Document *doc = [[Document alloc] init];
    doc.name = photoName;
    doc.data = photoData;
    [self addDocument:doc];
//    [self addAttachmentData:photoData name:photoName];
    [self addAttachment:@"jpg" data:photoData];
    [self layoutScrollImages:YES];
}

@end
