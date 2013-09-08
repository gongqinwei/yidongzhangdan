//
//  Node.m
//  Mobill
//
//  Created by Qinwei Gong on 6/29/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "Node.h"

@implementation Node

@synthesize value;
@synthesize prev;
@synthesize next;

- (id)init {
    if (self = [super init]) {
        self.prev = nil;
        self.next = nil;
        self.value = nil;
    }
    return self;
}

@end
