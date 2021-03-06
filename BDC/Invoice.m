//
//  Invoice.m
//  BDC
//
//  Created by Qinwei Gong on 8/27/12.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import "Invoice.h"
#import "Constants.h"
#import "APIHandler.h"
#import "InvoiceDetailsViewController.h"
#import "Util.h"
#import "Customer.h"
#import "Item.h"
#import "User.h"
#import "UIHelper.h"
#import "BDCAppDelegate.h"
#import "RateAppManager.h"
#import "RootMenuViewController.h"

#define LIST_ACTIVE_INV_FILTER      @"{ \"start\" : 0, \
                                        \"max\" : 999, \
                                        \"filters\" : [{\"field\" : \"isActive\", \"op\" : \"=\", \"value\" : \"1\"}, {\"field\" : \"paymentStatus\", \"op\" : \"!=\", \"value\" : \"0\"}] \
                                      }"

#define LIST_INACTIVE_INV_FILTER    @"{ \"start\" : 0, \
                                        \"max\" : 999, \
                                        \"filters\" : [{\"field\" : \"isActive\", \"op\" : \"=\", \"value\" : \"2\"}, {\"field\" : \"paymentStatus\", \"op\" : \"!=\", \"value\" : \"0\"}] \
                                      }"

#define SEND_INVOICE_DATA           @"{ \"id\" : \"%@\", \"invoiceId\" : \"%@\", \"headers\" : { \"fromUserId\" : \"%@\" }, \"content\" : { }}"


@implementation Invoice

static id<InvoiceListDelegate> ARDelegate = nil;
static id<InvoiceListDelegate> ListDelegate = nil;
static NSMutableArray *invoices = nil;
static NSMutableArray *inactiveInvoices = nil;

@synthesize customerId;
@synthesize customerName;
@synthesize invoiceNumber;
@synthesize invoiceDate;
@synthesize dueDate;
@synthesize amount;
@synthesize amountDue;
@synthesize paymentStatus;
//@synthesize createdDate;
//@synthesize updatedDate;
//@synthesize desc;
//@synthesize discountInfo;
//@synthesize tax;
//@synthesize netBillId;
//@synthesize netOrgId;
//@synthesize creditAmount;
//@synthesize jobId;
//@synthesize poNumber;
//@synthesize isToBePrinted;
//@synthesize isToBeMailed;
//@synthesize itemSalesTax;
//@synthesize salesTaxPercentage;
//@synthesize salesTaxTotal;
//@synthesize customerMsg;
//@synthesize terms;
////@synthesize emailTemplate; //?
//@synthesize salesRep;
//@synthesize fob;
//@synthesize shipDate;
//@synthesize shipMethod;
//@synthesize deptId;
//@synthesize invoiceTemplateId;
//@synthesize nextReminder;
//@synthesize paymentTermId;
//@synthesize externalId;
//@synthesize estPaymentDate;
//@synthesize cashflowDate;
//@synthesize firstPaymentDate;
//@synthesize fullPaymentDate;
//@synthesize lastSentDate;
//@synthesize expectedPayDate;
@synthesize lineItems;
@synthesize detailsDelegate;
@synthesize mailDelegate;

- (void)sendInvoice {
    NSString *action = [INVOICE_SEND_API stringByAppendingFormat:@"?%@=%@", _ID, self.objectId];
    NSString *objStr = [NSString stringWithFormat:SEND_INVOICE_DATA, self.objectId, self.objectId, [Util getUserId]];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA_, objStr, nil];
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {        
        NSInteger response_status;
        [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            [UIHelper showInfo: EMAIL_SENT withStatus:kSuccess];
            
            // prompt for Rate app
            if (![[RateAppManager sharedInstance] checkPromptForRate]) {
                [self.mailDelegate didSendInvoice];
            }
            
            [Util track:@"sent_invoice"];
        } else {
            [UIHelper showInfo: EMAIL_FAILED withStatus:kFailure];
        }
    }];
}

+ (Invoice *)loadWithId:(NSString *)objId {
    NSPredicate *predicate = [BDCBusinessObject getPredicate:objId];
    NSArray *result = [invoices filteredArrayUsingPredicate:predicate];
    if ([result count] == 1) {
        return result[0];
    }
    
    result = [inactiveInvoices filteredArrayUsingPredicate:predicate];
    if ([result count] == 1) {
        return result[0];
    }
    
    return nil;
}

+ (void)resetList {
    invoices = [NSMutableArray array];
    inactiveInvoices = [NSMutableArray array];
}

+ (void)setARDelegate:(id<InvoiceListDelegate>)delegate {
    ARDelegate = delegate;
}

+ (void)setListDelegate:(id<InvoiceListDelegate>)delegate {
    ListDelegate = delegate;
}

- (NSString *)name {
    return self.invoiceNumber;
}

- (id)init {
    if (self = [super init]) {
        self.lineItems = [NSMutableArray array];
//        self.attachments = [NSMutableArray array];
    }
    return self;
}

- (void)saveFor:(NSString *)action {
    NSString *theAction = [NSString stringWithString:action];
    
    action = [NSString stringWithFormat:@"%@/%@/%@", CRUD, action, INVOICE_API];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    NSMutableString *objStr = [NSMutableString string];
    [objStr appendString:@"{"];
    [objStr appendString:OBJ];
    [objStr appendString:@": {"];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", ENTITY, INVOICE];
    if ([theAction isEqualToString:UPDATE]) {
        [objStr appendFormat:@"\"%@\" : \"%@\", ", _ID, self.objectId];
    }
    [objStr appendFormat:@"\"%@\" : \"%@\", ", INV_CUSTOMER_ID, self.customerId];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", INV_NUMBER, self.invoiceNumber];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", INV_DATE, [Util formatDate:self.invoiceDate format:@"yyyy-MM-dd"]];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", INV_DUE_DATE, [Util formatDate:self.dueDate format:@"yyyy-MM-dd"]];
    [objStr appendFormat:@"\"%@\" : [", INV_LINE_ITEMS];
    NSUInteger total = [self.lineItems count];
    int i = 0;
    for (Item* item in self.lineItems) {
        [objStr appendString:@"{"];
        [objStr appendFormat:@"\"%@\" : \"%@\", ", ENTITY, INV_LINE_ITEM];
        [objStr appendFormat:@"\"%@\" : \"%@\", ", INV_ITEM_ID, item.objectId];
        [objStr appendFormat:@"\"%@\" : %lu, ", INV_ITEM_QUANTITY, (unsigned long)item.qty];
        [objStr appendFormat:@"\"%@\" : %@", INV_ITEM_PRICE, item.price];
        [objStr appendString:@"}"];
        if (i < total - 1) {
            [objStr appendString:@", "];
        }
        i++;
    }
    [objStr appendString:@"]"];
    [objStr appendString:@"}"];
    [objStr appendString:@"}"];
    
    [params setObject:DATA_ forKey:objStr];
    
    __weak Invoice *weakSelf = self;
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSDictionary *info = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            NSString *invId = [info objectForKey:_ID];
            self.objectId = invId;
            
            if ([theAction isEqualToString:CREATE]) {
                self.isActive = YES;
            }
            
            if (self.isActive) {
                [Invoice retrieveListForActive:YES];
            } else {
                [Invoice retrieveListForActive:NO];
            }
            
            if ([theAction isEqualToString:UPDATE]) {
                [weakSelf.editDelegate didUpdateObject];
                [weakSelf.detailsDelegate didUpdateObject];
            } else {
                [weakSelf.editDelegate didCreateObject:invId];
            }
        } else {
            [weakSelf.editDelegate failedToSaveObject];
            
            if ([theAction isEqualToString:UPDATE]) {
                [UIHelper showInfo:[NSString stringWithFormat:@"Failed to update invoice %@: %@", self.objectId, [err localizedDescription]] withStatus:kFailure];
                Error(@"Failed to update invoice %@: %@", self.objectId, [err localizedDescription]);
            } else {
                [UIHelper showInfo:[NSString stringWithFormat:@"Failed to create invoice: %@", [err localizedDescription]] withStatus:kFailure];
                Error(@"Failed to create invoice: %@", [err localizedDescription]);
            }
        }
    }];
}

- (void)toggleActive:(Boolean)isActive {
    NSString *act = isActive ? UNDELETE : DELETE;
    NSString *action = [NSString stringWithFormat:@"%@/%@/%@", CRUD, act, INVOICE_API];
    NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\"}", _ID, self.objectId];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA_, objStr, nil];
    
    __weak Invoice *weakSelf = self;
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            [weakSelf.editDelegate didDeleteObject];
            
            self.isActive = isActive;
            
            if (isActive) {
                [inactiveInvoices removeObject:self];
                [invoices addObject:self];
            } else {
                [invoices removeObject:self];
                [inactiveInvoices addObject:self];
            }

            [ListDelegate didDeleteObject];
        } else {
            [UIHelper showInfo:[NSString stringWithFormat:@"Failed to %@ invoice %@: %@", act, self.objectId, [err localizedDescription]] withStatus:kFailure];
            Error(@"Failed to %@ invoice %@: %@", act, self.objectId, [err localizedDescription]);
        }
    }];
}

+ (id)list:(NSArray *)invArr orderBy:(NSString *)attribue ascending:(Boolean)isAscending {
    if ([attribue isEqualToString:INV_CUSTOMER_NAME]) {
        for (Invoice *inv in invArr) {
            inv.customerName = [Customer objectForKey:inv.customerId].name;
        }
    }
    
    NSSortDescriptor *firstOrder;
    if ([attribue isEqualToString:INV_NUMBER] || [attribue isEqualToString:INV_CUSTOMER_NAME]) {
        firstOrder = [[NSSortDescriptor alloc] initWithKey:attribue ascending:isAscending selector:@selector(localizedCaseInsensitiveCompare:)];
    } else {
        firstOrder = [[NSSortDescriptor alloc] initWithKey:attribue ascending:isAscending];
    }
    NSSortDescriptor *secondOrder = [[NSSortDescriptor alloc] initWithKey:INV_NUMBER ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    return [NSMutableArray arrayWithArray:[invArr sortedArrayUsingDescriptors:[NSArray arrayWithObjects:firstOrder, secondOrder, nil]]];
}

+ (id)listOrderBy:(NSString *)attribue ascending:(Boolean)isAscending active:(Boolean)isActive {
    NSArray *invArr = isActive ? invoices : inactiveInvoices;
    return [[self class] list:invArr orderBy:attribue ascending:isAscending];
}

+ (id)list {
    return invoices;
}

+ (id)listInactive {
    return inactiveInvoices;
}

+ (NSUInteger)count {
    return invoices.count;
}

+ (NSUInteger)countInactive {
    return inactiveInvoices.count;
}

- (void)populateObjectWithInfo:(NSDictionary *)dict {
    self.objectId = [dict objectForKey:_ID];
    self.invoiceNumber = [dict objectForKey:INV_NUMBER];
    self.paymentStatus = [dict objectForKey:INV_PAYMENT_STATUS];
    self.amount = [Util id2Decimal:[dict objectForKey:INV_AMOUNT]];
    self.amountDue = [Util id2Decimal:[dict objectForKey:INV_AMOUNT_DUE]];
    self.customerId = [dict objectForKey:INV_CUSTOMER_ID];
    self.invoiceDate = [Util getDate:[dict objectForKey:INV_DATE] format:nil];
    self.dueDate = [Util getDate:[dict objectForKey:INV_DUE_DATE] format:nil];
    self.isActive = [[dict objectForKey:IS_ACTIVE] isEqualToString:@"1"];
    
    self.lineItems = [NSMutableArray array];
    NSArray *jsonItems = [dict objectForKey:INV_LINE_ITEMS];
    for (id lineItem in jsonItems) {
        Item *item = [[Item alloc] init];
        item.objectId = [lineItem objectForKey:INV_ITEM_ID];
        if ([[lineItem objectForKey:INV_ITEM_QUANTITY] respondsToSelector:@selector(integerValue)]) {
            item.qty = [[lineItem objectForKey:INV_ITEM_QUANTITY] integerValue];
        }
        item.price = [Util id2Decimal:[lineItem objectForKey:INV_ITEM_PRICE]];
        [self.lineItems addObject:item];
    }
}

+ (void)retrieveListForActive:(BOOL)isActive reload:(BOOL)needReload {
//    [UIAppDelegate incrNetworkActivities];
    
    NSString *filter = isActive ? LIST_ACTIVE_INV_FILTER : LIST_INACTIVE_INV_FILTER;
    NSString *action = [LIST_API stringByAppendingString: INVOICE_API];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA_, filter, nil];

    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        id json = [APIHandler getResponse:response data:data error:&err status:&response_status];

//        [UIAppDelegate decrNetworkActivities];
        
        if(response_status == RESPONSE_SUCCESS) {
            [[User GetLoginUser] markProfileFor:kInvoicesChecked checked:YES];
            
            NSMutableArray *invArr;
            if (isActive) {
                if (invoices) {
                    [invoices removeAllObjects];
                } else {
                    invoices = [NSMutableArray array];
                }

                invArr = invoices;
            } else {
                if (inactiveInvoices) {
                    [inactiveInvoices removeAllObjects];
                } else {
                    inactiveInvoices = [NSMutableArray array];
                }

                invArr = inactiveInvoices;
            }
            
            NSArray *jsonInvs = (NSArray *)json;
            
            for (id item in jsonInvs) {
                NSDictionary *dict = (NSDictionary*)item;
                Invoice *inv = [[Invoice alloc] init];
                [inv populateObjectWithInfo:dict];
                                
                [invArr addObject:inv];
            }

            if (needReload) {
//                [ARDelegate didGetInvoices:[NSArray arrayWithArray:invArr]];
                [ListDelegate didGetInvoices:[NSArray arrayWithArray:invArr]];
            }
        } else if (response_status == RESPONSE_TIMEOUT) {
            [ListDelegate failedToGetInvoices];
            [UIHelper showInfo:SysTimeOut withStatus:kError];
            Error(@"Time out when retrieving list of invoice for %@!", isActive ? @"active" : @"inactive");
        } else {
            NSString *errCode = [json objectForKey:RESPONSE_ERROR_CODE];
            if ([INVALID_PERMISSION isEqualToString:errCode]) {
                if (isActive && [ListDelegate respondsToSelector:@selector(deniedPermissionForInvoices)]) {
                    [ListDelegate deniedPermissionForInvoices];
                }
                
                [[User GetLoginUser] markProfileFor:kInvoicesChecked checked:NO];
                if (ListDelegate != [RootMenuViewController sharedInstance]) {
                    [UIHelper showInfo:@"You don't have permission to retrieve invoices." withStatus:kWarning];
                }
            } else {
                if ([ListDelegate respondsToSelector:@selector(failedToGetInvoices)]) {
                    [ListDelegate failedToGetInvoices];
                }
                
                [UIHelper showInfo:[NSString stringWithFormat:@"Failed to retrieve list of invoice for %@! %@", isActive ? @"active" : @"inactive", [err localizedDescription]] withStatus:kFailure];
                Error(@"Failed to retrieve list of invoice for %@! %@", isActive ? @"active" : @"inactive", [err localizedDescription]);
            }
        }
    }];
}

- (void)cloneTo:(BDCBusinessObject *)target {
    [Invoice clone:self to:target];
}

+ (void)clone:(Invoice *)source to:(Invoice *)target {
    [super clone:source to:target];
    
    target.customerId = source.customerId;
    target.invoiceNumber = source.invoiceNumber;
    target.invoiceDate = source.invoiceDate;
    target.dueDate = source.dueDate;
    target.editDelegate = source.editDelegate;
    target.detailsDelegate = source.detailsDelegate;
    
    if (source.lineItems != nil) {
        target.lineItems = [NSMutableArray array];
        for (int i = 0; i < [source.lineItems count]; i++) {
            Item *item = [[Item alloc] init];
            [Item clone:[source.lineItems objectAtIndex:i] to:item];
            [target.lineItems addObject:item];
        }
    }
    
    if (source.attachments != nil) {
        target.attachments = nil;
        target.attachments = [NSMutableArray array];
        //TODO: need deep copy?
        for (id item in source.attachments) {
            [target.attachments addObject:item];
        }
    }
}

- (void)updateParentList {
    if (self.isActive) {
        [Invoice retrieveListForActive:YES];
    } else {
        [Invoice retrieveListForActive:NO];
    }
}

@end
