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
@property (nonatomic, strong) NSString *fileUrl;
@property (nonatomic, assign) BOOL isPublic;
@property (nonatomic, assign) NSInteger page;

@end
