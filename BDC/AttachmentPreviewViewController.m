//
//  AttachmentPreviewViewController.m
//  BDC
//
//  Created by Qinwei Gong on 9/30/12.
//
//

#import "AttachmentPreviewViewController.h"
#import "UIHelper.h"

@interface AttachmentPreviewViewController ()

@end

@implementation AttachmentPreviewViewController

@synthesize document;
@synthesize photoImageView;
@synthesize previewNavigationBar;

- (void)imageTapped:(UITapGestureRecognizer *)gestureRecognizer {
    if (self.previewNavigationBar.hidden == YES) {
        self.previewNavigationBar.hidden = NO;
    } else {
        self.previewNavigationBar.hidden = YES;
    }
}

- (IBAction)donePreview:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [UIHelper makeFullScreen:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [UIHelper exitFullScreen:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [self.previewNavigationBar setBarStyle:UIBarStyleBlackTranslucent];
    self.previewNavigationBar.topItem.title = self.document.name;
    
    UIImage *img = [[UIImage alloc] initWithData:self.document.data];
    self.photoImageView.image = img;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    [self.photoImageView addGestureRecognizer:tap];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setPhotoImageView:nil];
    [self setPreviewNavigationBar:nil];
    [super viewDidUnload];
}
@end
