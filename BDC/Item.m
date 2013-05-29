//
//  Item.m
//  BDC
//
//  Created by Qinwei Gong on 9/21/12.
//
//

#import "Item.h"
#import "Constants.h"
#import "APIHandler.h"
#import "Util.h"
#import "UIHelper.h"
#import "BDCAppDelegate.h"


@implementation Item

static id <ItemListDelegate> ListDelegate = nil;
static NSMutableDictionary *items = nil;
static NSMutableDictionary *inactiveItems = nil;

@synthesize price;
@synthesize qty;
@synthesize type;


+ (id<ItemListDelegate>)getListDelegate {
    return ListDelegate;
}

+ (void)setListDelegate:(id<ItemListDelegate>)theDelegate {
    ListDelegate = theDelegate;
}

- (void)saveFor:(NSString *)action {
    NSString *theAction = [NSString stringWithString:action];
    
    action = [NSString stringWithFormat:@"%@/%@/%@", CRUD, action, ITEM_API];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    NSMutableString *objStr = [NSMutableString string];
    [objStr appendString:@"{"];
    [objStr appendString:OBJ];
    [objStr appendString:@": {"];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", ENTITY, ITEM];
    if ([theAction isEqualToString:UPDATE]) {
        [objStr appendFormat:@"\"%@\" : \"%@\", ", ID, self.objectId];
    }
    [objStr appendFormat:@"\"%@\" : \"%@\", ", ITEM_NAME, self.name];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", ITEM_TYPE, [NSString stringWithFormat:@"%d", [[ItemTypes objectAtIndex:self.type] intValue]]];
    [objStr appendFormat:@"\"%@\" : %@ ", ITEM_PRICE, self.price];
    [objStr appendString:@"}"];
    [objStr appendString:@"}"];
    
    [params setObject:DATA forKey:objStr];
    
    __weak Item *weakSelf = self;
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSDictionary *info = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            NSString *itemId = [info objectForKey:ID];
            self.objectId = itemId;
            
            if ([theAction isEqual:CREATE] || self.isActive) {
                [Item retrieveListForActive:YES];
            } else {
                [Item retrieveListForActive:NO];
            }
            
            if ([theAction isEqualToString:UPDATE]) {
                [weakSelf.editDelegate didUpdateObject];
            } else {
                [weakSelf.editDelegate didCreateObject:itemId];
                [ListDelegate didAddItem:self];
            }
        } else {
            [weakSelf.editDelegate failedToSaveObject];
            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
            
            if ([theAction isEqualToString:UPDATE]) {
                NSLog(@"Failed to update item %@: %@", self.objectId, [err localizedDescription]);
            } else {
                NSLog(@"Failed to create item: %@", [err localizedDescription]);
            }
        }
    }];
}

- (void)toggleActive:(Boolean)isActive {
    NSString *act = isActive ? UNDELETE : DELETE;
    NSString *action = [NSString stringWithFormat:@"%@/%@/%@", CRUD, act, ITEM_API];
    NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\"}", ID, self.objectId];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA, objStr, nil];
    
    __weak Item *weakSelf = self;
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            [weakSelf.editDelegate didDeleteObject];
            
            // manually update model
            self.isActive = isActive;
            
            if (isActive) {
                [inactiveItems removeObjectForKey:self.objectId];
                [items setObject:self forKey:self.objectId];
            } else {
                [items removeObjectForKey:self.objectId];
                [inactiveItems setObject:self forKey:self.objectId];
            }
            
            [ListDelegate didDeleteObject];
        } else {
            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
            NSLog(@"Failed to %@ item %@: %@", act, self.objectId, [err localizedDescription]);
        }
    }];
}

+ (id)listOrderBy:(NSString *)attribue ascending:(Boolean)isAscending active:(Boolean)isActive {
    NSDictionary *itemList = isActive ? items : inactiveItems;
    NSArray *itemArr = [itemList allValues];
    
    NSSortDescriptor *firstOrder = [[NSSortDescriptor alloc] initWithKey:ITEM_NAME ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSSortDescriptor *secondOrder = [[NSSortDescriptor alloc] initWithKey:ID ascending:NO];
    itemArr = [itemArr sortedArrayUsingDescriptors:[NSArray arrayWithObjects:firstOrder, secondOrder, nil]];
    
    for (Item *item in itemArr) {
        item.qty = 1;
    }
    
    return [NSMutableArray arrayWithArray:itemArr];
}

+ (id)list {
    return [NSMutableArray arrayWithArray:[items allValues]];
}

+ (id)listInactive {
    return [NSMutableArray arrayWithArray:[inactiveItems allValues]];
}

//+ (void)setItems:(NSDictionary *)itemDict active:(Boolean)isActive {
//    if (isActive) {
//        items = itemDict;
//    } else {
//        inactiveItems = itemDict;
//    }
//}

+ (Item *)objectForKey:(NSString *)itemId {
    Item *item = [items objectForKey:itemId];
    if (item == nil) {
        item = [inactiveItems objectForKey:itemId];
    }
    return item;
}

+ (void)retrieveListForActive:(BOOL)isActive {
    [UIAppDelegate incrNetworkActivities];
    
    NSString *filter = isActive ? LIST_ACTIVE_FILTER : LIST_INACTIVE_FILTER;
    NSString *action = [LIST_API stringByAppendingString: ITEM_API];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA, filter, nil];
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSArray *jsonItems = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        [UIAppDelegate decrNetworkActivities];
        
        if(response_status == RESPONSE_SUCCESS) {
            NSMutableDictionary *itemDict;
            if (isActive) {
                items = [NSMutableDictionary dictionary];
                itemDict = items;
            } else {
                inactiveItems = [NSMutableDictionary dictionary];
                itemDict = inactiveItems;
            }
            
            for (id item in jsonItems) {
                NSDictionary *dict = (NSDictionary*)item;
                Item *item = [[Item alloc] init];
                item.objectId = [dict objectForKey:ID];
                item.name = [dict objectForKey:ITEM_NAME];
                item.type = [ItemTypes indexOfObject:[NSNumber numberWithInt: [[dict objectForKey:ITEM_TYPE] intValue]]];
                item.price = [Util id2Decimal:[dict objectForKey:ITEM_PRICE]];
                item.isActive = [[dict objectForKey:IS_ACTIVE] isEqualToString:@"1"];
                
                [itemDict setObject:item forKey:item.objectId];
            }
            
//            [Item setItems:itemDict active:isActive];
            [ListDelegate didGetItems];
        } else if (response_status == RESPONSE_TIMEOUT) {
            [ListDelegate failedToGetItems];
            [UIHelper showInfo:SysTimeOut withStatus:kError];
            NSLog(@"Time out when retrieving list of items!");
        } else {
            [ListDelegate failedToGetItems];
            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
            NSLog(@"Failed to retrieve list of items for %@! %@", isActive ? @"active" : @"inactive", [err localizedDescription]);
        }
    }];
}

+ (void)clone:(Item *)source to:(Item *)target {
    [super clone:source to:target];
    
    target.type = source.type;
    target.name = source.name;
    target.price = source.price;
    target.qty = source.qty;
    target.editDelegate = source.editDelegate;
//    target.editInvoiceDelegate = source.editInvoiceDelegate;
}

@end
