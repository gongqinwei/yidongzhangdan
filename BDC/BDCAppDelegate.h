//
//  BDCAppDelegate.h
//  BDC
//
//  Created by Qinwei Gong on 6/20/12.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

#define UIAppDelegate       ((BDCAppDelegate *)[UIApplication sharedApplication].delegate)

@interface BDCAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, assign) int numNetworkActivities;
@property (nonatomic, strong) NSString *bncDeeplinkObjId;

- (void)incrNetworkActivities;
- (void)decrNetworkActivities;

- (void)presentUpgrade;
- (void)nagivateToAppStore;

- (MFMailComposeViewController *)getMailer;

@end
