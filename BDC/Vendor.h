//
//  Vendor.h
//  BDC
//
//  Created by Qinwei Gong on 4/24/13.
//
//

#import "BDCBusinessObject.h"
#import "SlidingDetailsTableViewController.h"
#import "SlidingListTableViewController.h"

typedef enum {
    kCheck,
    kAch,
    kRpps
} VendorPaymentType;

#define VENDOR            @"Vendor"
#define VENDOR_NAME       @"name"
#define VENDOR_ADDR1      @"address1"
#define VENDOR_ADDR2      @"address2"
#define VENDOR_ADDR3      @"address3"
#define VENDOR_ADDR4      @"address4"
#define VENDOR_CITY       @"addressCity"
#define VENDOR_STATE      @"addressState"
#define VENDOR_COUNTRY    @"addressCountry"
#define VENDOR_ZIP        @"addressZip"
#define VENDOR_EMAIL      @"email"
#define VENDOR_PHONE      @"phone"
#define VENDOR_PAYBY      @"payBy"

#define VendorPaymentTypes  [NSArray arrayWithObjects:[NSNumber numberWithInt:kCheck], [NSNumber numberWithInt:kAch], [NSNumber numberWithInt:kRpps], nil]

@protocol VendorDelegate <DetailsViewDelegate>
@optional
- (void)didCreateVendor:(NSString *)newVendorId;
@end

@protocol VendorListDelegate <ListViewDelegate>
@optional
- (void)didGetVendors;
- (void)failedToGetVendors;
@end

@interface Vendor : BDCBusinessObject

@property (nonatomic, strong) NSString *addr1;
@property (nonatomic, strong) NSString *addr2;
@property (nonatomic, strong) NSString *addr3;
@property (nonatomic, strong) NSString *addr4;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) id state;
@property (nonatomic, assign) int country;
@property (nonatomic, strong) NSString *zip;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *payBy;

@property (nonatomic, weak) id<VendorDelegate> editDelegate;
@property (nonatomic, weak) id<VendorDelegate> editBillDelegate;

+ (void)setListDelegate:(id<VendorListDelegate>)listDelegate;

+ (Vendor *)objectForKey:(NSString *)vendorId;

@end
