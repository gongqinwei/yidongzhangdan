//
//  SlidingCollectionViewController.m
//  BDC
//
//  Created by Qinwei Gong on 5/29/13.
//
//

#import "SlidingCollectionViewController.h"
#import "RootMenuViewController.h"


@implementation SlidingCollectionViewController

@synthesize dataArray;
@synthesize currentDocument;
@synthesize refreshControl;

- (void)refreshView {
    self.refreshControl.attributedTitle = REFRESHING;
//    [[self class] retrieveList];
    
//    [self exitEditMode];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    self.isActive = YES;
    self.isAsc = YES;
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [RootMenuViewController sharedInstance].currVC = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initialize];
}

#pragma mark - Action Menu delegate

- (void)didSelectCrudAction:(NSString *)action {
    if ([action isEqualToString:ACTION_DELETE]) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle: @"Delete Confirmation"
                              message: [NSString stringWithFormat:@"Are you sure to delete this %@?", [self.currentDocument class]]
                              delegate: self
                              cancelButtonTitle:@"No"
                              otherButtonTitles:@"Yes", nil];
        [alert show];
    }
}

@end
