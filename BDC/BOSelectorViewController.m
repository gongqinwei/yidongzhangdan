//
//  BOSelectorViewController.m
//  BDC
//
//  Created by Qinwei Gong on 6/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BOSelectorViewController.h"
#include "EditInvoiceViewController.h"
#import "InvoicesTableViewController.h"
#import "ScannerViewController.h"
#import "Uploader.h"
#import "APIHandler.h"
#import "Constants.h"
#import "UIHelper.h"

#define RESET_SCANNER_FROM_BO_SELECT_SEGUE          @"ResetScanner"
#define ATTACH_TO_NEW_INVOICE_SEGUE                 @"AttachToNewInvoice"
#define ATTACH_TO_EXISTING_INVOICE_SEGUE            @"AttachToExistingInvoice"
#define ATTACH_TO_NEW_BILL_SEGUE                    @"AttachToNewBill"
#define ATTACH_TO_EXISTING_BILL_SEGUE               @"AttachToExistingBill"
#define ATTACH_TO_NEW_VENDCREDIT_SEGUE              @"AttachToNewVendorCredit"
#define ATTACH_TO_EXISTING_VENDCREDIT_SEGUE         @"AttachToExistingVendorCredit"

@interface BOSelectorViewController ()

@end

@implementation BOSelectorViewController

@synthesize photoName;
@synthesize photoData;

@synthesize uploadIndicator;
@synthesize uploadError;
@synthesize photoNameLabel;

- (IBAction)uploadToInbox:(UIButton *)sender {
    self.uploadError.hidden = YES;
    self.uploadIndicator.hidden = NO;
    [self.uploadIndicator startAnimating];
    
    __weak BOSelectorViewController *weakSelf = self;
    
    [Uploader uploadFile:self.photoName data:self.photoData objectId:nil handler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger status;
        [APIHandler getResponse:response data:data error:&err status:&status];
        
        if(status == RESPONSE_SUCCESS) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.uploadError.hidden = YES;
//                [(ScannerViewController *)[((UINavigationController *)[self.tabBarController.viewControllers objectAtIndex:kScanTab]).viewControllers objectAtIndex:0] reset];
//                [UIHelper switchViewController:self toTab:kInboxTab withSegue:nil animated:YES];
                [UIHelper switchViewController:self toTab:kInboxTab withSegue:RESET_SCANNER_FROM_BO_SELECT_SEGUE animated:YES];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.uploadError.hidden = NO;
            });
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.uploadIndicator stopAnimating];
        });
    }];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (![segue.identifier isEqualToString:RESET_SCANNER_FROM_BO_SELECT_SEGUE] && [segue.destinationViewController respondsToSelector:@selector(setPhotoData:)]) {
        [segue.destinationViewController setPhotoName:self.photoName];
        [segue.destinationViewController setPhotoData:self.photoData];
    }
    
    if ([segue.identifier isEqualToString:ATTACH_TO_NEW_INVOICE_SEGUE] || [segue.identifier isEqualToString:ATTACH_TO_NEW_BILL_SEGUE] || [segue.identifier isEqualToString:ATTACH_TO_NEW_VENDCREDIT_SEGUE]) {
        [segue.destinationViewController addPhotoData:self.photoData name:self.photoName];
        [segue.destinationViewController setMode:kAttachMode];
    } else if ([segue.identifier isEqualToString:ATTACH_TO_EXISTING_INVOICE_SEGUE] || [segue.identifier isEqualToString:ATTACH_TO_EXISTING_BILL_SEGUE] || [segue.identifier isEqualToString:ATTACH_TO_EXISTING_VENDCREDIT_SEGUE]) {
        [segue.destinationViewController setMode:kSelectMode];
        [segue.destinationViewController setInvoices:[Invoice list]];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.uploadIndicator stopAnimating];
    self.uploadError.hidden = YES;
    self.photoNameLabel.text = self.photoName;
}

- (void)viewDidUnload
{
    [self setUploadIndicator:nil];
    [self setUploadError:nil];
    [self setPhotoName:nil];
    [self setPhotoNameLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
