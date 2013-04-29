//
//  UIHelper.h
//  BDC
//
//  Created by Qinwei Gong on 9/14/12.
//
//

#import <Foundation/Foundation.h>

typedef enum {
    kSuccess,
    kInfo,
    kWarning,
    kFailure,
    kError,
} NotificationStatus;

@interface UIHelper : NSObject

+ (void)showInfo:(NSString *)info withStatus:(NotificationStatus)status;

+ (void)makeFullScreen:(UIViewController *)vc;
+ (void)exitFullScreen:(UIViewController *)vc;

+ (void)addShaddowForView:(UIView *)view;
+ (void)removeShaddowForView:(UIView *)view;

+ (void)enterFullScreen;    // depricated
+ (void)quitFullScreen;     // depricated
+ (void)adjustScreen:(UIViewController *)vc;

+ (void)switchViewController:(UIViewController *)vc toTab:(int)tabIndex withSegue:(NSString *)segueId animated:(BOOL)animated;

+ (void)initializeHeaderLabel:(UILabel *)label;
+ (void)addGradientForView:(UIView *)view;

@end
