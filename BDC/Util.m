//
//  Util.m
//  BDC
//
//  Created by Qinwei Gong on 9/6/12.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "Util.h"
#import "Constants.h"
#import "KeychainItemWrapper.h"
#import "Branch.h"
#import "Mixpanel.h"
#import <Security/Security.h>

#define STAY_LOGGED_IN      @"StayLoggedIn"

@implementation Util

+ (void)track:(NSString *)message {
    [[Branch getInstance] userCompletedAction:message];
    [[Mixpanel sharedInstance] track:message];
}

+ (void)logout {
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_ID accessGroup:nil];
    [Util setSession:@""];
    [keychainItem setObject:@"" forKey:(__bridge id)(kSecValueData)];
    
    // Branch Metrics
    Branch *branch = [Branch getInstance];
    [branch logout];
    
    // Mixpanel
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Logout"];
}

+ (void)setUsername:(NSString *)username andPassword:(NSString *)password {
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_ID accessGroup:nil];
    
    [keychainItem setObject:username forKey:(__bridge id)(kSecAttrAccount)];
    [keychainItem setObject:password forKey:(__bridge id)(kSecValueData)];
}

+ (void)removePassword {
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_ID accessGroup:nil];
    [keychainItem setObject:@"" forKey:(__bridge id)(kSecValueData)];
}

+ (NSString *)getUsername {
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_ID accessGroup:nil];
    return [keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];
}

+ (NSString *)getPassword {
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_ID accessGroup:nil];
    return [keychainItem objectForKey:(__bridge id)(kSecValueData)];
}

+ (NSString *)getSelectedOrgId {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:ORG_ID];
}

+ (void)setSelectedOrgId:(NSString *)orgId {
    // persist
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:orgId forKey:ORG_ID];
    [defaults synchronize];
}

+ (BOOL)isStayLoggedIn {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id ret = [defaults objectForKey:STAY_LOGGED_IN];
    return ret ? [ret boolValue] : YES;
}

+ (void)setStayLoggedIn:(BOOL)stayLoggedIn {
    // persiste
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:stayLoggedIn] forKey:STAY_LOGGED_IN];
    [defaults synchronize];
}

+ (void)setSession:(NSString *)sessionId {
    // set session cookie
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
    [cookieProperties setObject:sessionId forKey:SESSION_ID_KEY];
    [cookieProperties setObject:[[NSDate date] dateByAddingTimeInterval:3600 * 24 * 365] forKey:NSHTTPCookieExpires];
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:sessionId forKey:SESSION_ID_KEY];
    [defaults synchronize];
}

+ (NSString *)getSession {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:SESSION_ID_KEY];
}

+ (void)setUserId:(NSString *)userId {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:userId forKey:USER_ID];
    [defaults synchronize];
}

+ (NSString *)getUserId {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:USER_ID];
}

+ (void)setUserProfile:(NSString *)profileId Fname:(NSString *)fname Lname:(NSString *)lname Email:(NSString *)email {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:profileId forKey:USER_PROFILE_ID];
    [defaults setObject:fname forKey:USER_FNAME];
    [defaults setObject:lname forKey:USER_LNAME];
    [defaults setObject:email forKey:USER_EMAIL];
    [defaults synchronize];
}

+ (NSString *)getUserEmail {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:USER_EMAIL];
}

+ (NSString *)getUserFirstName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:USER_FNAME];
}

+ (NSString *)getUserLastName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:USER_LNAME];
}

+ (NSString *)getUserFullName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [NSString stringWithFormat:@"%@ %@", [defaults objectForKey:USER_FNAME], [defaults objectForKey:USER_LNAME]];
}

+ (NSString *)getUserProfileId {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:USER_PROFILE_ID];
}


+ (BOOL)isSameDay:(NSDate *)date1 otherDay:(NSDate *)date2 {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents *comp1 = [calendar components:unitFlags fromDate:date1];
    NSDateComponents *comp2 = [calendar components:unitFlags fromDate:date2];
    
    return [comp1 day]  == [comp2 day] && [comp1 month] == [comp2 month] && [comp1 year]  == [comp2 year];
}

+ (BOOL)isDay:(NSDate *)date1 earlierThanDay:(NSDate *)date2 {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents *comp1 = [calendar components:unitFlags fromDate:date1];
    NSDateComponents *comp2 = [calendar components:unitFlags fromDate:date2];
    
//    Debug(@"%d", [comp1 year]);
//    Debug(@"%d", [comp1 month]);
//    Debug(@"%d", [comp1 day]);
//    Debug(@"%d", [comp2 year]);
//    Debug(@"%d", [comp2 month]);
//    Debug(@"%d", [comp2 day]);
    
    if ([comp1 year] != [comp2 year]) {
        return [comp1 year] < [comp2 year];
    } else {
        if ([comp1 month] != [comp2 month]) {
            return [comp1 month] < [comp2 month];
        } else {
            return [comp1 day] < [comp2 day];
        }
    }
    
//    if ([comp1 year] == [comp2 year]) {
//        if ([comp1 month] == [comp2 month]) {
//            return [comp1 day] < [comp2 day];
//        } else  {
//            return [comp1 month] < [comp2 month];
//        }
//    } else {
//        if([comp1 day] < [comp2 day]) {
//            Debug(@"true");
//        } else {
//            Debug(@"false");
//        }
//        return [comp1 day] < [comp2 day];
//    }
}

+ (NSDecimalNumber *)parseCurrency:(NSString *)str {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    if ([[Util trim:str] hasPrefix:@"$"]) {
        [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    } else {
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    }
    
    NSNumber *number = [formatter numberFromString:str];
    return [NSDecimalNumber decimalNumberWithDecimal:[number decimalValue]];
}

+ (NSString *)formatCurrency:(NSDecimalNumber *)amount {
    if (!amount) {
        return @"$0.00";
    }
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    return [formatter stringFromNumber:amount];
}

+ (NSDate *)getDate:(NSString *)date format:(NSString *)format {
    if (format == nil) {
        format = @"yyyy-MM-dd";
    }
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:format];
    
    return [df dateFromString: date];
}

+ (NSString *)formatDate:(NSDate *)date format:(NSString *)format {
    if (format == nil) {
        format = @"MM/dd/yyyy";
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = format;
    
    return [formatter stringFromDate:date];
}

+ (NSDecimalNumber *)id2Decimal:(id)number {
    if (!number || number == [NSNull null]) {
        return [NSDecimalNumber zero];
    } else {
        return [[NSDecimalNumber alloc] initWithDouble:[number doubleValue]];
    }
}

+ (NSString *)URLEncode:(NSString *)string {
    NSString *encodedEmail = (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                          (__bridge CFStringRef)string,
                                                                                          NULL,
                                                                                          (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                          kCFStringEncodingUTF8 );
    return encodedEmail;
}

+ (NSString *)trim:(NSString *)string {
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

@end
