//
//  Node.h
//  Mobill
//
//  Created by Qinwei Gong on 6/29/13.
//
//

#import <Foundation/Foundation.h>


@interface Node : NSObject

@property (nonatomic, strong) id value;
@property (nonatomic, strong) Node *prev;
@property (nonatomic, strong) Node *next;

@end