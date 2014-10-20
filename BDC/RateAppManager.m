//
//  RateAppManager.m
//  Mobill Lite
//
//  Created by Qinwei Gong on 4/1/14.
//  Copyright (c) 2014 Mobill Inc. All rights reserved.
//

#import "RateAppManager.h"
#import "Constants.h"
#import "Util.h"


#define RATE_DECISION               @"RateDecision"
#define DECISION_VERSION            @"DecisionVersion"
#define LAST_PROMPT_DATE            @"LastPromptForRateDate"
#define RATE_REMINDER_THRESHOLD     2
#define REMINDER_WAIT_COUNT         @"RateReminderWaitCount"
#define APP_STORE_REVIEW_URL        [NSString stringWithFormat:@"%@%d", @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=", FULL_VERSION_ID]

static RateAppManager *_sharedInstance = nil;

@implementation RateAppManager

+ (RateAppManager *)sharedInstance {
    if (!_sharedInstance) {
        _sharedInstance = [[RateAppManager alloc] init];
    }
    return _sharedInstance;
}

- (void)checkPromptForRate {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *decision_version = [userDefaults stringForKey:DECISION_VERSION];
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *currVersion = [infoDict objectForKey:@"CFBundleVersion"];
    NSDate *lastPromptDate = [userDefaults objectForKey:LAST_PROMPT_DATE];
    
    if (!decision_version){
        if (![Util isSameDay:lastPromptDate otherDay:[NSDate date]]) {
            [self promptAux:RATE_REMINDER_THRESHOLD];
        }
    } else if (![decision_version isEqualToString:currVersion]) {
        BOOL rated = [userDefaults boolForKey:RATE_DECISION];
        
        if (rated) {
            [self promptAux:RATE_REMINDER_THRESHOLD * 2];
        } else {
            [self promptAux:RATE_REMINDER_THRESHOLD * 1];
        }
    }
}

- (void)promptAux:(int)threshold {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger waitCount = [userDefaults integerForKey:REMINDER_WAIT_COUNT];
    if (waitCount >= threshold) {
        [self presentToRate];
    } else {
        waitCount++;
        [userDefaults setInteger:waitCount forKey:REMINDER_WAIT_COUNT];
        [userDefaults synchronize];
    }
}

- (void)presentToRate {
    UIAlertView *rateAppPrompt = [[UIAlertView alloc] initWithTitle:@"Rate the App"
                                                            message:@"Would you like to rate Mobill in the app store?\n\nIt will only take a couple minutes and will help make this app better!"
                                                           delegate:self
                                                  cancelButtonTitle:@"Remind me later"
                                                  otherButtonTitles:@"Yes, rate it!", @"No, thanks.", nil];
    [rateAppPrompt show];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSDate date] forKey:LAST_PROMPT_DATE];
    [userDefaults synchronize];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:0 forKey:REMINDER_WAIT_COUNT];
    
    switch (buttonIndex) {
        case 0:     //remind me later
            [userDefaults removeObjectForKey:DECISION_VERSION];
            break;
        case 1:     //yes, rate it
        {
            NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
            [userDefaults setObject:[infoDict objectForKey:@"CFBundleVersion"] forKey:DECISION_VERSION];
            [userDefaults setBool:YES forKey:RATE_DECISION];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:APP_STORE_REVIEW_URL]];
        }
            break;
        case 2:     //no, thanks
        {
            NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
            [userDefaults setObject:[infoDict objectForKey:@"CFBundleVersion"] forKey:DECISION_VERSION];
            [userDefaults setBool:NO forKey:RATE_DECISION];
        }
            break;
            
        default:
            break;
    }
    
    [userDefaults synchronize];
}

@end
