//
//  ScannerViewController.m
//  BDC
//
//  Created by Qinwei Gong on 6/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
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
    self.preview.image = nil;
    self.submit.hidden = YES;
}

- (NSString *)autoFillPhotoName {
    NSString *file = self.fileName.text;
    
    if(file.length == 0) {
//        NSDateFormatter *format = [[NSDateFormatter alloc] init];
//        [format setDateFormat:@"yyyyMMMddHHmmss"];
//        file = [format stringFromDate:[NSDate date]];   //use timestamp as filename if it's not given
        
        file = [Util formatDate:[NSDate date] format:@"yyyyMMMddHHmmss"];
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
        [self dismissModalViewControllerAnimated:YES];
    } else {
        [self performSegueWithIdentifier:SELECT_BO_SEGUE sender:self];
    }    
}
- (IBAction)takePhoto:(UIBarButtonItem *)sender {
    [self.actions showFromBarButtonItem:sender animated:YES];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString *photoName = [self autoFillPhotoName];
        
//    [(BOSelectorViewController *)segue.destinationViewController setPhotoName:photoName];
//    [segue.destinationViewController setPhotoData:self.photoData];
    
    Document *doc = [[Document alloc] init];
    doc.name = photoName;
    doc.data = self.photoData;
    [segue.destinationViewController setDocument:doc];
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
                    [self presentModalViewController:self.picker animated:YES];
                }
            }

            break;
        case kChooseFromLibrary:
            self.picker = [[UIImagePickerController alloc] init];
            self.picker.delegate = self;
            self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self presentModalViewController:self.picker animated:YES];

            break;
        default:
            if (self.mode == kAttachMode) {
                [self dismissModalViewControllerAnimated:YES];
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
    [self dismissModalViewControllerAnimated:YES];
    [self.fileName resignFirstResponder];
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage * image = [info objectForKey:UIImagePickerControllerEditedImage];
    if(!image) image = [info objectForKey:UIImagePickerControllerOriginalImage];
    if(image) {
        self.photoData = UIImageJPEGRepresentation(image, 1.0);
        UIImage *img = [UIImage imageWithData:self.photoData];
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
    [self dismissImagePicker];
}

@end
