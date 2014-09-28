//
//  Util.h
//  BDC
//
//  Created by Qinwei Gong on 9/6/12.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Util : NSObject

+ (void)logout;

+ (NSString *)getUsername;
+ (NSString *)getPassword;
+ (void)setUsername:(NSString *)username andPassword:(NSString *)password;
+ (void)removePassword;

+ (NSString *)getSelectedOrgId;
+ (void)setSelectedOrgId:(NSString *)orgId;

+ (BOOL)isStayLoggedIn;
+ (void)setStayLoggedIn:(BOOL)stayLoggedIn;
+ (void)setSession:(NSString *)sessionId;
+ (NSString *)getSession;

+ (void)setUserId:(NSString *)userId;
+ (NSString *)getUserId;
+ (void)setUserProfile:(NSString *)profileId Fname:(NSString *)fname Lname:(NSString *)lname Email:(NSString *)email;
+ (NSString *)getUserEmail;
+ (NSString *)getUserFirstName;
+ (NSString *)getUserLastName;
+ (NSString *)getUserProfileId;


+ (BOOL)isSameDay:(NSDate*)date1 otherDay:(NSDate*)date2;
+ (BOOL)isDay:(NSDate*)date1 earlierThanDay:(NSDate*)date2;

+ (NSDate *)getDate:(NSString *)date format:(NSString *)format;
+ (NSString *)formatDate:(NSDate *)date format:(NSString *)format;
+ (NSString *)formatCurrency:(NSDecimalNumber *)amount;
+ (NSDecimalNumber *)parseCurrency:(NSString *)str;

+ (NSDecimalNumber *)id2Decimal:(id)number;

+ (NSString *)URLEncode:(NSString *)string;
+ (NSString *)trim:(NSString *)string;
 
@end
