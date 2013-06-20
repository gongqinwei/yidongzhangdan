//
//  DocumentCell.m
//  BDC
//
//  Created by Qinwei Gong on 5/29/13.
//
//

#import "DocumentCell.h"
#import <QuartzCore/QuartzCore.h>


@interface DocumentCell () <DocumentDelegate>

@property (nonatomic, strong) UIView *infoOverlay;

@end


@implementation DocumentCell

@synthesize infoOverlay;
@synthesize documentImageView;
@synthesize documentName;
@synthesize document = _document;
@synthesize selectDelegate;

- (void)toggleInfoDisplay:(BOOL)hidden {
    self.documentName.hidden = hidden;
    self.documentCreatedDate.hidden = hidden;
    self.infoOverlay.hidden = hidden;
}

- (IBAction)showDocumentInfo:(UIButton *)sender {
    if (!self.infoOverlay) {
        self.infoOverlay = [[UIView alloc] initWithFrame:self.documentImageView.frame];
        self.infoOverlay.backgroundColor = [UIColor darkGrayColor];
        self.infoOverlay.alpha = 0.8f;
        self.infoOverlay.layer.masksToBounds = YES;
        self.infoOverlay.hidden = YES;
        [self.documentImageView addSubview:self.infoOverlay];
    }
    
    [self toggleInfoDisplay: !self.infoOverlay.hidden];
    
    [self.selectDelegate didSelectCell:self];
}

- (void)setDocument:(Document *)document {
    if (_document != document) {
        _document = document;
    }
    
    self.document.documentDelegate = self;
    self.documentImageView.image = [Document getIconForType:[[document.name pathExtension] lowercaseString] data:document.data];
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
    self.document = self.document;  // to reload image
}

- (void)didGetSelected {
    self.documentImageView.layer.borderColor = [[UIColor orangeColor]CGColor];
    self.documentImageView.layer.borderWidth = 3.0f;
}

- (void)didGetDeselected {
    self.documentImageView.layer.borderColor = [[UIColor clearColor]CGColor];
    self.documentImageView.layer.borderWidth = 0.0f;
}

@end