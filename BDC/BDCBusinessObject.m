//
//  BDCBusinessObject.m
//  BDC
//
//  Created by Qinwei Gong on 9/21/12.
//
//

#import "BDCBusinessObject.h"
#import "Constants.h"
#import "APIHandler.h"
#import "UIHelper.h"

@interface BDCBusinessObject()

@end

@implementation BDCBusinessObject

@synthesize objectId;
@synthesize name;
@synthesize isActive;
@synthesize editDelegate;


-(NSUInteger) hash {
    return [self.objectId hash];
}

-(BOOL) isEqual:(id)other {
    if([other isKindOfClass:[self class]])
        return [self.objectId isEqualToString:((BDCBusinessObject *)other).objectId];
    else
        return NO;
}

- (id)copyWithZone:(NSZone *)zone {
    BDCBusinessObject *copy = [[[self class] allocWithZone: zone] init];
    copy.objectId = self.objectId;
    copy.name = self.name;
    
    return copy;
}

- (void)create {
    [self saveFor:CREATE];
}

- (void)read {
    NSString *objAPI = [NSString stringWithFormat:@"%@.json", [self class]];
    NSString *action = [NSString stringWithFormat:@"%@/%@/%@", CRUD, READ, objAPI];
    NSString *objStr = [NSString stringWithFormat:@"{\"%@\" : \"%@\"}", ID, self.objectId];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA, objStr, nil];
        
    [APIHandler asyncCallWithAction:action Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        NSDictionary *dict = [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {            
            [self populateObjectWithInfo:dict];
            [self.editDelegate didReadObject];
            [self updateParentList];
        } else {
            [self.editDelegate failedToReadObject];
            [UIHelper showInfo:[NSString stringWithFormat:@"Failed to read %@ %@: %@", [self class], self.objectId, [err localizedDescription]] withStatus:kFailure];
            Debug(@"Failed to read %@ %@: %@", [self class], self.objectId, [err localizedDescription]);
        }
    }];
}

- (void)updateParentList {}

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
- (void)populateObjectWithInfo:(NSDictionary *)dict {}

- (void)cloneTo:(BDCBusinessObject *)target {}

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
