//
//  EditBillViewController.h
//  BDC
//
//  Created by Qinwei Gong on 4/23/13.
//
//

#import "SlidingDetailsTableViewController.h"
#import "Bill.h"

@interface EditBillViewController : SlidingDetailsTableViewController

@property (nonatomic, strong) Bill *bill;

- (void)addAttachmentData:(NSData *)attachmentData name:(NSString *)attachmentName;

@end
