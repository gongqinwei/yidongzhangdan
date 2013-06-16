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

//@synthesize addr1;
//@synthesize addr2;
//@synthesize addr3;
//@synthesize addr4;
//@synthesize city;
//@synthesize state;
//@synthesize country;
//@synthesize zip;

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
    
    NSSortDescriptor *firstOrder = [[NSSortDescriptor alloc] initWithKey:CUSTOMER_NAME ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSSortDescriptor *secondOrder = [[NSSortDescriptor alloc] initWithKey:ID ascending:NO];
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
                if (customers) {
                    [customers removeAllObjects];
                } else {
                    customers = [NSMutableDictionary dictionary];
                }

                customerDict = customers;
            } else {
                if (inactiveCustomers) {
                    [inactiveCustomers removeAllObjects];
                } else {
                    inactiveCustomers = [NSMutableDictionary dictionary];
                }

                customerDict = inactiveCustomers;
            }

            for (id item in jsonCustomers) {
                NSDictionary *dict = (NSDictionary*)item;
                Customer *customer = [[Customer alloc] init];
                customer.objectId = [dict objectForKey:ID];
                customer.name = [dict objectForKey:CUSTOMER_NAME];
                
                NSString *addr1 = [dict objectForKey:CUSTOMER_ADDR1];
                NSString *addr2 = [dict objectForKey:CUSTOMER_ADDR2];
                NSString *addr3 = [dict objectForKey:CUSTOMER_ADDR3];
                NSString *addr4 = [dict objectForKey:CUSTOMER_ADDR4];
                NSString *city = [dict objectForKey:CUSTOMER_CITY];
                NSString *state = [dict objectForKey:CUSTOMER_STATE];
                NSString *country = [dict objectForKey:CUSTOMER_COUNTRY];
                NSString *zip = [dict objectForKey:CUSTOMER_ZIP];
                NSString *email = [dict objectForKey:CUSTOMER_EMAIL];
                NSString *phone = [dict objectForKey:CUSTOMER_PHONE];

                customer.addr1 = (addr1 == (id)[NSNull null]) ? nil : addr1;
                customer.addr2 = (addr2 == (id)[NSNull null]) ? nil : addr2;
                customer.addr3 = (addr3 == (id)[NSNull null]) ? nil : addr3;
                customer.addr4 = (addr4 == (id)[NSNull null]) ? nil : addr4;
                customer.city = (city == (id)[NSNull null]) ? nil : city;
                customer.country = (country == (id)[NSNull null]) ? INVALID_OPTION : [COUNTRIES indexOfObject:country];
                if (state == (id)[NSNull null]) {
                    if (customer.country == 0) {  //USA
                        customer.state = [NSNumber numberWithInt: INVALID_OPTION];
                    } else {
                        customer.state = nil;
                    }
                } else {
                    if (customer.country == 0) {  //USA
                        customer.state = [NSNumber numberWithInt: [US_STATE_CODES indexOfObject:state]];
                    } else {
                        customer.state = [NSString stringWithString: state];
                    }
                }                
                customer.zip = (zip == (id)[NSNull null]) ? nil : zip;
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
    target.addr1 = source.addr1;
    target.addr2 = source.addr2;
    target.addr3 = source.addr3;
    target.addr4 = source.addr4;
    target.city = source.city;
    target.state = source.state;
    target.country = source.country;
    target.zip = source.zip;
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
    [objStr appendFormat:@"\"%@\" : \"%@\", ", CUSTOMER_ADDR1, self.addr1 == nil ? @"" : self.addr1];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", CUSTOMER_ADDR2, self.addr2 == nil ? @"" : self.addr2];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", CUSTOMER_ADDR3, self.addr3 == nil ? @"" : self.addr3];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", CUSTOMER_ADDR4, self.addr4 == nil ? @"" : self.addr4];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", CUSTOMER_CITY, self.city == nil ? @"" : self.city];
    
    if ([self.state isKindOfClass:[NSNumber class]]) {
        int idx = [self.state intValue];
        if (idx == -1) {
            [objStr appendFormat:@"\"%@\" : \"\", ", CUSTOMER_STATE];
        } else {
            [objStr appendFormat:@"\"%@\" : \"%@\", ", CUSTOMER_STATE, [US_STATE_CODES objectAtIndex:idx]];
        }

    } else {
        [objStr appendFormat:@"\"%@\" : \"%@\", ", CUSTOMER_STATE, self.state == nil ? @"" : self.state];
    }
    if (self.country == -1) {
        [objStr appendFormat:@"\"%@\" : \"\", ", CUSTOMER_COUNTRY];
    } else {
        [objStr appendFormat:@"\"%@\" : \"%@\", ", CUSTOMER_COUNTRY, [COUNTRIES objectAtIndex: self.country]];
    }
    
    [objStr appendFormat:@"\"%@\" : \"%@\", ", CUSTOMER_ZIP, self.zip == nil ? @"" : self.zip];
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
            
            if ([theAction isEqualToString:CREATE]) {
                self.isActive = YES;
            }
            
            if (self.isActive) {
                [Customer retrieveListForActive:YES];
            } else {
                [Customer retrieveListForActive:NO];
            }
            
            if ([theAction isEqualToString:UPDATE]) {
                [weakSelf.editDelegate didUpdateObject];
                [weakSelf.editInvoiceDelegate didUpdateObject];
            } else {
                [weakSelf.editDelegate didCreateObject:customerId];
            }
        } else {
            [weakSelf.editDelegate failedToSaveObject];
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
    
    __weak Customer *weakSelf = self;
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            [weakSelf.editDelegate didDeleteObject];
            
            // manually update model
            self.isActive = isActive;
            
            if (isActive) {
                [inactiveCustomers removeObjectForKey:self.objectId];
                [customers setObject:self forKey:self.objectId];
            } else {
                [customers removeObjectForKey:self.objectId];
                [inactiveCustomers setObject:self forKey:self.objectId];
            }
            
            [ListDelegate didDeleteObject];
        } else {
            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
            NSLog(@"Failed to %@ customer %@: %@", act, self.objectId, [err localizedDescription]);
        }
    }];
}


@end
