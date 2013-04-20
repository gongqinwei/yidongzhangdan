//
//  AROverViewController.h
//  BDC
//
//  Created by Qinwei Gong on 8/31/12.
//
//

#import <UIKit/UIKit.h>
#import "SlidingTableViewController.h"
#import "Invoice.h"

@interface AROverViewController : SlidingTableViewController  <InvoiceListDelegate>

@property (weak, nonatomic) IBOutlet UILabel *overDueInvCount;
@property (weak, nonatomic) IBOutlet UILabel *overDueInvAmount;
@property (weak, nonatomic) IBOutlet UILabel *dueIn7InvCount;
@property (weak, nonatomic) IBOutlet UILabel *dueIn7InvAmount;
@property (weak, nonatomic) IBOutlet UILabel *dueOver7InvCount;
@property (weak, nonatomic) IBOutlet UILabel *dueOver7InvAmount;
@property (weak, nonatomic) IBOutlet UILabel *totalInvCount;
@property (weak, nonatomic) IBOutlet UILabel *totalInvAmount;

@end
