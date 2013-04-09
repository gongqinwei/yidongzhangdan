//
//  SlidingTableViewController.h
//  BDC
//
//  Created by Qinwei Gong on 10/15/12.
//
//

#import <UIKit/UIKit.h>
#import "UIViewController+Sliding.h"


@interface SlidingTableViewController : UITableViewController

@property (nonatomic, strong) NSString *createNewSegue;

- (void)didSelectCrudAction:(NSString *)action;

@end
