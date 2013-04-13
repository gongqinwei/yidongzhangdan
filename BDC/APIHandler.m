//
//  APIHandler.m
//  BDC
//
//  Created by Qinwei Gong on 7/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "APIHandler.h"
#import "Constants.h"

@implementation APIHandler

+ (void) asyncCallWithAction:(NSString*)action Info:(NSDictionary*)info AndHandler:(Handler)handler {
    NSString *urlStr = [NSString stringWithFormat:@"%@/%@/%@", DOMAIN_URL, API_BASE, action];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:API_TIMEOUT];
    NSLog(@"url: %@", urlStr);
    
    [req setHTTPMethod:@"POST"];
    
    NSMutableString *params = [NSMutableString string];
    [params appendFormat:@"%@=%@", APP_KEY, APP_KEY_VALUE];
    
    // info's dictionary entry stores url param as value=>key to handle multiple param with same key
    for(NSString *value in info) {
        NSString *key = [info objectForKey:value];
        if ([params length] > 0) {
            [params appendString:@"&"];
        }
        [params appendFormat:@"%@=%@", key, value];
    }
    
    NSLog(@"params: %@", params);
    [req setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
    
    [NSURLConnection sendAsynchronousRequest:req queue:[[NSOperationQueue alloc] init] completionHandler:handler];
}

+ (void) asyncCallWithRequest:(NSMutableURLRequest*)req AndHandler:(Handler)handler {
    [NSURLConnection sendAsynchronousRequest:req queue:[[NSOperationQueue alloc] init] completionHandler:handler];
}

+ (id) getResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError **) err status:(NSInteger *)status {
    NSArray *result = nil;
    if (err && *err) {
        if ([*err code] == -1001 ) {
            *status = RESPONSE_TIMEOUT;
        } else if (data == nil) {
            *status = RESPONSE_FALURE;
        }
    } else {
        NSError *error;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        
        *status = [[json objectForKey:RESPONSE_STATUS_KEY] intValue];
        
        if(*status == RESPONSE_SUCCESS) {
            result = [json objectForKey:RESPONSE_DATA_KEY];
        } else {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:[[json objectForKey:RESPONSE_DATA_KEY] objectForKey:RESPONSE_ERROR_MSG] forKey:NSLocalizedDescriptionKey];
            
            *err = [NSError errorWithDomain:ERR_DOMAIN code:[[[json objectForKey:RESPONSE_DATA_KEY] objectForKey:RESPONSE_ERROR_CODE] intValue] userInfo:details];
        }
    }
    
    return result;
}
    
@end
