//
//  SlidingCollectionViewController.h
//  BDC
//
//  Created by Qinwei Gong on 5/29/13.
//
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>
#import "UIViewController+Sliding.h"
#import "Document.h"
#import "LRU.h"


@interface SlidingCollectionViewController : UICollectionViewController <QLPreviewControllerDataSource, QLPreviewControllerDelegate>

@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, strong) Document *currentDocument;
@property (nonatomic, strong) LRU *dataInMemCache;

@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) QLPreviewController *previewController;

- (void)refreshView;
- (void)endRefreshView;
- (void)downloadDocument:(Document *)doc;
- (BOOL)changeCurrentDocumentTo:(Document *)doc;

@end
