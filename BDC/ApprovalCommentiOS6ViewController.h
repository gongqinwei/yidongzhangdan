//
//  ApprovalCommentiOS6ViewController.h
//  Mobill
//
//  Created by Qinwei Gong on 11/22/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Approvable.h"
#import "Approver.h"

@interface ApprovalCommentiOS6ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIBarButtonItem *approvalButton;
@property (weak, nonatomic) IBOutlet UITextView *approvalNoteView;

@property (nonatomic, strong) id<Approvable> busObj;
@property (nonatomic, assign) ApproverStatusEnum approvalDecision;

@end
