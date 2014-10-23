//
//  BDCBusinessObjectWithAttachmentsAndAddress.h
//  BDC
//
//  Created by Qinwei Gong on 6/14/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "BDCBusinessObjectWithAttachments.h"
#import <MapKit/MapKit.h>

@interface BDCBusinessObjectWithAttachmentsAndAddress : BDCBusinessObjectWithAttachments <MKAnnotation>

@property (nonatomic, strong) NSString *addr1;
@property (nonatomic, strong) NSString *addr2;
@property (nonatomic, strong) NSString *addr3;
@property (nonatomic, strong) NSString *addr4;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) id state;
@property (nonatomic, assign) NSUInteger country;
@property (nonatomic, strong) NSString *zip;
@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@property (nonatomic, strong) NSMutableString *formattedAddress;
@property (nonatomic, assign) int numOfLinesInAddr;

@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *phone;
//@property (nonatomic, strong) NSString *altPhone;
//@property (nonatomic, strong) NSString *fax;

- (int)formatAddress:(NSMutableString *)addr;
- (void) geoCodeUsingAddress:(NSString *)address;

- (void)createAndInvite;

@end
