//
//  ScannerViewController.m
//  BDC
//
//  Created by Qinwei Gong on 6/21/12.
//  Copyright (c) 2012 Mobill Inc. All rights reserved.
//

#import "ScannerViewController.h"
#import "Constants.h"
#import "APIHandler.h"
#import "BOSelectorViewController.h"
#import "Util.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define SELECT_BO_SEGUE         @"Select_BO_to_attach"
#define PREVIEW_SCAN_SEGUE      @"PreviewScan"

enum PhotoSourceType {
    kTakePhoto,
    kChooseFromLibrary
};

@interface ScannerViewController () <UITextFieldDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UIImagePickerController * picker;
@property (nonatomic, strong) NSData * photoData;
@property (nonatomic, strong) UIActionSheet *actions;

@end

@implementation ScannerViewController

@synthesize fileName;
@synthesize preview;
@synthesize submit;
@synthesize picker;
@synthesize actions;
@synthesize photoData;
@synthesize mode;
@synthesize delegate;

- (void)reset {
    self.fileName.text = nil;
    self.photoData = nil;
    self.preview.image = nil;
    self.submit.hidden = YES;
}

- (NSString *)autoFillPhotoName {
    NSString *file = self.fileName.text;
    
    if(file.length == 0) {
//        NSDateFormatter *format = [[NSDateFormatter alloc] init];
//        [format setDateFormat:@"yyyyMMMddHHmmss"];
//        file = [format stringFromDate:[NSDate date]];   //use timestamp as filename if it's not given
        
        file = [Util formatDate:[NSDate date] format:@"yyMMddHHmmss"];
    } else {
        file = [file lastPathComponent];
        file = [[file componentsSeparatedByString:@"."] objectAtIndex:0];
    }
    return [file stringByAppendingString:@".jpg"];
}

- (void)imageTapped:(UITapGestureRecognizer *)gestureRecognizer {
    [self performSegueWithIdentifier:PREVIEW_SCAN_SEGUE sender:self.preview];
}

- (IBAction)submit:(id)sender {
    if (self.mode == kAttachMode) {
        [self.delegate didScanPhoto:self.photoData name:self.fileName.text];
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self performSegueWithIdentifier:SELECT_BO_SEGUE sender:self];
    }    
}
- (IBAction)takePhoto:(UIBarButtonItem *)sender {
    [self.actions showFromBarButtonItem:sender animated:YES];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString *photoName = [self autoFillPhotoName];
    
    Document *doc = [[Document alloc] init];
    doc.name = photoName;
    doc.data = self.photoData;
    doc.page = 1;
    [segue.destinationViewController setDocument:doc];
    
    if ([segue.identifier isEqualToString:SELECT_BO_SEGUE]) {
        [segue.destinationViewController setMode:kCreateMode];
    }
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
    self.navigationItem.hidesBackButton = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fileName.delegate = self;
    self.submit.hidden = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    [self.preview addGestureRecognizer:tap];
    
    self.actions = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo", @"Choose from Library", nil];
    [self.actions showInView:self.view];
    
//    if (self.mode == kAttachMode) {
//        Debug(@"nav bar: %@", self.navigationItem.leftBarButtonItem);
//        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissImagePicker)];
//        self.navigationItem.leftBarButtonItem = nil;
//    }
}

- (void)viewDidUnload
{
    [self setPreview:nil];
    [self setFileName:nil];
    self.picker = nil;
    [self setSubmit:nil];

    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Sliding Table View Controller delegate

- (void)viewDidSlideIn {
    [super viewDidSlideIn];
    
    if (!self.actions.window && !self.photoData) {
        [self.actions showInView:self.view];
    }
}

#pragma mark - Action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case kTakePhoto:
            if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                NSArray *mediaType = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
                if([mediaType containsObject:(NSString *)kUTTypeImage]) {
                    self.picker = [[UIImagePickerController alloc] init];
                    self.picker.delegate = self;
                    self.picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                    self.picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
//                    self.picker.allowsEditing = YES;
                    [self presentViewController:self.picker animated:YES completion:nil];
                }
            }

            break;
        case kChooseFromLibrary:
            self.picker = [[UIImagePickerController alloc] init];
            self.picker.delegate = self;
            self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self presentViewController:self.picker animated:YES completion:nil];

            break;
        default:
            if (self.mode == kAttachMode) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            break;
    }
}

#pragma mark - UITextField delegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - UIImagePickerController delegate

- (void) dismissImagePicker {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.fileName resignFirstResponder];
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage * image = [info objectForKey:UIImagePickerControllerEditedImage];
    if(!image) {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    if(image) {
        self.photoData = UIImageJPEGRepresentation(image, 0.1);
        UIImage *img = [UIImage imageWithData:self.photoData];
        img = [Document imageWithImage:img scaledToSize:CGSizeMake(160, 160)];
        self.preview.image = img;
    }
    [self dismissImagePicker];
    
    self.submit.hidden = NO;
    
//    NSString *file = self.fileName.text;
//    
//    if(file.length == 0) {
//        NSDateFormatter *format = [[NSDateFormatter alloc] init];
//        [format setDateFormat:@"yyyyMMMddHHmmss"];
//        file = [format stringFromDate:[NSDate date]];   //use timestamp as filename if it's not given
//    } else {
//        file = [file lastPathComponent];
//        file = [[file componentsSeparatedByString:@"."] objectAtIndex:0];
//    }
//    file = [file stringByAppendingString:@".jpg"];
    self.fileName.text = [self autoFillPhotoName];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:^{
        [self dismissImagePicker];
    }];
}

@end
