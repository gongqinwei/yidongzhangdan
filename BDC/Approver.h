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
#define APPROVER_USER_ID        @"usersId"
#define APPROVER_NAME           @"name"
#define APPROVER_PIC_URL        @"profilePicUrl"
#define APPROVER_SMART_DATA     @"smartDataEntry"
#define APPROVER_SORT_ORDER     @"sortOrder"
#define APPROVER_STATUS         @"status"
#define APPROVER_STATUS_DATE    @"statusDate"
#define STATUS_CHANGED_DATE     @"statusChangedDate"

#define APPROVER_STATUSES       [NSArray arrayWithObjects:@"Waiting", @"Viewed", @"Skipped", @"Denied", @"Approved", @"Upcoming", @"Stale", nil]

typedef enum {
    kApproverSent,
    kApproverViewed,
    kApproverRerouted,
    kApproverDenied,
    kApproverApproved,
    kApproverNew,
    kApproverStale
} ApproverStatusEnum;

@class Approver;

@protocol ApproverDelegate <NSObject>

- (void)didAddApprover:(Approver *)approver;
- (void)failedToAddApprover;

@end

@protocol ApproverListDelegate <ListViewDelegate>

@optional
- (void)didGetApprovers;
- (void)failedToGetApprovers;
- (void)didGetApprovers:(NSArray *)approvers;
- (void)didAddApprover:(Approver *)approver;

@end

@interface Approver : BDCBusinessObject

@property (nonatomic, strong) NSString *profilePicUrl;
@property (nonatomic, strong) NSData *profilePicData;
@property (nonatomic, assign) int sortOrder;
@property (nonatomic, assign) int status;
@property (nonatomic, strong) NSString *statusName;
@property (nonatomic, strong) NSString *statusDate;     //for display purpose only, no need to convert to NSSDate
@property (nonatomic, assign) int smartDataEntry;
@property (nonatomic, strong) id<ApproverDelegate> createDelegate;


+ (void)setListDelegate:(id<ApproverListDelegate>)listDelegate;
+ (void)resetList;
+ (Approver *)objectForKey:(NSString *)approverId;
+ (void)retrieveListForObject:(NSString *)objId;
+ (void)retrieveListForVendor:(NSString *)vendorId andSmartData:(BOOL)smartData;
+ (void)setList:(NSArray *)approvers forObject:(NSString *)objId andVendor:(NSString *)vendorId ;
- (void)createWithFirstName:(NSString *)fname lastName:(NSString *)lname andEmail:(NSString *)email;

@end
