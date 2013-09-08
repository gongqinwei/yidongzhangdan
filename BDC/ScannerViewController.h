//
//  ScannerViewController.h
//  BDC
//
//  Created by Qinwei Gong on 6/21/12.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlidingViewController.h"
#import "Constants.h"

@protocol ScannerDelegate <NSObject>

- (void)didScanPhoto:(NSData *)photoData name:(NSString *)photoName;

@end

@interface ScannerViewController : SlidingViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *fileName;
@property (weak, nonatomic) IBOutlet UIImageView *preview;
@property (weak, nonatomic) IBOutlet UIButton *submit;

@property (nonatomic, assign) ViewMode mode;
@property (nonatomic, weak) id<ScannerDelegate> delegate;

- (void)reset;

@end
