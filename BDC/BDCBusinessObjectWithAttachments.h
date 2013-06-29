//
//  BDCBusinessObjectWithAttachments.h
//  BDC
//
//  Created by Qinwei Gong on 5/20/13.
//
//

#import "BDCBusinessObject.h"
#import "Document.h"


@protocol AttachmentDelegate

@optional
- (void)didUploadDocument:(Document *)doc needUI:(BOOL)needUI;
- (void)didAttachDocument:(Document *)doc;
- (void)didDetachDocument:(Document *)doc;

@end


@interface BDCBusinessObjectWithAttachments : BDCBusinessObject

@property (nonatomic, strong) NSMutableArray *attachments;          // array of Document: used for ordering
@property (nonatomic, strong) NSMutableDictionary *attachmentDict;  // map doc id => Document: used for lookup addition/deletion
@property (nonatomic, strong) id<AttachmentDelegate> attachmentDelegate;

@end
