//
//  ApproversTableViewController.h
//  Mobill
//
//  Created by Qinwei Gong on 10/10/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "SlidingListTableViewController.h"
#import "Approver.h"
#import "Vendor.h"

@protocol ApproverSelectDelegate <NSObject>

@required
- (void)didSelectApprovers:(NSArray *)approvers;

@end


@interface ApproversTableViewController : SlidingListTableViewController

@property (nonatomic, strong) Vendor *vendor;
@property (nonatomic, strong) NSMutableArray *approverLists;
@property (nonatomic, weak) id<ApproverSelectDelegate> selectDelegate;

@end
