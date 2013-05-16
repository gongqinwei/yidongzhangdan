//
//  EditInvoiceViewController.h
//  BDC
//
//  Created by Qinwei Gong on 9/21/12.
//
//

#import <UIKit/UIKit.h>
#import "SlidingDetailsTableViewController.h"
#import "Invoice.h"

@interface EditInvoiceViewController : SlidingDetailsTableViewController

@property (nonatomic, strong) Invoice *invoice;

- (void)addAttachmentData:(NSData *)attachmentData name:(NSString *)attachmentName;

@end
