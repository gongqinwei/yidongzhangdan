//
//  ImportABPersonViewController.h
//  Mobill
//
//  Created by Qinwei Gong on 11/27/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "SlidingDetailsTableViewController.h"
#import "ABPerson.h"


@interface ImportABPersonViewController : SlidingDetailsTableViewController

@property (nonatomic, strong) ABPerson *person;
@property (nonatomic, assign) Class importingClass;

@end
