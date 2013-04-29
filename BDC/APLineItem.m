//
//  APLineItem.m
//  BDC
//
//  Created by Qinwei Gong on 4/23/13.
//
//

#import "APLineItem.h"

@implementation APLineItem

@synthesize amount;
@synthesize account;

+ (void)clone:(APLineItem *)source to:(APLineItem *)target {
    [super clone:source to:target];
    
    target.account = [[ChartOfAccount alloc] init];
    [ChartOfAccount clone:source.account to:target.account];
    target.amount = source.amount;
}

@end
