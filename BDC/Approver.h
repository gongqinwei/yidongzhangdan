//
//  Approver.h
//  Mobill
//
//  Created by Qinwei Gong on 10/10/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "BDCBusinessObject.h"
#import "SlidingListTableViewController.h"

#define APPROVERS               @"approvers"
#define APPROVER_USER_ID        @"userId"
#define APPROVER_NAME           @"name"
#define APPROVER_PIC_URL        @"profilePicUrl"
#define APPROVER_SORT_ORDER     @"sortOrder"
#define APPROVER_STATUS         @"status"
#define APPROVER_STATUS_DATE    @"statusDate"

#define APPROVER_STATUSES       [NSArray arrayWithObjects:@"Sent", @"Viewed", @"Skipped", @"Denied", @"Approved", @"New", @"Stale", nil]

typedef enum {
    kApproverSent,
    kApproverViewed,
    kApproverRerouted,
    kApproverDenied,
    kApproverApproved,
    kApproverNew,
    kApproverStale
} ApproverStatusEnum;


@protocol ApproverListDelegate <ListViewDelegate>

@optional
- (void)didGetApprovers;
- (void)failedToGetApprovers;
- (void)didGetApprovers:(NSArray *)approvers;

@end

@interface Approver : BDCBusinessObject

@property (nonatomic, strong) NSString *profilePicUrl;
@property (nonatomic, assign) int sortOrder;
@property (nonatomic, assign) int status;
@property (nonatomic, strong) NSString *statusName;
@property (nonatomic, strong) NSString *statusDate;     //for display purpose only, no need to convert to NSSDate


+ (void)setListDelegate:(id<ApproverListDelegate>)listDelegate;
+ (void)resetList;
+ (Approver *)objectForKey:(NSString *)approverId;
+ (void)retrieveListForObject:(NSString *)objId;
+ (void)setList:(NSArray *)approvers forObject:(NSString *)objId;

@end
