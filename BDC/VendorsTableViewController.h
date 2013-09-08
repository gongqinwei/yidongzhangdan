//
//  VendorsTableViewController.h
//  BDC
//
//  Created by Qinwei Gong on 8/31/12.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlidingListTableViewController.h"

@protocol VendorSelectDelegate <NSObject>

@required
- (void)didSelectVendor:(NSString *)vendorId;

@end

@interface VendorsTableViewController : SlidingListTableViewController

@property (nonatomic, strong) NSMutableArray *vendors;

@property (nonatomic, weak) id<VendorSelectDelegate> selectDelegate;

@end