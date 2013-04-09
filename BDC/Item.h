//
//  Item.h
//  BDC
//
//  Created by Qinwei Gong on 9/21/12.
//
//

#import <Foundation/Foundation.h>
#import "BDCBusinessObject.h"

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

#define ItemTypes       [NSArray arrayWithObjects:[NSNumber numberWithInt:kService], [NSNumber numberWithInt:kProduct], [NSNumber numberWithInt:kDiscount], [NSNumber numberWithInt:kSalesTax], nil]

#define ItemTypeNames   [NSArray arrayWithObjects:@"Service", @"Product (Non-inventory)", @"Discount", @"Sales Tax", nil]

@protocol ItemDelegate <NSObject>

@optional
- (void)didCreateItem:(NSString *)newItemId;
- (void)didUpdateItem;
- (void)didDeleteItem;

- (void)failedToSaveItem;

@end

@class Item;

@protocol ItemListDelegate <NSObject>

@optional
- (void)didGetItems;
- (void)didAddItem:(Item *)item;
- (void)failedToGetItems;

@end

@interface Item : BDCBusinessObject

@property (nonatomic, assign) int type;
//@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDecimalNumber *price;
@property (nonatomic, assign) int qty;
//@property (nonatomic, assign) BOOL taxable;

@property (nonatomic, weak) id<ItemDelegate> editDelegate;
//@property (nonatomic, weak) id<ItemDelegate> editInvoiceDelegate;

+ (void)setListDelegate:(id<ItemListDelegate>)listDelegate;

+ (Item *)objectForKey:(NSString *)itemId;

@end
