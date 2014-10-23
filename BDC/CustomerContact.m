//
//  CustomerContact.m
//  Mobill
//
//  Created by Qinwei Gong on 9/15/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "CustomerContact.h"
#import "APIHandler.h"
#import "UIHelper.h"
#import "BDCAppDelegate.h"


#define LIST_ACTIVE_FOR_CUSTOMER_FILTER     @"{ \"start\" : 0, \
                                                \"max\" : 999, \
                                                \"filters\" : [ \
                                                    {\"field\" : \"isActive\", \"op\" : \"=\", \"value\" : \"1\"}, \
                                                    {\"field\" : \"customerId\", \"op\" : \"=\", \"value\" : \"%@\"} \
                                                ], \
                                                \"sort\" : [ \
                                                    {\"field\" : \"firstName\", \"asc\" : \"true\"}, \
                                                    {\"field\" : \"lastName\", \"asc\" : \"true\"} \
                                                ] \
                                            }"


static NSMutableDictionary * contacts = nil;
static id <ContactListDelegate> ListDelegate = nil;

@implementation CustomerContact

@synthesize customerId;
@synthesize fname;
@synthesize lname;
@synthesize email;
@synthesize phone;
@synthesize editCustomerDelegate;

+ (void)resetList {
    contacts = [NSMutableDictionary dictionary];
}

- (id)initWithCustomer:(Customer *)customer {
    if (self = [super init]) {        
        self.customerId = customer.objectId;
    }
    return self;
}

+ (id<ContactListDelegate>)getListDelegate {
    return ListDelegate;
}

+ (void)setListDelegate:(id<ContactListDelegate>)theDelegate {
    ListDelegate = theDelegate;
}

+ (NSMutableArray *)listContactsForCustomer:(Customer *)customer {
    return [contacts objectForKey:customer.objectId];
}

- (void)populateObjectWithInfo:(NSDictionary *)dict {
    self.objectId = [dict objectForKey:_ID];
    
    self.customerId = [dict objectForKey:CONTACT_CUSTOMER];
    NSString *fnameStr = [dict objectForKey:CONTACT_FNAME];
    NSString *lnameStr = [dict objectForKey:CONTACT_LNAME];
    NSString *emailStr = [dict objectForKey:CONTACT_EMAIL];
    NSString *phoneStr = [dict objectForKey:CONTACT_PHONE];
    
    self.fname = (fnameStr == (id)[NSNull null]) ? nil : fnameStr;
    self.lname = (lnameStr == (id)[NSNull null]) ? nil : lnameStr;
    self.email = (emailStr == (id)[NSNull null]) ? nil : emailStr;
    self.phone = (phoneStr == (id)[NSNull null]) ? nil : phoneStr;
    
    self.name = self.fname;
    if (self.lname) {
        self.name = [self.name stringByAppendingFormat:@" %@", self.lname];
    }
    
    self.isActive = YES;
    
    [super populateObjectWithInfo:dict];
}

+ (void)retrieveListForCustomer:(NSString *)customerId {
//    [UIAppDelegate incrNetworkActivities];
    
    NSString *filter = [NSString stringWithFormat:LIST_ACTIVE_FOR_CUSTOMER_FILTER, customerId];
    NSString *action = [LIST_API stringByAppendingString: CONTACT_API];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA, filter, nil];
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        id json = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
//        [UIAppDelegate decrNetworkActivities];
        
        if(response_status == RESPONSE_SUCCESS) {
            NSMutableArray *subContacts;
            if (![contacts objectForKey:customerId]) {
                subContacts = [NSMutableArray array];
                [contacts setObject:subContacts forKey:customerId];
            } else {
                subContacts = [contacts objectForKey:customerId];
                [subContacts removeAllObjects];
            }
            
            NSArray *jsonContacts = (NSArray *)json;
            
            for (id item in jsonContacts) {
                NSDictionary *dict = (NSDictionary*)item;
                CustomerContact *contact = [[CustomerContact alloc] init];
                [contact populateObjectWithInfo:dict];
                
                [subContacts addObject:contact];
            }
            
            [ListDelegate didGetContacts];
        } else if (response_status == RESPONSE_TIMEOUT) {
            [ListDelegate failedToGetContacts];
            [UIHelper showInfo:SysTimeOut withStatus:kError];
            Debug(@"Time out when retrieving list of contacts");
        } else {
            [ListDelegate failedToGetContacts];
            
            NSString *errCode = [json objectForKey:RESPONSE_ERROR_CODE];
            if ([INVALID_PERMISSION isEqualToString:errCode]) {
                [UIHelper showInfo:@"You don't have permission to retrieve accounts." withStatus:kWarning];
            } else {
                [UIHelper showInfo:[NSString stringWithFormat:@"Failed to retrieve contacts for %@! %@", customerId, [err localizedDescription]] withStatus:kFailure];
                Error(@"Failed to retrieve contacts for %@! %@", customerId, [err localizedDescription]);
            }
        }
    }];
}

+ (void)retrieveListForActive:(BOOL)isActive {
//    [UIAppDelegate incrNetworkActivities];
    
    NSString *filter = LIST_ACTIVE_FILTER;
    NSString *action = [LIST_API stringByAppendingString: CONTACT_API];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA, filter, nil];
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSArray *jsonContacts = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
//        [UIAppDelegate decrNetworkActivities];
        
        if(response_status == RESPONSE_SUCCESS) {
            if (contacts) {
                [contacts removeAllObjects];
            } else {
                contacts = [NSMutableDictionary dictionary];
            }                
            
            for (id item in jsonContacts) {
                NSDictionary *dict = (NSDictionary*)item;
                CustomerContact *contact = [[CustomerContact alloc] init];
                [contact populateObjectWithInfo:dict];
                
                NSMutableArray *subContacts;
                if (![contacts objectForKey:contact.customerId]) {
                    subContacts = [NSMutableArray array];
                    [contacts setObject:subContacts forKey:contact.customerId];
                } else {
                    subContacts = [contacts objectForKey:contact.customerId];
                }
                
                [subContacts addObject:contact];
            }
            
        } else if (response_status == RESPONSE_TIMEOUT) {
            [UIHelper showInfo:SysTimeOut withStatus:kError];
            Debug(@"Time out when retrieving list of contacts");
        } else {
            [UIHelper showInfo:[NSString stringWithFormat:@"Failed to retrieve list of contacts! %@", [err localizedDescription]] withStatus:kFailure];
            Debug(@"Failed to retrieve list of contacts! %@", [err localizedDescription]);
        }
    }];
}

- (void)saveFor:(NSString *)action {
    NSString *theAction = [NSString stringWithString:action];
    
    action = [NSString stringWithFormat:@"%@/%@/%@", CRUD, action, CONTACT_API];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    NSMutableString *objStr = [NSMutableString string];
    [objStr appendString:@"{"];
    [objStr appendString:OBJ];
    [objStr appendString:@": {"];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", ENTITY, CONTACT];
    if ([theAction isEqualToString:UPDATE]) {
        [objStr appendFormat:@"\"%@\" : \"%@\", ", _ID, self.objectId];
    }
    [objStr appendFormat:@"\"%@\" : \"%@\", ", CONTACT_CUSTOMER, self.customerId];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", CONTACT_FNAME, self.fname == nil ? @"" : self.fname];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", CONTACT_LNAME, self.lname == nil ? @"" : self.lname];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", CONTACT_EMAIL, self.email == nil ? @"" : [Util URLEncode:self.email]];    
    if ([theAction isEqualToString:CREATE]) {
        [objStr appendFormat:@"\"%@\" : \"%@\", ", @"timezoneId", @"3"];
    }
    [objStr appendFormat:@"\"%@\" : \"%@\" ", CONTACT_PHONE, self.phone == nil ? @"" : self.phone];
    [objStr appendString:@"}"];
    [objStr appendString:@"}"];
    
    [params setObject:DATA forKey:objStr];
    
    __weak CustomerContact *weakSelf = self;
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSDictionary *info = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            NSString *contactId = [info objectForKey:_ID];
            self.objectId = contactId;
            
            [CustomerContact retrieveListForCustomer:self.customerId];
            
            if ([theAction isEqualToString:UPDATE]) {
                [weakSelf.editDelegate didUpdateObject];
            } else {
                self.isActive = YES;
                
                NSMutableArray *subContacts;
                if (![contacts objectForKey:self.customerId]) {
                    subContacts = [NSMutableArray array];
                    [contacts setObject:subContacts forKey:self.customerId];
                } else {
                    subContacts = [contacts objectForKey:self.customerId];
                }
                [subContacts addObject:self];
                
                [weakSelf.editDelegate didCreateObject:contactId];
//                [weakSelf.editCustomerDelegate didUpdateObject];
            }
        } else {
            [weakSelf.editDelegate failedToSaveObject];
            
            if ([theAction isEqualToString:UPDATE]) {
                [UIHelper showInfo:[NSString stringWithFormat:@"Failed to update contact %@: %@", self.objectId, [err localizedDescription]] withStatus:kFailure];
                Debug(@"Failed to update contact %@: %@", self.objectId, [err localizedDescription]);
            } else {
                [UIHelper showInfo:[NSString stringWithFormat:@"Failed to create contact: %@", [err localizedDescription]] withStatus:kFailure];
                Debug(@"Failed to create contact: %@", [err localizedDescription]);
            }
        }
    }];
}

- (void)toggleActive:(Boolean)isActive {
    NSString *act = DELETE; //isActive ? UNDELETE : DELETE;
    NSString *action = [NSString stringWithFormat:@"%@/%@/%@", CRUD, act, CONTACT_API];
    NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\"}", _ID, self.objectId];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA, objStr, nil];
    
    __weak CustomerContact *weakSelf = self;
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            [weakSelf.editDelegate didDeleteObject];
            
            // manually update model
            self.isActive = NO; //isActive;
            
            NSMutableArray *contactList = [contacts objectForKey:self.customerId];
            [contactList removeObject:self];
            
            [ListDelegate didDeleteObject];
        } else {
            [UIHelper showInfo:[NSString stringWithFormat:@"Failed to %@ contact %@: %@", act, self.objectId, [err localizedDescription]] withStatus:kFailure];
            Debug(@"Failed to %@ contact %@: %@", act, self.objectId, [err localizedDescription]);
        }
    }];
}

- (void)cloneTo:(BDCBusinessObject *)target {
    [CustomerContact clone:self to:target];
}

+ (void)clone:(CustomerContact *)source to:(CustomerContact *)target {
    [super clone:source to:target];
    
    target.customerId = source.customerId;
    target.fname = source.fname;
    target.lname = source.lname;
    target.name = source.name;
    target.isActive = source.isActive;
    
    target.phone = source.phone;
    target.email = source.email;
    target.editDelegate = source.editDelegate;
    target.editCustomerDelegate = source.editCustomerDelegate;
}

- (void)updateParentList {
    [ListDelegate didReadObject];
}

@end
