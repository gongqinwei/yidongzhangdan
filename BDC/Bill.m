//
//  Bill.m
//  BDC
//
//  Created by Qinwei Gong on 7/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Bill.h"
#import "Constants.h"
#import "APIHandler.h"
#import "Util.h"
#import "Uploader.h"
#import "UIHelper.h"

@interface Bill()

//- (NSString *)formatDate:(NSDate *)date;
- (void) attachDocs;

@end

@implementation Bill

@synthesize billId;
@synthesize orgId;
@synthesize vendorId;
@synthesize createdDate;
@synthesize updatedDate;
@synthesize invNum;
@synthesize desc;
@synthesize status;
@synthesize paymentstatus;
@synthesize dueDate;
@synthesize invDate;
@synthesize paymentScheduledByDate;
@synthesize deptId;
@synthesize quickbooksId;
@synthesize exportedDate;
@synthesize firstPaymentDate;
@synthesize lastPaymentDate;
@synthesize fullPamentDate;
@synthesize expectedPayDate;
@synthesize allowExport;
@synthesize amount;
@synthesize discountAmount;
@synthesize approvedAmount;
@synthesize paidAmount;
@synthesize paymentTermId;
@synthesize lastSyncTime;
@synthesize sentSyncTime;
@synthesize updateSyncTime;
@synthesize isOneChainMode;
@synthesize isSplit;

@synthesize docs;

- (NSString *)name {
    return self.invNum;
}

- (id) init {
    if (self = [super init]) {
        self.docs = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void) create {
    NSString * action = [NSString stringWithFormat:@"%@/%@/%@", CRUD, CREATE, BILL_API];
    
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
////    [info setObject:APP_KEY_VALUE forKey:APP_KEY];
//    [info setObject:APP_KEY forKey:APP_KEY_VALUE];
    
    NSMutableString *objStr = [NSMutableString string];
    [objStr appendString:@"{"];
    [objStr appendString:OBJ];
    [objStr appendString:@": {"];
    [objStr appendString:@"\"entity\" : \"Bill\","];
    [objStr appendFormat:@"\"vendorId\" : \"%@\",", @"00901LJFXVBTKIUXUZ8e"];  //self.vendorId];
    [objStr appendFormat:@"\"invoiceNumber\" : \"%@\",", self.invNum];
    [objStr appendFormat:@"\"invoiceDate\" : \"%@\",", [Util formatDate:self.invDate format:@"yyyy-MM-dd"]];
    [objStr appendFormat:@"\"dueDate\" : \"%@\",", [Util formatDate:self.dueDate format:@"yyyy-MM-dd"]];
    [objStr appendString:@"\"paymentStatus\" : \"1\","];
    [objStr appendString:@"\"billLineItems\" : ["];
    [objStr appendString:@"{"];
    [objStr appendString:@"\"entity\" : \"BillLineItem\","];
    [objStr appendFormat:@"\"amount\" : %.2f", [[NSDecimalNumber decimalNumberWithDecimal:self.amount] doubleValue] ];
    [objStr appendString:@"}"];
    [objStr appendString:@"]"];
    [objStr appendString:@"}"];
    [objStr appendString:@"}"];
    [info setObject:DATA forKey:objStr];
//    NSLog(@"%@", objStr);
    
    [APIHandler asyncCallWithAction:action Info:info AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;

        NSDictionary *info = [APIHandler getResponse:response data:data error:&err status:&response_status];
        if(response_status == RESPONSE_SUCCESS) {
            NSString *bId = [info objectForKey:ID];
            NSLog(@"New bill's id: %@", bId);
            self.billId = bId;
            
            // TODO: need to change server code to return DocumentPg id instead of Document id here
            // assotiate documents(photos) to this newly created bill object
//            [self attachDoc];
            [self.delegate didCreateBill];
            
        } else {
            NSString * msg = @"Failed to create new bill! ";
            [UIHelper showInfo:[msg stringByAppendingString:[err localizedDescription]] withStatus:kFailure];
            NSLog(@"%@ %@", msg, [err localizedDescription]);
        }
    }];
    
}

// currently not used...
- (void) attachDocs {
    NSString * action = [NSString stringWithFormat:@"%@", UPLOAD_API];
    
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
//    [info setObject:self.billId forKey:BILL_ID];
//    [info setObject:[[self.docs allObjects] componentsJoinedByString:@","] forKey:DOC_PG_IDS];

    [info setObject:ID forKey:self.billId];

    for (NSString *doc in self.docs) {
        [info setObject:DOC_PG_ID forKey:doc];
    }
    
    [APIHandler asyncCallWithAction:action Info:info AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
//        NSError *error;
//        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
//        
//        int response_status = [[json objectForKey:RESPONSE_STATUS_KEY] intValue];
        
        NSInteger response_status;
        [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {
            //TODO: display overlay here?
            NSLog(@"Succeeded in attaching photo to bill");
        } else {
            NSLog(@"Failed to attaching photo to bill");
            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
            NSLog(@"Failed to attaching photo to bill: %@", [err localizedDescription]);
        }
    }];
}
     


@end
