//
//  Approver.m
//  Mobill
//
//  Created by Qinwei Gong on 10/10/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "Approver.h"
#import "APIHandler.h"
#import "UIHelper.h"
#import "BDCAppDelegate.h"


static NSMutableDictionary * approvers = nil;
static id <ApproverListDelegate> ListDelegate = nil;

@implementation Approver

@synthesize profilePicUrl;
@synthesize profilePicData;
@synthesize sortOrder;
@synthesize status;
@synthesize statusDate;
@synthesize statusName;


+ (void)setListDelegate:(id<ApproverListDelegate>)theDelegate {
    ListDelegate = theDelegate;
}

+ (void)resetList {
    approvers = [NSMutableDictionary dictionary];
}

+ (int)count {
    return approvers.count;
}

+ (id)list {
    NSSortDescriptor *order = [[NSSortDescriptor alloc] initWithKey:APPROVER_NAME ascending:YES selector:nil];
    NSArray *sortedApprovers = [[approvers allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObjects:order, nil]];
    return [NSMutableArray arrayWithArray:sortedApprovers];
}

+ (Approver *)objectForKey:(NSString *)approverId {
    return [approvers objectForKey:approverId];
}

- (void)populateObjectWithInfo:(NSDictionary *)dict {
    self.objectId = [dict objectForKey:ID];
    self.name = [dict objectForKey:APPROVER_NAME];
    self.profilePicUrl = [dict objectForKey:APPROVER_PIC_URL];
    self.isActive = YES;
    
    [super populateObjectWithInfo:dict];
}

+ (void)retrieveListForActive:(BOOL)isActive {
    [Approver retrieveList];
}

+ (void)retrieveList {
    [UIAppDelegate incrNetworkActivities];
    
    [APIHandler asyncCallWithAction:APPROVER_LIST_API Info:nil AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSArray *jsonApprovers = [APIHandler getResponse:response data:data error:&err status:&response_status];

        [UIAppDelegate decrNetworkActivities];
        
        if(response_status == RESPONSE_SUCCESS) {
            if (approvers) {
                [approvers removeAllObjects];
            } else {
                approvers = [NSMutableDictionary dictionary];
            }
            
            for (id item in jsonApprovers) {
                NSDictionary *dict = (NSDictionary*)item;
                Approver *approver = [[Approver alloc] init];
                [approver populateObjectWithInfo:dict];
                
                [approvers setObject:approver forKey:approver.objectId];
            }
            
            [ListDelegate didGetApprovers];
        } else if (response_status == RESPONSE_TIMEOUT) {
            [ListDelegate failedToGetApprovers];
            [UIHelper showInfo:SysTimeOut withStatus:kError];
            Debug(@"Time out when retrieving list of approvers");
        } else {
            [ListDelegate failedToGetApprovers];
            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
            Debug(@"Failed to retrieve list of approvers! %@", [err localizedDescription]);
        }
    }];
}

+ (void)retrieveListForObject:(NSString *)objId {
    [UIAppDelegate incrNetworkActivities];
    
    NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\"}", OBJ_ID, objId];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA, objStr, nil];
    
    [APIHandler asyncCallWithAction:APPROVERS_GET_API Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSArray *jsonApprovers = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        [UIAppDelegate decrNetworkActivities];
        
        if(response_status == RESPONSE_SUCCESS) {
            NSMutableArray *approverArr = [NSMutableArray array];
            
            for (id item in jsonApprovers) {
                NSDictionary *dict = (NSDictionary*)item;
                
                NSString *uid = [dict objectForKey:APPROVER_USER_ID];
                Approver *approver = [approvers objectForKey:uid];
                
                if (approver) {
                    approver.sortOrder = [[dict objectForKey:APPROVER_SORT_ORDER] intValue];
                    approver.status = [[dict objectForKey:APPROVER_STATUS] intValue];
                    approver.statusName = APPROVER_STATUSES[approver.status];
                    approver.statusDate = [dict objectForKey:APPROVER_STATUS_DATE];
                    
                    [approverArr addObject:approver];
                }
            }
            
            NSSortDescriptor *order = [[NSSortDescriptor alloc] initWithKey:APPROVER_SORT_ORDER ascending:YES selector:nil];
            [ListDelegate didGetApprovers:[approverArr sortedArrayUsingDescriptors:[NSArray arrayWithObjects:order, nil]]];
        } else if (response_status == RESPONSE_TIMEOUT) {
            [ListDelegate failedToGetApprovers];
            [UIHelper showInfo:SysTimeOut withStatus:kError];
            Debug(@"Time out when retrieving approvers");
        } else {
            [ListDelegate failedToGetApprovers];
            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
            Debug(@"Failed to retrieve approvers! %@", [err localizedDescription]);
        }
    }];
}

+ (void)setList:(NSArray *)approvers forObject:(NSString *)objId {
    [UIAppDelegate incrNetworkActivities];
    
    NSMutableString *approverList = [NSMutableString string];
    for (int i = 0; i < approvers.count; i++) {
        [approverList appendString:@"\""];
        [approverList appendString:((Approver *)approvers[i]).objectId];
        [approverList appendString:@"\""];
        if (i < approvers.count - 1) {
            [approverList appendString:@","];
        }
    }
    
    NSString *dataStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\", \"%@\" : [%@]}", OBJ_ID, objId, APPROVERS, approverList];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA, dataStr, nil];
    
    [APIHandler asyncCallWithAction:APPROVERS_SET_API Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        [UIAppDelegate decrNetworkActivities];
        
        if(response_status == RESPONSE_SUCCESS) {
            // update approver list mainly to update "Sent" status
            [Approver retrieveListForObject:objId];
        } else if (response_status == RESPONSE_TIMEOUT) {
            [UIHelper showInfo:SysTimeOut withStatus:kError];
            Debug(@"Time out when saving approvers");
        } else {
            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
            Debug(@"Failed to save approvers! %@", [err localizedDescription]);
        }
    }];
}

- (BOOL)isEqual:(id)other {
    return [self.objectId isEqual:((Approver *)other).objectId];
}

- (NSUInteger)hash {
    return [self.objectId hash];
}

@end
