//
//  Vendor.m
//  BDC
//
//  Created by Qinwei Gong on 4/24/13.
//
//

#import "Vendor.h"
#import "Constants.h"
#import "APIHandler.h"
#import "UIHelper.h"
#import "Geo.h"
#import "Util.h"
#import "BDCAppDelegate.h"


@implementation Vendor

static id <VendorListDelegate> ListDelegate = nil;
static NSMutableDictionary * vendors = nil;
static NSMutableDictionary * inactiveVendors = nil;

@synthesize addr1;
@synthesize addr2;
@synthesize addr3;
@synthesize addr4;
@synthesize city;
@synthesize state;
@synthesize country;
@synthesize zip;
@synthesize email;
@synthesize phone;
@synthesize payBy;

@synthesize editDelegate;
@synthesize editBillDelegate;

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
    NSSortDescriptor *secondOrder = [[NSSortDescriptor alloc] initWithKey:ID ascending:NO];
    vendorArr = [vendorArr sortedArrayUsingDescriptors:[NSArray arrayWithObjects:firstOrder, secondOrder, nil]];
    
    return [NSMutableArray arrayWithArray:vendorArr];
}

+ (id)list {
    return [NSMutableArray arrayWithArray:[vendors allValues]];
}

+ (id)listInactive {
    return [NSMutableArray arrayWithArray:[inactiveVendors allValues]];
}

+ (Vendor *)objectForKey:(NSString *)vendorId {
    Vendor *vendor = [vendors objectForKey:vendorId];
    if (vendor == nil) {
        vendor = [inactiveVendors objectForKey:vendorId];
    }
    return vendor;
}

+ (void)retrieveListForActive:(BOOL)isActive {
    [UIAppDelegate incrNetworkActivities];
    
    NSString *filter = isActive ? LIST_ACTIVE_FILTER : LIST_INACTIVE_FILTER;
    NSString *action = [LIST_API stringByAppendingString: VENDOR_API];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA, filter, nil];
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSArray *jsonVendors = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        [UIAppDelegate decrNetworkActivities];
        
        if(response_status == RESPONSE_SUCCESS) {
            NSMutableDictionary *vendorDict;
            if (isActive) {
                vendors = [NSMutableDictionary dictionary];
                vendorDict = vendors;
            } else {
                inactiveVendors = [NSMutableDictionary dictionary];
                vendorDict = inactiveVendors;
            }
            
            for (id item in jsonVendors) {
                NSDictionary *dict = (NSDictionary*)item;
                Vendor *vendor = [[Vendor alloc] init];
                vendor.objectId = [dict objectForKey:ID];
                vendor.name = [dict objectForKey:VENDOR_NAME];
                
                NSString *addr1 = [dict objectForKey:VENDOR_ADDR1];
                NSString *addr2 = [dict objectForKey:VENDOR_ADDR2];
                NSString *addr3 = [dict objectForKey:VENDOR_ADDR3];
                NSString *addr4 = [dict objectForKey:VENDOR_ADDR4];
                NSString *city = [dict objectForKey:VENDOR_CITY];
                NSString *state = [dict objectForKey:VENDOR_STATE];
                NSString *country = [dict objectForKey:VENDOR_COUNTRY];
                NSString *zip = [dict objectForKey:VENDOR_ZIP];
                NSString *email = [dict objectForKey:VENDOR_EMAIL];
                NSString *phone = [dict objectForKey:VENDOR_PHONE];
                NSString *payBy = [dict objectForKey:VENDOR_PAYBY];
                
                vendor.addr1 = (addr1 == (id)[NSNull null]) ? nil : addr1;
                vendor.addr2 = (addr2 == (id)[NSNull null]) ? nil : addr2;
                vendor.addr3 = (addr3 == (id)[NSNull null]) ? nil : addr3;
                vendor.addr4 = (addr4 == (id)[NSNull null]) ? nil : addr4;
                vendor.city = (city == (id)[NSNull null]) ? nil : city;
                vendor.country = (country == (id)[NSNull null]) ? -1 : [COUNTRIES indexOfObject:country];
                if (state == (id)[NSNull null]) {
                    if (vendor.country == 0) {  //USA
                        vendor.state = [NSNumber numberWithInt: -1];
                    } else {
                        vendor.state = nil;
                    }
                } else {
                    if (vendor.country == 0) {  //USA
                        vendor.state = [NSNumber numberWithInt: [US_STATE_CODES indexOfObject:state]];
                    } else {
                        vendor.state = [NSString stringWithString: state];
                    }
                }
                vendor.zip = (zip == (id)[NSNull null]) ? nil : zip;
                vendor.email = (email == (id)[NSNull null]) ? nil : email;
                vendor.phone = (phone == (id)[NSNull null]) ? nil : phone;
                vendor.payBy = payBy; //[VendorPaymentTypes indexOfObject:[NSNumber numberWithInt:[payBy intValue]]];
                
                vendor.isActive = [[dict objectForKey:IS_ACTIVE] isEqualToString:@"1"];
                
                [vendorDict setObject:vendor forKey:vendor.objectId];
            }
            
            [ListDelegate didGetVendors];
        } else if (response_status == RESPONSE_TIMEOUT) {
            [ListDelegate failedToGetVendors];
            [UIHelper showInfo:SysTimeOut withStatus:kError];
            NSLog(@"Time out when retrieving list of vendors");
        } else {
            [ListDelegate failedToGetVendors];
            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
            NSLog(@"Failed to retrieve list of vendors for %@! %@", isActive ? @"active" : @"inactive", [err localizedDescription]);
        }
    }];
}

+ (void)clone:(Vendor *)source to:(Vendor *)target {
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
    target.payBy = source.payBy;
    target.editDelegate = source.editDelegate;
    target.editBillDelegate = source.editBillDelegate;
}

- (void)saveFor:(NSString *)action {
    NSString *theAction = [NSString stringWithString:action];
    
    action = [NSString stringWithFormat:@"%@/%@/%@", CRUD, action, VENDOR_API];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    NSMutableString *objStr = [NSMutableString string];
    [objStr appendString:@"{"];
    [objStr appendString:OBJ];
    [objStr appendString:@": {"];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", ENTITY, VENDOR];
    if ([theAction isEqualToString:UPDATE]) {
        [objStr appendFormat:@"\"%@\" : \"%@\", ", ID, self.objectId];
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
    
    [params setObject:DATA forKey:objStr];
    
    __weak Vendor *weakSelf = self;
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSDictionary *info = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            NSString *vendorId = [info objectForKey:ID];
            self.objectId = vendorId;
            
            if ([theAction isEqual:CREATE] || self.isActive) {
                [Vendor retrieveListForActive:YES];
            } else {
                [Vendor retrieveListForActive:NO];
            }
            
            if ([theAction isEqualToString:UPDATE]) {
                [weakSelf.editDelegate didUpdateObject];
                [weakSelf.editBillDelegate didUpdateObject];
            } else {
                [weakSelf.editDelegate didCreateVendor:vendorId];
            }
        } else {
            [weakSelf.editDelegate failedToSaveObject];
            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
            
            if ([theAction isEqualToString:UPDATE]) {
                NSLog(@"Failed to update vendor %@: %@", self.objectId, [err localizedDescription]);
            } else {
                NSLog(@"Failed to create vendor: %@", [err localizedDescription]);
            }
        }
    }];
}

- (void)toggleActive:(Boolean)isActive {
    NSString *act = isActive ? UNDELETE : DELETE;
    NSString *action = [NSString stringWithFormat:@"%@/%@/%@", CRUD, act, VENDOR_API];
    NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\"}", ID, self.objectId];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA, objStr, nil];
    
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
            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
            NSLog(@"Failed to %@ vendor %@: %@", act, self.objectId, [err localizedDescription]);
        }
    }];
}


@end

