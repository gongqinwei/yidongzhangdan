//
//  UIButton7.h
//  Mobill
//
//  Created by Qinwei Gong on 12/2/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum {
    kLeft,
    kRight
} BarButtonPositionEnum;

@interface UIButton7 : UIButton

@property (nonatomic, assign) BarButtonPositionEnum position;

@end
