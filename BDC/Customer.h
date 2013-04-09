//
//  Customer.h
//  BDC
//
//  Created by Qinwei Gong on 9/7/12.
//
//

#import <Foundation/Foundation.h>
#import "BDCBusinessObject.h"

#define CUSTOMER            @"Customer"
#define CUSTOMER_NAME       @"name"
#define CUSTOMER_ADDR1      @"billAddress1"
#define CUSTOMER_ADDR2      @"billAddress2"
#define CUSTOMER_ADDR3      @"billAddress3"
#define CUSTOMER_ADDR4      @"billAddress4"
#define CUSTOMER_CITY       @"billAddressCity"
#define CUSTOMER_STATE      @"billAddressState"
#define CUSTOMER_COUNTRY    @"billAddressCountry"
#define CUSTOMER_ZIP        @"billAddressZip"
#define CUSTOMER_EMAIL      @"email"
#define CUSTOMER_PHONE      @"phone"


@protocol CustomerDelegate <NSObject>

@optional
- (void)didCreateCustomer:(NSString *)newCustomerId;
- (void)didUpdateCustomer;
- (void)didDeleteCustomer;

- (void)failedToSaveCustomer;

@end

@protocol CustomerListDelegate <NSObject>

@optional
- (void)didGetCustomers;
- (void)failedToGetCustomers;

@end

@interface Customer : BDCBusinessObject

//@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *billAddr1;
@property (nonatomic, strong) NSString *billAddr2;
@property (nonatomic, strong) NSString *billAddr3;
@property (nonatomic, strong) NSString *billAddr4;
@property (nonatomic, strong) NSString *billCity;
@property (nonatomic, strong) id billState;
@property (nonatomic, assign) int billCountry;
@property (nonatomic, strong) NSString *billZip;
//@property (nonatomic, strong) NSString *shipAddr1;
//@property (nonatomic, strong) NSString *shipAddr2;
//@property (nonatomic, strong) NSString *shipAddr3;
//@property (nonatomic, strong) NSString *shipAddr4;
//@property (nonatomic, strong) NSString *shipCity;
//@property (nonatomic, strong) NSString *shipState;
//@property (nonatomic, strong) NSString *shipCountry;
//@property (nonatomic, strong) NSString *shipZip;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *phone;
//@property (nonatomic, strong) NSString *altPhone;
//@property (nonatomic, strong) NSString *fax;

@property (nonatomic, weak) id<CustomerDelegate> editDelegate;
@property (nonatomic, weak) id<CustomerDelegate> editInvoiceDelegate;

+ (void)setListDelegate:(id<CustomerListDelegate>)listDelegate;

+ (Customer *)objectForKey:(NSString *)customerId;

@end
