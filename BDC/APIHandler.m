//
//  APIHandler.m
//  BDC
//
//  Created by Qinwei Gong on 7/2/12.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import "APIHandler.h"
#import "Constants.h"
#import "RootMenuViewController.h"
#import "UIHelper.h"
#import "Util.h"
#import "BDCAppDelegate.h"

static Handler sessionValidatingHandler = nil;

@implementation APIHandler

+ (void) asyncGetCallWithAction:(NSString*)action Info:(NSDictionary*)info NeedSession:(BOOL)needSession AndHandler:(Handler)handler {
    [UIAppDelegate incrNetworkActivities];
    
    NSMutableString *urlStr = [NSMutableString string];
    [urlStr appendFormat:@"%@/%@/%@", DOMAIN_URL, API_BASE, action];
    
    if (needSession) {
        [urlStr appendFormat:@"?%@=%@", SESSION_ID_KEY, [Util getSession]];
    }
    
    // info's dictionary entry stores url param as value=>key to handle multiple param with same key
    for(NSString *value in info) {
        if (value) {
            NSString *key = [info objectForKey:value];
            [urlStr appendFormat:@"&%@=%@", key, value];
        }
    }
    
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:API_TIMEOUT];
    Debug(@"url: %@", urlStr);
    
    [req setHTTPMethod:HTTP_GET];
    
    sessionValidatingHandler = ^(NSURLResponse * response, NSData * data, NSError * err) {
        [UIAppDelegate decrNetworkActivities];
        
        NSInteger response_status;
        NSDictionary *json = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_FALURE) {
            NSString *errCode = [json objectForKey:RESPONSE_ERROR_CODE];
            if ([INVALID_SESSION isEqualToString:errCode]) {
                NSMutableDictionary *signInInfo = [NSMutableDictionary dictionary];
                [signInInfo setObject:ORG_ID forKey:[Util getSelectedOrgId]];
                [signInInfo setObject:USERNAME forKey:[Util getUsername]];
                [signInInfo setObject:PASSWORD forKey:[Util getPassword]];
                
                [APIHandler asyncCallWithAction:LOGIN_API Info:signInInfo AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
                    NSInteger status;
                    NSDictionary *responseData = [APIHandler getResponse:response data:data error:&err status:&status];
                    
                    if (status == RESPONSE_SUCCESS) {
                        // set cookie for session id
                        NSString *sessionId = [responseData objectForKey:SESSION_ID_KEY];
                        [Util setSession:sessionId];
                        NSString *usersId = [responseData objectForKey:USER_ID];
                        [Util setUserId:usersId];
                        
                        [APIHandler asyncCallWithAction:action Info:info AndHandler:handler];
                    } else {
                        //                        [UIHelper showInfo:@"Session timed out! Please sign in again." withStatus:kInfo];
                        [[RootMenuViewController sharedInstance] performSegueWithIdentifier:MENU_LOGOUT sender:self];
                    }
                }];
                
                return;
            }
        }
        
        handler(response, data, err);
    };
    
    [NSURLConnection sendAsynchronousRequest:req queue:[[NSOperationQueue alloc] init] completionHandler:sessionValidatingHandler];
}

+ (void) asyncGetCallWithAction:(NSString*)action Info:(NSDictionary*)info AndHandler:(Handler)handler {
    [APIHandler asyncGetCallWithAction:action Info:info NeedSession:YES AndHandler:handler];
}


+ (void) asyncCallWithAction:(NSString*)action Info:(NSDictionary*)info AndHandler:(Handler)handler {
    [UIAppDelegate incrNetworkActivities];
    
    NSString *urlStr = [NSString stringWithFormat:@"%@/%@/%@", DOMAIN_URL, API_BASE, action];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:API_TIMEOUT];
    Debug(@"url: %@", urlStr);
    
    [req setHTTPMethod:HTTP_POST];
    
    NSMutableString *params = [NSMutableString string];
    [params appendFormat:@"%@=%@", APP_KEY, APP_KEY_VALUE];
    
    // info's dictionary entry stores url param as value=>key to handle multiple param with same key
    for(NSString *value in info) {
        if (value) {
            NSString *key = [info objectForKey:value];
            if ([params length] > 0) {
                [params appendString:@"&"];
            }
            [params appendFormat:@"%@=%@", key, value];
        }
    }
    
    Debug(@"params: %@", params);
    [req setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
    
    sessionValidatingHandler = ^(NSURLResponse * response, NSData * data, NSError * err) {
        [UIAppDelegate decrNetworkActivities];
        
        NSInteger response_status;
        NSDictionary *json = [APIHandler getResponse:response data:data error:&err status:&response_status];
                
        if(response_status == RESPONSE_FALURE) {
            NSString *errCode = [json objectForKey:RESPONSE_ERROR_CODE];
            if ([INVALID_SESSION isEqualToString:errCode]) {                
                NSMutableDictionary *signInInfo = [NSMutableDictionary dictionary];
                [signInInfo setObject:ORG_ID forKey:[Util getSelectedOrgId]];
                [signInInfo setObject:USERNAME forKey:[Util getUsername]];
                [signInInfo setObject:PASSWORD forKey:[Util getPassword]];
                
                [APIHandler asyncCallWithAction:LOGIN_API Info:signInInfo AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
                    NSInteger status;
                    NSDictionary *responseData = [APIHandler getResponse:response data:data error:&err status:&status];
                    
                    if (status == RESPONSE_SUCCESS) {
                        // set cookie for session id
                        NSString *sessionId = [responseData objectForKey:SESSION_ID_KEY];
                        [Util setSession:sessionId];
                        NSString *usersId = [responseData objectForKey:USER_ID];
                        [Util setUserId:usersId];
                        
                        [APIHandler asyncCallWithAction:action Info:info AndHandler:handler];
                    } else {
//                        [UIHelper showInfo:@"Session timed out! Please sign in again." withStatus:kInfo];
                        [[RootMenuViewController sharedInstance] performSegueWithIdentifier:MENU_LOGOUT sender:self];
                    }
                }];

                return;
            }
        }
        
        handler(response, data, err);
    };
    
    [NSURLConnection sendAsynchronousRequest:req queue:[[NSOperationQueue alloc] init] completionHandler:sessionValidatingHandler];
}

+ (void) asyncCallWithRequest:(NSMutableURLRequest*)req AndHandler:(Handler)handler {
    [NSURLConnection sendAsynchronousRequest:req queue:[[NSOperationQueue alloc] init] completionHandler:handler];
}

+ (id) getResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError **) err status:(NSInteger *)status {
    id result = nil;
    
    if (err && *err) {
        if ([*err code] == -1001 ) {
            *status = RESPONSE_TIMEOUT;
        } else if (data == nil) {
            *status = RESPONSE_FALURE;
        } else {
            *status = RESPONSE_FALURE;
            NSError *error;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            result = [json objectForKey:RESPONSE_DATA_KEY];
        }
    } else {
        NSError *error;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        
        *status = [[json objectForKey:RESPONSE_STATUS_KEY] intValue];
        result = [json objectForKey:RESPONSE_DATA_KEY];
        
        if(*status != RESPONSE_SUCCESS) {            
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:[[json objectForKey:RESPONSE_DATA_KEY] objectForKey:RESPONSE_ERROR_MSG] forKey:NSLocalizedDescriptionKey];
            *err = [NSError errorWithDomain:ERR_DOMAIN code:[[[json objectForKey:RESPONSE_DATA_KEY] objectForKey:RESPONSE_ERROR_CODE] intValue] userInfo:details];
        }
    }
    return result;
}
    
@end
