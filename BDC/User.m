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

#import "Invoice.h"
#import "Document.h"
#import "Bill.h"


#define LIST_ACTIVE_USER_FILTER     @"{ \"start\" : 0, \
                                        \"max\" : 999, \
                                        \"filters\" : [{\"field\" : \"isActive\", \"op\" : \"=\", \"value\" : \"1\"}] \
                                    }"

#define LIST_PROFILE_FILTER         @"{ \"start\" : 0, \
                                        \"max\" : 999 \
                                    }"
#define PROFILES                    @"Profiles"


@interface User()

@property (nonatomic, assign) unsigned int profileMask;
@property (nonatomic, assign) unsigned int profileCheck;

@end

@implementation User

static User *loginUser = nil;
static id<UserDelegate> UserDelegate = nil;


- (void)markProfileFor:(ProfileCheckList) position checked:(BOOL)checked {
    @synchronized(self) {
        self.profileCheck |= 1 << position;
        self.profileMask |= checked << position;
        
        Debug(@"profile checklist: %i, %i", self.profileCheck, self.profileMask);
        
        if (self.profileCheck == 15) {
//            [self.profileDelegate didFinishProfileCheckList];
//            self.profileDelegate = nil;
            
            // if can't retrieve bills nor invoices -> approver role;
            // else if can't retrieve inbox -> payer role;
            // else if can't retrieve billsToApprove -> clerk;
            // else -> accountant role
            if (!(self.profileMask & 1 << kBillsChecked) && !(self.profileMask & 1 << kInvoicesChecked)){
                self.profile = kApprover;
            } else if (!(self.profileMask & 1 << kInboxChecked)) {
                self.profile = kPayer;
            } else if (!(self.profileMask & 1 << kToApproveChecked)) {
                self.profile = kClerk;
            } else {
                self.profile = kAccountant;
            }
            
//            [self getOrgFeaturesForProfile];
        }
    }
}

- (void)resetProfilemark {
    self.profileMask = 0;
    self.profileCheck = 0;
}

+ (User *)GetLoginUser {
    if (!loginUser) {
        loginUser = [[User alloc] init];
        loginUser.objectId = [Util getUserId];
        loginUser.email = [Util getUserEmail];
        loginUser.firstName = [Util getUserFirstName];
        loginUser.lastName = [Util getUserLastName];
    }
    return loginUser;
}

- (void)getOrgFeaturesForProfile {
    Organization *currentOrg = [Organization getSelectedOrg];
    
    switch (self.profile) {
        case kAdmin:
            currentOrg.enableAP = YES;
            currentOrg.enableAR = YES;
            currentOrg.canPay = YES;
            currentOrg.canApprove = YES;
            currentOrg.hasInbox = YES;
            
            [currentOrg getOrgFeatures];
            break;
            
        case kAccountant:
            currentOrg.enableAP = YES;
            currentOrg.enableAR = YES;
            currentOrg.canPay = NO;
            currentOrg.canApprove = YES;
            currentOrg.hasInbox = YES;
            
            [currentOrg getOrgFeatures];
            break;
            
        case kPayer:
            currentOrg.enableAP = NO;
            currentOrg.enableAR = NO;
            currentOrg.canPay = YES;
            currentOrg.canApprove = NO;
            currentOrg.hasInbox = NO;
            
            [currentOrg getOrgFeatures];
            break;
            
        case kApprover:
            currentOrg.showAP = YES;
            currentOrg.enableAP = NO;
            currentOrg.showAR = NO;
            currentOrg.enableAR = NO;
            currentOrg.canPay = NO;
            currentOrg.canApprove = YES;
            currentOrg.hasInbox = NO;
            
            [[Organization getDelegate] didGetOrgFeatures];
            break;
            
        case kClerk:
            currentOrg.enableAP = YES;
            currentOrg.enableAR = YES;
            currentOrg.canPay = NO;
            currentOrg.canApprove = NO;
            currentOrg.hasInbox = YES;
            
            [currentOrg getOrgFeatures];
            break;
            
        default:
            [currentOrg getOrgFeatures];
            break;
    }
}

+ (void)setUserDelegate:(id<UserDelegate>)delegate {
    UserDelegate = delegate;
}

+ (void)GetUserInfo:(NSString *)userId {
    [UIAppDelegate incrNetworkActivities];
    
    NSString *action = [NSString stringWithFormat:@"%@/%@/%@", CRUD, READ, USER_API];
    NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\"}", _ID, userId];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA, objStr, nil];
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSArray *jsonUser = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        [UIAppDelegate decrNetworkActivities];
        
        if(response_status == RESPONSE_SUCCESS) {
            NSDictionary *dict = (NSDictionary*)jsonUser;
            NSString *userEmail = [dict objectForKey:@"email"];
            NSString *profileId = [dict objectForKey:@"profileId"];
            NSString *fName = [dict objectForKey:@"firstName"];
            NSString *lName = [dict objectForKey:@"lastName"];
            
            [Util setUserProfile:profileId Fname:fName Lname:lName Email:userEmail];
            
            [UserDelegate didGetUserInfo];
            
//            [User GetOrgFeaturesForProfile:profileId];
            
        } else if (response_status == RESPONSE_TIMEOUT) {
            [UIHelper showInfo:SysTimeOut withStatus:kError];
            Error(@"Time out when retrieving user info for %@", userId);
        } else {
            [UIHelper showInfo:[NSString stringWithFormat:@"Failed to retrieve user info! %@", [err localizedDescription]] withStatus:kFailure];
            Error(@"Failed to retrieve user info for %@! %@", userId, [err localizedDescription]);
        }
    }];
}

+ (void)RetrieveProfiles {
    [UIAppDelegate incrNetworkActivities];
    
    NSString *filter = LIST_PROFILE_FILTER;
    NSString *action = [LIST_API stringByAppendingString: PROFILE_API];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA, filter, nil];
    
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        [UIAppDelegate decrNetworkActivities];
        
        if(response_status == RESPONSE_SUCCESS) {
            // only administrator role can successfully retrieve profiles
            // so, proceed to get org features
            [Organization getSelectedOrg].enableAP = YES;
            [Organization getSelectedOrg].enableAR = YES;
            [Organization getSelectedOrg].canApprove = YES;
            [Organization getSelectedOrg].canPay = YES;
            [Organization getSelectedOrg].hasInbox = YES;
            [[Organization getSelectedOrg] getOrgFeatures];
            [User GetLoginUser].profile = kAdmin;
        } else if (response_status == RESPONSE_TIMEOUT) {
            [UIHelper showInfo:SysTimeOut withStatus:kError];
            Error(@"Time out when retrieving list of profiles");
        } else if (YES) {       //temp: error code is no valid permission
            // role is anything but administrator
            
            // if can't retrieve bills nor invoices -> approver role;
            // else if can't retrieve inbox -> payer role;
            // else if can't retrieve billsToApprove -> clerk;
            // else -> accountant role
            
            [[User GetLoginUser] resetProfilemark];
            
            [Bill retrieveListForActive:YES];
            [Invoice retrieveListForActive:YES];
            [Document retrieveListForCategory:FILE_CATEGORY_DOCUMENT];
            [Bill retrieveListForApproval:nil];
            
        } else {
            [UIHelper showInfo:[NSString stringWithFormat:@"Failed to retrieve list of profiles! %@", [err localizedDescription]] withStatus:kFailure];
            Error(@"Failed to retrieve list of profiles! %@", [err localizedDescription]);
        }
    }];
}

+ (NSString *)GetOrgProfileDictKey {
    Organization *currentOrg = [Organization getSelectedOrg];
    return [NSString stringWithFormat:@"%@-%@@", PROFILES, currentOrg.objectId];
}



//+ (void)GetOrgFeaturesForProfile:(NSString *)profileId {
//    Organization *currentOrg = [Organization getSelectedOrg];
//    
//    NSDictionary *profileDict = [[NSUserDefaults standardUserDefaults] objectForKey:[User GetOrgProfileDictKey]];
//    if (profileDict) {
//        NSString *profile = [profileDict objectForKey:profileId];
//        
//        if ([profile isEqualToString:PROFILE_ADMIN]) {
//            currentOrg.showAP = YES;
//            currentOrg.enableAP = YES;
//            currentOrg.showAR = YES;
//            currentOrg.enableAR = YES;
//            currentOrg.canPay = YES;
//            currentOrg.canApprove = YES;
//            currentOrg.hasInbox = YES;
//            [[Organization getDelegate] didGetOrgFeatures];
//        } else if ([profile isEqualToString:PROFILE_ACCOUNTANT]) {
//            currentOrg.showAP = YES;
//            currentOrg.enableAP = YES;
//            currentOrg.showAR = YES;
//            currentOrg.enableAR = YES;
//            currentOrg.canPay = NO;
//            currentOrg.canApprove = YES;
//            currentOrg.hasInbox = YES;
//            [[Organization getDelegate] didGetOrgFeatures];
//        } else if ([profile isEqualToString:PROFILE_PAYER]) {
//            currentOrg.showAP = YES;
//            currentOrg.enableAP = NO;
//            currentOrg.showAR = YES;
//            currentOrg.enableAR = NO;
//            currentOrg.canPay = YES;
//            currentOrg.canApprove = NO;
//            currentOrg.hasInbox = NO;
//            [[Organization getDelegate] didGetOrgFeatures];
//        } else if ([profile isEqualToString:PROFILE_APPROVER]) {
//            currentOrg.showAP = YES;
//            currentOrg.enableAP = NO;
//            currentOrg.showAR = NO;
//            currentOrg.enableAR = NO;
//            currentOrg.canPay = NO;
//            currentOrg.canApprove = YES;
//            currentOrg.hasInbox = NO;
//            [[Organization getDelegate] didGetOrgFeatures];
//        } else if ([profile isEqualToString:PROFILE_CLERK]) {
//            currentOrg.showAP = YES;
//            currentOrg.enableAP = YES;
//            currentOrg.showAR = YES;
//            currentOrg.enableAR = YES;
//            currentOrg.canPay = NO;
//            currentOrg.canApprove = NO;
//            currentOrg.hasInbox = YES;
//            [[Organization getDelegate] didGetOrgFeatures];
//        } else {        // User customized profile type - no API to retrieve permissions
//            [currentOrg getOrgFeatures];
//        }
//        
//    } else {
//        [currentOrg getOrgFeatures];
//    }
//    
//}


//// Called only once
//+ (void)RetrieveProfiles {
//    NSDictionary *profileDict = [[NSUserDefaults standardUserDefaults] objectForKey:[User GetOrgProfileDictKey]];
//    
//    if (!profileDict) {
//        [UIAppDelegate incrNetworkActivities];
//        
//        NSString *filter = LIST_PROFILE_FILTER;
//        NSString *action = [LIST_API stringByAppendingString: PROFILE_API];
//        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA, filter, nil];
//        
//        [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
//            NSInteger response_status;
//            NSArray *jsonProfiles = [APIHandler getResponse:response data:data error:&err status:&response_status];
//            
//            [UIAppDelegate decrNetworkActivities];
//            
//            if(response_status == RESPONSE_SUCCESS) {
//                NSMutableDictionary *profileDict = [NSMutableDictionary dictionary];
//                
//                for (id item in jsonProfiles) {
//                    NSDictionary *dict = (NSDictionary*)item;
//                    NSString *profileId = [dict objectForKey:_ID];
//                    NSString *profileName = [dict objectForKey:@"name"];
//                    [profileDict setObject:profileName forKey:profileId];
//                }
//                
//                [[NSUserDefaults standardUserDefaults] setObject:profileDict forKey:[User GetOrgProfileDictKey]];
//                
//                //                [User GetUserAndOrgFeaturesForEmail:[Util getUsername]];
//                [User GetUserInfo:[Util getUserId]];
//                
//            } else if (response_status == RESPONSE_TIMEOUT) {
//                [UIHelper showInfo:SysTimeOut withStatus:kError];
//                Error(@"Time out when retrieving list of profiles");
//            } else {
//                [UIHelper showInfo:[NSString stringWithFormat:@"Failed to retrieve list of profiles! %@", [err localizedDescription]] withStatus:kFailure];
//                Error(@"Failed to retrieve list of profiles! %@", [err localizedDescription]);
//            }
//        }];
//    } else {
//        [User GetUserInfo:[Util getUserId]];
//    }
//}



//+ (void)useProfileToGetOrgFeatures {
//    NSString *userEmail = [Util getUserEmail];
//    if (userEmail) {
//        NSString *userName = [Util getUsername];
//        
//        if ([userEmail caseInsensitiveCompare:userName] == NSOrderedSame) {
//            NSString *profileId = [Util getUserProfileId];
//            
//            // Assumption: if user defaults have this user info, then List Profile API should have been called already
//            [User GetOrgFeaturesForProfile:profileId];
//        } else {
//            [User GetUserAndOrgFeaturesForEmail:userName];
//        }
//    } else {
//        [User RetrieveProfiles];    //when retrieve profiles done, it will call get user and org features.
//    }
//}
//
//+ (void)GetUserAndOrgFeaturesForEmail:(NSString *)email {
//    [UIAppDelegate incrNetworkActivities];
//    
//    NSString *filter = LIST_ACTIVE_USER_FILTER;
//    NSString *action = [LIST_API stringByAppendingString: USER_API];
//    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:DATA, filter, nil];
//    
//    NSString *lowercaseEmail = [email lowercaseString];
//    
//    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
//        NSInteger response_status;
//        NSArray *jsonUsers = [APIHandler getResponse:response data:data error:&err status:&response_status];
//        
//        [UIAppDelegate decrNetworkActivities];
//        
//        if(response_status == RESPONSE_SUCCESS) {
//            for (id item in jsonUsers) {
//                NSDictionary *dict = (NSDictionary*)item;
//                NSString *userEmail = [dict objectForKey:@"email"];
//                
//                if ([userEmail isEqualToString:lowercaseEmail]) {
//                    //                    NSString *userId = [dict objectForKey:_ID];
//                    NSString *profileId = [dict objectForKey:@"profileId"];
//                    NSString *fName = [dict objectForKey:@"firstName"];
//                    NSString *lName = [dict objectForKey:@"lastName"];
//                    
//                    [Util setUserProfile:profileId Fname:fName Lname:lName Email:userEmail];
//                    //                    [[NSUserDefaults standardUserDefaults] setObject:userEmail forKey:USER_EMAIL];
//                    //                    [[NSUserDefaults standardUserDefaults] setObject:fName forKey:USER_FNAME];
//                    //                    [[NSUserDefaults standardUserDefaults] setObject:lName forKey:USER_LNAME];
//                    //                    [[NSUserDefaults standardUserDefaults] setObject:profileId forKey:USER_PROFILE_ID];
//                    //                    [[NSUserDefaults standardUserDefaults] setObject:userId forKey:USER_ID];
//                    
//                    [User GetOrgFeaturesForProfile:profileId];
//                    
//                    break;
//                }
//            }
//            
//        } else if (response_status == RESPONSE_TIMEOUT) {
//            [UIHelper showInfo:SysTimeOut withStatus:kError];
//            Error(@"Time out when retrieving list of users");
//        } else {
//            [UIHelper showInfo:[NSString stringWithFormat:@"Failed to retrieve list of users! %@", [err localizedDescription]] withStatus:kFailure];
//            Error(@"Failed to retrieve list of users! %@", [err localizedDescription]);
//        }
//    }];
//}



@end
