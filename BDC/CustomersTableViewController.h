//
//  CustomersTableViewController.h
//  BDC
//
//  Created by Qinwei Gong on 8/31/12.
//
//

#import <UIKit/UIKit.h>
#import "SlidingListTableViewController.h"

@protocol CustomerSelectDelegate <NSObject>

@required
- (void)didSelectCustomer:(NSString *)customerId;

@end

@interface CustomersTableViewController : SlidingListTableViewController

@property (nonatomic, strong) NSMutableArray *customers;

@property (nonatomic, weak) id<CustomerSelectDelegate> selectDelegate;

@end
