//
//  BOSelectorViewController.h
//  BDC
//
//  Created by Qinwei Gong on 6/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlidingViewController.h"

@interface BOSelectorViewController : SlidingViewController

@property (nonatomic, strong) NSString *photoName;
@property (nonatomic, strong) NSData *photoData;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *uploadIndicator;
@property (weak, nonatomic) IBOutlet UILabel *uploadError;
@property (weak, nonatomic) IBOutlet UILabel *photoNameLabel;

@end
