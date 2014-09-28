//
//  User.h
//  Mobill Lite
//
//  Created by Qinwei Gong on 4/20/14.
//  Copyright (c) 2014 Mobill Inc. All rights reserved.
//

#import "BDCBusinessObject.h"

typedef enum {
    kAdmin,
    kAccountant,
    kApprover,
    kPayer,
    kClerk
} ProfileEnum;

typedef enum {
    kBillsChecked,
    kInvoicesChecked,
    kInboxChecked,
    kToApproveChecked
} ProfileCheckList;


@protocol UserDelegate

- (void)didGetUserInfo;

@end

@protocol ProfileDelegate

- (void)didFinishProfileCheckList;

@end


@interface User : BDCBusinessObject

@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *profileId;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, assign) ProfileEnum profile;

@property (nonatomic, strong) id<ProfileDelegate> profileDelegate;
//@property (nonatomic, strong) id<UserDelegate> userDelegate;

- (void)markProfileFor:(ProfileCheckList) position checked:(BOOL)checked;
- (void)resetProfilemark;

+ (User *)GetLoginUser;

//+ (void)useProfileToGetOrgFeatures;
+ (void)RetrieveProfiles;
+ (void)GetUserInfo:(NSString *)userId;
+ (void)setUserDelegate:(id<UserDelegate>)delegate;

@end
