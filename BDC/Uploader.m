//
//  Uploader.m
//  BDC
//
//  Created by Qinwei Gong on 9/19/12.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "Uploader.h"
#import "APIHandler.h"
#import "Util.h"

@implementation Uploader

+ (void) uploadFile:(NSString *)file data:(NSData *)data objectId:(NSString *)objId handler:(Handler)handler {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    if(file.length == 0) {
        //use timestamp as filename if it's not given
        file = [Util formatDate:[NSDate date] format:@"yyyyMMddHHmmss"];
    } else {
        file = [file lastPathComponent];
        file = [[file componentsSeparatedByString:@"."] objectAtIndex:0];
    }
    file = [file stringByAppendingString:@".jpg"];
    
    NSString *urlStr = [NSString stringWithFormat:@"%@/%@/%@?%@=%@&%@=%@", DOMAIN_URL, API_BASE, UPLOAD_API, APP_KEY, APP_KEY_VALUE, FILE_NAME, file];
    
    [request setURL:[NSURL URLWithString:urlStr]];
    [request setHTTPMethod:@"POST"];
    
    // Set Header and content type of your request.
    NSString *boundary = @"---------------------------Boundary Line---------------------------";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    // create the body of the request.
    NSMutableData *body = [NSMutableData data];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];    
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"data\"\r\n\r\n"]  dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"{\"id\":\"%@\", \"fileName\":\"%@\"}\r\n", objId?objId:@"", file] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"Filedata\"; filename=\"%@\"\r\n", file] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:data]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // set body with request.
    [request setHTTPBody:body];
    [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)[body length]] forHTTPHeaderField:@"Content-Length"];
//    [request addValue:APP_KEY_VALUE forHTTPHeaderField:APP_KEY];
    
    // send request async
    [APIHandler asyncCallWithRequest:request AndHandler:handler];
}

@end
