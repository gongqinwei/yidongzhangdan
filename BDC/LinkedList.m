//
//  LinkedList.m
//  Mobill
//
//  Created by Qinwei Gong on 6/29/13.
//
//

#import "LinkedList.h"

@implementation LinkedList

@synthesize head;
@synthesize tail;
@synthesize size;

- (id)init {
    if (self = [super init]) {
        self.head = nil;
        self.tail = nil;
        self.size = 0;
    }
    return self;
}

- (Node *)enqueue:(id)value {
    Node *node = [[Node alloc] init];
    node.value = value;
    
    if (size == 0) {
        self.head = self.tail = node;
    } else {
        self.tail.next = node;
        node.prev = self.tail;
        node.next = nil;
        self.tail = node;
    }
    
    self.size++;
    
    return node;
}

- (id)dequeue {
    id value = nil;
    
    if (self.size > 0) {
        value = self.head.value;
        
        if (self.size == 1) {
            self.head = self.tail = nil;
        } else {
            self.head.next.prev = nil;
            self.head = self.head.next;
        }
        
        self.size--;
    }
    
    return value;
}

// move the node out of the list and put it back to the tail
// assumption: node exist in linked list
- (void)refresh:(Node *)node {
    if (node && self.size > 1 && node != self.tail) {
        // temporarily remove from list
        if (node.prev) {
            node.prev.next = node.next;
        } else {
            self.head = node.next;
        }
        
        node.next.prev = node.prev;
        
        // add back to the tail
        [self enqueue:node.value];
    }
}

- (void)empty {
    Node *curr = self.head;
    Node *next;
    while (curr) {
        next = curr.next;
        curr.prev = nil;
        curr.next = nil;
        curr = next;
    }
    
    self.size = 0;
}

@end
