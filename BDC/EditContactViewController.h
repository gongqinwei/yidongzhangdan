//
//  EditContactViewController.h
//  Mobill
//
//  Created by Qinwei Gong on 9/15/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "SlidingDetailsTableViewController.h"
#import "CustomerContact.h"
#import "Customer.h"

@interface EditContactViewController : SlidingDetailsTableViewController

@property (nonatomic, strong) Customer *customer;

@end
