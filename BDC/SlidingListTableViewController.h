//
//  SlidingListTableViewController.h
//  BDC
//
//  Created by Qinwei Gong on 4/11/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "SlidingTableViewController.h"
#import "Document.h"

@protocol ListViewDelegate <NSObject>
@optional
- (void)didReadObject;
- (void)didDeleteObject;
- (void)didDeleteObject:(NSIndexPath *)indexPath;
@end


static NSArray * Alphabets;

@interface SlidingListTableViewController : SlidingTableViewController <ListViewDelegate>

@property (nonatomic, strong, readonly) Class busObjClass;

@property (nonatomic, strong) Document *document;

@property (nonatomic, strong) NSString *createNewSegue;
@property (nonatomic, strong) id<ListViewDelegate> listViewDelegate;

@property (nonatomic, strong) NSIndexPath *lastSelected;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) NSMutableArray *alphabeticList;
@property (nonatomic, strong) NSMutableArray *indice;

- (void)navigateDone;
- (void)navigateAttach;
- (void)navigateCancel;

- (void)didSelectCrudAction:(NSString *)action;
- (void)attachDocumentForObject:(BDCBusinessObject *)obj;

- (NSMutableArray *)sortIntoAlphabetsForList:(NSArray *)list;

@end
