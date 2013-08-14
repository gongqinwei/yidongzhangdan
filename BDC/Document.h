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

#define EBILL                       @"eBill"
#define EBILL_EVENT                 @"event"
#define EBILL_EVENT_TYPE            @"type"
#define EBILL_PAYLOAD               @"payload"
#define EBILL_BO                    @"bo"
#define EBILL_INV_ORG_NAME          @"invoicingOrgName"
#define EBILL_CUSTOMER              @"customer"
#define EBILL_NET_VENDOR_ID         @"netVendorId"
#define EBILL_AMOUNT_DUE            @"amountDue"

#define EBILL_SEND_INVOICE_TYPE     @"SEND_INVOICE"

//#define EBILL_INV_NUM               @"invNum"
//#define EBILL_INV_DATE              @"invDate"
//#define EBILL_DUE_DATE              @"dueDate"
//#define EBILL_AMOUNT                @"amount"
//#define EBILL_VENDOR                @"vendorName"


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

@class Bill;

@interface Document : BDCBusinessObject

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSData *thumbnail;
@property (nonatomic, strong) NSString *fileUrl;
@property (nonatomic, assign) BOOL isPublic;
@property (nonatomic, assign) NSInteger page;
@property (nonatomic, strong) NSString *associatedTo;
@property (nonatomic, strong) NSDate *createdDate;
@property (nonatomic, strong) id<DocumentDelegate> documentDelegate;

@property (nonatomic, strong) Bill *eBill;
@property (nonatomic, strong) NSString *eBillVendorOrgName;

@property (nonatomic, assign) BOOL showInfo;    //used in Inbox View

//@property (nonatomic, strong) NSString *invNum;
//@property (nonatomic, strong) NSDate *invDate;
//@property (nonatomic, strong) NSDate *dueDate;
//@property (nonatomic, strong) NSDecimalNumber *amount;
//@property (nonatomic, strong) NSString *vendor;

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
+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;

@end
