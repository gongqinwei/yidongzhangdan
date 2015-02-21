//
//  Bill.m
//  BDC
//
//  Created by Qinwei Gong on 7/2/12.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import "Bill.h"
#import "Vendor.h"
#import "APLineItem.h"
#import "Constants.h"
#import "APIHandler.h"
#import "Util.h"
#import "User.h"
#import "Uploader.h"
#import "UIHelper.h"
#import "BDCAppDelegate.h"
#import "RootMenuViewController.h"

#define LIST_ACTIVE_BILL_FILTER     @"{ \"start\" : 0, \
                                        \"max\" : 999, \
                                        \"filters\" : [{\"field\" : \"isActive\", \"op\" : \"=\", \"value\" : \"1\"}, {\"field\" : \"paymentStatus\", \"op\" : \"!=\", \"value\" : \"0\"}] \
                                    }"

#define LIST_INACTIVE_BILL_FILTER   @"{ \"start\" : 0, \
                                        \"max\" : 999, \
                                        \"filters\" : [{\"field\" : \"isActive\", \"op\" : \"=\", \"value\" : \"2\"}, {\"field\" : \"paymentStatus\", \"op\" : \"!=\", \"value\" : \"0\"}] \
                                    }"

#define LIST_APPROVALS_FILTER       @"{ \"type\" : \"Bill\", \"usersId\" :  \"%@\", \"entity\" : \"Bill\", \"approvalType\" : \"0\", \"marker\" : \"\", \"max\" : 999 }"

#define APPROVAL_DATA               @"{ \"objectId\" : \"%@\", \"comment\" : \"%@\" , \"entity\" : \"Bill\" }"


@implementation Bill

static id<BillListDelegate> APDelegate = nil;
static id<BillListDelegate> ListDelegate = nil;
static id<BillListDelegate> ListForApprovalDelegate = nil;
static NSMutableArray *bills = nil;
static NSMutableArray *inactiveBills = nil;
static NSMutableArray *billsToApprove;
static NSMutableSet *billsToApproveSet;

@synthesize vendorId;
@synthesize vendorName;
@synthesize invoiceNumber;
@synthesize dueDate;
@synthesize invoiceDate;
@synthesize amount;
@synthesize paidAmount;
@synthesize scheduledAmount;
@synthesize approvalStatus;
@synthesize paymentStatus;
@synthesize lineItems;
@synthesize detailsDelegate;
@synthesize approvalDelegate;


- (void)approve {
    [self approveWithComment:@""];
}

- (void)approveWithComment:(NSString *)comment {
    [self makeApprovalDecision:APPROVE_API withComment:comment];
}

- (void)denyWithComment:(NSString *)comment {
    [self makeApprovalDecision:DENY_API withComment:comment];
}

- (void)skipWithComment:(NSString *)comment {
    [self makeApprovalDecision:SKIP_API withComment:comment];
}

- (void)makeApprovalDecision:(NSString *)action withComment:(NSString *)comment {
//    [UIAppDelegate incrNetworkActivities];
    
    NSString *filter = [NSString stringWithFormat:APPROVAL_DATA, self.objectId, comment];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA_, filter, nil];
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        [APIHandler getResponse:response data:data error:&err status:&response_status];
        
//        [UIAppDelegate decrNetworkActivities];
        
        if(response_status == RESPONSE_SUCCESS) {
            [billsToApprove removeObject:self];
            [billsToApproveSet removeObject:self];
            
            [self.approvalDelegate didProcessApproval];
            [ListForApprovalDelegate didProcessApproval];
            
            [Bill updateNumToApprove:billsToApprove.count];
            
            NSString *did;
            if ([action isEqualToString:APPROVE_API]) {
                did = @"approved";
            } else if ([action isEqualToString:DENY_API]) {
                did = @"denied";
            } else {
                did = @"processed";
            }
            [UIHelper showInfo:[NSString stringWithFormat:@"Successfully %@ the bill!", did] withStatus:kSuccess];
            
            [Util track:[NSString stringWithFormat:@"%@-ed_bill", action]];
        } else if (response_status == RESPONSE_TIMEOUT) {
            [self.approvalDelegate failedToProcessApproval];
            [ListForApprovalDelegate failedToProcessApproval];
            [UIHelper showInfo:SysTimeOut withStatus:kError];
            Error(@"Time out when processing %@ for bill %@!", action, self.objectId);
        } else {
            [self.approvalDelegate failedToProcessApproval];
            [ListForApprovalDelegate failedToProcessApproval];
            [UIHelper showInfo:[NSString stringWithFormat:@"Failed to processing %@ for bill %@! %@", action, self.objectId, [err localizedDescription]] withStatus:kFailure];
            Error(@"Failed to processing %@ for bill %@! %@", action, self.objectId, [err localizedDescription]);
        }
    }];
}

+ (Bill *)loadWithId:(NSString *)objId {
    NSPredicate *predicate = [BDCBusinessObject getPredicate:objId];
    NSArray *result = [bills filteredArrayUsingPredicate:predicate];
    if ([result count] == 1) {
        return result[0];
    }
    
    result = [inactiveBills filteredArrayUsingPredicate:predicate];
    if ([result count] == 1) {
        return result[0];
    }
    
    return nil;
}

+ (void)updateNumToApprove:(NSInteger)count {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].applicationIconBadgeNumber = count;    //update badge
        
        if (count == 0) {
            [RootMenuViewController sharedInstance].numBillsToApproveLabel.hidden = YES;
        } else {
            [RootMenuViewController sharedInstance].numBillsToApproveLabel.text = [NSString stringWithFormat:@"(%ld)", (long)count];
            [RootMenuViewController sharedInstance].numBillsToApproveLabel.hidden = NO;
        }
    });
}

+ (void)resetList {
    bills = [NSMutableArray array];
    inactiveBills = [NSMutableArray array];
    billsToApprove = [NSMutableArray array];
}

+ (void)setAPDelegate:(id<BillListDelegate>)delegate {
    APDelegate = delegate;
}

+ (void)setListDelegate:(id<BillListDelegate>)delegate {
    ListDelegate = delegate;
}

+ (void)setListForApprovalDelegate:(id<BillListDelegate>)delegate {
    ListForApprovalDelegate = delegate;
}

- (NSString *)name {
    return self.invoiceNumber;
}

- (id) init {
    if (self = [super init]) {
        self.lineItems = [NSMutableArray array];
//        self.attachments = [NSMutableArray array];
    }
    return self;
}

- (void)populateObjectWithInfo:(NSDictionary *)dict {
    self.objectId = [dict objectForKey:_ID];
    self.invoiceNumber = [dict objectForKey:BILL_NUMBER];
    self.amount = [Util id2Decimal:[dict objectForKey:BILL_AMOUNT]];
    self.paidAmount = [Util id2Decimal:[dict objectForKey:BILL_AMOUNT_PAID]];
    self.scheduledAmount = [Util id2Decimal:[dict objectForKey:BILL_AMOUNT_SCHEDULED]];
    self.vendorId = [dict objectForKey:BILL_VENDOR_ID];
    self.invoiceDate = [Util getDate:[dict objectForKey:BILL_DATE] format:nil];
    self.dueDate = [Util getDate:[dict objectForKey:BILL_DUE_DATE] format:nil];
    self.approvalStatus = [dict objectForKey:BILL_APPROVAL_STATUS];    
    self.paymentStatus = [dict objectForKey:BILL_PAYMENT_STATUS];
    self.isActive = [[dict objectForKey:IS_ACTIVE] isEqualToString:@"1"];
    
    self.lineItems = [NSMutableArray array];
    NSArray *jsonItems = [dict objectForKey:BILL_LINE_ITEMS];
    for (id lineItem in jsonItems) {
        APLineItem *item = [[APLineItem alloc] init];
        item.objectId = [lineItem objectForKey:_ID];
        item.account = [ChartOfAccount objectForKey:[lineItem objectForKey:LINE_ITEM_ACCOUNT]];        
        item.amount = [Util id2Decimal:[lineItem objectForKey:LINE_ITEM_AMOUNT]];
        [self.lineItems addObject:item];
    }
}

- (void)saveFor:(NSString *)action {
    NSString *theAction = [NSString stringWithString:action];
    
    action = [NSString stringWithFormat:@"%@/%@/%@", CRUD, action, BILL_API];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    NSMutableString *objStr = [NSMutableString string];
    [objStr appendString:@"{"];
    [objStr appendString:OBJ];
    [objStr appendString:@": {"];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", ENTITY, BILL];
    if ([theAction isEqualToString:UPDATE]) {
        [objStr appendFormat:@"\"%@\" : \"%@\", ", _ID, self.objectId];
    }
    [objStr appendFormat:@"\"%@\" : \"%@\", ", BILL_VENDOR_ID, self.vendorId];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", BILL_NUMBER, self.invoiceNumber];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", BILL_DATE, [Util formatDate:self.invoiceDate format:@"yyyy-MM-dd"]];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", BILL_DUE_DATE, [Util formatDate:self.dueDate format:@"yyyy-MM-dd"]];
    [objStr appendFormat:@"\"%@\" : [", BILL_LINE_ITEMS];
    NSInteger total = [self.lineItems count];
    int i = 0;
    for (APLineItem *lineItem in self.lineItems) {
        [objStr appendString:@"{"];
        [objStr appendFormat:@"\"%@\" : \"%@\", ", ENTITY, BILL_LINE_ITEM];
        if ([theAction isEqualToString:UPDATE] && lineItem.objectId) {
            [objStr appendFormat:@"\"%@\" : \"%@\", ", _ID, lineItem.objectId];
        }
        if (lineItem.account.objectId) {
            [objStr appendFormat:@"\"%@\" : \"%@\", ", BILL_LINE_ITEM_ACCOUNT, lineItem.account.objectId];
        }
        [objStr appendFormat:@"\"%@\" : %@", BILL_LINE_ITEM_AMOUNT, lineItem.amount];
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
    
    __weak Bill *weakSelf = self;
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSDictionary *info = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            NSString *billId = [info objectForKey:_ID];
            self.objectId = billId;
            
            if ([theAction isEqualToString:CREATE]) {
                self.isActive = YES;
            }
            
            if (self.isActive) {
                [Bill retrieveListForActive:YES];
            } else {
                [Bill retrieveListForActive:NO];
            }
            
            if ([theAction isEqualToString:UPDATE]) {
                [weakSelf.editDelegate didUpdateObject];
                [weakSelf.detailsDelegate didUpdateObject];
            } else {
                self.newBorn = YES;
                [weakSelf read];    //to get default approval info and line item id's
                [weakSelf.editDelegate didCreateObject:billId];
            }
        } else {
            [weakSelf.editDelegate failedToSaveObject];
            
            if ([theAction isEqualToString:UPDATE]) {
                [UIHelper showInfo:[NSString stringWithFormat:@"Failed to update bill %@: %@", self.name, [err localizedDescription]] withStatus:kFailure];
                Error(@"Failed to update bill %@: %@", self.name, [err localizedDescription]);
            } else {
                [UIHelper showInfo:[NSString stringWithFormat:@"Failed to create bill: %@", [err localizedDescription]] withStatus:kFailure];
                Error(@"Failed to create bill: %@", [err localizedDescription]);
            }
        }
    }];
}

- (void)toggleActive:(Boolean)isActive {
    NSString *act = isActive ? UNDELETE : DELETE;
    NSString *action = [NSString stringWithFormat:@"%@/%@/%@", CRUD, act, BILL_API];
    NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\"}", _ID, self.objectId];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA_, objStr, nil];
    
    __weak Bill *weakSelf = self;
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            [weakSelf.editDelegate didDeleteObject];
            
            self.isActive = isActive;
            
            if (isActive) {
                [inactiveBills removeObject:self];
                [bills addObject:self];
            } else {
                [bills removeObject:self];
                [inactiveBills addObject:self];
            }
            
            [ListDelegate didDeleteObject];
        } else {
            [UIHelper showInfo:[NSString stringWithFormat:@"Failed to %@ bill %@: %@", act, self.objectId, [err localizedDescription]] withStatus:kFailure];
            Error(@"Failed to %@ bill %@: %@", act, self.objectId, [err localizedDescription]);
        }
    }];
}

+ (id)list:(NSArray *)arr orderBy:(NSString *)attribue ascending:(Boolean)isAscending {
    if ([attribue isEqualToString:BILL_VENDOR_NAME]) {
        for (Bill *bill in arr) {
            bill.vendorName = [Vendor objectForKey:bill.vendorId].name;
        }
    }
    
    NSSortDescriptor *firstOrder;
    if ([attribue isEqualToString:BILL_NUMBER] || [attribue isEqualToString:BILL_VENDOR_NAME] || [attribue isEqualToString:BILL_APPROVAL_STATUS]) {
        firstOrder = [[NSSortDescriptor alloc] initWithKey:attribue ascending:isAscending selector:@selector(localizedCaseInsensitiveCompare:)];
    } else {
        firstOrder = [[NSSortDescriptor alloc] initWithKey:attribue ascending:isAscending];
    }
    
    NSSortDescriptor *secondOrder = [[NSSortDescriptor alloc] initWithKey:BILL_NUMBER ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    return [NSMutableArray arrayWithArray:[arr sortedArrayUsingDescriptors:[NSArray arrayWithObjects:firstOrder, secondOrder, nil]]];
}

+ (id)listOrderBy:(NSString *)attribue ascending:(Boolean)isAscending active:(Boolean)isActive {
    NSArray *arr = isActive ? bills : inactiveBills;
    return [[self class] list:arr orderBy:attribue ascending:isAscending];
}

+ (id)list {
    return bills;
}

+ (id)listInactive {
    return inactiveBills;
}

+ (NSUInteger)count {
    return bills.count;
}

+ (NSUInteger)countInactive {
    return inactiveBills.count;
}

+ (id)listBillsToApprove {
    return billsToApprove;
}

+ (BOOL)isBillToApprove:(Bill *)bill {
    return [billsToApproveSet containsObject:bill];
}

+ (void)retrieveListForApproval:(void (^)(UIBackgroundFetchResult))completionHandler {
//    [UIAppDelegate incrNetworkActivities];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA_, [NSString stringWithFormat:LIST_APPROVALS_FILTER, [Util getUserId]], nil];
    
    [APIHandler asyncCallWithAction:LIST_APPROVALS_API Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        id json = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
//        [UIAppDelegate decrNetworkActivities];
        
        if(response_status == RESPONSE_SUCCESS) {
            [[User GetLoginUser] markProfileFor:kToApproveChecked checked:YES];
            
            if (billsToApprove) {
                [billsToApprove removeAllObjects];
                [billsToApproveSet removeAllObjects];
            } else {
                billsToApprove = [NSMutableArray array];
                billsToApproveSet = [NSMutableSet set];
            }
            
            NSArray *jsonBills = [json objectForKey:@"approvals"];
            
            for (id item in jsonBills) {
                NSDictionary *dict = (NSDictionary*)item;
                Bill *bill = [[Bill alloc] init];
                [bill populateObjectWithInfo:dict];
                
                [billsToApprove addObject:bill];
                [billsToApproveSet addObject:bill];
            }
            
            billsToApprove = [Bill list:billsToApprove orderBy:BILL_NUMBER ascending:YES];
            
            [ListForApprovalDelegate didGetBillsToApprove:billsToApprove];
            
            [Bill updateNumToApprove:billsToApprove.count];
            
            if (completionHandler) {
                completionHandler(UIBackgroundFetchResultNewData);
            }
        } else if (response_status == RESPONSE_TIMEOUT) {
            [ListForApprovalDelegate failedToGetBillsToApprove];
            [UIHelper showInfo:SysTimeOut withStatus:kError];
            Error(@"Time out when retrieving list of bill to approve!");
            if (completionHandler) {
                completionHandler(UIBackgroundFetchResultFailed);
            }
        } else {
            [ListForApprovalDelegate failedToGetBillsToApprove];
            
            NSString *errCode = [json objectForKey:RESPONSE_ERROR_CODE];
            if ([INVALID_PERMISSION isEqualToString:errCode]) {
                if ([ListForApprovalDelegate respondsToSelector:@selector(deniedPermissionForApproval)]) {
                    [ListForApprovalDelegate deniedPermissionForApproval];
                }
                
                [[User GetLoginUser] markProfileFor:kToApproveChecked checked:NO];
//                if (ListForApprovalDelegate != [RootMenuViewController sharedInstance]) {
//                    [UIHelper showInfo:@"You don't have permission to retrieve approvals" withStatus:kWarning];
//                }
            } else {
                [UIHelper showInfo:[NSString stringWithFormat:@"Failed to retrieve list of bill to approve! %@", [err localizedDescription]] withStatus:kFailure];
                Error(@"Failed to retrieve list of bill to approve! %@", [err localizedDescription]);
                if (completionHandler) {
                    completionHandler(UIBackgroundFetchResultFailed);
                }
            }
        }
    }];
}

+ (void)retrieveListForActive:(BOOL)isActive reload:(BOOL)needReload {
//    [UIAppDelegate incrNetworkActivities];
    
    NSString *filter = isActive ? LIST_ACTIVE_BILL_FILTER : LIST_INACTIVE_BILL_FILTER;
    NSString *action = [LIST_API stringByAppendingString: BILL_API];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA_, filter, nil];
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        id json = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
//        [UIAppDelegate decrNetworkActivities];
        
        if(response_status == RESPONSE_SUCCESS) {
            [[User GetLoginUser] markProfileFor:kBillsChecked checked:YES];
            
            NSMutableArray *billArr;
            if (isActive) {
                if (bills) {
                    [bills removeAllObjects];
                } else {
                    bills = [NSMutableArray array];
                }
                
                billArr = bills;
            } else {
                if (inactiveBills) {
                    [inactiveBills removeAllObjects];
                } else {
                    inactiveBills = [NSMutableArray array];
                }

                billArr = inactiveBills;
            }
            
            NSArray *jsonBills = (NSArray *)json;
            
            for (id item in jsonBills) {
                NSDictionary *dict = (NSDictionary*)item;
                Bill *bill = [[Bill alloc] init];
                [bill populateObjectWithInfo:dict];
                
                [billArr addObject:bill];
            }
                        
            if (needReload) {
                [ListDelegate didGetBills:[NSArray arrayWithArray:billArr]];
            }
        } else if (response_status == RESPONSE_TIMEOUT) {
            [ListDelegate failedToGetBills];
            [UIHelper showInfo:SysTimeOut withStatus:kError];
            Error(@"Time out when retrieving list of bill for %@!", isActive ? @"active" : @"inactive");
        } else {
            NSString *errCode = [json objectForKey:RESPONSE_ERROR_CODE];
            if ([INVALID_PERMISSION isEqualToString:errCode]) {
                if (isActive && [ListDelegate respondsToSelector:@selector(deniedPermissionForBills)]) {
                    [ListDelegate deniedPermissionForBills];
                }
                
                [[User GetLoginUser] markProfileFor:kBillsChecked checked:NO];
                if (ListDelegate != [RootMenuViewController sharedInstance]) {
                    [UIHelper showInfo:@"You don't have permission to retrieve bills." withStatus:kWarning];
                }
            } else {
                if ([ListDelegate respondsToSelector:@selector(failedToGetBills)]) {
                    [ListDelegate failedToGetBills];
                }
                
                [UIHelper showInfo:[NSString stringWithFormat:@"Failed to retrieve list of bill for %@! %@", isActive ? @"active" : @"inactive", [err localizedDescription]] withStatus:kFailure];
                Error(@"Failed to retrieve list of bill for %@! %@", isActive ? @"active" : @"inactive", [err localizedDescription]);
            }
        }
    }];
}

- (void)cloneTo:(BDCBusinessObject *)target {
    [Bill clone:self to:target];
}

+ (void)clone:(Bill *)source to:(Bill *)target {
    [super clone:source to:target];
    
    target.vendorId = source.vendorId;
    target.invoiceNumber = source.invoiceNumber;
    target.invoiceDate = source.invoiceDate;
    target.dueDate = source.dueDate;
    target.approvalStatus = source.approvalStatus;
    target.paymentStatus = source.paymentStatus;
    target.amount = source.amount;
    target.paidAmount = source.paidAmount;
    target.scheduledAmount = source.scheduledAmount;
    target.editDelegate = source.editDelegate;
    target.detailsDelegate = source.detailsDelegate;
    
    if (source.lineItems != nil) {
        target.lineItems = [NSMutableArray array];
        for (int i = 0; i < [source.lineItems count]; i++) {
            APLineItem *item = [[APLineItem alloc] init];
            [APLineItem clone:[source.lineItems objectAtIndex:i] to:item];
            [target.lineItems addObject:item];
        }
    }
    
    if (source.attachments != nil) {
        target.attachments = nil;
        target.attachments = [NSMutableArray array];

        for (id item in source.attachments) {
            [target.attachments addObject:item];
        }
    }
}

- (void)updateParentList {
    if (self.isActive) {
        [Bill retrieveListForActive:YES];
    } else {
        [Bill retrieveListForActive:NO];
    }
}


//- (void) create {
//    NSString * action = [NSString stringWithFormat:@"%@/%@/%@", CRUD, CREATE, BILL_API];
//
//    NSMutableDictionary *info = [NSMutableDictionary dictionary];
//
//    NSMutableString *objStr = [NSMutableString string];
//    [objStr appendString:@"{"];
//    [objStr appendString:OBJ];
//    [objStr appendString:@": {"];
//    [objStr appendString:@"\"entity\" : \"Bill\","];
//    [objStr appendFormat:@"\"vendorId\" : \"%@\",", @"00901LJFXVBTKIUXUZ8e"];  //self.vendorId];
//    [objStr appendFormat:@"\"invoiceNumber\" : \"%@\",", self.invNum];
//    [objStr appendFormat:@"\"invoiceDate\" : \"%@\",", [Util formatDate:self.invDate format:@"yyyy-MM-dd"]];
//    [objStr appendFormat:@"\"dueDate\" : \"%@\",", [Util formatDate:self.dueDate format:@"yyyy-MM-dd"]];
//    [objStr appendString:@"\"paymentStatus\" : \"1\","];
//    [objStr appendString:@"\"billLineItems\" : ["];
//    [objStr appendString:@"{"];
//    [objStr appendString:@"\"entity\" : \"BillLineItem\","];
//    [objStr appendFormat:@"\"amount\" : %.2f", [[NSDecimalNumber decimalNumberWithDecimal:self.amount] doubleValue] ];
//    [objStr appendString:@"}"];
//    [objStr appendString:@"]"];
//    [objStr appendString:@"}"];
//    [objStr appendString:@"}"];
//    [info setObject:DATA_ forKey:objStr];
//    [APIHandler asyncCallWithAction:action Info:info AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
//        NSInteger response_status;
//        NSDictionary *info = [APIHandler getResponse:response data:data error:&err status:&response_status];
//        if(response_status == RESPONSE_SUCCESS) {
//            NSString *bId = [info objectForKey:_ID];
//            self.objectId = bId;
//            // TODO: need to change server code to return DocumentPg id instead of Document id here
//            // assotiate documents(photos) to this newly created bill object
////            [self attachDoc];
//            [self.delegate didCreateBill:self.objectId];
//        } else {
//            NSString * msg = @"Failed to create new bill! ";
//            [UIHelper showInfo:[msg stringByAppendingString:[err localizedDescription]] withStatus:kFailure];
//            Debug(@"%@ %@", msg, [err localizedDescription]);
//        }
//    }];
//}


//// currently not used...
//- (void) attachDocs {
//    NSString * action = [NSString stringWithFormat:@"%@", UPLOAD_API];
//    
//    NSMutableDictionary *info = [NSMutableDictionary dictionary];
////    [info setObject:self.billId forKey:BILL_ID];
////    [info setObject:[[self.docs allObjects] componentsJoinedByString:@","] forKey:DOC_PG_IDS];
//
//    [info setObject:_ID forKey:self.objectId];
//
//    for (NSString *doc in self.docs) {
//        [info setObject:DOC_PG_ID forKey:doc];
//    }
//    
//    [APIHandler asyncCallWithAction:action Info:info AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
////        NSError *error;
////        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
////        
////        int response_status = [[json objectForKey:RESPONSE_STATUS_KEY] intValue];
//        
//        NSInteger response_status;
//        [APIHandler getResponse:response data:data error:&err status:&response_status];
//        
//        if(response_status == RESPONSE_SUCCESS) {
//            //TODO: display overlay here?
//            Debug(@"Succeeded in attaching photo to bill");
//        } else {
//            Debug(@"Failed to attaching photo to bill");
//            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
//            Debug(@"Failed to attaching photo to bill: %@", [err localizedDescription]);
//        }
//    }];
//}



@end
