//
//  UIView+FindAndResignFirstResponder.h
//  BDC
//
//  Created by Qinwei Gong on 2/27/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (FindAndResignFirstResponder)

@property (nonatomic, retain) id objectTag;

- (UIView *)viewWithObjectTag:(id)object;

- (BOOL) findAndResignFirstResponder;

@end
