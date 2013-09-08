//
//  DocumentCell.m
//  BDC
//
//  Created by Qinwei Gong on 5/29/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "DocumentCell.h"
#import <QuartzCore/QuartzCore.h>


@interface DocumentCell ()

@property (nonatomic, strong) UIView *infoOverlay;

@end


@implementation DocumentCell

@synthesize infoOverlay;
@synthesize documentImageView;
@synthesize documentName;
@synthesize document = _document;
@synthesize docCellDelegate;
@synthesize parentVC;
@synthesize downloadingIndicator;
@synthesize ebillLabel;

- (void)toggleInfoDisplay:(BOOL)hidden {
    self.documentName.hidden = hidden;
    self.documentCreatedDate.hidden = hidden;
    self.infoOverlay.hidden = hidden;
    self.document.showInfo = !hidden;
}

- (IBAction)showDocumentInfo:(UIButton *)sender {
    if ([self.parentVC tryTap]) {
        if (!self.infoOverlay) {
            self.infoOverlay = [[UIView alloc] initWithFrame:self.documentImageView.frame];
            self.infoOverlay.backgroundColor = [UIColor darkGrayColor];
            self.infoOverlay.alpha = 0.5f;
            self.infoOverlay.layer.masksToBounds = YES;
            self.infoOverlay.hidden = YES;
            [self.documentImageView addSubview:self.infoOverlay];
        }
        
        [self toggleInfoDisplay: !self.infoOverlay.hidden];
        
        [self.docCellDelegate didSelectCell:self];
    }
}

- (void)setDocument:(Document *)document {
    if (_document != document) {
        _document = document;
    }
    
    self.document.documentDelegate = self;
    self.documentImageView.image = [Document getIconForType:[[document.name pathExtension] lowercaseString] data:document.data needScale:YES];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

#pragma mark - Document Delegate

- (void)didLoadData {    
    [self.docCellDelegate didLoadData:self];
    [self.downloadingIndicator stopAnimating];
}

- (void)didGetSelected {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.documentImageView.layer.borderColor = [[UIColor orangeColor]CGColor];
        self.documentImageView.layer.borderWidth = 3.0f;
    });
}

- (void)didGetDeselected {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.documentImageView.layer.borderColor = [[UIColor clearColor]CGColor];
        self.documentImageView.layer.borderWidth = 0.0f;
    });
}

@end
