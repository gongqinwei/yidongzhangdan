//
//  ApprovalCommentViewController.m
//  Mobill
//
//  Created by Qinwei Gong on 10/19/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "ApprovalCommentViewController.h"
#import "UIHelper.h"


@interface ApprovalCommentViewController ()

@end

@implementation ApprovalCommentViewController

@synthesize approvalCommentNavigationItem;
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
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelApproval:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.approvalDecision != kApproverDenied) {
        self.approvalCommentNavigationItem.title = @"Note (Optional)";
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
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
    else {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
