//
//  CreateBillViewController.h
//  BDC
//
//  Created by Qinwei Gong on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlidingViewController.h"
#import "Bill.h"

@interface CreateBillViewController : SlidingViewController {
    NSString *_photoId;
}

//model
@property (nonatomic, strong) Bill *bill;

@property (nonatomic, strong) NSArray *info;
@property (weak, nonatomic) IBOutlet UIImageView *attachment;
@property (weak, nonatomic) IBOutlet UITableView *infoTable;

@property (nonatomic, strong, setter = setPhotoId:) NSString *photoId;

@property (nonatomic, strong) NSString *photoName;
@property (nonatomic, strong) NSData *photoData;

@end
