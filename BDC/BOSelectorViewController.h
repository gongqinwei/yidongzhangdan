//
//  BOSelectorViewController.h
//  BDC
//
//  Created by Qinwei Gong on 6/25/12.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "SlidingTableViewController.h"
#import "Document.h"

@interface BOSelectorViewController : UITableViewController // SlidingTableViewController

@property (nonatomic, strong) Document *document;
@property (weak, nonatomic) IBOutlet UISegmentedControl *pickOrCreateSwitch;

@end
