//
//  InvoiceDetailsViewController.h
//  BDC
//
//  Created by Qinwei Gong on 9/9/12.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Invoice.h"

@interface InvoiceDetailsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIWebView *InvoicePDFView;
@property (nonatomic, strong) Invoice *invoice;
//@property (nonatomic, strong) NSMutableData * invoicePDFData;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;

//- (void)updateView;

@end
