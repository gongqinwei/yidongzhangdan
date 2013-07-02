//
//  LRU.h
//  Mobill
//
//  Created by Qinwei Gong on 6/29/13.
//
//

#import <Foundation/Foundation.h>
#import "LinkedList.h"

#define CACHE_THRESHOLD     100000

@interface LRU : NSObject

@property (nonatomic, strong) LinkedList *list;
@property (nonatomic, strong) NSMutableDictionary *map;

- (void)cache:(id)value;
- (id)spit;
- (void)purge;

@end
