//
//  UIView+FindAndResignFirstResponder.m
//  BDC
//
//  Created by Qinwei Gong on 2/27/13.
//
//

#import "UIView+FindAndResignFirstResponder.h"
#import <objc/runtime.h>

static char const * const ObjectTagKey = "ObjectTag";

@implementation UIView (FindAndResignFirstResponder)

@dynamic objectTag;

- (BOOL) findAndResignFirstResponder {
    if (self.isFirstResponder) {
        [self resignFirstResponder];
        return YES;
    }
    for (UIView *subView in self.subviews) {
        if ([subView findAndResignFirstResponder])
            return YES;
    }
    return NO;
}


- (id)objectTag {
    return objc_getAssociatedObject(self, ObjectTagKey);
}

- (void)setObjectTag:(id)newObjectTag {
    objc_setAssociatedObject(self, ObjectTagKey, newObjectTag, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)viewWithObjectTag:(id)object {
    // Raise an exception if object is nil
    if (object == nil) {
        [NSException raise:NSInternalInconsistencyException format:@"Argument to -viewWithObjectTag: must not be nil"];
    }
    
    // Recursively search the view hierarchy for the specified objectTag
    if ([self.objectTag isEqual:object]) {
        return self;
    }
    for (UIView *subview in self.subviews) {
        UIView *resultView = [subview viewWithObjectTag:object];
        if (resultView != nil) {
            return resultView;
        }
    }
    return nil;
}

@end
