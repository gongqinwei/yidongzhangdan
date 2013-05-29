//
//  BDCBusinessObject.m
//  BDC
//
//  Created by Qinwei Gong on 9/21/12.
//
//

#import "BDCBusinessObject.h"
#import "Constants.h"

@interface BDCBusinessObject()

@end

@implementation BDCBusinessObject

@synthesize objectId;
@synthesize name;
@synthesize isActive;
@synthesize editDelegate;

- (void)create {
    [self saveFor:CREATE];
}

- (void)update {
    [self saveFor:UPDATE];
}

- (void)toggleActive:(Boolean)isActive {}
- (void)remove {
    [self toggleActive:NO];
}
- (void)revive {
    [self toggleActive:YES];
}

- (void)saveFor:(NSString *)action {}

+ (void)retrieveList {
    [[self class] retrieveListForActive:YES];
    [[self class] retrieveListForActive:NO];
}
+ (void)retrieveListForActive:(BOOL)isActive {
    [[self class] retrieveListForActive:isActive reload:YES];
}
+ (void)retrieveListForActive:(BOOL)isActive reload:(BOOL)needReload {}

+ (id)list { return nil; }
+ (id)listInactive { return nil; }
+ (id)listOrderBy:(NSString *)attribue ascending:(Boolean)isAscending active:(Boolean)isActive { return nil; }
+ (void)clone:(BDCBusinessObject *)source to:(BDCBusinessObject *)target {
    if (source == nil || target == nil) {
        return;
    }
    
    target.objectId = source.objectId;
    target.isActive = source.isActive;
}

@end
