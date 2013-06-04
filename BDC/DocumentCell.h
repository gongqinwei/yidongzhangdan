//
//  DocumentCell.h
//  BDC
//
//  Created by Qinwei Gong on 5/29/13.
//
//

#import <UIKit/UIKit.h>
#import "Document.h"

@class DocumentCell;

@protocol DocumentCellDelegate <NSObject>

- (void)didSelectCell:(DocumentCell *)cell;

@end


@interface DocumentCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *documentImageView;
@property (weak, nonatomic) IBOutlet UILabel *documentName;
@property (weak, nonatomic) IBOutlet UILabel *documentCreatedDate;

@property (nonatomic, strong) Document *document;
@property (nonatomic, strong) id<DocumentCellDelegate> selectDelegate;

@end
