//
//  User.h
//  Mobill Lite
//
//  Created by Qinwei Gong on 4/20/14.
//  Copyright (c) 2014 Mobill Inc. All rights reserved.
//

#import "BDCBusinessObject.h"

@interface User : BDCBusinessObject

@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *profileId;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;

+ (void)useProfileToGetOrgFeatures;

@end
