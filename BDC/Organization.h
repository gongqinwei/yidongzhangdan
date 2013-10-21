//
//  Organization.h
//  BDC
//
//  Created by Qinwei Gong on 7/9/12.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Constants.h"
#import "BDCBusinessObjectWithAttachments.h"


#define ORG_PREF_APPROVALS                      @"approvals"
#define BILLS_NEED_APPROVALS                    @"billsNeedApprovals"
#define DEFAULT_APPROVER                        @"defaultApprover"
#define DEFAULT_APPROVER_FOR_ALL_FUTURE_BILLS   @"defaultApproverForAllFutureBills"
#define CHANGES_TO_APPROVED_BILLS               @"changesToApprovedBills"
#define SHOW_AR                                 @"showAR"
#define SHOW_AP                                 @"showAP"
#define ENABLE_AR                               @"enableAR"
#define ENABLE_AP                               @"enableAP"


@protocol OrgDelegate <NSObject>

@optional
- (void)didGetOrgs:(NSArray *)orgList status:(LoginStatus)status;
- (void)didGetOrgFeatures;
- (void)failedToGetOrgFeatures;

@end


@interface Organization : BDCBusinessObjectWithAttachments

@property (nonatomic, assign) BOOL needApprovalToPayBill;
@property (nonatomic, strong) NSString *defaultApproverId;
@property (nonatomic, assign) BOOL defaultApproverForAllFutureBills;
@property (nonatomic, assign) int changesToApprovedBills;

@property (nonatomic, assign) BOOL showAR;
@property (nonatomic, assign) BOOL showAP;
@property (nonatomic, assign) BOOL enableAR;
@property (nonatomic, assign) BOOL enableAP;


- (void)retrieveNeedApprovalToPayBill;      //depricated: use getOrgPrefs instead
- (void)getOrgFeatures;
- (void)getOrgPrefs;

+ (void)setDelegate:(id<OrgDelegate>)theDelegate;

+ (Organization *)getSelectedOrg;
+ (void)selectOrg:(Organization *)org;

@end
