//
//  Uploader.h
//  BDC
//
//  Created by Qinwei Gong on 9/19/12.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Constants.h"

@interface Uploader : NSObject

+ (void) uploadFile:(NSString *)file data:(NSData *)data objectId:(NSString *)objId handler:(Handler)handler;

@end
