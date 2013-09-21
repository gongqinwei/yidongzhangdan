//
//  ContactsTableViewController.h
//  Mobill
//
//  Created by Qinwei Gong on 9/16/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "SlidingListTableViewController.h"
#import "Customer.h"

@interface ContactsTableViewController : SlidingListTableViewController

@property (nonatomic, strong) Customer *customer;

@end
