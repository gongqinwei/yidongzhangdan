//
//  ChartOfAccount.m
//  BDC
//
//  Created by Qinwei Gong on 4/23/13.
//
//

#import "ChartOfAccount.h"
#import "Constants.h"
#import "APIHandler.h"
#import "Util.h"
#import "UIHelper.h"
#import "BDCAppDelegate.h"

@implementation ChartOfAccount

static id <AccountListDelegate> ListDelegate = nil;
static NSMutableDictionary *accounts = nil;
static NSMutableDictionary *inactiveAccounts = nil;

@synthesize type;
@synthesize editDelegate;

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
        [objStr appendFormat:@"\"%@\" : \"%@\", ", ID, self.objectId];
    }
    [objStr appendFormat:@"\"%@\" : \"%@\", ", ACCOUNT_NAME, self.name];
    [objStr appendFormat:@"\"%@\" : \"%@\" ", ACCOUNT_TYPE, [NSString stringWithFormat:@"%d", self.type]];
    [objStr appendString:@"}"];
    [objStr appendString:@"}"];
    
    [params setObject:DATA forKey:objStr];
    
    __weak ChartOfAccount *weakSelf = self;
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSDictionary *info = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            NSString *accountId = [info objectForKey:ID];
            self.objectId = accountId;
            
            if ([theAction isEqual:CREATE] || self.isActive) {
                [ChartOfAccount retrieveListForActive:YES];
            } else {
                [ChartOfAccount retrieveListForActive:NO];
            }
            
            if ([theAction isEqualToString:UPDATE]) {
                [weakSelf.editDelegate didUpdateObject];
            } else {
                [weakSelf.editDelegate didCreateAccount:accountId];
                [ListDelegate didAddAccount:self];
            }
        } else {
            [weakSelf.editDelegate failedToSaveObject];
            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
            
            if ([theAction isEqualToString:UPDATE]) {
                NSLog(@"Failed to update account %@: %@", self.objectId, [err localizedDescription]);
            } else {
                NSLog(@"Failed to create account: %@", [err localizedDescription]);
            }
        }
    }];
}

+ (id)listOrderBy:(NSString *)attribue ascending:(Boolean)isAscending active:(Boolean)isActive {
    NSDictionary *accountList = isActive ? accounts : inactiveAccounts;
    NSArray *accountArr = [accountList allValues];
    
    NSSortDescriptor *firstOrder = [[NSSortDescriptor alloc] initWithKey:ACCOUNT_NAME ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
//    NSSortDescriptor *secondOrder = [[NSSortDescriptor alloc] initWithKey:ID ascending:NO];
    accountArr = [accountArr sortedArrayUsingDescriptors:[NSArray arrayWithObjects:firstOrder, nil]];
    
    return [NSMutableArray arrayWithArray:accountArr];
}

+ (id)list {
    return [NSMutableArray arrayWithArray:[accounts allValues]];
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
    [UIAppDelegate incrNetworkActivities];
    
    NSString *filter = isActive ? LIST_ACTIVE_FILTER : LIST_INACTIVE_FILTER;
    NSString *action = [LIST_API stringByAppendingString: ACCOUNT_API];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA, filter, nil];
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSArray *jsonAccounts = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        [UIAppDelegate decrNetworkActivities];
        
        if(response_status == RESPONSE_SUCCESS) {
            NSMutableDictionary *accountDict;
            if (isActive) {
                accounts = [NSMutableDictionary dictionary];
                accountDict = accounts;
            } else {
                inactiveAccounts = [NSMutableDictionary dictionary];
                accountDict = inactiveAccounts;
            }
            
            for (id account in jsonAccounts) {
                NSDictionary *dict = (NSDictionary*)account;
                ChartOfAccount *account = [[ChartOfAccount alloc] init];
                account.objectId = [dict objectForKey:ID];
                account.name = [dict objectForKey:ACCOUNT_NAME];
                account.type = [[dict objectForKey:ACCOUNT_TYPE] intValue];
                account.isActive = [[dict objectForKey:IS_ACTIVE] isEqualToString:@"1"];
                
                [accountDict setObject:account forKey:account.objectId];
            }
            
            [ListDelegate didGetAccounts];
        } else if (response_status == RESPONSE_TIMEOUT) {
            [ListDelegate failedToGetAccounts];
            [UIHelper showInfo:SysTimeOut withStatus:kError];
            NSLog(@"Time out when retrieving list of accounts!");
        } else {
            [ListDelegate failedToGetAccounts];
            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
            NSLog(@"Failed to retrieve list of accounts for %@! %@", isActive ? @"active" : @"inactive", [err localizedDescription]);
        }
    }];
}

+ (void)clone:(ChartOfAccount *)source to:(ChartOfAccount *)target {
    [super clone:source to:target];
    
    target.type = source.type;
    target.name = source.name;
    target.editDelegate = source.editDelegate;
}

@end

