//
//  BDCBusinessObject.h
//  BDC
//
//  Created by Qinwei Gong on 9/21/12.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BusObjectDelegate

@optional
- (void)didCreateObject:(NSString *)newObjectId;
- (void)didReadObject;
- (void)didUpdateObject;
- (void)didDeleteObject;
- (void)failedToReadObject;
- (void)failedToSaveObject;

@end


@interface BDCBusinessObject : NSObject

@property (nonatomic, strong) NSString *objectId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) BOOL isActive;

@property (nonatomic, weak) id<BusObjectDelegate> editDelegate;

- (void)create;
- (void)read;
- (void)update;
- (void)remove;
- (void)revive;
- (NSUInteger) hash;
- (BOOL) isEqual:(id)other;
- (id)copyWithZone:(NSZone *)zone;

// don't call this directly: used by remove/revive
- (void)toggleActive:(Boolean)isActive;

- (void)saveFor:(NSString *)action;
- (void)populateObjectWithInfo:(NSDictionary *)dict;
- (void)cloneTo:(BDCBusinessObject *)target;
- (void)updateParentList;

+ (void)retrieveList;
+ (void)retrieveListForActive:(BOOL)isActive;
+ (void)retrieveListForActive:(BOOL)isActive reload:(BOOL)needReload;
+ (id)list;
+ (id)listInactive;
+ (id)listOrderBy:(NSString *)attribue ascending:(Boolean)isAscending active:(Boolean)isActive;
+ (void)clone:(BDCBusinessObject *)source to:(BDCBusinessObject *)target;
+ (NSUInteger)count;
+ (NSUInteger)countInactive;

+ (NSPredicate *)getPredicate:(NSString *)objId;
+ (BDCBusinessObject *)loadWithId:(NSString *)objId;

@end
