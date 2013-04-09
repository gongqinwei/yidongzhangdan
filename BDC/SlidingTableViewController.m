//
//  SlidingTableViewController.m
//  BDC
//
//  Created by Qinwei Gong on 10/15/12.
//
//

#import "SlidingTableViewController.h"
#import "RootMenuViewController.h"


@implementation SlidingTableViewController

@synthesize createNewSegue;

#pragma mark - Overriding methods

- (void)enterEditMode {
    [super enterEditMode];
    
    [self.tableView setEditing:YES animated:YES];
}

- (void)exitEditMode {
    [super exitEditMode];
    
    [self.tableView setEditing:NO animated:YES];
}

#pragma mark - life cycle methods

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    self.isActive = YES;
    self.isAsc = YES;
    
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [RootMenuViewController sharedInstance].currVC = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // keep a strong reference to self.navigationController so that it won't be released by ARC
    self.navigation = self.navigationController;
    
    self.leftSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toggleMenu:)];
    self.leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:self.leftSwipeRecognizer];
    
    self.rightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toggleMenu:)];
    self.rightSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:self.rightSwipeRecognizer];
    
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleMenu:)];
    
    self.actionMenuVC = nil;
    self.slidingOutDelegate = [RootMenuViewController sharedInstance];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.mode == kCreateMode || self.mode == kUpdateMode || self.mode == kModifyMode) {
        [self.view findAndResignFirstResponder];
    }
}

#pragma mark - Action Menu delegate

- (void)didSelectCrudAction:(NSString *)action {
    if ([action isEqualToString:ACTION_CREATE]) {
        [self.view removeGestureRecognizer:self.tapRecognizer];
        [self performSegueWithIdentifier:self.createNewSegue sender:nil];
    } else if ([action isEqualToString:ACTION_DELETE] || [action isEqualToString:ACTION_UNDELETE]) {
        [self enterEditMode];
    }
}

@end
