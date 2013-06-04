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

    [self initialize];
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

@end
