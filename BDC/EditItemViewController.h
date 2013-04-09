//
//  EditItemViewController.h
//  BDC
//
//  Created by Qinwei Gong on 10/20/12.
//
//

#import "SlidingTableViewController.h"
#import "Item.h"

@protocol LineItemDelegate <NSObject>

-(void) didModifyItem:(Item*)item forIndex:(int)index;

@end

@interface EditItemViewController : SlidingTableViewController

@property (nonatomic, strong) Item *item;
@property (nonatomic, assign) int lineItemIndex;

@property (nonatomic, weak) id<LineItemDelegate> lineItemDelegate;

@end
