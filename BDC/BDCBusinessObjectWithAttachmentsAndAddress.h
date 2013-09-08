//
//  BDCBusinessObjectWithAttachmentsAndAddress.h
//  BDC
//
//  Created by Qinwei Gong on 6/14/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "BDCBusinessObjectWithAttachments.h"

@interface BDCBusinessObjectWithAttachmentsAndAddress : BDCBusinessObjectWithAttachments

@property (nonatomic, strong) NSString *addr1;
@property (nonatomic, strong) NSString *addr2;
@property (nonatomic, strong) NSString *addr3;
@property (nonatomic, strong) NSString *addr4;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) id state;
@property (nonatomic, assign) int country;
@property (nonatomic, strong) NSString *zip;

- (int)formatAddress:(NSMutableString *)addr;

@end
