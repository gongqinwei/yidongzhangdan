//
//  IADHelper.h
//  Mobill
//
//  Created by Qinwei Gong on 2/1/14.
//  Copyright (c) 2014 Mobill Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^RequestProductsCompletionHandler)(BOOL success, NSArray * products);


@interface IADHelper : NSObject

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers;
- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler;

@end
