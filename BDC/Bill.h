//
//  Bill.h
//  BDC
//
//  Created by Qinwei Gong on 7/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDCBusinessObject.h"

@protocol BillDelegate <NSObject>

@optional
- (void)didCreateBill;

@end

@interface Bill : BDCBusinessObject

@property (nonatomic, weak) id<BillDelegate> delegate;

@property (nonatomic, strong) NSString *billId;
@property (nonatomic, strong) NSString *orgId;
@property (nonatomic, strong) NSString *vendorId;
@property (nonatomic, strong) NSDate *createdDate;
@property (nonatomic, strong) NSDate *updatedDate;
@property (nonatomic, strong) NSString *invNum;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, assign) int *status;
@property (nonatomic, assign) int *paymentstatus;
@property (nonatomic, strong) NSDate *dueDate;
@property (nonatomic, strong) NSDate *invDate;
@property (nonatomic, strong) NSDate *paymentScheduledByDate;
@property (nonatomic, strong) NSString *deptId;
@property (nonatomic, strong) NSString *quickbooksId;
@property (nonatomic, strong) NSDate *exportedDate;
@property (nonatomic, strong) NSDate *firstPaymentDate;
@property (nonatomic, strong) NSDate *lastPaymentDate;
@property (nonatomic, strong) NSDate *fullPamentDate;
@property (nonatomic, strong) NSDate *expectedPayDate;
@property (nonatomic, assign) bool allowExport;
@property (nonatomic, assign) NSDecimal amount;
@property (nonatomic, assign) NSDecimal discountAmount;
@property (nonatomic, assign) NSDecimal approvedAmount;
@property (nonatomic, assign) NSDecimal paidAmount;
@property (nonatomic, strong) NSString *paymentTermId;
@property (nonatomic, strong) NSDate *lastSyncTime;
@property (nonatomic, strong) NSDate *sentSyncTime;
@property (nonatomic, strong) NSDate *updateSyncTime;
@property (nonatomic, assign) bool isOneChainMode;
@property (nonatomic, assign) bool isSplit;

@property (nonatomic, strong) NSMutableSet *docs; //set of DocumentPg id

@end
