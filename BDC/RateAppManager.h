//
//  RateAppManager.h
//  Mobill Lite
//
//  Created by Qinwei Gong on 4/1/14.
//  Copyright (c) 2014 Mobill Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RateAppManager : NSObject <UIAlertViewDelegate>

+ (RateAppManager *)sharedInstance;
- (void)checkPromptForRate;

@end
