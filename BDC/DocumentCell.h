//
//  DocumentCell.h
//  BDC
//
//  Created by Qinwei Gong on 5/29/13.
//
//

#import <UIKit/UIKit.h>
#import "Document.h"
#import "SlidingCollectionViewController.h"

@class DocumentCell;

@protocol DocumentCellDelegate <NSObject>

- (void)didSelectCell:(DocumentCell *)cell;
- (void)didLoadData:(DocumentCell *)cell;

@end


@interface DocumentCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *documentImageView;
@property (weak, nonatomic) IBOutlet UILabel *documentName;
@property (weak, nonatomic) IBOutlet UILabel *documentCreatedDate;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *downloadingIndicator;

@property (nonatomic, strong) Document *document;
@property (nonatomic, strong) SlidingCollectionViewController *parentVC;
@property (nonatomic, strong) id<DocumentCellDelegate> docCellDelegate;

- (void)toggleInfoDisplay:(BOOL)show;


@end
