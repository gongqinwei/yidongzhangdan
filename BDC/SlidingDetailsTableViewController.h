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


@interface SlidingDetailsTableViewController : SlidingTableViewController <BusObjectDelegate, ScannerDelegate, AttachmentDelegate, UIAlertViewDelegate, UIScrollViewDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate>

@property (nonatomic, strong, readonly) Class busObjClass;

@property (nonatomic, strong) BDCBusinessObjectWithAttachments *busObj;
@property (nonatomic, strong) BDCBusinessObjectWithAttachments *shaddowBusObj;

@property (nonatomic, assign) BOOL modeChanged;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIToolbar *inputAccessoryView;

@property (nonatomic, strong) NSMutableDictionary *attachmentDict;
@property (nonatomic, strong) NSMutableDictionary *docsUploading;

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
- (void)addAttachment:(NSString *)ext data:(NSData *)attachmentData needScale:(BOOL)needScale;
- (void)selectAttachment:(UIImageView *)imageView;
- (void)imageTapped:(UITapGestureRecognizer *)gestureRecognizer;
- (IBAction)saveBusObj:(UIBarButtonItem *)sender;
- (void)retrieveDocAttachments;
- (void)layoutScrollImages:(BOOL)needChangePage;
- (void)doneSaveObject;
- (void)handleRemovalForDocument:(Document *)doc;
- (NSIndexPath *)getAttachmentPath;
- (NSIndexSet *)getNonAttachmentSections;
- (NSString *)getDocIDParam;
- (NSString *)getDocImageAPI;
- (void)resetScrollView;

- (void)textFieldDidBeginEditing:(UITextField *)textField;
- (void)textFieldDidEndEditing:(UITextField *)textField;

- (void)quitAttachMode;


@end
