//
//  BillsTableViewController.h
//  BDC
//
//  Created by Qinwei Gong on 4/22/13.
//
//

#import "SlidingListTableViewController.h"

@interface BillsTableViewController : SlidingListTableViewController

@property (nonatomic, strong) NSMutableArray *bills;

@property (nonatomic, strong) NSString *photoName;
@property (nonatomic, strong) NSData *photoData;

@end
