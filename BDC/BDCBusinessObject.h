//
//  BDCBusinessObject.h
//  BDC
//
//  Created by Qinwei Gong on 9/21/12.
//
//

#import <Foundation/Foundation.h>

@interface BDCBusinessObject : NSObject

@property (nonatomic, strong) NSString *objectId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) BOOL isActive;

- (void)create;
- (void)update;
- (void)remove;
- (void)revive;

// don't call this directly: used by remove/revive
- (void)toggleActive:(Boolean)isActive;

- (void)saveFor:(NSString *)action;

+ (void)retrieveList;
+ (void)retrieveListForActive:(BOOL)isActive;
+ (void)retrieveListForActive:(BOOL)isActive reload:(BOOL)needReload;
+ (id)list;
+ (id)listInactive;
+ (id)listOrderBy:(NSString *)attribue ascending:(Boolean)isAscending active:(Boolean)isActive;
+ (void)clone:(BDCBusinessObject *)source to:(BDCBusinessObject *)target;

@end
