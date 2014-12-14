//
//  EditCustomerViewController.h
//  BDC
//
//  Created by Qinwei Gong on 2/18/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "SlidingDetailsTableViewController.h"
#import "CustomerContact.h"

@interface EditCustomerViewController : SlidingDetailsTableViewController

@property (nonatomic, strong) CustomerContact *deepLinkContact;

@end
