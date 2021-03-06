//
//  LRU.h
//  Mobill
//
//  Created by Qinwei Gong on 6/29/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LinkedList.h"

#define CACHE_THRESHOLD     1000000

@interface LRU : NSObject

@property (nonatomic, strong) LinkedList *list;
@property (nonatomic, strong) NSMutableDictionary *map;

- (void)cache:(id)value;
- (id)spit;
- (void)purge;

@end
