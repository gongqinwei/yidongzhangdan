//
//  BDCBusinessObjectWithAttachments.h
//  BDC
//
//  Created by Qinwei Gong on 5/20/13.
//
//

#import "BDCBusinessObject.h"

@interface BDCBusinessObjectWithAttachments : BDCBusinessObject

@property (nonatomic, strong) NSMutableArray *attachments;          // array of Document: used for ordering
@property (nonatomic, strong) NSMutableDictionary *attachmentDict;  // map doc id => Document: used for lookup addition/deletion

@end
