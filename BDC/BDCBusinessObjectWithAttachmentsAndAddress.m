//
//  BDCBusinessObjectWithAttachmentsAndAddress.m
//  BDC
//
//  Created by Qinwei Gong on 6/14/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "BDCBusinessObjectWithAttachmentsAndAddress.h"
#import "Constants.h"
#import "Geo.h"


@implementation BDCBusinessObjectWithAttachmentsAndAddress

@synthesize addr1;
@synthesize addr2;
@synthesize addr3;
@synthesize addr4;
@synthesize city;
@synthesize state;
@synthesize country;
@synthesize zip;
@synthesize latitude;
@synthesize longitude;
@synthesize formattedAddress;
@synthesize numOfLinesInAddr;

- (id) init {
    if (self = [super init]) {
        self.country = US_FULL_INDEX;
        self.state = [NSNumber numberWithInt:INVALID_OPTION];
        self.formattedAddress = [NSMutableString string];
    }
    return self;
}

+ (void)clone:(BDCBusinessObjectWithAttachmentsAndAddress *)source to:(BDCBusinessObjectWithAttachmentsAndAddress *)target {
    [super clone:source to:target];
    
    target.addr1 = source.addr1;
    target.addr2 = source.addr2;
    target.addr3 = source.addr3;
    target.addr4 = source.addr4;
    target.city = source.city;
    target.state = source.state;
    target.country = source.country;
    target.zip = source.zip;
    target.latitude = source.latitude;
    target.longitude = source.longitude;
    target.formattedAddress = source.formattedAddress;
    target.numOfLinesInAddr = source.numOfLinesInAddr;
}

- (int)formatAddress:(NSMutableString *)addr {
    [addr setString:@""]; // reset
    self.numOfLinesInAddr = 0;
    BOOL hasCity = NO;
    BOOL hasState = NO;
    BOOL hasZip = NO;
    
    if (self.addr1 && self.addr1.length) {
        self.numOfLinesInAddr++;
        [addr appendFormat:@"%@\n", self.addr1];
    }
    if (self.addr2 && self.addr2.length) {
        self.numOfLinesInAddr++;
        [addr appendFormat:@"%@\n", self.addr2];
    }
    if (self.addr3 && self.addr3.length) {
        self.numOfLinesInAddr++;
        [addr appendFormat:@"%@\n", self.addr3];
    }
    if (self.addr4 && self.addr4.length) {
        self.numOfLinesInAddr++;
        [addr appendFormat:@"%@\n", self.addr4];
    }
    if (self.city && self.city.length) {
        hasCity = YES;
        [addr appendFormat:@"%@", self.city];
    }
    if (self.state) {
        NSString *stateStr;
        if ([self.state isKindOfClass:[NSNumber class]]) {
            if ([self.state intValue] != INVALID_OPTION && [self.state intValue] < [US_STATE_CODES count]) {
                hasState = YES;
                stateStr = [US_STATE_CODES objectAtIndex:[self.state intValue]];
            }
        } else {
            hasState = YES;
            stateStr = self.state;
        }
        
        if (hasState) {
            if (hasCity) {
                [addr appendFormat:@", %@ ", stateStr];
            } else {
                [addr appendFormat:@"%@ ", stateStr];
            }
        }
    }
    if (self.zip && self.zip.length) {
        hasZip = YES;
        [addr appendFormat:@"%@", self.zip];
    }
    if (hasCity || hasState || hasZip) {
        [addr appendString:@"\n"];
        self.numOfLinesInAddr++;
    }
    if (self.country != INVALID_OPTION && self.country < [COUNTRIES count]) {
        self.numOfLinesInAddr++;
        [addr appendFormat:@"%@ ", [COUNTRIES objectAtIndex: self.country]];
    }

    if (self.numOfLinesInAddr == 0) {
        self.numOfLinesInAddr++;
    }
    
    return self.numOfLinesInAddr;
}

- (void)populateObjectWithInfo:(NSDictionary *)dict {
    [self formatAddress:self.formattedAddress];
    
    /*** Not using CLGeocoder because of its inaccuracy  ***/
    //    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    //    [geocoder geocodeAddressString:self.formattedAddress completionHandler:^(NSArray *placemarks, NSError *error) {
    //        for (CLPlacemark *placemark in placemarks) {
    //            self.latitude = placemark.location.coordinate.latitude;
    //            self.longitude = placemark.location.coordinate.longitude;
    //            break;
    //        }
    //    }];
    
    /*** Using Google Maps API instead ***/
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//        [self geoCodeUsingAddress:self.formattedAddress];
//    });
}

- (void)geoCodeUsingAddress:(NSString *)address {
    double lat = 0.0, lon = 0.0;

    NSString *esc_addr =  [address stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *req = [NSString stringWithFormat:GOOGLE_MAP_API, esc_addr];
    NSString *result = [NSString stringWithContentsOfURL:[NSURL URLWithString:req] encoding:NSUTF8StringEncoding error:NULL];
    if (result) {
        NSScanner *scanner = [NSScanner scannerWithString:result];
        if ([scanner scanUpToString:GOOGLE_MAP_LAT intoString:nil] && [scanner scanString:GOOGLE_MAP_LAT intoString:nil]) {
            [scanner scanDouble:&lat];
            if ([scanner scanUpToString:GOOGLE_MAP_LON intoString:nil] && [scanner scanString:GOOGLE_MAP_LON intoString:nil]) {
                [scanner scanDouble:&lon];
            }
        }
    }
    
    self.latitude = lat;
    self.longitude = lon;
}

#pragma mark - MKAnnotation

- (NSString *)title
{
    return self.name;
}

//- (NSString *)subtitle
//{
//    return self.name;
//}

- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = self.latitude;
    coordinate.longitude = self.longitude;
    return coordinate;
}

@end
