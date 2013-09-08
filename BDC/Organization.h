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

@protocol OrgDelegate <NSObject>

@optional
- (void)didGetOrgs:(NSArray *)orgList status:(LoginStatus)status;

@end


@interface Organization : BDCBusinessObjectWithAttachments

@property (nonatomic, assign) BOOL needApprovalToPayBill;

- (void)retrieveNeedApprovalToPayBill;

+ (void)setDelegate:(id<OrgDelegate>)theDelegate;

+ (Organization *)getSelectedOrg;
+ (void)selectOrg:(Organization *)org;

@end
