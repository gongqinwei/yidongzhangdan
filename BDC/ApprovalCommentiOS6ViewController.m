//
//  ApprovalCommentiOS6ViewController.m
//  Mobill
//
//  Created by Qinwei Gong on 11/22/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "ApprovalCommentiOS6ViewController.h"
#import "UIHelper.h"


@interface ApprovalCommentiOS6ViewController ()

@end

@implementation ApprovalCommentiOS6ViewController

@synthesize approvalButton;
@synthesize approvalNoteView;
@synthesize busObj;
@synthesize approvalDecision;


- (IBAction)submitApproval:(UIBarButtonItem *)sender {
    if (self.approvalDecision == kApproverApproved) {
        [busObj approveWithComment:self.approvalNoteView.text];
    } else if (self.approvalDecision == kApproverDenied) {
        if (self.approvalNoteView.text.length == 0) {
            [UIHelper showInfo:@"Please add a note to explain why you are denying." withStatus:kWarning];
        } else {
            [busObj denyWithComment:self.approvalNoteView.text];
        }
    } else {
        [busObj skipWithComment:self.approvalNoteView.text];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.approvalDecision != kApproverDenied) {
        self.title = @"Note (Optional)";
    }
    
    if (self.approvalDecision == kApproverApproved) {
        self.approvalButton.title = @"Approve";
    } else {
        self.approvalButton.title = @"Deny";
    }
	
    self.approvalNoteView.layer.borderWidth = 1.0f;
    self.approvalNoteView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    self.approvalNoteView.layer.cornerRadius = 8.0f;
    self.approvalNoteView.layer.masksToBounds = YES;
    [self.approvalNoteView becomeFirstResponder];
}


@end
