//
//  BDCAppDelegate.h
//  BDC
//
//  Created by Qinwei Gong on 6/20/12.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define UIAppDelegate       ((BDCAppDelegate *)[UIApplication sharedApplication].delegate)

@interface BDCAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, assign) BOOL stayLoggedIn;

@property (nonatomic, assign) int numNetworkActivities;

- (void)incrNetworkActivities;
- (void)decrNetworkActivities;

@end
