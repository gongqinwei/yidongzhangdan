//
//  BDCBusinessObjectWithAttachments.m
//  BDC
//
//  Created by Qinwei Gong on 5/20/13.
//
//

#import "BDCBusinessObjectWithAttachments.h"
#import "Document.h"

@implementation BDCBusinessObjectWithAttachments

@synthesize attachments;
@synthesize attachmentDict;

- (id)init {
    if (self = [super init]) {
        self.attachments = [NSMutableArray array];
        self.attachmentDict = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (void)clone:(BDCBusinessObjectWithAttachments *)source to:(BDCBusinessObjectWithAttachments *)target {
    [super clone:source to:target];
    
    if (source.attachments != nil) {
        target.attachments = nil;
        target.attachments = [NSMutableArray array];
        target.attachmentDict = nil;
        target.attachmentDict = [NSMutableDictionary dictionary];
        
        for (Document *doc in source.attachments) {
            [target.attachments addObject:doc];
            if (doc.objectId) {
                [target.attachmentDict setObject:doc forKey:doc.objectId];
            }
        }
    }
}

@end
