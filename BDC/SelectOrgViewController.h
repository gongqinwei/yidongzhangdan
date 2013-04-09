//
//  SelectOrgViewController.h
//  BDC
//
//  Created by Qinwei Gong on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SelectOrgViewController : UITableViewController

@property (nonatomic, strong) NSArray *orgs; //list of organizations
@property (nonatomic, assign) BOOL isInitialLogin;

@end
