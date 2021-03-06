//
//  Vendor.m
//  BDC
//
//  Created by Qinwei Gong on 4/24/13.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import "Vendor.h"
#import "Constants.h"
#import "APIHandler.h"
#import "UIHelper.h"
#import "Geo.h"
#import "Util.h"
#import "BDCAppDelegate.h"
#import "RootMenuViewController.h"


#define VENDOR_INVITE_DATA          @"{ \"vendorId\" : \"%@\", \"email\" : \"%@\"  }"
#define VENDOR_NAME_DATA            @"{ \"objectId\" : \"%@\"  }"


@implementation Vendor

static id <VendorListDelegate> ListDelegate = nil;
static id<VendorNameDelegate> NameDelegate = nil;
static NSMutableDictionary * vendors = nil;
static NSMutableDictionary * inactiveVendors = nil;

@synthesize payBy;
@synthesize editBillDelegate;

+ (Vendor *)loadWithId:(NSString *)objId {
    NSPredicate *predicate = [BDCBusinessObject getPredicate:objId];
    NSArray *result = [[vendors allValues] filteredArrayUsingPredicate:predicate];
    if ([result count] == 1) {
        return result[0];
    }
    
    result = [[inactiveVendors allValues] filteredArrayUsingPredicate:predicate];
    if ([result count] == 1) {
        return result[0];
    }
    
    return nil;
}

+ (void)resetList {
    vendors = [NSMutableDictionary dictionary];
    inactiveVendors = [NSMutableDictionary dictionary];
}

+ (id<VendorListDelegate>)getListDelegate {
    return ListDelegate;
}

+ (void)setListDelegate:(id<VendorListDelegate>)theDelegate {
    ListDelegate = theDelegate;
}

+ (id)listOrderBy:(NSString *)attribue ascending:(Boolean)isAscending active:(Boolean)isActive {
    NSDictionary *vendorList = isActive ? vendors : inactiveVendors;
    NSArray *vendorArr = [vendorList allValues];
    
    NSSortDescriptor *firstOrder = [[NSSortDescriptor alloc] initWithKey:VENDOR_NAME ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
//    NSSortDescriptor *secondOrder = [[NSSortDescriptor alloc] initWithKey:_ID ascending:NO];
    vendorArr = [vendorArr sortedArrayUsingDescriptors:[NSArray arrayWithObjects:firstOrder, nil]];
    
    return [NSMutableArray arrayWithArray:vendorArr];
}

+ (id)list {
    return [NSMutableArray arrayWithArray:[vendors allValues]];
}

+ (id)listInactive {
    return [NSMutableArray arrayWithArray:[inactiveVendors allValues]];
}

+ (NSUInteger)count {
    return vendors.count;
}

+ (NSUInteger)countInactive {
    return inactiveVendors.count;
}

+ (Vendor *)objectForKey:(NSString *)vendorId {
    Vendor *vendor = [vendors objectForKey:vendorId];
    if (vendor == nil) {
        vendor = [inactiveVendors objectForKey:vendorId];
    }
    return vendor;
}

- (void)populateObjectWithInfo:(NSDictionary *)dict {
    self.objectId = [dict objectForKey:_ID];
    self.name = [dict objectForKey:VENDOR_NAME];
    
    NSString *addr1 = [dict objectForKey:VENDOR_ADDR1];
    NSString *addr2 = [dict objectForKey:VENDOR_ADDR2];
    NSString *addr3 = [dict objectForKey:VENDOR_ADDR3];
    NSString *addr4 = [dict objectForKey:VENDOR_ADDR4];
    NSString *city = [dict objectForKey:VENDOR_CITY];
    NSString *state = [dict objectForKey:VENDOR_STATE];
    NSString *country = [dict objectForKey:VENDOR_COUNTRY];
    NSString *zip = [dict objectForKey:VENDOR_ZIP];
    NSString *emailStr = [dict objectForKey:VENDOR_EMAIL];
    NSString *phoneStr = [dict objectForKey:VENDOR_PHONE];
    NSString *payByStr = [dict objectForKey:VENDOR_PAYBY];
    
    self.addr1 = (addr1 == (id)[NSNull null]) ? nil : addr1;
    self.addr2 = (addr2 == (id)[NSNull null]) ? nil : addr2;
    self.addr3 = (addr3 == (id)[NSNull null]) ? nil : addr3;
    self.addr4 = (addr4 == (id)[NSNull null]) ? nil : addr4;
    self.city = (city == (id)[NSNull null]) ? nil : city;
    self.country = (country == (id)[NSNull null]) ? INVALID_OPTION : [COUNTRIES indexOfObject:country];
    if (state == (id)[NSNull null]) {
        if (self.country == 0 || self.country == US_FULL_INDEX) {  //USA
            self.state = [NSNumber numberWithInt: INVALID_OPTION];
        } else {
            self.state = nil;
        }
    } else {
        if (self.country == 0 || self.country == US_FULL_INDEX) {  //USA
            self.state = [NSNumber numberWithUnsignedInteger: [US_STATE_CODES indexOfObject:state]];
        } else {
            self.state = [NSString stringWithString: state];
        }
    }
    self.zip = (zip == (id)[NSNull null]) ? nil : zip;
    self.email = (emailStr == (id)[NSNull null]) ? nil : emailStr;
    self.phone = (phoneStr == (id)[NSNull null]) ? nil : phoneStr;
    self.payBy = payByStr; //[VendorPaymentTypes indexOfObject:[NSNumber numberWithInt:[payBy intValue]]];
    
    self.isActive = [[dict objectForKey:IS_ACTIVE] isEqualToString:@"1"];
    
    [super populateObjectWithInfo:dict];
}

+ (void)retrieveListForActive:(BOOL)isActive {
//    [UIAppDelegate incrNetworkActivities];
    
    NSString *filter = isActive ? LIST_ACTIVE_FILTER : LIST_INACTIVE_FILTER;
    NSString *action = [LIST_API stringByAppendingString: VENDOR_API];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA_, filter, nil];
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        id json = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
//        [UIAppDelegate decrNetworkActivities];

        if(response_status == RESPONSE_SUCCESS) {
            NSMutableDictionary *vendorDict;
            if (isActive) {
                if (vendors) {
                    [vendors removeAllObjects];
                } else {
                    vendors = [NSMutableDictionary dictionary];
                }

                vendorDict = vendors;
            } else {
                if (inactiveVendors) {
                    [inactiveVendors removeAllObjects];
                } else {
                    inactiveVendors = [NSMutableDictionary dictionary];
                }

                vendorDict = inactiveVendors;
            }
            
            NSArray *jsonVendors = (NSArray *)json;
            
            for (id item in jsonVendors) {
                NSDictionary *dict = (NSDictionary*)item;
                Vendor *vendor = [[Vendor alloc] init];
                [vendor populateObjectWithInfo:dict];
                
                [vendorDict setObject:vendor forKey:vendor.objectId];
            }
            
            [ListDelegate didGetVendors];
        } else if (response_status == RESPONSE_TIMEOUT) {
            [ListDelegate failedToGetVendors];
            [UIHelper showInfo:SysTimeOut withStatus:kError];
            Error(@"Time out when retrieving list of vendors");
        } else {
            [ListDelegate failedToGetVendors];
            
            NSString *errCode = [json objectForKey:RESPONSE_ERROR_CODE];
            if ([INVALID_PERMISSION isEqualToString:errCode]) {
                if (ListDelegate != [RootMenuViewController sharedInstance]) {
                    [UIHelper showInfo:@"You don't have permission to retrieve vendors." withStatus:kWarning];
                }
            } else {
                [UIHelper showInfo:[NSString stringWithFormat:@"Failed to retrieve list of vendors for %@! %@", isActive ? @"active" : @"inactive", [err localizedDescription]] withStatus:kFailure];
                Error(@"Failed to retrieve list of vendors for %@! %@", isActive ? @"active" : @"inactive", [err localizedDescription]);
            }
        }
    }];
}

- (void)cloneTo:(BDCBusinessObject *)target {
    [Vendor clone:self to:target];
}

+ (void)clone:(Vendor *)source to:(Vendor *)target {
    [super clone:source to:target];
    
    target.name = source.name;
    target.isActive = source.isActive;
//    target.addr1 = source.addr1;
//    target.addr2 = source.addr2;
//    target.addr3 = source.addr3;
//    target.addr4 = source.addr4;
//    target.city = source.city;
//    target.state = source.state;
//    target.country = source.country;
//    target.zip = source.zip;
    target.phone = source.phone;
    target.email = source.email;
    target.payBy = source.payBy;
    target.editDelegate = source.editDelegate;
    target.editBillDelegate = source.editBillDelegate;
}

- (void)createAndInvite {
    [self saveFor:CREATE andInvite:YES];
}

- (void)saveFor:(NSString *)action {
    [self saveFor:action andInvite:NO];
}

- (void)saveFor:(NSString *)action andInvite:(BOOL)invite {
    NSString *theAction = [NSString stringWithString:action];
    
    action = [NSString stringWithFormat:@"%@/%@/%@", CRUD, action, VENDOR_API];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    NSMutableString *objStr = [NSMutableString string];
    [objStr appendString:@"{"];
    [objStr appendString:OBJ];
    [objStr appendString:@": {"];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", ENTITY, VENDOR];
    if ([theAction isEqualToString:UPDATE]) {
        [objStr appendFormat:@"\"%@\" : \"%@\", ", _ID, self.objectId];
    }
    [objStr appendFormat:@"\"%@\" : \"%@\", ", VENDOR_NAME, self.name];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", VENDOR_ADDR1, self.addr1 == nil ? @"" : self.addr1];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", VENDOR_ADDR2, self.addr2 == nil ? @"" : self.addr2];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", VENDOR_ADDR3, self.addr3 == nil ? @"" : self.addr3];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", VENDOR_ADDR4, self.addr4 == nil ? @"" : self.addr4];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", VENDOR_CITY, self.city == nil ? @"" : self.city];
    
    if ([self.state isKindOfClass:[NSNumber class]]) {
        int idx = [self.state intValue];
        if (idx == -1) {
            [objStr appendFormat:@"\"%@\" : \"\", ", VENDOR_STATE];
        } else {
            [objStr appendFormat:@"\"%@\" : \"%@\", ", VENDOR_STATE, [US_STATE_CODES objectAtIndex:idx]];
        }
        
    } else {
        [objStr appendFormat:@"\"%@\" : \"%@\", ", VENDOR_STATE, self.state == nil ? @"" : self.state];
    }
    if (self.country == -1) {
        [objStr appendFormat:@"\"%@\" : \"\", ", VENDOR_COUNTRY];
    } else {
        [objStr appendFormat:@"\"%@\" : \"%@\", ", VENDOR_COUNTRY, [COUNTRIES objectAtIndex: self.country]];
    }
    
    [objStr appendFormat:@"\"%@\" : \"%@\", ", VENDOR_ZIP, self.zip == nil ? @"" : self.zip];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", VENDOR_EMAIL, self.email == nil ? @"" : [Util URLEncode:self.email]];
    [objStr appendFormat:@"\"%@\" : \"%@\" ", VENDOR_PHONE, self.phone == nil ? @"" : self.phone];
    [objStr appendString:@"}"];
    [objStr appendString:@"}"];
    
    [params setObject:DATA_ forKey:objStr];
    
    __weak Vendor *weakSelf = self;
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSDictionary *info = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            NSString *vendorId = [info objectForKey:_ID];
            self.objectId = vendorId;
            
            if ([theAction isEqualToString:CREATE]) {
                self.isActive = YES;
            }
            
            if (self.isActive) {
                [Vendor retrieveListForActive:YES];
            } else {
                [Vendor retrieveListForActive:NO];
            }
            
            if ([theAction isEqualToString:UPDATE]) {
                [weakSelf.editDelegate didUpdateObject];
                [weakSelf.editBillDelegate didUpdateObject];
            } else {
                [weakSelf.editDelegate didCreateObject:vendorId];
            }
            
            if (invite) {
                [self sendVendorInvite];
            }
        } else {
            [weakSelf.editDelegate failedToSaveObject];
            
            if ([theAction isEqualToString:UPDATE]) {
                [UIHelper showInfo:[NSString stringWithFormat:@"Failed to update vendor %@: %@", self.objectId, [err localizedDescription]] withStatus:kFailure];
                Error(@"Failed to update vendor %@: %@", self.objectId, [err localizedDescription]);
            } else {
                [UIHelper showInfo:[NSString stringWithFormat:@"Failed to create vendor: %@", [err localizedDescription]] withStatus:kFailure];
                Error(@"Failed to create vendor: %@", [err localizedDescription]);
            }
        }
    }];
}

- (void)sendVendorInvite {
    NSString *data = [NSString stringWithFormat:VENDOR_INVITE_DATA, self.objectId, [Util URLEncode:self.email]];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA_, data, nil];
    
    [APIHandler asyncCallWithAction:VENDOR_INVITE_API Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            [UIHelper showInfo:[NSString stringWithFormat:@"%@ invited.\nePayment pending.", self.name] withStatus:kInfo];
        } else if (response_status == RESPONSE_TIMEOUT) {
            [UIHelper showInfo:SysTimeOut withStatus:kError];
        } else {
            [UIHelper showInfo:[NSString stringWithFormat:@"Failed to invite %@! %@", self.name, [err localizedDescription]] withStatus:kFailure];
        }
    }];
}

- (void)toggleActive:(Boolean)isActive {
    NSString *act = isActive ? UNDELETE : DELETE;
    NSString *action = [NSString stringWithFormat:@"%@/%@/%@", CRUD, act, VENDOR_API];
    NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\"}", _ID, self.objectId];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA_, objStr, nil];
    
    __weak Vendor *weakSelf = self;
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            [weakSelf.editDelegate didDeleteObject];
            
            // manually update model
            self.isActive = isActive;
            
            if (isActive) {
                [inactiveVendors removeObjectForKey:self.objectId];
                [vendors setObject:self forKey:self.objectId];
            } else {
                [vendors removeObjectForKey:self.objectId];
                [inactiveVendors setObject:self forKey:self.objectId];
            }
            
            [ListDelegate didDeleteObject];
        } else {
            [UIHelper showInfo:[NSString stringWithFormat:@"Failed to %@ vendor %@: %@", act, self.objectId, [err localizedDescription]] withStatus:kFailure];
            Error(@"Failed to %@ vendor %@: %@", act, self.objectId, [err localizedDescription]);
        }
    }];
}

- (void)updateParentList {
    [ListDelegate didReadObject];
}

+ (void)setRetrieveVendorNameDelegate:(id<VendorNameDelegate>)nameDelegate {
    NameDelegate = nameDelegate;
}

+ (void)retrieveVendorName:(NSString *)vendorId {
    NSString *data = [NSString stringWithFormat:VENDOR_NAME_DATA, vendorId];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA_, data, nil];
    
    [APIHandler asyncCallWithAction:OBJECT_NAME_API Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSDictionary *resp = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            [NameDelegate didGetVendorName:resp[@"name"]];
        } else if (response_status == RESPONSE_TIMEOUT) {
            [UIHelper showInfo:SysTimeOut withStatus:kError];
        } else {
            [UIHelper showInfo:[NSString stringWithFormat:@"Failed to get name of %@! %@", vendorId, [err localizedDescription]] withStatus:kFailure];
        }
    }];
}


@end

