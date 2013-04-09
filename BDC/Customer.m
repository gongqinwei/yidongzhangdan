//
//  Customer.m
//  BDC
//
//  Created by Qinwei Gong on 9/7/12.
//
//

#import "Customer.h"
#import "Constants.h"
#import "APIHandler.h"
#import "UIHelper.h"
#import "Geo.h"
#import "Util.h"
#import "BDCAppDelegate.h"


@interface Customer ()

//+ (void)setCustomers:(NSDictionary *)custDict active:(Boolean)isActive;

@end

@implementation Customer

static id <CustomerListDelegate> ListDelegate = nil;
static NSMutableDictionary * customers = nil;
static NSMutableDictionary * inactiveCustomers = nil;

//@synthesize name;
@synthesize billAddr1;
@synthesize billAddr2;
@synthesize billAddr3;
@synthesize billAddr4;
@synthesize billCity;
@synthesize billState;
@synthesize billCountry;
@synthesize billZip;
//@synthesize shipAddr1;
//@synthesize shipAddr2;
//@synthesize shipAddr3;
//@synthesize shipAddr4;
//@synthesize shipCity;
//@synthesize shipState;
//@synthesize shipCountry;
//@synthesize shipZip;
@synthesize email;
@synthesize phone;
//@synthesize altPhone;
//@synthesize fax;

@synthesize editDelegate;
@synthesize editInvoiceDelegate;

+ (id<CustomerListDelegate>)getListDelegate {
    return ListDelegate;
}

+ (void)setListDelegate:(id<CustomerListDelegate>)theDelegate {
    ListDelegate = theDelegate;
}

+ (id)listOrderBy:(NSString *)attribue ascending:(Boolean)isAscending active:(Boolean)isActive {
    NSDictionary *custList = isActive ? customers : inactiveCustomers;
    NSArray *customerArr = [custList allValues];
    NSSortDescriptor *firstOrder = [[NSSortDescriptor alloc] initWithKey:attribue ascending:isAscending];
    NSSortDescriptor *secondOrder = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    customerArr = [customerArr sortedArrayUsingDescriptors:[NSArray arrayWithObjects:firstOrder, secondOrder, nil]];
    
    return [NSMutableArray arrayWithArray:customerArr];
}

+ (id)list {
    return [NSMutableArray arrayWithArray:[customers allValues]];
}

+ (id)listInactive {
    return [NSMutableArray arrayWithArray:[inactiveCustomers allValues]];
}

//+ (void)setCustomers:(NSDictionary *)custDict active:(Boolean)isActive {
//    if (isActive) {
//        customers = custDict;
//    } else {
//        inactiveCustomers = custDict;
//    }
//}

+ (Customer *)objectForKey:(NSString *)customerId {
    Customer *customer = [customers objectForKey:customerId];
    if (customer == nil) {
        customer = [inactiveCustomers objectForKey:customerId];
    }
    return customer;
}

+ (void)retrieveListForActive:(BOOL)isActive {
    [UIAppDelegate incrNetworkActivities];
    
    NSString *filter = isActive ? LIST_ACTIVE_FILTER : LIST_INACTIVE_FILTER;
    NSString *action = [LIST_API stringByAppendingString: CUSTOMER_API];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA, filter, nil];
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSArray *jsonCustomers = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        [UIAppDelegate decrNetworkActivities];
        
        if(response_status == RESPONSE_SUCCESS) {
            NSMutableDictionary *customerDict;
            if (isActive) {
                customers = [NSMutableDictionary dictionary];
                customerDict = customers;
            } else {
                inactiveCustomers = [NSMutableDictionary dictionary];
                customerDict = inactiveCustomers;
            }

            for (id item in jsonCustomers) {
                NSDictionary *dict = (NSDictionary*)item;
                Customer *customer = [[Customer alloc] init];
                customer.objectId = [dict objectForKey:ID];
                customer.name = [dict objectForKey:@"name"];
                
                NSString *addr1 = [dict objectForKey:@"billAddress1"];
                NSString *addr2 = [dict objectForKey:@"billAddress2"];
                NSString *addr3 = [dict objectForKey:@"billAddress3"];
                NSString *addr4 = [dict objectForKey:@"billAddress4"];
                NSString *city = [dict objectForKey:@"billAddressCity"];
                NSString *state = [dict objectForKey:@"billAddressState"];
                NSString *country = [dict objectForKey:@"billAddressCountry"];
                NSString *zip = [dict objectForKey:@"billAddressZip"];
                NSString *email = [dict objectForKey:@"email"];
                NSString *phone = [dict objectForKey:@"phone"];

                customer.billAddr1 = (addr1 == (id)[NSNull null]) ? nil : addr1;
                customer.billAddr2 = (addr2 == (id)[NSNull null]) ? nil : addr2;
                customer.billAddr3 = (addr3 == (id)[NSNull null]) ? nil : addr3;
                customer.billAddr4 = (addr4 == (id)[NSNull null]) ? nil : addr4;
                customer.billCity = (city == (id)[NSNull null]) ? nil : city;
                customer.billCountry = (country == (id)[NSNull null]) ? -1 : [COUNTRIES indexOfObject:country];
                if (state == (id)[NSNull null]) {
                    if (customer.billCountry == 0) {  //USA
                        customer.billState = [NSNumber numberWithInt: -1];
                    } else {
                        customer.billState = nil;
                    }
                } else {
                    if (customer.billCountry == 0) {  //USA
                        customer.billState = [NSNumber numberWithInt: [US_STATE_CODES indexOfObject:state]];
                    } else {
                        customer.billState = [NSString stringWithString: state];
                    }
                }                
                customer.billZip = (zip == (id)[NSNull null]) ? nil : zip;
                customer.email = (email == (id)[NSNull null]) ? nil : email;
                customer.phone = (phone == (id)[NSNull null]) ? nil : phone;
                
                customer.isActive = [[dict objectForKey:IS_ACTIVE] isEqualToString:@"1"];

                [customerDict setObject:customer forKey:customer.objectId];
            }

//            [Customer setCustomers:customerDict active:isActive];
            [ListDelegate didGetCustomers];
        } else if (response_status == RESPONSE_TIMEOUT) {
            [ListDelegate failedToGetCustomers];
            [UIHelper showInfo:SysTimeOut withStatus:kError];
            NSLog(@"Time out when retrieving list of customers");
        } else {
            [ListDelegate failedToGetCustomers];
            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
            NSLog(@"Failed to retrieve list of customers for %@! %@", isActive ? @"active" : @"inactive", [err localizedDescription]);
        }
    }];

}

+ (void)clone:(Customer *)source to:(Customer *)target {
    [super clone:source to:target];
    
    target.name = source.name;
    target.isActive = source.isActive;
    target.billAddr1 = source.billAddr1;
    target.billAddr2 = source.billAddr2;
    target.billAddr3 = source.billAddr3;
    target.billAddr4 = source.billAddr4;
    target.billCity = source.billCity;
    target.billState = source.billState;
    target.billCountry = source.billCountry;
    target.billZip = source.billZip;
    target.phone = source.phone;
    target.email = source.email;
    target.editDelegate = source.editDelegate;
    target.editInvoiceDelegate = source.editInvoiceDelegate;
}

- (void)saveFor:(NSString *)action {
    NSString *theAction = [NSString stringWithString:action];
    
    action = [NSString stringWithFormat:@"%@/%@/%@", CRUD, action, CUSTOMER_API];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    NSMutableString *objStr = [NSMutableString string];
    [objStr appendString:@"{"];
    [objStr appendString:OBJ];
    [objStr appendString:@": {"];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", ENTITY, CUSTOMER];
    if ([theAction isEqualToString:UPDATE]) {
        [objStr appendFormat:@"\"%@\" : \"%@\", ", ID, self.objectId];
    }
    [objStr appendFormat:@"\"%@\" : \"%@\", ", CUSTOMER_NAME, self.name];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", CUSTOMER_ADDR1, self.billAddr1 == nil ? @"" : self.billAddr1];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", CUSTOMER_ADDR2, self.billAddr2 == nil ? @"" : self.billAddr2];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", CUSTOMER_ADDR3, self.billAddr3 == nil ? @"" : self.billAddr3];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", CUSTOMER_ADDR4, self.billAddr4 == nil ? @"" : self.billAddr4];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", CUSTOMER_CITY, self.billCity == nil ? @"" : self.billCity];
    
    if ([self.billState isKindOfClass:[NSNumber class]]) {
        int idx = [self.billState intValue];
        if (idx == -1) {
            [objStr appendFormat:@"\"%@\" : \"\", ", CUSTOMER_STATE];
        } else {
            [objStr appendFormat:@"\"%@\" : \"%@\", ", CUSTOMER_STATE, [US_STATE_CODES objectAtIndex:idx]];
        }

    } else {
        [objStr appendFormat:@"\"%@\" : \"%@\", ", CUSTOMER_STATE, self.billState == nil ? @"" : self.billState];
    }
    if (self.billCountry == -1) {
        [objStr appendFormat:@"\"%@\" : \"\", ", CUSTOMER_COUNTRY];
    } else {
        [objStr appendFormat:@"\"%@\" : \"%@\", ", CUSTOMER_COUNTRY, [COUNTRIES objectAtIndex: self.billCountry]];
    }
    
    [objStr appendFormat:@"\"%@\" : \"%@\", ", CUSTOMER_ZIP, self.billZip == nil ? @"" : self.billZip];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", CUSTOMER_EMAIL, self.email == nil ? @"" : [Util URLEncode:self.email]];
    [objStr appendFormat:@"\"%@\" : \"%@\" ", CUSTOMER_PHONE, self.phone == nil ? @"" : self.phone];
    [objStr appendString:@"}"];
    [objStr appendString:@"}"];
    
    [params setObject:DATA forKey:objStr];
    
    __weak Customer *weakSelf = self;
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSDictionary *info = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            NSString *customerId = [info objectForKey:ID];
            self.objectId = customerId;
            
            if ([theAction isEqual:CREATE] || self.isActive) {
                [Customer retrieveListForActive:YES];
            } else {
                [Customer retrieveListForActive:NO];
            }
            
            if ([theAction isEqualToString:UPDATE]) {
                [weakSelf.editDelegate didUpdateCustomer];
                [weakSelf.editInvoiceDelegate didUpdateCustomer];
            } else {
                [weakSelf.editDelegate didCreateCustomer:customerId];
            }
        } else {
            [weakSelf.editDelegate failedToSaveCustomer];
            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
            
            if ([theAction isEqualToString:UPDATE]) {
                NSLog(@"Failed to update customer %@: %@", self.objectId, [err localizedDescription]);
            } else {
                NSLog(@"Failed to create customer: %@", [err localizedDescription]);
            }
        }
    }];
}

- (void)toggleActive:(Boolean)isActive {
    NSString *act = isActive ? UNDELETE : DELETE;
    NSString *action = [NSString stringWithFormat:@"%@/%@/%@", CRUD, act, CUSTOMER_API];
    NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\"}", ID, self.objectId];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA, objStr, nil];
    
//    __weak Customer *weakSelf = self;
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            // manually update model
            self.isActive = isActive;
            
            if (isActive) {
                [inactiveCustomers removeObjectForKey:self.objectId];
                [customers setObject:self forKey:self.objectId];
            } else {
                [customers removeObjectForKey:self.objectId];
                [inactiveCustomers setObject:self forKey:self.objectId];
            }
//            [Customer retrieveListForActive:isActive reload:NO]; // manually update model above instead
            
//            [weakSelf.editDelegate didDeleteCustomer]; //TODO: need another delegate?
        } else {
            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
            NSLog(@"Failed to %@ customer %@: %@", act, self.objectId, [err localizedDescription]);
        }
    }];
}


@end
