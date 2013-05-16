//
//  Document.h
//  BDC
//
//  Created by Qinwei Gong on 5/14/13.
//
//

#import "BDCBusinessObject.h"
#import "Constants.h"

@interface Document : BDCBusinessObject

@property (nonatomic, strong) NSData *data;
@property (nonatomic, assign) FileType type;
@property (nonatomic, strong) NSString *attachedTo;

@end
