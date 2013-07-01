//
//  LinkedList.h
//  Mobill
//
//  Created by Qinwei Gong on 6/29/13.
//
//  Queue like LinkedList made for LRU

#import <Foundation/Foundation.h>
#import "Node.h"

@interface LinkedList : NSObject

@property (nonatomic, strong) Node *head;
@property (nonatomic, strong) Node *tail;
@property (nonatomic, assign) int size;

- (Node *)enqueue:(id)value;
- (id)dequeue;
- (void)refresh:(Node *)node;
- (void)empty;

@end
