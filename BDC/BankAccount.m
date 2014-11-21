//
//  BankAccount.m
//  BDC
//
//  Created by Qinwei Gong on 5/11/13.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import "BankAccount.h"
#import "BDCAppDelegate.h"
#import "Constants.h"
#import "APIHandler.h"
#import "UIHelper.h"

#define LIST_BANK_ACCOUNT_FILTER    @"{ \"start\" : 0, \
                                        \"max\" : 999, \
                                        \"filters\" : [{\"field\" : \"isActive\", \"op\" : \"=\", \"value\" : \"1\"}, {\"field\" : \"status\", \"op\" : \"=\", \"value\" : \"1\"}] \
                                      }"

static NSArray *bankAccounts = nil;
static int primaryAP = -1;

@implementation BankAccount

@synthesize accountNumber;
@synthesize bankName;
@synthesize primaryAP;


+ (void)resetList {
    bankAccounts = [NSArray array];
}

+ (id)list {
    return bankAccounts;
}

+ (NSUInteger)count {
    return bankAccounts.count;
}

+ (void)retrieveList {
//    [UIAppDelegate incrNetworkActivities];
    
    NSString *filter = LIST_BANK_ACCOUNT_FILTER;
    NSString *action = [LIST_API stringByAppendingString: BANK_ACCOUNT_API];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA, filter, nil];
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        id json = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
//        [UIAppDelegate decrNetworkActivities];

        if(response_status == RESPONSE_SUCCESS) {
            NSMutableArray *accounts = [NSMutableArray array];
            NSArray *jsonItems = (NSArray *)json;
            int i = 0;
            for (id item in jsonItems) {
                NSDictionary *dict = (NSDictionary*)item;
                BankAccount *account = [[BankAccount alloc] init];
                account.objectId = [dict objectForKey:_ID];
                account.bankName = [dict objectForKey:BANK_ACCOUNT_BANK_NAME];
                account.accountNumber = [dict objectForKey:BANK_ACCOUNT_NUMBER];
                account.name = [account.bankName stringByAppendingFormat:@" %@", account.accountNumber];
                account.primaryAP = [[dict objectForKey:BANK_ACCOUNT_PRIMARY_AP] boolValue];
                account.isActive = [[dict objectForKey:IS_ACTIVE] isEqualToString:@"1"];
                [accounts addObject:account];
                
                if (account.primaryAP) {
                    primaryAP = i;
                }
                i++;
            }
            
            bankAccounts = [NSArray arrayWithArray:accounts];
            
        } else if (response_status == RESPONSE_TIMEOUT) {
            [UIHelper showInfo:SysTimeOut withStatus:kError];
            Debug(@"Time out when retrieving list of bank accounts!");
        } else {
            NSString *errCode = [json objectForKey:RESPONSE_ERROR_CODE];
            if ([INVALID_PERMISSION isEqualToString:errCode]) {
                [UIHelper showInfo:@"You don't have permission to retrieve accounts." withStatus:kWarning];
            } else {
                [UIHelper showInfo:[NSString stringWithFormat:@"Failed to retrieve list of bank accounts! %@", [err localizedDescription]] withStatus:kFailure];
                Error(@"Failed to retrieve list of bank accounts! %@", [err localizedDescription]);
            }
        }
    }];
}

+ (int)primaryAPAccountIndex {
    return primaryAP;
}

@end
