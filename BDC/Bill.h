//
//  Bill.h
//  BDC
//
//  Created by Qinwei Gong on 7/2/12.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDCBusinessObjectWithAttachments.h"
#import "SlidingDetailsTableViewController.h"
#import "SlidingListTableViewController.h"

#define BILL_VENDOR_ID              @"vendorId"
#define BILL_VENDOR_NAME            @"vendorName"
#define BILL_NUMBER                 @"invoiceNumber"
#define BILL_DATE                   @"invoiceDate"
#define BILL_DUE_DATE               @"dueDate"
#define BILL_AMOUNT                 @"amount"
#define BILL_AMOUNT_PAID            @"paidAmount"
#define BILL_APPROVAL_STATUS        @"approvalStatus"
#define BILL_PAYMENT_STATUS         @"paymentStatus"
#define BILL_LINE_ITEMS             @"billLineItems"
#define BILL_LINE_ITEM              @"BillLineItem"
#define BILL_LINE_ITEM_AMOUNT       @"amount"
#define BILL_LINE_ITEM_ACCOUNT      @"chartOfAccountId"

#define BILL_LABELS     [NSDictionary dictionaryWithObjectsAndKeys: \
                            @"Vendor", BILL_VENDOR_NAME, \
                            @"Invoice Number", BILL_NUMBER, \
                            @"Invoice Date", BILL_DATE, \
                            @"Due Date", BILL_DUE_DATE, \
                            @"Amount", BILL_AMOUNT, \
                            @"Amount Paid", BILL_AMOUNT_PAID, \
                            @"Approval Status", BILL_APPROVAL_STATUS, \
                            @"Payment Status", BILL_PAYMENT_STATUS, \
                        nil]


@protocol BillListDelegate <ListViewDelegate>

@optional
- (void)didGetBills:(NSArray *)billList;
- (void)failedToGetBills;

@end


@interface Bill : BDCBusinessObjectWithAttachments

@property (nonatomic, strong) NSString *vendorId;
@property (nonatomic, strong) NSString *vendorName;
@property (nonatomic, strong) NSString *invoiceNumber;
@property (nonatomic, strong) NSDate *dueDate;
@property (nonatomic, strong) NSDate *invoiceDate;
@property (nonatomic, strong) NSDecimalNumber *amount;
@property (nonatomic, strong) NSDecimalNumber *paidAmount;
@property (nonatomic, strong) NSString *approvalStatus;
@property (nonatomic, strong) NSString *paymentStatus;

@property (nonatomic, strong) NSMutableArray *lineItems;

// delegates
+ (void)setAPDelegate:(id<BillListDelegate>)delegate;
+ (void)setListDelegate:(id<BillListDelegate>)delegate;

+ (id)list:(NSArray *)invArr orderBy:(NSString *)attribue ascending:(Boolean)isAscending;

@property (nonatomic, weak) id<BusObjectDelegate> detailsDelegate;

@end
