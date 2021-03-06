//
//  EditItemViewController.h
//  BDC
//
//  Created by Qinwei Gong on 10/20/12.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "SlidingDetailsTableViewController.h"
#import "Item.h"

@protocol LineItemDelegate <NSObject>

-(void) didModifyItem:(Item*)item forIndex:(int)index;

@end

@interface EditItemViewController : SlidingDetailsTableViewController

@property (nonatomic, assign) int lineItemIndex;
@property (nonatomic, weak) id<LineItemDelegate> lineItemDelegate;

@end
