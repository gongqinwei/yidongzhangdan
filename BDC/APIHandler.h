//
//  APIHandler.h
//  BDC
//
//  Created by Qinwei Gong on 7/2/12.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import "Constants.h"

@interface APIHandler : NSObject

+ (void) asyncCallWithAction:(NSString*)action Info:(NSDictionary*)info AndHandler:(Handler)handler;
+ (void) asyncGetCallWithAction:(NSString*)action Info:(NSDictionary*)info AndHandler:(Handler)handler;
+ (void) asyncCallWithRequest:(NSMutableURLRequest*)req AndHandler:(Handler)handler;

+ (id) getResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError **) err status:(NSInteger *)status;

@end
