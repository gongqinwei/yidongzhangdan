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


#define BILL_TABLE_SECTION_HEADER_HEIGHT    28
#define BILL_TABLE_CELL_HEIGHT              90
#define BILL_TABLE_LABEL_HEIGHT             15
#define BILL_TABLE_LABEL_WIDTH              130
#define BILL_NUM_RECT                       CGRectMake(10, 5, BILL_TABLE_LABEL_WIDTH, BILL_TABLE_LABEL_HEIGHT)
#define VENDOR_RECT                         CGRectMake(10, 25, BILL_TABLE_LABEL_WIDTH, BILL_TABLE_LABEL_HEIGHT)
#define BILL_DATE_RECT                      CGRectMake(160, 25, BILL_TABLE_LABEL_WIDTH, BILL_TABLE_LABEL_HEIGHT)
#define APPROVAL_STATUS_RECT                CGRectMake(10, 45, BILL_TABLE_LABEL_WIDTH, BILL_TABLE_LABEL_HEIGHT)
#define DUE_DATE_RECT                       CGRectMake(160, 45, BILL_TABLE_LABEL_WIDTH, BILL_TABLE_LABEL_HEIGHT)
#define PAYMENT_STATUS_RECT                 CGRectMake(10, 65, BILL_TABLE_LABEL_WIDTH, BILL_TABLE_LABEL_HEIGHT)
#define AMOUNT_RECT                         CGRectMake(160, 65, BILL_TABLE_LABEL_WIDTH, BILL_TABLE_LABEL_HEIGHT)
#define SECTION_HEADER_RECT                 CGRectMake(0, 0, SCREEN_WIDTH, BILL_TABLE_SECTION_HEADER_HEIGHT)
#define SECTION_HEADER_LABEL_RECT           CGRectMake(10, 7, 150, 15)
#define SECTION_HEADER_LABEL_RECT2          CGRectMake(20, 7, 150, 15)
#define SECTION_HEADER_QTY_AMT_RECT         CGRectMake(SCREEN_WIDTH - 170, 7, 170, 15)
#define SECTION_ACCESSORY_RECT              CGRectMake(SCREEN_WIDTH - 30, 7, 30, 15)
#define TOGGLE_ARROW_RECT                   CGRectMake(5, 10, 10, 10)
#define TOGGLE_ARROW_CENTER                 CGPointMake(10, 15)
#define BILL_NUM_FONT_SIZE                  16
#define BILL_FONT_SIZE                      13


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
- (void)didGetBillsToApprove:(NSMutableArray *)bills;
- (void)failedToGetBillsToApprove;
- (void)failedToProcessApproval;

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
@property (nonatomic, weak) id<BusObjectDelegate> detailsDelegate;

// approval methods
- (void)approve;
- (void)approveWithComment:(NSString *)comment;
- (void)denyWithComment:(NSString *)comment;
- (void)skipWithComment:(NSString *)comment;

// delegates
+ (void)setAPDelegate:(id<BillListDelegate>)delegate;
+ (void)setListDelegate:(id<BillListDelegate>)delegate;
+ (void)setListForApprovalDelegate:(id<BillListDelegate>)delegate;

+ (id)list:(NSArray *)invArr orderBy:(NSString *)attribue ascending:(Boolean)isAscending;
+ (void)resetList;

+ (id)listBillsToApprove;
+ (BOOL)isBillToApprove:(Bill *)bill;
+ (void)retrieveListForApproval;

@end
