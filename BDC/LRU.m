//
//  LRU.m
//  Mobill
//
//  Created by Qinwei Gong on 6/29/13.
//
//  Mainly used for free up memory on receiving memory warning

#import "LRU.h"

@implementation LRU

@synthesize list;
@synthesize map;

- (id)init {
    if (self = [super init]) {
        self.list = [[LinkedList alloc] init];
        self.map = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)cache:(id)obj {
    if (obj) {
        Node *node = [self.map objectForKey:obj];
        if (node) {
            [self.list refresh:node];
        } else {
            node = [self.list enqueue:obj];
            [self.map setObject:node forKey:obj];
        }
    }
}

- (id)spit {
    id obj = [self.list dequeue];
    
    if (obj) {
        [self.map removeObjectForKey:obj];
    }
    
    return obj;
}

- (void)purge {
    [self.list empty];
    [self.map removeAllObjects];
}

@end
