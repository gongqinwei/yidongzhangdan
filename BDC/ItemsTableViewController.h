//
//  ItemsTableViewController.h
//  BDC
//
//  Created by Qinwei Gong on 9/22/12.
//
//

#import <UIKit/UIKit.h>
#import "SlidingListTableViewController.h"

@protocol ItemSelectDelegate <NSObject>

@required
- (void)didSelectItems:(NSArray *)items;

@end

@interface ItemsTableViewController : SlidingListTableViewController

@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, weak) id<ItemSelectDelegate> selectDelegate;

@end
