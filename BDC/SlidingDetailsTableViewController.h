//
//  SlidingDetailsTableViewController.h
//  BDC
//
//  Created by Qinwei Gong on 4/11/13.
//
//

#import "SlidingTableViewController.h"
#import "BDCBusinessObject.h"

@protocol DetailsViewDelegate <NSObject>
@optional
- (void)didUpdateObject;
- (void)didDeleteObject;
- (void)failedToSaveObject;
@end


@interface SlidingDetailsTableViewController : SlidingTableViewController

@property (nonatomic, strong) BDCBusinessObject *busObj;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

- (void)navigateBack;
- (void)didSelectCrudAction:(NSString *)action;

@end
