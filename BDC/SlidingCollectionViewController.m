//
//  SlidingCollectionViewController.m
//  BDC
//
//  Created by Qinwei Gong on 5/29/13.
//
//

#import "SlidingCollectionViewController.h"
#import "RootMenuViewController.h"


@implementation SlidingCollectionViewController

@synthesize dataArray;
@synthesize currentDocument;
@synthesize refreshControl;
@synthesize previewController;
@synthesize dataInMemCache;


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
