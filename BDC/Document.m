//
//  Document.m
//  BDC
//
//  Created by Qinwei Gong on 5/14/13.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import "Document.h"
#import "BDCAppDelegate.h"
#import "APIHandler.h"
#import "UIHelper.h"
#import "Util.h"
#import "Bill.h"
#import "APLineItem.h"

#define COMPRESSION_THRESHOLD       500000
#define DOCUMENT_PREFIX             @"00h"
#define ATTACHMENT_PREFIX           @"att"


static NSMutableArray *documents = nil;
static NSMutableArray *attachments = nil;
static id <DocumentListDelegate> DocumentListDelegate = nil;
static id <DocumentListDelegate> AttachmentListDelegate = nil;
static NSLock *DocumentsLock = nil;

@implementation Document

@synthesize data = _data;
@synthesize thumbnail = _thumbnail;
@synthesize fileUrl;
@synthesize isPublic;
//@synthesize page;
@synthesize associatedTo;
@synthesize createdDate;
@synthesize documentDelegate;

@synthesize showInfo;
@synthesize eBill;

//@synthesize invNum;
//@synthesize invDate;
//@synthesize dueDate;
//@synthesize amount;
//@synthesize vendor;


+ (void)resetList {
    documents = [NSMutableArray array];
    attachments = [NSMutableArray array];
}

- (id)copyWithZone:(NSZone *)zone {
    Document *doc = [super copyWithZone:zone];
    doc.data = self.data;
    doc.fileUrl = self.fileUrl;
    doc.isPublic = self.isPublic;
//    doc.page = self.page;
    doc.associatedTo = self.associatedTo;
    doc.createdDate = self.createdDate;
    doc.documentDelegate = self.documentDelegate;
    
    return doc;
}

- (DocType)getDocType {
    if ([self.objectId hasPrefix:DOCUMENT_PREFIX]) {
        return kDocument;
    } else {
        return kAttachment;
    }
}

- (void)setData:(NSData *)data {
    if (data) {
        if ([self isImageOrPDF]) {
            int size = data.length;
            if (size > COMPRESSION_THRESHOLD) {
                UIImage *img = [UIImage imageWithData:data];
                data = UIImageJPEGRepresentation(img, COMPRESSION_THRESHOLD / size);
                img = nil;
            }
        }
    }
    
    _data = data;
    
    [self.documentDelegate didLoadData];
}

//private
- (NSString *)filePath {
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    return [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:self.name]];
}

- (NSString *)getDocFilePath {
    NSString *filePath = [self filePath];
    
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    
    if (!exists && self.data) {
        [self.data writeToFile:filePath atomically:YES];
    }
    
    return filePath;
}

- (BOOL)docFileExists {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self filePath]];
}

- (void)writeToFile {
    NSString *filePath = [self filePath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    
    [self.data writeToFile:filePath atomically:YES];
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
//        Debug(@"%@", jsonDocs);
        
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
                
                NSDictionary *jsonEBill = [dict objectForKey:EBILL];
                if (jsonEBill) {
                    NSDictionary *jsonEventBag = [jsonEBill objectForKey:EBILL_EVENT];
                    NSString *eventType = [jsonEventBag objectForKey:EBILL_EVENT_TYPE];
                    
                    if ([eventType isEqualToString:EBILL_SEND_INVOICE_TYPE]) {
                        doc.eBill = [[Bill alloc] init];
                        
                        NSDictionary *jsonPayload = [jsonEventBag objectForKey:EBILL_PAYLOAD];
                        NSDictionary *jsonBO = [jsonPayload objectForKey:EBILL_BO];
                        
                        doc.eBill.invoiceNumber = [jsonBO objectForKey:BILL_NUMBER];
                        doc.eBill.invoiceDate = [Util getDate:[jsonBO objectForKey:BILL_DATE] format:@"MM/dd/yy"];
                        doc.eBill.dueDate = [Util getDate:[jsonBO objectForKey:BILL_DUE_DATE] format:@"MM/dd/yy"];
                        doc.eBill.vendorId = [[jsonBO objectForKey:EBILL_CUSTOMER] objectForKey:EBILL_NET_VENDOR_ID];                        
                        doc.eBillVendorOrgName = [jsonBO objectForKey:EBILL_INV_ORG_NAME];
                        
                        doc.eBill.amount = [Util id2Decimal:[jsonBO objectForKey:BILL_AMOUNT]];
                        NSDecimalNumber *amountDue = [Util id2Decimal:[jsonBO objectForKey:EBILL_AMOUNT_DUE]];
                        doc.eBill.paidAmount = [doc.eBill.amount decimalNumberBySubtracting:amountDue];
                        
                        APLineItem *item = [[APLineItem alloc] init];
                        item.amount = doc.eBill.amount;
                        [doc.eBill.lineItems addObject:item];
                    }
                }
                
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
            Debug(@"Time out when retrieving list of documents!");
        } else {
            if ([category isEqualToString:FILE_CATEGORY_ATTACHMENT]) {
                [AttachmentListDelegate failedToGetDocuments];
            } else if ([category isEqualToString:FILE_CATEGORY_DOCUMENT]) {
                [DocumentListDelegate failedToGetDocuments];
            }
            [UIHelper showInfo:[NSString stringWithFormat:@"Failed to retrieve list of %@! %@", category, [err localizedDescription]] withStatus:kFailure];
            Debug(@"Failed to retrieve list of %@! %@", category, [err localizedDescription]);
        }
    }];
}

+ (UIImage *)getIconForType:(NSString *)ext data:(NSData *)attachmentData needScale:(BOOL)needScale {
    UIImage *image;
    
    if (attachmentData && ([IMAGE_TYPE_SET containsObject:ext] || [ext isEqualToString:@"pdf"])) {
        UIImage * tmpImg = [UIImage imageWithData:attachmentData];
        if (!needScale) {
            image = tmpImg;
        } else {
            image = [Document imageWithImage:tmpImg scaledToSize:CGSizeMake(DOCUMENT_CELL_DIMENTION, DOCUMENT_CELL_DIMENTION)];
        }
    } else {
        NSString *iconFileName = [NSString stringWithFormat:@"%@_icon.png", ext];
        image = [UIImage imageNamed:iconFileName];
        
        if (!image) {
            image = [UIImage imageNamed:@"unknown_file_icon.png"];
        }
    }
    
    return image;
}

+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContext(newSize);
    CGRect rect = {CGPointMake(0, 0), newSize};
    [image drawInRect:rect];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    image = nil;
    
    return newImage;
}

- (BOOL)isImage {
    NSString *ext = [[self.name pathExtension] lowercaseString];
    return [IMAGE_TYPE_SET containsObject:ext];
}

- (BOOL)isImageOrPDF {
    NSString *ext = [[self.name pathExtension] lowercaseString];
    return [IMAGE_TYPE_SET containsObject:ext] || [ext isEqualToString:@"pdf"];
}

@end
