//
//  Invoice.h
//  BDC
//
//  Created by Qinwei Gong on 8/27/12.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDCBusinessObjectWithAttachments.h"
#import "SlidingDetailsTableViewController.h"
#import "SlidingListTableViewController.h"

#define INV_CUSTOMER_ID             @"customerId"
#define INV_CUSTOMER_NAME           @"customerName"
#define INV_NUMBER                  @"invoiceNumber"
#define INV_DATE                    @"invoiceDate"
#define INV_DUE_DATE                @"dueDate"
#define INV_AMOUNT                  @"amount"
#define INV_AMOUNT_DUE              @"amountDue"
#define INV_PAYMENT_STATUS          @"paymentStatus"
#define INV_LINE_ITEMS              @"invoiceLineItems"
#define INV_ITEM_ID                 @"itemId"
#define INV_ITEM_PRICE              @"price"
#define INV_ITEM_QUANTITY           @"quantity"
#define INV_LINE_ITEM               @"InvoiceLineItem"

#define INV_LABELS      [NSDictionary dictionaryWithObjectsAndKeys: \
                                    @"Customer", INV_CUSTOMER_NAME, \
                                    @"Invoice Number", INV_NUMBER, \
                                    @"Invoice Date", INV_DATE, \
                                    @"Due Date", INV_DUE_DATE, \
                                    @"Amount", INV_AMOUNT, \
                                    @"Amount Due", INV_AMOUNT_DUE, \
                        nil]


@protocol InvoiceListDelegate <ListViewDelegate>

@optional
- (void)didGetInvoices:(NSArray *)invoiceList;
- (void)didReadAnInvoice;
- (void)failedToGetInvoices;

@end


@interface Invoice : BDCBusinessObjectWithAttachments

@property (nonatomic, strong) NSString *invoiceNumber;
@property (nonatomic, strong) NSString *customerId;
@property (nonatomic, strong) NSString *customerName;
@property (nonatomic, strong) NSDate *invoiceDate;
@property (nonatomic, strong) NSDate *dueDate;
@property (nonatomic, strong) NSDecimalNumber *amount;
@property (nonatomic, strong) NSDecimalNumber *amountDue;
@property (nonatomic, strong) NSString *paymentStatus;
//@property (nonatomic, strong) NSDate *createdDate;
//@property (nonatomic, strong) NSDate *updatedDate;
//@property (nonatomic, strong) NSString *desc;
//@property (nonatomic, strong) NSString *discountInfo;
//@property (nonatomic, strong) NSDecimalNumber *tax;
//@property (nonatomic, strong) NSString *netBillId;
//@property (nonatomic, strong) NSString *netOrgId;
//@property (nonatomic, strong) NSDecimalNumber *creditAmount;
//@property (nonatomic, strong) NSString *jobId;
//@property (nonatomic, strong) NSString *poNumber;
//@property (nonatomic, assign) bool isToBePrinted;
//@property (nonatomic, assign) bool isToBeMailed;
//@property (nonatomic, strong) NSString *itemSalesTax;
//@property (nonatomic, assign) double salesTaxPercentage;
//@property (nonatomic, strong) NSDecimalNumber *salesTaxTotal;
//@property (nonatomic, strong) NSString *customerMsg;
//@property (nonatomic, strong) NSString *terms;
////@property (nonatomic, strong) NSString *emailTemplate; //?
//@property (nonatomic, strong) NSString *salesRep;
//@property (nonatomic, strong) NSString *fob;
//@property (nonatomic, strong) NSDate *shipDate;
//@property (nonatomic, strong) NSString *shipMethod;
//@property (nonatomic, strong) NSString *deptId;
//@property (nonatomic, strong) NSString *invoiceTemplateId;
//@property (nonatomic, assign) int nextReminder;
//@property (nonatomic, strong) NSString *paymentTermId;
//@property (nonatomic, strong) NSString *externalId;
//@property (nonatomic, strong) NSDate *estPaymentDate;
//@property (nonatomic, strong) NSDate *cashflowDate;
//@property (nonatomic, strong) NSDate *firstPaymentDate;
//@property (nonatomic, strong) NSDate *fullPaymentDate;
//@property (nonatomic, strong) NSDate *lastSentDate;
//@property (nonatomic, strong) NSDate *expectedPayDate;
@property (nonatomic, strong) NSMutableArray *lineItems;
//@property (nonatomic, strong) NSMutableDictionary *attachments;     // map filename => data

//@property (nonatomic, strong) NSMutableArray *attachments;            // array of Documents
//@property (nonatomic, strong) NSMutableSet *attachmentSet;            // set of doc id's

//+ (void)clone:(Invoice *)source to:(Invoice *)target;

// delegates
+ (void)setARDelegate:(id<InvoiceListDelegate>)delegate;
+ (void)setListDelegate:(id<InvoiceListDelegate>)delegate;

+ (id)list:(NSArray *)invArr orderBy:(NSString *)attribue ascending:(Boolean)isAscending;

@property (nonatomic, weak) id<BusObjectDelegate> detailsDelegate;

@end
