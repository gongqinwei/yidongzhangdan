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


static NSMutableArray *documents = nil;
static NSMutableArray *attachments = nil;
static id <DocumentListDelegate> DocumentListDelegate = nil;
static id <DocumentListDelegate> AttachmentListDelegate = nil;

@implementation Document

@synthesize data = _data;
@synthesize fileUrl;
@synthesize isPublic;
@synthesize page;
@synthesize associatedTo;
@synthesize createdDate;
@synthesize documentDelegate;

- (void)setData:(NSData *)data {
    _data = data;
    [self.documentDelegate didLoadData];
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
                doc.name = [dict objectForKey:@"fileName"];
                doc.fileUrl = [dict objectForKey:@"fileUrl"];
                doc.createdDate = [Util getDate:[[dict objectForKey:@"createdDate"] substringToIndex:10] format:nil];
                
                if ([category isEqualToString:FILE_CATEGORY_ATTACHMENT]) {
                    doc.associatedTo = [dict objectForKey:@"busObject"];
                    doc.isPublic = [[dict objectForKey:@"isPublic"] intValue];
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
