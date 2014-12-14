//
//  CustomersTableViewController.h
//  BDC
//
//  Created by Qinwei Gong on 8/31/12.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlidingListTableViewController.h"
#import "EditCustomerViewController.h"

#define CUSTOMER_VIEW_CUSTOMER_SEGUE        @"ViewCustomer"

@protocol CustomerSelectDelegate <NSObject>

@required
- (void)didSelectCustomer:(NSString *)customerId;

@end

@interface CustomersTableViewController : SlidingListTableViewController

@property (nonatomic, strong) NSMutableArray *customers;

@property (nonatomic, weak) id<CustomerSelectDelegate> selectDelegate;

- (void)navigateToCustomer:(Customer *)customer contact:(CustomerContact *)contact;

@end
