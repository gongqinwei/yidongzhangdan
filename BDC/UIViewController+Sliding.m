//
//  UIViewController+Sliding.m
//  BDC
//
//  Created by Qinwei Gong on 4/2/13.
//
//

#import "UIViewController+Sliding.h"
#import "RootMenuViewController.h"
#import "Constants.h"
#import "UIHelper.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static char const * const SlidingInDelegateKey = "slidingInDelegate";
static char const * const SlidingOutDelegateKey = "slidingOutDelegate";
static char const * const NavigationKey = "navigation";
static char const * const NavigationIdKey = "navigationId";
static char const * const ModeKey = "mode";
static char const * const ActionMenuVCKey = "actionMenuVC";
static char const * const SortAttributesKey = "sortAttributes";
static char const * const SortAttributeLabelsKey = "sortAttributeLabels";
static char const * const CrudActionsKey = "crudActions";
static char const * const InactiveCrudActionsKey = "inactiveCrudActions";
static char const * const SortAttributeKey = "sortAttribute";
static char const * const IsAscKey = "isAsc";
static char const * const IsActiveKey = "isActive";
static char const * const LeftSwipeRecognizerKey = "leftSwipeRecognizer";
static char const * const RightSwipeRecognizerKey = "rightSwipeRecognizer";
static char const * const TapRecognizerKey = "tapRecognizer";


@implementation UIViewController (Sliding)

@dynamic slidingInDelegate;
@dynamic slidingOutDelegate;
@dynamic navigation;
@dynamic navigationId;
@dynamic mode;

@dynamic actionMenuVC;
@dynamic sortAttributes;
@dynamic sortAttributeLabels;
@dynamic crudActions;
@dynamic inactiveCrudActions;

@dynamic sortAttribute;
@dynamic isAsc;
@dynamic isActive;

@dynamic leftSwipeRecognizer;
@dynamic rightSwipeRecognizer;
@dynamic tapRecognizer;


//- (void)removeTapGesture {
//    UIViewController *vc = [self.navigationController.childViewControllers objectAtIndex:0];
////    UIViewController * vc = self.navigationController.topViewController;
//    if ([vc respondsToSelector:@selector(slideIn)]) {
//        [vc.view removeGestureRecognizer:vc.tapRecognizer];
//    }
//}

- (BOOL)tryTap {
    if ([self.view.gestureRecognizers containsObject:self.tapRecognizer]) {
        [self toggleMenu:nil];
        return NO;
    }

    return YES;
}

- (void)slideTo:(CGRect)destination completion:completionHandler {
    [UIView animateWithDuration:SLIDING_DURATION animations:^{
        self.navigationController.view.frame = destination;
    } completion:completionHandler];
}

- (IBAction)toggleMenu:(id)sender {
    CGRect destination = self.navigationController.view.frame;
    if (destination.origin.x == 0) {        
        if (([sender isKindOfClass:[UIBarButtonItem class]] && ((UIBarButtonItem*)sender).tag == 0) || ([sender isKindOfClass:[UISwipeGestureRecognizer class]] && ((UISwipeGestureRecognizer *)sender).direction == UISwipeGestureRecognizerDirectionRight)) {
            destination.origin.x += SLIDING_DISTANCE;
            [self.view findAndResignFirstResponder];
            [self slideTo:destination completion:^(BOOL finished) {
                [UIHelper addShaddowForView:self.navigationController.view];
                self.navigationItem.hidesBackButton = YES;
                [self.view addGestureRecognizer:self.tapRecognizer];
            }];
        } else { //if ([sender isKindOfClass:[UISwipeGestureRecognizer class]] && ((UISwipeGestureRecognizer *)sender).direction == UISwipeGestureRecognizerDirectionLeft) {
            if (self.actionMenuVC == nil) {
                self.actionMenuVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ActionMenu"];
                self.actionMenuVC.targetViewController = self;
                self.slidingInDelegate = self;
                [UIHelper adjustScreen:self.actionMenuVC];
            }
            [[RootMenuViewController sharedInstance].view insertSubview:self.actionMenuVC.view atIndex:1];
            
            destination.origin.x -= SLIDING_DISTANCE;
            [self.view findAndResignFirstResponder];
            [self slideTo:destination completion:^(BOOL finished) {
                [UIHelper addShaddowForView:self.navigationController.view];
                [self.view addGestureRecognizer:self.tapRecognizer];
            }];
        }
    } else {
        CGFloat x = destination.origin.x;
        destination.origin.x = 0;
        [self slideTo:destination completion:^{
            if (x < 0) {
                NSString *attr = nil;
                if (self.sortAttributes && self.sortAttributes.count > 0) {
                    attr = [self.sortAttributes objectAtIndex:self.actionMenuVC.lastSortAttribute.row];
                }
                [self didSelectSortAttribute:attr
                                   ascending:self.actionMenuVC.ascSwitch.on
                                      active:!self.actionMenuVC.activenessSwitch.selectedSegmentIndex];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.slidingInDelegate viewDidSlideIn];
                });
            }
            
            self.navigationItem.hidesBackButton = NO;
            [self.view removeGestureRecognizer:self.tapRecognizer];
        }];
    }
}

- (void)slideIn {
    [[RootMenuViewController sharedInstance].view addSubview:self.navigationController.view];
    
    CGRect selfFrame = self.navigationController.view.frame;
    selfFrame.origin.x = [UIScreen mainScreen].bounds.size.width;
    self.navigationController.view.frame = selfFrame;
    
    selfFrame.origin.x = 0;
    [self slideTo:selfFrame completion:^{
        
    }];
}

- (void)slideOut {
    [self.actionMenuVC.view removeFromSuperview];
    
    self.navigationItem.hidesBackButton = NO;
    [self.view removeGestureRecognizer:self.tapRecognizer];
    
    CGRect destination = self.navigationController.view.frame;
    if (destination.origin.x > 0) {
        destination.origin.x = [UIScreen mainScreen].bounds.size.width;
    } else {
        destination.origin.x = [UIScreen mainScreen].bounds.size.width * -1;
    }
    
    [self slideTo:destination completion:^(BOOL finished) {
        UIViewController *topVC = self.navigationController.topViewController;
        [topVC.view removeGestureRecognizer:topVC.tapRecognizer];
        topVC.navigationItem.hidesBackButton = NO;
        
        [self.navigationController removeFromParentViewController];
        [self.slidingOutDelegate viewDidSlideOut];
        [UIHelper removeShaddowForView:self.navigationController.view];
    }];
}

- (void)enterEditMode {
//    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(exitEditMode)];
//    [self.navigationItem setRightBarButtonItem:doneButton];
}

- (void)exitEditMode {
//    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(toggleMenu:)];
//    actionButton.tag = 1;
//    [self.navigationItem setRightBarButtonItem:actionButton];
}

#pragma mark - Sliding Table View Controller delegate

- (void)viewDidSlideIn {
    [self.actionMenuVC.view removeFromSuperview];
}

#pragma mark - Action Menu delegate

- (void)didSelectSortAttribute:(NSString *)attribute ascending:(BOOL)ascending active:(BOOL)active {
    
}

#pragma mark - getters & setters

- (id<SlideDelegate>) slidingInDelegate {
    return objc_getAssociatedObject(self, SlidingInDelegateKey);
}

- (void) setSlidingInDelegate:(id<SlideDelegate>)slidingInDelegate {
    objc_setAssociatedObject(self, SlidingInDelegateKey, slidingInDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<SlideDelegate>) slidingOutDelegate {
    return objc_getAssociatedObject(self, SlidingOutDelegateKey);
}

- (void) setSlidingOutDelegate:(id<SlideDelegate>)slidingOutDelegate {
    objc_setAssociatedObject(self, SlidingOutDelegateKey, slidingOutDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UINavigationController *) navigation {
    return objc_getAssociatedObject(self, NavigationKey);
}

- (void) setNavigation:(UINavigationController *)navigation {
    objc_setAssociatedObject(self, NavigationKey, navigation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *) navigationId {
    return objc_getAssociatedObject(self, NavigationIdKey);
}

- (void) setNavigationId:(NSString *)navigationId {
    objc_setAssociatedObject(self, NavigationIdKey, navigationId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (ViewMode) mode {
    return [objc_getAssociatedObject(self, ModeKey) intValue];
}

- (void) setMode:(ViewMode)mode {
    objc_setAssociatedObject(self, ModeKey, [NSNumber numberWithInt:mode], OBJC_ASSOCIATION_ASSIGN);
}

- (ActionMenuViewController *) actionMenuVC {
    return objc_getAssociatedObject(self, ActionMenuVCKey);
}

- (void) setActionMenuVC:(ActionMenuViewController *)actionMenuVC {
    objc_setAssociatedObject(self, ActionMenuVCKey, actionMenuVC, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray *) sortAttributes {
    return objc_getAssociatedObject(self, SortAttributesKey);
}

- (void) setSortAttributes:(NSArray *)sortAttributes {
    objc_setAssociatedObject(self, SortAttributesKey, sortAttributes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDictionary *) sortAttributeLabels {
    return objc_getAssociatedObject(self, SortAttributeLabelsKey);
}

- (void) setSortAttributeLabels:(NSDictionary *)sortAttributeLabels {
    objc_setAssociatedObject(self, SortAttributeLabelsKey, sortAttributeLabels, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray *) crudActions {
    return objc_getAssociatedObject(self, CrudActionsKey);
}

- (void) setCrudActions:(NSArray *)crudActions {
    objc_setAssociatedObject(self, CrudActionsKey, crudActions, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray *) inactiveCrudActions {
    return objc_getAssociatedObject(self, InactiveCrudActionsKey);
}

- (void) setInactiveCrudActions:(NSArray *)crudActions {
    objc_setAssociatedObject(self, InactiveCrudActionsKey, crudActions, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *) sortAttribute {
    return objc_getAssociatedObject(self, SortAttributeKey);
}

- (void) setSortAttribute:(NSString *)sortAttribute {
    objc_setAssociatedObject(self, SortAttributeKey, sortAttribute, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL) isAsc {
    return [objc_getAssociatedObject(self, IsAscKey) boolValue];
}

- (void) setIsAsc:(BOOL)isAsc {
    objc_setAssociatedObject(self, IsAscKey, [NSNumber numberWithBool:isAsc], OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL) isActive {
    return [objc_getAssociatedObject(self, IsActiveKey) boolValue];
}

- (void) setIsActive:(BOOL)isActive {
    objc_setAssociatedObject(self, IsActiveKey, [NSNumber numberWithBool:isActive], OBJC_ASSOCIATION_ASSIGN);
}

- (UISwipeGestureRecognizer *) leftSwipeRecognizer {
    return objc_getAssociatedObject(self, LeftSwipeRecognizerKey);;
}

- (void) setLeftSwipeRecognizer:(UISwipeGestureRecognizer *)leftSwipeRecognizer {
    objc_setAssociatedObject(self, LeftSwipeRecognizerKey, leftSwipeRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UISwipeGestureRecognizer *) rightSwipeRecognizer {
    return objc_getAssociatedObject(self, RightSwipeRecognizerKey);
}

- (void) setRightSwipeRecognizer:(UISwipeGestureRecognizer *)rightSwipeRecognizer {
    objc_setAssociatedObject(self, RightSwipeRecognizerKey, rightSwipeRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UITapGestureRecognizer *) tapRecognizer {
    return objc_getAssociatedObject(self, TapRecognizerKey);
}

- (void) setTapRecognizer:(UITapGestureRecognizer *)tapRecognizer {
    objc_setAssociatedObject(self, TapRecognizerKey, tapRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end
