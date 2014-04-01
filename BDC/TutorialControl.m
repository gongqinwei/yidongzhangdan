//
//  TutorialControl.m
//  WeiChat
//
//  Created by Qinwei Gong on 3/3/14.
//  Copyright (c) 2014 Mobill Inc. All rights reserved.
//

#import "TutorialControl.h"
#import "Constants.h"


@implementation TutorialControl


- (id)init {
    return [self initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
}

- (id)initWithFrame:(CGRect)theFrame {
    self = [super initWithFrame:theFrame];
    if (self) {
        [self addTarget:self action:@selector(dismissTutorial) forControlEvents:UIControlEventTouchUpInside];
        [self addTarget:self action:@selector(dismissTutorial) forControlEvents:UIControlEventTouchDragInside];
        self.opaque = NO;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    }
    return self;
}

- (void)dismissTutorial {
    [self removeFromSuperview];
}

- (void)addText:(NSString *)text at:(CGRect)frame {
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.text = NSLocalizedString(text, nil);
    label.font = [UIFont fontWithName:@"Noteworthy-Light" size:19.0];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 3;
    [self addSubview:label];
}

- (void)addImageNamed:(NSString *)imageName at:(CGRect)frame {
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:frame];
    imgView.image = [UIImage imageNamed:imageName];
    [self addSubview:imgView];
}

@end
