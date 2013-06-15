//
//  InvoicesTableViewController.h
//  BDC
//
//  Created by Qinwei Gong on 8/31/12.
//
//

#import <UIKit/UIKit.h>
#import "SlidingListTableViewController.h"

@interface InvoicesTableViewController : SlidingListTableViewController

@property (nonatomic, strong) NSMutableArray *invoices;

@end
