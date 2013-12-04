//
//  ABPerson.h
//  Mobill
//
//  Created by Qinwei Gong on 11/26/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ABPerson : NSObject

@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSMutableString *name;
@property (nonatomic, strong) NSString *company;
@property (nonatomic, strong) NSMutableDictionary *emails;

@property (nonatomic, strong) NSString *addr1;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, assign) NSString *country;
@property (nonatomic, assign) NSString *countryCode;
@property (nonatomic, strong) NSString *zip;
@property (nonatomic, strong) NSString *phone;

@end
