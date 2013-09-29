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
#define ACCOUNT_NUMBER      @"accountNumber"
#define ACCOUNT_TYPE        @"type"
#define ACCOUNT_PARENT      @"parentChartOfAccountId"


@class ChartOfAccount;

@protocol AccountListDelegate <ListViewDelegate>
@optional
- (void)didGetAccounts;
- (void)didAddAccount:(ChartOfAccount *)account;
- (void)failedToGetAccounts;
@end


@interface ChartOfAccount : BDCBusinessObjectWithAttachments

@property (nonatomic, strong) NSString *number;
@property (nonatomic, strong) NSString *fullName;
@property (nonatomic, assign) int type;
@property (nonatomic, strong) NSString *parent;
@property (nonatomic, assign) int indent;
@property (nonatomic, strong) NSString *indentedName;

+ (void)setListDelegate:(id<AccountListDelegate>)listDelegate;
+ (ChartOfAccount *)objectForKey:(NSString *)accountId;

@end
