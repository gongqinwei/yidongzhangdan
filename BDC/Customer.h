//
//  Customer.h
//  BDC
//
//  Created by Qinwei Gong on 9/7/12.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDCBusinessObjectWithAttachmentsAndAddress.h"
#import "SlidingDetailsTableViewController.h"
#import "SlidingListTableViewController.h"

#define CUSTOMER            @"Customer"
#define CUSTOMER_NAME       @"name"
#define CUSTOMER_ADDR1      @"billAddress1"
#define CUSTOMER_ADDR2      @"billAddress2"
#define CUSTOMER_ADDR3      @"billAddress3"
#define CUSTOMER_ADDR4      @"billAddress4"
#define CUSTOMER_CITY       @"billAddressCity"
#define CUSTOMER_STATE      @"billAddressState"
#define CUSTOMER_COUNTRY    @"billAddressCountry"
#define CUSTOMER_ZIP        @"billAddressZip"
#define CUSTOMER_EMAIL      @"email"
#define CUSTOMER_PHONE      @"phone"


@protocol CustomerListDelegate <ListViewDelegate>

@optional
- (void)didGetCustomers;
- (void)failedToGetCustomers;

@end


@interface Customer : BDCBusinessObjectWithAttachmentsAndAddress

@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *phone;
//@property (nonatomic, strong) NSString *altPhone;
//@property (nonatomic, strong) NSString *fax;

@property (nonatomic, weak) id<BusObjectDelegate> editInvoiceDelegate;

+ (void)setListDelegate:(id<CustomerListDelegate>)listDelegate;
+ (void)resetList;
+ (Customer *)objectForKey:(NSString *)customerId;

@end
