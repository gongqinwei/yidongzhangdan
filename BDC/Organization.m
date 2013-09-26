//
//  Organization.m
//  BDC
//
//  Created by Qinwei Gong on 7/9/12.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "Organization.h"
#import "Constants.h"
#import "APIHandler.h"
#import "Util.h"
#import "UIHelper.h"


@implementation Organization

static id <OrgDelegate> delegate = nil;
static NSArray *orgs = nil;
static Organization *selectedOrg = nil;

@synthesize needApprovalToPayBill;
@synthesize defaultApproverId;
@synthesize defaultApproverForAllFutureBills;
@synthesize changesToApprovedBills;

@synthesize showAR;
@synthesize showAP;
@synthesize enableAR;
@synthesize enableAP;


- (void)getOrgFeatures {
    [APIHandler asyncCallWithAction:ORG_FEATURE_API Info:nil AndHandler:^(NSURLResponse *response, NSData *data, NSError *err) {
        NSInteger response_status;
        NSDictionary *orgFeatures = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            self.showAR = [[orgFeatures objectForKey:SHOW_AR] boolValue];
            self.showAP = [[orgFeatures objectForKey:SHOW_AP] boolValue];
            self.enableAR = [[orgFeatures objectForKey:ENABLE_AR] boolValue];
            self.enableAP = [[orgFeatures objectForKey:ENABLE_AP] boolValue];
            
            [delegate didGetOrgFeatures];
        } else {
            if ([[orgFeatures objectForKey:RESPONSE_ERROR_CODE] isEqualToString:ORG_LOCKED_OUT]) {
                [UIHelper showInfo:@"This account is past due and is locked out by Bill.com!" withStatus:kWarning];
            } else {
                Debug(@"Failed to get org features for %@!", self.objectId);
            }
            
            [delegate failedToGetOrgFeatures];
        }
    }];
}

- (void)getOrgPrefs {
    [APIHandler asyncCallWithAction:ORG_PREF_API Info:nil AndHandler:^(NSURLResponse *response, NSData *data, NSError *err) {
        NSInteger response_status;
        NSDictionary *orgPrefs = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            self.needApprovalToPayBill = [[orgPrefs objectForKey:BILLS_NEED_APPROVALS] boolValue];
            self.defaultApproverId = [orgPrefs objectForKey:DEFAULT_APPROVER];
            self.defaultApproverForAllFutureBills = [[orgPrefs objectForKey:DEFAULT_APPROVER_FOR_ALL_FUTURE_BILLS] boolValue];
            self.changesToApprovedBills = [[orgPrefs objectForKey:CHANGES_TO_APPROVED_BILLS] intValue];
        }
    }];
}

// depricated
- (void)retrieveNeedApprovalToPayBill {
    [APIHandler asyncCallWithAction:ORG_PAY_NEED_APPROVAL_API Info:nil AndHandler:^(NSURLResponse *response, NSData *data, NSError *err) {
        NSInteger response_status;
        
        id json = [APIHandler getResponse:response data:data error:&err status:&response_status];
                
        if(response_status == RESPONSE_SUCCESS) {
            self.needApprovalToPayBill = [json boolValue];
        }
    }];
}

+ (id<OrgDelegate>)getDelegate {
    return delegate;
}

+ (void)setDelegate:(id<OrgDelegate>)theDelegate {
    delegate = theDelegate;
}

+ (id)list {
    NSSortDescriptor *firstOrder = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
//    NSSortDescriptor *secondOrder = [[NSSortDescriptor alloc] initWithKey:ID ascending:NO selector:@selector(localizedCaseInsensitiveCompare:)];
    orgs = [orgs sortedArrayUsingDescriptors:[NSArray arrayWithObjects:firstOrder, nil]];
    
    return orgs;
}

+ (int)count {
    return orgs.count;
}

+ (void)setOrgs:(NSArray *)orgList {
    orgs = orgList;
}

+ (Organization *)getSelectedOrg {
    return selectedOrg;
}

+ (void)selectOrg:(Organization *)org {
    selectedOrg = org;
    
    // persist
    [Util setSelectedOrgId:org.objectId];
    
    // retrieve org bill pay need approval info
//    [org retrieveNeedApprovalToPayBill];
    [org getOrgPrefs];
}

+ (void)retrieveList {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    [info setObject:USERNAME forKey:[Util URLEncode:[Util getUsername]]];
    [info setObject:PASSWORD forKey:[Util URLEncode:[Util getPassword]]];
    
    [APIHandler asyncCallWithAction:LIST_ORG_API Info:info AndHandler:^(NSURLResponse *response, NSData *data, NSError *err) {
        NSInteger response_status;
        
        NSArray *jsonOrgs = [APIHandler getResponse:response data:data error:&err status:&response_status];
        if(response_status == RESPONSE_SUCCESS) {
            if ([jsonOrgs count] > 0) {
                NSMutableArray *orgArr = [[NSMutableArray alloc] init];

                for (int i = 0; i < [jsonOrgs count]; i++) {
                    NSDictionary *dict = (NSDictionary*)[jsonOrgs objectAtIndex:i];
                    Organization *org = [[Organization alloc] init];
                    org.objectId = [dict objectForKey:@"orgId"];
                    org.name = [dict objectForKey:@"orgName"];
                    [orgArr addObject:org];
                    
                    NSString *selectedOrgId = [Util getSelectedOrgId];
                    if (selectedOrgId != nil && [selectedOrgId length] > 0 && [selectedOrgId isEqualToString:org.objectId]) {
                        [Organization selectOrg:org];
                    }
                }
                
                NSArray *orgs = [NSArray arrayWithArray:orgArr];
                [Organization setOrgs:orgs];                
                
                [delegate didGetOrgs:orgs status:kSucceedLogin];
            } else {
                [delegate didGetOrgs:nil status:kFailListOrgs];
            }
        } else {
            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
            [delegate didGetOrgs:nil status:kFailLogin];
        }
    }];
}

@end
