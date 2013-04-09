//
//  InvoicesTableViewController.h
//  BDC
//
//  Created by Qinwei Gong on 8/31/12.
//
//

#import <UIKit/UIKit.h>
#import "SlidingTableViewController.h"

@interface InvoicesTableViewController : SlidingTableViewController

@property (nonatomic, strong) NSMutableArray *invoices;

@property (nonatomic, strong) NSString *photoName;
@property (nonatomic, strong) NSData *photoData;

@end
