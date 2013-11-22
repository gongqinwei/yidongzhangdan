//
//  UIViewController+Sliding.h
//  BDC
//
//  Created by Qinwei Gong on 4/2/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
#import "ActionMenuViewController.h"
#import "UIView+FindAndResignFirstResponder.h"

#define ACTION_CRUD                 @"Actions"
#define ACTION_CREATE               @"Create New"
#define ACTION_UPDATE               @"Edit"
#define ACTION_DELETE               @"Delete ..."
#define ACTION_UNDELETE             @"Undelete ..."
#define ACTION_LIST                 @"List for"
#define ACTION_MAP                  @"Map View"
#define ACTION_ORDER                @"Order by"
#define ACTION_PAY                  @"Pay"
#define ACTION_ASSOCIATE            @"Associate %@"
#define ACTION_ACCEPT_EBILL         @"Accept eBill"
#define ACTION_BDC_PROCESSING       @"Bill.com is still processing this document, so it's not available"
#define ACTION_BDC_PROCESSING2      @"for association now. Please refresh Inbox in a minute."
#define ACTION_LIST_VENDOR_BILLS    @"List Bills"
#define ACTION_LIST_CUSTOMER_INVS   @"List Invoices"
#define ACTION_APPROVE              @"Approve"
#define ACTION_DENY                 @"Deny"
#define ACTION_SKIP                 @"Skip"


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

@interface UIViewController (Sliding) <SlideDelegate, ActionMenuDelegate, UINavigationControllerDelegate>

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

- (void)initialize;
- (void)slideIn;
- (void)slideOut;
- (void)slideOutOnly;
- (void)disappear;
- (void)disappearOnly;
- (IBAction)toggleMenu:(id)sender;
//- (void)removeTapGesture;
- (void)enterEditMode;
- (void)exitEditMode;
- (void)refreshView;
- (BOOL)tryTap;
- (void)setSlidingMenuLeftBarButton;
- (void)setActionMenuRightBarButton;

@end
