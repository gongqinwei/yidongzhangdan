//
//  InvoicesTableViewController.h
//  BDC
//
//  Created by Qinwei Gong on 8/31/12.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlidingListTableViewController.h"

@interface InvoicesTableViewController : SlidingListTableViewController

@property (nonatomic, strong) NSMutableArray *invoices;
@property (nonatomic, strong) NSMutableArray *customerSectionLabels;

@end
