//
//  PayBillViewController.h
//  BDC
//
//  Created by Qinwei Gong on 5/1/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Bill.h"

@interface PayBillViewController : UITableViewController

@property (nonatomic, strong) Bill *bill;
@property (weak, nonatomic) IBOutlet UILabel *billAmountLabel;
@property (weak, nonatomic) IBOutlet UILabel *paidAmountLabel;
@property (weak, nonatomic) IBOutlet UILabel *dueDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *bankAccountLabel;
@property (weak, nonatomic) IBOutlet UILabel *invalidPayAmountLabel;
@property (weak, nonatomic) IBOutlet UITextField *payAmountTextField;
@property (weak, nonatomic) IBOutlet UITextField *processDateTextField;
@property (weak, nonatomic) IBOutlet UINavigationItem *navBar;

@end
