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
@synthesize canPay;
@synthesize canApprove;
@synthesize hasInbox;


- (void)getOrgFeatures {
    [APIHandler asyncCallWithAction:ORG_FEATURE_API Info:nil AndHandler:^(NSURLResponse *response, NSData *data, NSError *err) {
        NSInteger response_status;
        id json = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            NSDictionary *orgFeatures = (NSDictionary *)json;
            self.showAR = [[orgFeatures objectForKey:SHOW_AR] boolValue];
            self.showAP = [[orgFeatures objectForKey:SHOW_AP] boolValue];
            
            self.enableAR = [[orgFeatures objectForKey:ENABLE_AR] boolValue];
            self.enableAP = [[orgFeatures objectForKey:ENABLE_AP] boolValue];
            
            // need to check based on either retrieval api's or role in future
            self.canApprove = YES;
            self.canPay = YES;
            self.hasInbox = YES;
            
            [delegate didGetOrgFeatures];
        } else {
            NSString *errCode = [json objectForKey:RESPONSE_ERROR_CODE];
            if ([errCode isEqualToString:ORG_LOCKED_OUT]) {
                [UIHelper showInfo:@"This account is past due and is locked out by Bill.com!" withStatus:kWarning];
                [delegate failedToGetOrgFeatures];  //temp
            } else if ([errCode isEqualToString:INVALID_PERMISSION]) {  // right now only approvers don't have this permission
                self.showAR = NO;
                self.showAP = YES;
                self.enableAR = NO;
                self.enableAP = NO;
                self.canApprove = YES;
                self.canPay = NO;
                self.hasInbox = NO;
                [delegate didGetOrgFeatures];
            } else {
                Error(@"Failed to get org features for %@!", self.objectId);
                
                // temp solution: if can't get org features, display everything regardless
                // let subsequent api calls fail
                self.showAR = YES;
                self.showAP = YES;
                self.enableAR = YES;
                self.enableAP = YES;
                self.canApprove = YES;
                self.canPay = YES;
                self.hasInbox = YES;
                [delegate didGetOrgFeatures];
            }
        }
    }];
}

- (void)getOrgPrefs {
    [APIHandler asyncCallWithAction:ORG_PREF_API Info:nil AndHandler:^(NSURLResponse *response, NSData *data, NSError *err) {
        NSInteger response_status;
        NSDictionary *approvals = [APIHandler getResponse:response data:data error:&err status:&response_status];
        NSDictionary *orgPrefs = [approvals objectForKey:ORG_PREF_APPROVALS];
        
        if(response_status == RESPONSE_SUCCESS) {
            self.needApprovalToPayBill = [[orgPrefs objectForKey:BILLS_NEED_APPROVALS] boolValue];
            self.defaultApproverId = [orgPrefs objectForKey:DEFAULT_APPROVER];
            self.defaultApproverForAllFutureBills = [[orgPrefs objectForKey:DEFAULT_APPROVER_FOR_ALL_FUTURE_BILLS] boolValue];
            self.changesToApprovedBills = [[orgPrefs objectForKey:CHANGES_TO_APPROVED_BILLS] intValue];
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
//    NSSortDescriptor *secondOrder = [[NSSortDescriptor alloc] initWithKey:_ID ascending:NO selector:@selector(localizedCaseInsensitiveCompare:)];
    orgs = [orgs sortedArrayUsingDescriptors:[NSArray arrayWithObjects:firstOrder, nil]];
    
    return orgs;
}

+ (NSUInteger)count {
    return (int)orgs.count;
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
            [UIHelper showInfo:[NSString stringWithFormat:@"Failed to retrieve org list! %@", [err localizedDescription]] withStatus:kFailure];
            [delegate didGetOrgs:nil status:kFailLogin];
        }
    }];
}


@end
