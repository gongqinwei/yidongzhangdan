//
//  Document.m
//  BDC
//
//  Created by Qinwei Gong on 5/14/13.
//
//

#import "Document.h"
#import "BDCAppDelegate.h"
#import "APIHandler.h"
#import "UIHelper.h"
#import "Util.h"

#define COMPRESSION_THRESHOLD       100000


static NSMutableArray *documents = nil;
static NSMutableArray *attachments = nil;
static id <DocumentListDelegate> DocumentListDelegate = nil;
static id <DocumentListDelegate> AttachmentListDelegate = nil;
static NSLock *DocumentsLock = nil;

@implementation Document

@synthesize data = _data;
@synthesize fileUrl;
@synthesize isPublic;
@synthesize page;
@synthesize associatedTo;
@synthesize createdDate;
@synthesize documentDelegate;


- (id)copyWithZone:(NSZone *)zone {
    Document *doc = [super copyWithZone:zone];
    doc.data = self.data;
    doc.fileUrl = self.fileUrl;
    doc.isPublic = self.isPublic;
    doc.page = self.page;
    doc.associatedTo = self.associatedTo;
    doc.createdDate = self.createdDate;
    doc.documentDelegate = self.documentDelegate;
    
    return doc;
}

- (void)setData:(NSData *)data {
    if (data) {
        NSString *ext = [[self.name pathExtension] lowercaseString];
        if ([IMAGE_TYPE_SET containsObject:ext]) {
            int size = data.length;
            if (size > COMPRESSION_THRESHOLD) {
                UIImage *img = [UIImage imageWithData:data];
                data = UIImageJPEGRepresentation(img, COMPRESSION_THRESHOLD / size / 10);
            }
        }        
    }
    
    _data = data;
    
    NSLog(@"=== document delegate: %@", self.documentDelegate);
    [self.documentDelegate didLoadData];
}

+ (void)initialize {
    DocumentsLock = [[NSLock alloc] init];
}

+ (void)setDocumentListDelegate:(id<DocumentListDelegate>)theDelegate {
    DocumentListDelegate = theDelegate;
}

+ (void)setAttachmentListDelegate:(id<DocumentListDelegate>)theDelegate {
    AttachmentListDelegate = theDelegate;
}

+ (NSMutableArray *)listForCategory:(NSString *)category {
    if ([category isEqualToString:FILE_CATEGORY_ATTACHMENT]) {
        return attachments;
    } else if ([category isEqualToString:FILE_CATEGORY_DOCUMENT]) {
        return documents;
    }
    
    return nil;
}

+ (void)addToInbox:(Document *)doc {
    [DocumentsLock lock];
    [documents insertObject:doc atIndex:0];
    [DocumentListDelegate didAddDocument:doc];
    [DocumentsLock unlock];
}

+ (void)removeFromInbox:(Document *)doc {
    [DocumentsLock lock];
    [documents removeObject:doc];
    [DocumentListDelegate didGetDocuments];
    [DocumentsLock unlock];
}

+ (void)retrieveListForCategory:(NSString *)category {
    [UIAppDelegate incrNetworkActivities];
    
    NSString *str = [NSString stringWithFormat:@"{\"%@\" : \"%@\"}", FILE_CATEGORY, category];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA, str, nil];
    
    [APIHandler asyncCallWithAction:RETRIEVE_DOCS_API Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSArray *jsonDocs = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        [UIAppDelegate decrNetworkActivities];
        
        if(response_status == RESPONSE_SUCCESS) {
            if ([category isEqualToString:FILE_CATEGORY_ATTACHMENT]) {
                if (attachments) {
                    [attachments removeAllObjects];
                } else {
                    attachments = [NSMutableArray array];
                }
            } else if ([category isEqualToString:FILE_CATEGORY_DOCUMENT]) {
                if (documents) {
                    [documents removeAllObjects];
                } else {
                    documents = [NSMutableArray array];
                }
            }
            
            for (NSDictionary *dict in jsonDocs) {
                Document *doc = [[Document alloc] init];
                doc.objectId = [dict objectForKey:ID];
                doc.name = [dict objectForKey:FILE_NAME];
                doc.fileUrl = [dict objectForKey:FILE_URL];
                doc.createdDate = [Util getDate:[dict objectForKey:FILE_CREATED_DATE] format:@"MM/dd/yy hh:mm a"];
                
                if ([category isEqualToString:FILE_CATEGORY_ATTACHMENT]) {
                    doc.associatedTo = [dict objectForKey:FILE_OWNER];
                    doc.isPublic = [[dict objectForKey:FILE_IS_PUBLIC] intValue];
                    [attachments addObject:doc];
                } else if ([category isEqualToString:FILE_CATEGORY_DOCUMENT]) {
                    [documents addObject:doc];
                }
            }
            
            if ([category isEqualToString:FILE_CATEGORY_ATTACHMENT]) {
                [AttachmentListDelegate didGetDocuments];
            } else if ([category isEqualToString:FILE_CATEGORY_DOCUMENT]) {
                [DocumentListDelegate didGetDocuments];
            }
        } else if (response_status == RESPONSE_TIMEOUT) {
            if ([category isEqualToString:FILE_CATEGORY_ATTACHMENT]) {
                [AttachmentListDelegate failedToGetDocuments];
            } else if ([category isEqualToString:FILE_CATEGORY_DOCUMENT]) {
                [DocumentListDelegate failedToGetDocuments];
            }
            [UIHelper showInfo:SysTimeOut withStatus:kError];
            NSLog(@"Time out when retrieving list of documents!");
        } else {
            if ([category isEqualToString:FILE_CATEGORY_ATTACHMENT]) {
                [AttachmentListDelegate failedToGetDocuments];
            } else if ([category isEqualToString:FILE_CATEGORY_DOCUMENT]) {
                [DocumentListDelegate failedToGetDocuments];
            }
            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
            NSLog(@"Failed to retrieve list of %@! %@", category, [err localizedDescription]);
        }
    }];
}

+ (UIImage *)getIconForType:(NSString *)ext data:(NSData *)attachmentData {
    UIImage *image;
    
    if (attachmentData && [IMAGE_TYPE_SET containsObject:ext]) {
        image = [UIImage imageWithData:attachmentData];
    } else {
        NSString *iconFileName = [NSString stringWithFormat:@"%@_icon.png", ext];
        image = [UIImage imageNamed:iconFileName];
        
        if (!image) {
            image = [UIImage imageNamed:@"unknown_file_icon.png"];
        }
    }
    
    return image;
}

@end
