//
//  Document.h
//  BDC
//
//  Created by Qinwei Gong on 5/14/13.
//
//

#import "BDCBusinessObject.h"
#import "Constants.h"

#define FILE_CATEGORY               @"category"
#define FILE_CATEGORY_DOCUMENT      @"document"
#define FILE_CATEGORY_ATTACHMENT    @"attachment"

#define FILE_NAME                   @"fileName"
#define FILE_URL                    @"fileUrl"
#define FILE_CREATED_DATE           @"createdDate"
#define FILE_OWNER                  @"busObject"
#define FILE_IS_PUBLIC              @"isPublic"
#define FILE_PAGE_NUM               @"page"


@protocol DocumentDelegate <NSObject>

@optional
- (void)didLoadData;
- (void)didGetSelected;
- (void)didGetDeselected;

@end


@class Document;

@protocol DocumentListDelegate

@optional
- (void)didGetDocuments;
- (void)didAddDocument:(Document *)doc;
- (void)failedToGetDocuments;

@end


@interface Document : BDCBusinessObject

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSData *thumbnail;
@property (nonatomic, strong) NSString *fileUrl;
@property (nonatomic, assign) BOOL isPublic;
@property (nonatomic, assign) NSInteger page;
@property (nonatomic, strong) NSString *associatedTo;
@property (nonatomic, strong) NSDate *createdDate;
@property (nonatomic, strong) id<DocumentDelegate> documentDelegate;

- (NSString *)getDocFilePath;
- (BOOL)docFileExists;
- (void)writeToFile;

+ (void)setDocumentListDelegate:(id<DocumentListDelegate>)listDelegate;
+ (void)setAttachmentListDelegate:(id<DocumentListDelegate>)listDelegate;

+ (NSMutableArray *)listForCategory:(NSString *)category;
+ (void)retrieveListForCategory:(NSString *)category;
+ (void)addToInbox:(Document *)doc;
+ (void)removeFromInbox:(Document *)doc;

+ (UIImage *)getIconForType:(NSString *)ext data:(NSData *)attachmentData needScale:(BOOL)needScale;

@end
