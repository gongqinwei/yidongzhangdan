//
//  SlidingListTableViewController.h
//  BDC
//
//  Created by Qinwei Gong on 4/11/13.
//
//

#import "SlidingTableViewController.h"
#import "Document.h"

@protocol ListViewDelegate <NSObject>
@optional
- (void)didDeleteObject;
- (void)didDeleteObject:(NSIndexPath *)indexPath;
@end


@interface SlidingListTableViewController : SlidingTableViewController <ListViewDelegate>

@property (nonatomic, strong) Document *document;

@property (nonatomic, strong) NSString *createNewSegue;
@property (nonatomic, strong) id<ListViewDelegate> listViewDelegate;


- (void)navigateDone;
- (void)navigateAttach;
- (void)navigateCancel;

- (void)didSelectCrudAction:(NSString *)action;
- (void)attachDocumentForObject:(BDCBusinessObject *)obj;

@end
