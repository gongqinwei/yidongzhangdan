//
//  SlidingDetailsTableViewController.h
//  BDC
//
//  Created by Qinwei Gong on 4/11/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "SlidingTableViewController.h"
#import "BDCBusinessObjectWithAttachments.h"
#import "ScannerViewController.h"
#import "Document.h"
#import <QuickLook/QuickLook.h>


#define INPUT_ACCESSORY_PREV            @"Left.png"
#define INPUT_ACCESSORY_NEXT            @"Right.png"
#define INPUT_ACCESSORY_DONE            @"Down.png"
#define INPUT_ACCESSORY_VIEW_FRAME      CGRectMake(0, 0, SCREEN_WIDTH, ToolbarHeight)
#define INPUT_ACCESSORY_LABEL_FRAME     CGRectMake(15, 7, 60, ToolbarHeight - 9)
#define INPUT_ACCESSORY_TEXT_FRAME      CGRectMake(0, 7, SCREEN_WIDTH - 170, ToolbarHeight - 9)
#define INPUT_ACCESSORY_TEXT_FRAME_S    CGRectMake(0, 7, SCREEN_WIDTH - 200, ToolbarHeight - 9)
#define INPUT_ACCESSORY_NAV_FRAME       CGRectMake(0.0, 0.0, 66.0, ToolbarHeight - 12.0)


@interface SlidingDetailsTableViewController : SlidingTableViewController <BusObjectDelegate, ScannerDelegate, AttachmentDelegate, UIAlertViewDelegate, UIScrollViewDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate>

@property (nonatomic, strong, readonly) Class busObjClass;
@property (nonatomic, assign, readonly) BOOL isAR;
@property (nonatomic, assign, readonly) BOOL isAP;

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

// for kAttachMode
@property (nonatomic, assign) BOOL firstItemAdded;
@property (nonatomic, assign) BOOL viewHasAppeared;
@property (nonatomic, strong) UIScrollView *previewScrollView;
@property (nonatomic, strong) UIImageView *attachmentImageView;
@property (nonatomic, strong) UIView *attachmentImageObscure;
@property (nonatomic, strong) UIActivityIndicatorView *attachmentImageDownloadingIndicator;


- (void)scrollToTop;
- (void)hideAdditionalKeyboard;
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
- (void)downloadAttachPreviewDocument:(Document *)doc;

- (void)textFieldDidBeginEditing:(UITextField *)textField;
- (void)textFieldDidEndEditing:(UITextField *)textField;

- (void)quitAttachMode;

- (UIBarButtonItem *)initializeInputAccessoryLabelItem:(NSString *)labelText;
- (UITextField *)initializeInputAccessoryTextField;
- (UITextField *)initializeInputAccessoryTextField:(BOOL)small;
- (UIView *)initializeSectionHeaderViewWithLabel:(NSString *)labelText needAddButton:(BOOL)needAddButton addAction:(SEL)action;

@end
