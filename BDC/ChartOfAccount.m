//
//  ChartOfAccount.m
//  BDC
//
//  Created by Qinwei Gong on 4/23/13.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import "ChartOfAccount.h"
#import "Constants.h"
#import "APIHandler.h"
#import "Util.h"
#import "UIHelper.h"
#import "BDCAppDelegate.h"
#import "RootMenuViewController.h"

@implementation ChartOfAccount

static id <AccountListDelegate> ListDelegate = nil;
static NSMutableDictionary *accounts = nil;
static NSMutableArray *sortedAccounts = nil;
static NSMutableDictionary *inactiveAccounts = nil;

@synthesize number;
@synthesize fullName;
@synthesize type;
@synthesize parent;
@synthesize indent;
@synthesize indentedName;


+ (void)resetList {
    accounts = [NSMutableDictionary dictionary];
    inactiveAccounts = [NSMutableDictionary dictionary];
    sortedAccounts = [NSMutableArray array];
}

+ (id<AccountListDelegate>)getListDelegate {
    return ListDelegate;
}

+ (void)setListDelegate:(id<AccountListDelegate>)theDelegate {
    ListDelegate = theDelegate;
}

- (void)saveFor:(NSString *)action {
    NSString *theAction = [NSString stringWithString:action];
    
    action = [NSString stringWithFormat:@"%@/%@/%@", CRUD, action, ACCOUNT_API];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    NSMutableString *objStr = [NSMutableString string];
    [objStr appendString:@"{"];
    [objStr appendString:OBJ];
    [objStr appendString:@": {"];
    [objStr appendFormat:@"\"%@\" : \"%@\", ", ENTITY, ChartAccount];
    if ([theAction isEqualToString:UPDATE]) {
        [objStr appendFormat:@"\"%@\" : \"%@\", ", _ID, self.objectId];
    }
    [objStr appendFormat:@"\"%@\" : \"%@\", ", ACCOUNT_NAME, self.name];
    if (self.number) {
        [objStr appendFormat:@"\"%@\" : \"%@\", ", ACCOUNT_NUMBER, self.number];
    }
    [objStr appendFormat:@"\"%@\" : \"%@\", ", ACCOUNT_PARENT, self.parent];
    [objStr appendFormat:@"\"%@\" : \"%@\" ", ACCOUNT_TYPE, [NSString stringWithFormat:@"%d", self.type]];
    [objStr appendString:@"}"];
    [objStr appendString:@"}"];
    
    [params setObject:DATA forKey:objStr];
    
    __weak ChartOfAccount *weakSelf = self;
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSDictionary *info = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            NSString *accountId = [info objectForKey:_ID];
            self.objectId = accountId;
            
            if ([theAction isEqualToString:CREATE]) {
                self.isActive = YES;
            }
            
            if (self.isActive) {
                [ChartOfAccount retrieveListForActive:YES];
            } else {
                [ChartOfAccount retrieveListForActive:NO];
            }
            
            if ([theAction isEqualToString:UPDATE]) {
                [weakSelf.editDelegate didUpdateObject];
            } else {
                [weakSelf.editDelegate didCreateObject:accountId];
                [ListDelegate didAddAccount:self];
            }
        } else {
            [weakSelf.editDelegate failedToSaveObject];
            
            if ([theAction isEqualToString:UPDATE]) {
                [UIHelper showInfo:[NSString stringWithFormat:@"Failed to update account %@: %@", self.objectId, [err localizedDescription]] withStatus:kFailure];
                Error(@"Failed to update account %@: %@", self.objectId, [err localizedDescription]);
            } else {
                [UIHelper showInfo:[NSString stringWithFormat:@"Failed to create account: %@", [err localizedDescription]] withStatus:kFailure];
                Error(@"Failed to create account: %@", [err localizedDescription]);
            }
        }
    }];
}

+ (int)indentNameForAccount:(ChartOfAccount *)account {
    if (!account.parent || [account.parent isEqualToString:EMPTY_ID]) {
        return 0;
    }
    
    if (account.indent > 0) {
        return account.indent;
    }
    
    ChartOfAccount *parent = [ChartOfAccount objectForKey:account.parent];
    account.indent = [ChartOfAccount indentNameForAccount:parent] + 1;      // recursive
    
    NSMutableString *prefix = [NSMutableString string];
    for (int i = 0; i < account.indent; i++) {
        [prefix appendString:@"-"];
    }
    account.indentedName = [NSString stringWithFormat:@" %@ %@", prefix, account.fullName];
    
    return account.indent;
}

+ (id)listOrderBy:(NSString *)attribue ascending:(Boolean)isAscending active:(Boolean)isActive {
    NSDictionary *accountList = isActive ? accounts : inactiveAccounts;
    NSArray *accountArr = [accountList allValues];
    
    NSSortDescriptor *firstOrder = [[NSSortDescriptor alloc] initWithKey:@"number" ascending:YES];
    NSSortDescriptor *secondOrder = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    accountArr = [accountArr sortedArrayUsingDescriptors:[NSArray arrayWithObjects:firstOrder, secondOrder, nil]];
    
    NSMutableArray *sortedArray = [NSMutableArray arrayWithArray:accountArr];
    
    for (ChartOfAccount *account in accountArr) {
        if (account.parent && ![account.parent isEqualToString:EMPTY_ID]) {
            [sortedArray removeObject:account];
            ChartOfAccount *parent = [ChartOfAccount objectForKey:account.parent];
            if ([sortedArray containsObject:parent]) {
                NSUInteger parentIndex = [sortedArray indexOfObject:parent];
                [sortedArray insertObject:account atIndex:parentIndex + 1];
                
                [ChartOfAccount indentNameForAccount:account];
            }
        }
    }
    
    return sortedArray;
}

+ (id)list {
    return sortedAccounts; //[NSMutableArray arrayWithArray:[accounts allValues]];
}

+ (id)listInactive {
    return [NSMutableArray arrayWithArray:[inactiveAccounts allValues]];
}

+ (ChartOfAccount *)objectForKey:(NSString *)accountId {
    ChartOfAccount *account = [accounts objectForKey:accountId];
    if (account == nil) {
        account = [inactiveAccounts objectForKey:accountId];
    }
    return account;
}

+ (void)retrieveListForActive:(BOOL)isActive {
//    [UIAppDelegate incrNetworkActivities];
    
    NSString *filter = isActive ? LIST_ACTIVE_FILTER : LIST_INACTIVE_FILTER;
    NSString *action = [LIST_API stringByAppendingString: ACCOUNT_API];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA, filter, nil];
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        id json = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
//        [UIAppDelegate decrNetworkActivities];
        
        if(response_status == RESPONSE_SUCCESS) {
            NSMutableDictionary *accountDict;
            if (isActive) {
                if (accounts) {
                    [accounts removeAllObjects];
                } else {
                    accounts = [NSMutableDictionary dictionary];
                }

                accountDict = accounts;
            } else {
                if (inactiveAccounts) {
                    [inactiveAccounts removeAllObjects];
                } else {
                    inactiveAccounts = [NSMutableDictionary dictionary];
                }

                accountDict = inactiveAccounts;
            }
            
            NSArray *jsonAccounts = (NSArray *)json;
            
            for (id account in jsonAccounts) {
                NSDictionary *dict = (NSDictionary*)account;
                ChartOfAccount *account = [[ChartOfAccount alloc] init];
                account.objectId = [dict objectForKey:_ID];
                account.name = [dict objectForKey:ACCOUNT_NAME];
                NSString *number = [dict objectForKey:ACCOUNT_NUMBER];
                if (number == (id)[NSNull null]) {
                    account.number = nil;
                    account.fullName = account.name;
                } else {
                    account.number = number;
                    account.fullName = [NSString stringWithFormat:@"%@ %@", number, account.name];
                }
                account.type = [[dict objectForKey:ACCOUNT_TYPE] intValue];
                account.parent = [dict objectForKey:ACCOUNT_PARENT];
                account.indent = 0;
                account.indentedName = account.fullName;
                account.isActive = [[dict objectForKey:IS_ACTIVE] isEqualToString:@"1"];
                
                [accountDict setObject:account forKey:account.objectId];
            }
            
            if (isActive) {
                sortedAccounts = [ChartOfAccount listOrderBy:ACCOUNT_NUMBER ascending:YES active:YES];
            }
            
            [ListDelegate didGetAccounts];
        } else if (response_status == RESPONSE_TIMEOUT) {
            [ListDelegate failedToGetAccounts];
            [UIHelper showInfo:SysTimeOut withStatus:kError];
            Error(@"Time out when retrieving list of accounts!");
        } else {
            [ListDelegate failedToGetAccounts];
            
            NSString *errCode = [json objectForKey:RESPONSE_ERROR_CODE];
            if ([INVALID_PERMISSION isEqualToString:errCode]) {
                if (ListDelegate != [RootMenuViewController sharedInstance]) {
                    [UIHelper showInfo:@"You don't have permission to retrieve accounts." withStatus:kWarning];
                }
            } else {
                [UIHelper showInfo:[NSString stringWithFormat:@"Failed to retrieve list of accounts for %@! %@", isActive ? @"active" : @"inactive", [err localizedDescription]] withStatus:kFailure];
                Error(@"Failed to retrieve list of accounts for %@! %@", isActive ? @"active" : @"inactive", [err localizedDescription]);
            }
        }
    }];
}

+ (void)clone:(ChartOfAccount *)source to:(ChartOfAccount *)target {
    [super clone:source to:target];
    
    target.name = source.name;
    target.number = source.number;
    target.fullName = source.fullName;
    target.type = source.type;
    target.parent = source.parent;
    target.indent = source.indent;
    target.indentedName = source.indentedName;
    target.editDelegate = source.editDelegate;
}

@end

