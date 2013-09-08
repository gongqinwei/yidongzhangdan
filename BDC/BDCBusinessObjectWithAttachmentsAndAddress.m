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


- (id) init {
    if (self = [super init]) {
        self.country = US_FULL_INDEX;
        self.state = [NSNumber numberWithInt:INVALID_OPTION];
    }
    return self;
}

- (int)formatAddress:(NSMutableString *)addr {
    int numOfLines = 0;
    BOOL hasCity = NO;
    BOOL hasState = NO;
    BOOL hasZip = NO;
    
    if (self.addr1 && self.addr1.length) {
        numOfLines++;
        [addr appendFormat:@"%@\n", self.addr1];
    }
    if (self.addr2 && self.addr2.length) {
        numOfLines++;
        [addr appendFormat:@"%@\n", self.addr2];
    }
    if (self.addr3 && self.addr3.length) {
        numOfLines++;
        [addr appendFormat:@"%@\n", self.addr3];
    }
    if (self.addr4 && self.addr4.length) {
        numOfLines++;
        [addr appendFormat:@"%@\n", self.addr4];
    }
    if (self.city && self.city.length) {
        hasCity = YES;
        [addr appendFormat:@"%@", self.city];
    }
    if (self.state) {
        NSString *stateStr;
        if ([self.state isKindOfClass:[NSNumber class]]) {
            if ([self.state intValue] != INVALID_OPTION) {
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
        numOfLines++;
    }
    if (self.country != INVALID_OPTION) {
        numOfLines++;
        [addr appendFormat:@"%@ ", [COUNTRIES objectAtIndex: self.country]];
    }

    if (numOfLines == 0) {
        numOfLines++;
    }

    return numOfLines;
}

@end
