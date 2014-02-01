//
//  Item.h
//  BDC
//
//  Created by Qinwei Gong on 9/21/12.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDCBusinessObjectWithAttachments.h"
#import "SlidingDetailsTableViewController.h"
#import "SlidingListTableViewController.h"

typedef enum {
    kService = 1,
    kProduct = 3,
    kDiscount = 5,
    kSalesTax = 6
} ItemType;

#define ITEM                @"Item"
#define ITEM_NAME           @"name"
#define ITEM_TYPE           @"type"
#define ITEM_PRICE          @"price"
#define ITEM_QTY            @"quantity"
#define ITEM_AMOUNT         @"amount"
#define ITEM_DESC           @"description"

#define ItemTypes       [NSArray arrayWithObjects:[NSNumber numberWithInt:kService], [NSNumber numberWithInt:kProduct], [NSNumber numberWithInt:kDiscount], [NSNumber numberWithInt:kSalesTax], nil]

#define ItemTypeNames   [NSArray arrayWithObjects:@"Service", @"Product (Non-inventory)", @"Discount", @"Sales Tax", nil]


@class Item;

@protocol ItemListDelegate <ListViewDelegate>

@optional
- (void)didGetItems;
- (void)didAddItem:(Item *)item;
- (void)failedToGetItems;

@end


@interface Item : BDCBusinessObjectWithAttachments

@property (nonatomic, assign) int type;
@property (nonatomic, strong) NSDecimalNumber *price;
@property (nonatomic, assign) int qty;
@property (nonatomic, strong) NSString *desc;

+ (void)setListDelegate:(id<ItemListDelegate>)listDelegate;
+ (void)resetList;
+ (Item *)objectForKey:(NSString *)itemId;

@end
