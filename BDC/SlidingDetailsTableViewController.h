//
//  SlidingDetailsTableViewController.h
//  BDC
//
//  Created by Qinwei Gong on 4/11/13.
//
//

#import "SlidingTableViewController.h"
#import "BDCBusinessObjectWithAttachments.h"
#import "ScannerViewController.h"
#import "Document.h"
#import <QuickLook/QuickLook.h>


@interface SlidingDetailsTableViewController : SlidingTableViewController <BusObjectDelegate, ScannerDelegate, UIAlertViewDelegate, UIScrollViewDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate>

@property (nonatomic, strong, readonly) Class busObjClass;

@property (nonatomic, strong) BDCBusinessObjectWithAttachments *busObj;
@property (nonatomic, strong) BDCBusinessObjectWithAttachments *shaddowBusObj;

@property (nonatomic, assign) BOOL modeChanged;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIToolbar *inputAccessoryView;

@property (nonatomic, strong) NSMutableDictionary *attachmentDict;

@property (nonatomic, strong) UIScrollView *attachmentScrollView;
@property (nonatomic, strong) UIPageControl *attachmentPageControl;
@property (nonatomic, strong) UIImageView *currAttachment;
@property (nonatomic, strong) QLPreviewController *previewController;


- (void)navigateBack;
- (void)didSelectCrudAction:(NSString *)action;
- (void)initializeTextField:(UITextField *)textField;
- (void)inputAccessoryDoneAction:(UIBarButtonItem *)button;

- (void)cancelEdit:(UIBarButtonItem *)sender;
- (void)addDocument:(Document *)document;
- (void)addAttachment:(NSString *)ext data:(NSData *)attachmentData;
- (void)selectAttachment:(UIImageView *)imageView;
- (void)imageTapped:(UITapGestureRecognizer *)gestureRecognizer;
- (IBAction)saveBusObj:(UIBarButtonItem *)sender;
- (void)retrieveDocAttachments;
- (void)layoutScrollImages:(BOOL)needChangePage;
- (void)doneSaveObject;
- (void)handleRemovalForDocument:(Document *)doc;
- (NSIndexPath *)getAttachmentPath;


@end
