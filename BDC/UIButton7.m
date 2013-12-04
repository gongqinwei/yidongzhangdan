//
//  UIButton7.m
//  Mobill
//
//  Created by Qinwei Gong on 12/2/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "UIButton7.h"

@implementation UIButton7

- (UIEdgeInsets)alignmentRectInsets {
    UIEdgeInsets insets;
    if (self.position == kLeft) {
        insets = UIEdgeInsetsMake(0, 10.0f, 0, 0);
    } else {
        insets = UIEdgeInsetsMake(0, 0, 0, 10.0f);
    }
    return insets;
}

@end
