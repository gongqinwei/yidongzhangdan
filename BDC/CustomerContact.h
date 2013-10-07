//
//  CustomerContact.h
//  Mobill
//
//  Created by Qinwei Gong on 9/15/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "BDCBusinessObjectWithAttachments.h"
#import "Customer.h"

#define CONTACT             @"CustomerContact"
#define CONTACT_CUSTOMER    @"customerId"
#define CONTACT_FNAME       @"firstName"
#define CONTACT_LNAME       @"lastName"
#define CONTACT_EMAIL       @"email"
#define CONTACT_PHONE       @"phone"


@protocol ContactListDelegate <ListViewDelegate>

@optional
- (void)didGetContacts;
- (void)failedToGetContacts;

@end


@interface CustomerContact : BDCBusinessObjectWithAttachments

@property (nonatomic, strong) NSString *customerId;
@property (nonatomic, strong) NSString *fname;
@property (nonatomic, strong) NSString *lname;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *phone;

@property (nonatomic, weak) id<BusObjectDelegate> editCustomerDelegate;

- (id)initWithCustomer:(Customer *)customer;

+ (NSMutableArray *)listContactsForCustomer:(Customer *)customer;
+ (void)retrieveListForCustomer:(NSString *)customerId;
+ (void)setListDelegate:(id<ContactListDelegate>)listDelegate;
+ (void)resetList;

@end
