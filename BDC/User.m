//
//  User.m
//  Mobill Lite
//
//  Created by Qinwei Gong on 4/20/14.
//  Copyright (c) 2014 Mobill Inc. All rights reserved.
//

#import "User.h"
#import "Constants.h"
#import "APIHandler.h"
#import "Organization.h"
#import "UIHelper.h"
#import "BDCAppDelegate.h"

#define LIST_ACTIVE_USER_FILTER     @"{ \"start\" : 0, \
                                        \"max\" : 999, \
                                        \"filters\" : [{\"field\" : \"isActive\", \"op\" : \"=\", \"value\" : \"1\"}] \
                                    }"

#define LIST_PROFILE_FILTER         @"{ \"start\" : 0, \
                                        \"max\" : 999 \
                                    }"


@implementation User

+ (void)useProfileToGetOrgFeatures {
    NSString *userEmail = [[NSUserDefaults standardUserDefaults] objectForKey:USER_EMAIL];
    if (userEmail) {
        NSString *userName = [Util getUsername];
        
        if ([userEmail caseInsensitiveCompare:userName] == NSOrderedSame) {
            NSString *profileId = [[NSUserDefaults standardUserDefaults] objectForKey:USER_PROFILE_ID];
            
            // Assumption: if user defaults have this user info, then List Profile API should have been called already
            [User GetOrgFeaturesForProfile:profileId];
        } else {
            [User GetUserAndOrgFeaturesForEmail:userName];
        }
    } else {
        [User RetrieveProfiles];    //when retrieve profiles done, it will call get user and org features.
    }
}

+ (void)GetOrgFeaturesForProfile:(NSString *)profileId {
    NSString *profile = [[NSUserDefaults standardUserDefaults] objectForKey:profileId];
    Organization *currentOrg = [Organization getSelectedOrg];
    
    if ([profile isEqualToString:PROFILE_ADMIN]) {
        currentOrg.canPay = YES;
        currentOrg.canApprove = YES;
        currentOrg.hasInbox = YES;
        
//        [currentOrg getOrgFeatures];                                //TODO: 1) uncomment once login api returns userID; 2) need to set delegate???
    } else if ([profile isEqualToString:PROFILE_ACCOUNTANT]) {
        currentOrg.showAP = YES;
        currentOrg.enableAP = YES;
        currentOrg.showAR = YES;
        currentOrg.enableAR = YES;
        currentOrg.canPay = NO;
        currentOrg.canApprove = YES;
        currentOrg.hasInbox = YES;
    } else if ([profile isEqualToString:PROFILE_PAYER]) {
        currentOrg.showAP = YES;
        currentOrg.enableAP = NO;
        currentOrg.showAR = YES;
        currentOrg.enableAR = NO;
        currentOrg.canPay = YES;
        currentOrg.canApprove = NO;
        currentOrg.hasInbox = NO;
    } else if ([profile isEqualToString:PROFILE_APPROVER]) {
        currentOrg.showAP = YES;
        currentOrg.enableAP = NO;
        currentOrg.showAR = NO;
        currentOrg.enableAR = NO;
        currentOrg.canPay = NO;
        currentOrg.canApprove = YES;
        currentOrg.hasInbox = NO;
    } else if ([profile isEqualToString:PROFILE_CLERK]) {
        currentOrg.showAP = YES;
        currentOrg.enableAP = YES;
        currentOrg.showAR = YES;
        currentOrg.enableAR = YES;
        currentOrg.canPay = NO;
        currentOrg.canApprove = NO;
        currentOrg.hasInbox = YES;
    }
    
    [[Organization getDelegate] didGetOrgFeatures];
}



+ (void)GetUserAndOrgFeaturesForEmail:(NSString *)email {
    [UIAppDelegate incrNetworkActivities];
    
    NSString *filter = LIST_ACTIVE_USER_FILTER;
    NSString *action = [LIST_API stringByAppendingString: USER_API];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA, filter, nil];
    
    NSString *lowercaseEmail = [email lowercaseString];
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSArray *jsonUsers = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        [UIAppDelegate decrNetworkActivities];
        
        if(response_status == RESPONSE_SUCCESS) {
            for (id item in jsonUsers) {
                NSDictionary *dict = (NSDictionary*)item;
                NSString *userEmail = [dict objectForKey:@"email"];
                
                if ([userEmail isEqualToString:lowercaseEmail]) {
                    NSString *userId = [dict objectForKey:ID];
                    NSString *profileId = [dict objectForKey:@"profileId"];
                    NSString *fName = [dict objectForKey:@"firstName"];
                    NSString *lName = [dict objectForKey:@"lastName"];
                    
                    [[NSUserDefaults standardUserDefaults] setObject:userEmail forKey:USER_EMAIL];
                    [[NSUserDefaults standardUserDefaults] setObject:fName forKey:USER_FNAME];
                    [[NSUserDefaults standardUserDefaults] setObject:lName forKey:USER_LNAME];
                    [[NSUserDefaults standardUserDefaults] setObject:profileId forKey:USER_PROFILE_ID];
                    [[NSUserDefaults standardUserDefaults] setObject:userId forKey:USER_ID];
                    
                    [User GetOrgFeaturesForProfile:profileId];
                    
                    break;
                }
            }
            
        } else if (response_status == RESPONSE_TIMEOUT) {
            [UIHelper showInfo:SysTimeOut withStatus:kError];
            Error(@"Time out when retrieving list of users");
        } else {
            [UIHelper showInfo:[NSString stringWithFormat:@"Failed to retrieve list of users! %@", [err localizedDescription]] withStatus:kFailure];
            Error(@"Failed to retrieve list of users! %@", [err localizedDescription]);
        }
    }];
}

// Called only once
+ (void)RetrieveProfiles {
    [UIAppDelegate incrNetworkActivities];
    
    NSString *filter = LIST_PROFILE_FILTER;
    NSString *action = [LIST_API stringByAppendingString: PROFILE_API];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA, filter, nil];
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSArray *jsonProfiles = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        [UIAppDelegate decrNetworkActivities];
        
        if(response_status == RESPONSE_SUCCESS) {
            for (id item in jsonProfiles) {
                NSDictionary *dict = (NSDictionary*)item;
                NSString *profileId = [dict objectForKey:ID];
                NSString *profileName = [dict objectForKey:@"name"];
                
                [[NSUserDefaults standardUserDefaults] setObject:profileName forKey:profileId];
            }
            
            [User GetUserAndOrgFeaturesForEmail:[Util getUsername]];
            
        } else if (response_status == RESPONSE_TIMEOUT) {
            [UIHelper showInfo:SysTimeOut withStatus:kError];
            Error(@"Time out when retrieving list of profiles");
        } else {
            [UIHelper showInfo:[NSString stringWithFormat:@"Failed to retrieve list of profiles! %@", [err localizedDescription]] withStatus:kFailure];
            Error(@"Failed to retrieve list of profiles! %@", [err localizedDescription]);
        }
    }];
}


@end
