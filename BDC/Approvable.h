//
//  Approvable.h
//  Mobill
//
//  Created by Qinwei Gong on 10/19/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol ApprovalDelegate <NSObject>

- (void)didProcessApproval;
- (void)failedToProcessApproval;

@end

@protocol Approvable <NSObject>

- (void)approve;
- (void)approveWithComment:(NSString *)comment;
- (void)denyWithComment:(NSString *)comment;
- (void)skipWithComment:(NSString *)comment;

@end
