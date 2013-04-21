//
//  UIViewController+Sliding.h
//  BDC
//
//  Created by Qinwei Gong on 4/2/13.
//
//

#import <UIKit/UIKit.h>
#import "Constants.h"
#import "ActionMenuViewController.h"
#import "UIView+FindAndResignFirstResponder.h"

#define ACTION_CRUD             @"Actions"
#define ACTION_CREATE           @"Create New"
#define ACTION_UPDATE           @"Edit"
#define ACTION_DELETE           @"Delete..."
#define ACTION_UNDELETE         @"Undelete..."
#define ACTION_LIST             @"List For"
#define ACTION_ORDER            @"Order By"


@protocol SlideDelegate <NSObject>

@optional
- (void)viewDidSlideIn;
- (void)viewDidSlideOut;

@end

@protocol ActionMenuDelegate <NSObject>

@optional
- (void)didSelectSortAttribute:(NSString *)attribute ascending:(BOOL)ascending active:(BOOL)active;
- (void)didSelectCrudAction:(NSString *)action;

@end

@class ActionMenuViewController;

@interface UIViewController (Sliding) <SlideDelegate, ActionMenuDelegate>

@property (nonatomic, strong) id<SlideDelegate> slidingInDelegate;
@property (nonatomic, strong) id<SlideDelegate> slidingOutDelegate;
@property (nonatomic, strong) UINavigationController *navigation;
@property (nonatomic, strong) NSString *navigationId;
@property (nonatomic, assign) ViewMode mode;

@property (nonatomic, strong) ActionMenuViewController *actionMenuVC;
@property (nonatomic, strong) NSArray *sortAttributes;
@property (nonatomic, strong) NSDictionary *sortAttributeLabels;
@property (nonatomic, strong) NSArray *crudActions;
@property (nonatomic, strong) NSArray *inactiveCrudActions;

@property (nonatomic, strong) NSString *sortAttribute;
@property (nonatomic, assign) BOOL isAsc;
@property (nonatomic, assign) BOOL isActive;

@property (nonatomic, strong) UISwipeGestureRecognizer *leftSwipeRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *rightSwipeRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;

- (void)slideIn;
- (void)slideOut;
- (IBAction)toggleMenu:(id)sender;
//- (void)removeTapGesture;
- (void)enterEditMode;
- (void)exitEditMode;
- (BOOL)tryTap;

@end
