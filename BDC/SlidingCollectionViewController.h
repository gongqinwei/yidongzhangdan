//
//  SlidingCollectionViewController.h
//  BDC
//
//  Created by Qinwei Gong on 5/29/13.
//
//

#import <UIKit/UIKit.h>
#import "UIViewController+Sliding.h"
#import "Document.h"

@interface SlidingCollectionViewController : UICollectionViewController

@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, strong) Document *currentDocument;

@property (nonatomic, strong) UIRefreshControl *refreshControl;

- (void)refreshView;

@end
