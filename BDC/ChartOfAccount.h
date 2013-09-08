//
//  ChartOfAccount.h
//  BDC
//
//  Created by Qinwei Gong on 4/23/13.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import "BDCBusinessObjectWithAttachments.h"
#import "SlidingDetailsTableViewController.h"
#import "SlidingListTableViewController.h"

#define ACCOUNT_NAME        @"name"
#define ACCOUNT_TYPE        @"type"


@class ChartOfAccount;

@protocol AccountListDelegate <ListViewDelegate>
@optional
- (void)didGetAccounts;
- (void)didAddAccount:(ChartOfAccount *)account;
- (void)failedToGetAccounts;
@end


@interface ChartOfAccount : BDCBusinessObjectWithAttachments

@property (nonatomic, assign) int type;

+ (void)setListDelegate:(id<AccountListDelegate>)listDelegate;
+ (ChartOfAccount *)objectForKey:(NSString *)accountId;

@end
