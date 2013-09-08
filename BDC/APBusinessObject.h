//
//  APBusinessObject.h
//  BDC
//
//  Created by Qinwei Gong on 4/23/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDCBusinessObject.h"
#import "SlidingDetailsTableViewController.h"
#import "SlidingListTableViewController.h"

#define VENDOR_ID                   @"vendorId"
#define VENDOR_NAME                 @"vendorName"
#define INV_NUMBER                  @"invoiceNumber"
#define REF_NUMBER                  @"refNumber"
#define INV_DATE                    @"invoiceDate"
#define DUE_DATE                    @"dueDate"
#define CREDIT_DATE                 @"creditDate"
#define AMOUNT                      @"amount"
#define AMOUNT_PAID                 @"paidAmount"
#define BILL_LINE_ITEMS             @"billLineItems"
#define VENDCREDIT_LINE_ITEMS       @"vendorCreditLineItems"
#define LINE_ITEM_ID                @"id"
#define BILL_LINE_ITEM              @"BillLineItem"
#define VENDCREDIT_LINE_ITEM        @"VendorCreditLineItem"
#define BILL_APPROVAL_STATUS             @"approvalStatus"

#define BILL_LABELS     [NSDictionary dictionaryWithObjectsAndKeys: \
@"Vendor", VENDOR_NAME, \
@"Invoice Number", INV_NUMBER, \
@"Invoice Date", INV_DATE, \
@"Due Date", DUE_DATE, \
@"Amount", AMOUNT, \
@"Amount Paid", AMOUNT_PAID, \
@"Approval Status", BILL_APPROVAL_STATUS, \
nil]

#define VENDCREDIT_LABELS     [NSDictionary dictionaryWithObjectsAndKeys: \
@"Vendor", BILL_VENDOR_NAME, \
@"Reference Number", REF_NUMBER, \
@"Credit Date", CREDIT_DATE, \
@"Amount", AMOUNT, \
@"Approval Status", BILL_APPROVAL_STATUS, \
nil]


@interface APBusinessObject : BDCBusinessObject

@property (nonatomic, strong) NSString *vendorId;
@property (nonatomic, strong) NSString *vendorName;
@property (nonatomic, assign) NSDecimal amount;
@property (nonatomic, assign) int *approvalStatus;

//@property (nonatomic, strong) NSMutableSet *docs; //set of DocumentPg id

@end

