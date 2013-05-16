//
//  BankAccount.h
//  BDC
//
//  Created by Qinwei Gong on 5/11/13.
//
//

#import "BDCBusinessObject.h"

#define BANK_ACCOUNT_BANK_NAME      @"bankName"
#define BANK_ACCOUNT_NUMBER         @"accountNumber"
#define BANK_ACCOUNT_PRIMARY_AP     @"primaryAP"


@interface BankAccount : BDCBusinessObject

@property (nonatomic, strong) NSString *bankName;
@property (nonatomic, strong) NSString *accountNumber;
@property (nonatomic, assign) BOOL primaryAP;

@end
