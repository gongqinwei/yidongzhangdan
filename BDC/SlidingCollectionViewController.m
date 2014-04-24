//
//  SlidingCollectionViewController.m
//  BDC
//
//  Created by Qinwei Gong on 5/29/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "SlidingCollectionViewController.h"
#import "RootMenuViewController.h"
#import "TutorialControl.h"


#define COLLECTION_VC_TUTORIAL                  @"COLLECTION_VC_TUTORIAL"
#define COLLECTION_SWIPE_LEFT_TUTORIAL_RECT     CGRectMake((SCREEN_WIDTH - 150) / 2, 160, 180, 100)
#define INFO_BUTTON_TUTORIAL_RECT               CGRectMake((SCREEN_WIDTH - 220) / 2, 300, 220, 65)


@interface SlidingCollectionViewController()

@property (nonatomic, strong) TutorialControl *collectionVCTutorialOverlay;

@end

@implementation SlidingCollectionViewController

@synthesize dataArray;
@synthesize currentDocument;
@synthesize refreshControl;
@synthesize previewController;
@synthesize dataInMemCache;

@synthesize collectionVCTutorialOverlay;


- (void)refreshView {
    self.refreshControl.attributedTitle = REFRESHING;
    [self changeCurrentDocumentTo:nil];
    
    [self.dataInMemCache purge];
    self.dataInMemCache = nil;
    self.dataInMemCache = [[LRU alloc] init];
}

- (void)endRefreshView {
    [self.collectionView reloadData];
    self.refreshControl.attributedTitle = LAST_REFRESHED;
    [self.refreshControl endRefreshing];
}

- (void)downloadDocument:(Document *)doc {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", DOMAIN_URL, doc.fileUrl]];
    NSURLRequest *req = [NSURLRequest  requestWithURL:url
                                          cachePolicy:NSURLRequestUseProtocolCachePolicy
                                      timeoutInterval:API_TIMEOUT];
    
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               doc.data = data;     // compression during setter
                               
                               // only cache big fish
                               if (doc.data.length >= CACHE_THRESHOLD) {
                                   [self.dataInMemCache cache:doc];
                               }
                           }];
}

- (BOOL)changeCurrentDocumentTo:(Document *)doc {
    if (self.currentDocument != doc) {
        [self.currentDocument.documentDelegate didGetDeselected];
        self.currentDocument = doc;
        [self.currentDocument.documentDelegate didGetSelected];
        return YES;
    } else {
        return FALSE;
    }
}

- (void)toggleMenu:(id)sender {
    [self.collectionVCTutorialOverlay removeFromSuperview];
    
    [super toggleMenu:sender];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    self.isActive = YES;
    self.isAsc = YES;
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    Document *doc = [self.dataInMemCache spit];
    doc.data = nil;
//    Debug(@"=== Freed up data for Document: %@ %d ===", doc.name, doc.data.length);
}

- (void)viewDidAppear:(BOOL)animated {
    [RootMenuViewController sharedInstance].currVC = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initialize];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshView) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl];
    
    self.previewController = [[QLPreviewController alloc] init];
    self.previewController.delegate = self;
    self.previewController.dataSource = self;
    
    self.dataInMemCache = [[LRU alloc] init];
    
    [self setSlidingMenuLeftBarButton];
    [self setActionMenuRightBarButton];
    
    // one time tutorial
    BOOL tutorialValue = [[NSUserDefaults standardUserDefaults] boolForKey:COLLECTION_VC_TUTORIAL];
    if (!tutorialValue) {
        self.collectionVCTutorialOverlay = [[TutorialControl alloc] init];
        [self.collectionVCTutorialOverlay addText:@"Swipe right to reveal menu" at:SWIPE_RIGHT_TUTORIAL_RECT];
        [self.collectionVCTutorialOverlay addImageNamed:@"arrow_right.png" at:SWIPE_RIGHT_ARROW_RECT];
        [self.collectionVCTutorialOverlay addText:@"Select any document, and then you can swipe left to reveal actions" at:COLLECTION_SWIPE_LEFT_TUTORIAL_RECT];
        [self.collectionVCTutorialOverlay addImageNamed:@"arrow_left.png" at:SWIPE_LEFT_ARROW_RECT];
        [self.collectionVCTutorialOverlay addText:@"Click the \"i\" button in each document to view its info" at:INFO_BUTTON_TUTORIAL_RECT];
        [self.view addSubview:self.collectionVCTutorialOverlay];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:COLLECTION_VC_TUTORIAL];
    }
}

#pragma mark - QuickLook Preview Controller Data Source

- (NSInteger) numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return 1; //self.dataArray.count;
}

- (id<QLPreviewItem>) previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    Document *doc = self.currentDocument; //self.dataArray[index];
    if (doc) {
        return [NSURL fileURLWithPath:[doc getDocFilePath]];
    } else {
        return nil;
    }
}

#pragma mark - Action Menu delegate

- (void)didSelectCrudAction:(NSString *)action {
    if ([action isEqualToString:ACTION_DELETE]) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle: @"Delete Confirmation"
                              message: [NSString stringWithFormat:@"Are you sure to delete this %@?", [self.currentDocument class]]
                              delegate: self
                              cancelButtonTitle:@"No"
                              otherButtonTitles:@"Yes", nil];
        [alert show];
    }
}

@end
