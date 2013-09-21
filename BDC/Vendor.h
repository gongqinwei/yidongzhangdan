//
//  Vendor.h
//  BDC
//
//  Created by Qinwei Gong on 4/24/13.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import "BDCBusinessObjectWithAttachmentsAndAddress.h"
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


@protocol VendorListDelegate <ListViewDelegate>
@optional
- (void)didGetVendors;
- (void)failedToGetVendors;
@end

@interface Vendor : BDCBusinessObjectWithAttachmentsAndAddress

@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *payBy;

@property (nonatomic, weak) id<BusObjectDelegate> editBillDelegate;

+ (void)setListDelegate:(id<VendorListDelegate>)listDelegate;

+ (Vendor *)objectForKey:(NSString *)vendorId;

@end
