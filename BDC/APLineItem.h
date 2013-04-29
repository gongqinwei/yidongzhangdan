//
//  APLineItem.h
//  BDC
//
//  Created by Qinwei Gong on 4/23/13.
//
//

#import "BDCBusinessObject.h"
#import "ChartOfAccount.h"

#define LINE_ITEM               @"LineItem"
#define LINE_ITEM_AMOUNT        @"amount"
#define LINE_ITEM_ACCOUNT       @"chartOfAccountId"

@interface APLineItem : BDCBusinessObject

@property (nonatomic, strong) NSDecimalNumber *amount;
@property (nonatomic, strong) ChartOfAccount *account;


@end
