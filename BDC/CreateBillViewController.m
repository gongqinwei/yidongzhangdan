//
//  CreateBillViewController.m
//  BDC
//
//  Created by Qinwei Gong on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CreateBillViewController.h"
#import "Constants.h"
#import "UIHelper.h"
#import "Uploader.h"
#import "APIHandler.h"

#import <QuartzCore/QuartzCore.h>

enum InfoType {
    kBillVendor,
    kBillNumber,
    kBillPaymentTerms,
    kBillDate,
    kBillDueDate,
    kBillApprovalStatus,
    kBillPaidAmount,
    kBillAmount,
    kBillAccount
};

#define RESET_SCANNER_FROM_NEW_BILL_SEGUE   @"Reset_Scan"
#define BILL_INFO_CELL_ID                   @"Bill info cell"


@interface CreateBillViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, BusObjectDelegate>

@property (nonatomic, strong) UIPickerView *vendorPicker;
@property (nonatomic, strong) UIPickerView *paymentTermsPicker;
@property (nonatomic, strong) UIPickerView *accountPicker;
@property (nonatomic, strong) UIDatePicker *invoiceDatePicker;
@property (nonatomic, strong) UIDatePicker *dueDatePicker;

@property (nonatomic, strong) UITextField *currentField;

//private methods
- (NSString *)shortLocalDateStringFromDate:(NSDate *)date;

@end

@implementation CreateBillViewController

@synthesize bill;
@synthesize info;
@synthesize currentField;

@synthesize attachment;
@synthesize infoTable;

@synthesize photoId = _photoId;

@synthesize photoName;
@synthesize photoData;

@synthesize vendorPicker;
@synthesize paymentTermsPicker;
@synthesize accountPicker;
@synthesize invoiceDatePicker;
@synthesize dueDatePicker;


- (void) setPhotoId:(NSString *)photoId {
    _photoId = photoId;

    if (!self.bill) {
        self.bill = [[Bill alloc] init];
    }
//    [self.bill.docs addObject:_photoId];
}

- (IBAction)saveBill:(UIBarButtonItem *)sender {
    [self.currentField resignFirstResponder];
    
//    if (self.mode == CREATE) {
        [self.bill create];
//    } else {
//        [self.bill update];
//    }

    [UIHelper switchViewController:self toTab:kAPTab withSegue:RESET_SCANNER_FROM_NEW_BILL_SEGUE animated:YES];
    
//    [self performSegueWithIdentifier:RESET_SCANNER_FROM_NEW_BILL_SEGUE sender:self];
//    [self.tabBarController setSelectedIndex:kAPTab];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:RESET_SCANNER_FROM_NEW_BILL_SEGUE]) {
        [segue.destinationViewController setPhotoData:nil]; //sets both photo data and id to nil
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.attachment setImage:[UIImage imageWithData:self.photoData]];
    self.infoTable.delegate = self;
    self.infoTable.dataSource = self;
    
    self.info = [NSArray arrayWithObjects:VENDOR, InvoiceNumber, PaymentTerms, InvoiceDate, DueDate, Amount, Account, nil];
    
    if (!self.bill) {
        self.bill = [[Bill alloc] init];
        self.bill.editDelegate = self;
    }
}

- (void)viewDidUnload
{
    [self setAttachment:nil];
    [self setInfoTable:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark UITableViewDatasource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.info count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * CellId = BILL_INFO_CELL_ID;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellId];
    }
    
    UILabel * nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 2, 95, 25)];
    nameLabel.text = [self.info objectAtIndex:indexPath.row];
    nameLabel.font = [nameLabel.font fontWithSize:13];
    nameLabel.textAlignment = NSTextAlignmentRight;
    [cell addSubview:nameLabel];
    
    UITextField * valueField = [[UITextField alloc] initWithFrame:CGRectMake(100, 0, 185, 30)];
    valueField.userInteractionEnabled = YES;
    valueField.font = [valueField.font fontWithSize:13];
    valueField.borderStyle = UITextBorderStyleNone;
    valueField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    valueField.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    valueField.layer.borderWidth = 0.5f;
    valueField.layer.cornerRadius = 5.0f;
    valueField.layer.masksToBounds = YES;
    valueField.tag = indexPath.row;
//    valueField.returnKeyType = UIReturnKeyNext;  //TODO: suitable here?????
    valueField.delegate = self;
    
    UIView *padding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 30)];
    valueField.leftView = padding;
    valueField.leftViewMode = UITextFieldViewModeAlways;
    
    switch (indexPath.row) {
        case kBillVendor:
            if (!self.vendorPicker) {
                self.vendorPicker = [[UIPickerView alloc] initWithFrame:PICKER_RECT];
                self.vendorPicker.delegate = self;
                self.vendorPicker.dataSource = self;
                self.vendorPicker.showsSelectionIndicator = YES;
            }
//            [self.vendorPicker selectRow:opportunity_.isTarget inComponent:0 animated:NO];
            valueField.inputView = self.vendorPicker;
//            valueField.inputAccessoryView = [self inputAccessoryViewForIndexPath:indexPath];
            break;
        case kBillNumber:
            break;
        case kBillPaymentTerms:
            if (!self.paymentTermsPicker) {
                self.paymentTermsPicker = [[UIPickerView alloc] initWithFrame:PICKER_RECT];
                self.paymentTermsPicker.delegate = self;
                self.paymentTermsPicker.dataSource = self;
                self.paymentTermsPicker.showsSelectionIndicator = YES;
            }
            valueField.inputView = self.paymentTermsPicker;
            break;
        case kBillDate:
            if (!self.invoiceDatePicker) {
                self.invoiceDatePicker = [[UIDatePicker alloc] initWithFrame:PICKER_RECT];
                self.invoiceDatePicker.datePickerMode = UIDatePickerModeDate;
                self.invoiceDatePicker.date = [NSDate date];
            }
            valueField.inputView = self.invoiceDatePicker;
            break;
        case kBillDueDate:
            if (!self.dueDatePicker) {
                self.dueDatePicker = [[UIDatePicker alloc] initWithFrame:PICKER_RECT];
                self.dueDatePicker.datePickerMode = UIDatePickerModeDate;
//                self.dueDatePicker.date = [NSDate date];
            }
            valueField.inputView = self.dueDatePicker;
            break;
        case kBillAmount:
            valueField.keyboardType = UIKeyboardTypeDecimalPad;
            break;
        case kBillAccount:
            if (!self.accountPicker) {
                self.accountPicker = [[UIPickerView alloc] initWithFrame:PICKER_RECT];
                self.accountPicker.delegate = self;
                self.accountPicker.dataSource = self;
                self.accountPicker.showsSelectionIndicator = YES;
            }
            valueField.inputView = self.accountPicker;
            break;
        default:
            break;
    }
    
    valueField.inputAccessoryView = [self inputAccessoryViewForIndexPath:indexPath];
    [cell addSubview:valueField];
    return cell;
}

#pragma mark UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 35;
}

#pragma mark UIPickerView Datascource

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if(pickerView == self.vendorPicker) {
        return [VendorArray count];
    } else if(pickerView == self.paymentTermsPicker) {
        return [PaymentTermsArray count];
    } else if(pickerView == self.accountPicker) {
        return [AccountArray count];
    }

    return 0;
}

- (NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if(pickerView == self.vendorPicker) {
        return [VendorArray objectAtIndex:row];
    } else if(pickerView == self.paymentTermsPicker) {
        return [PaymentTermsArray objectAtIndex:row];
    } else if(pickerView == self.accountPicker) {
        return [AccountArray objectAtIndex:row];
    }
    
    return NULL;
}

#pragma mark UIPickerView Delegate

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.currentField = textField;
    
//    UITableViewCell *cell = (UITableViewCell *)[textField superview];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.1]; 
    CGRect rect = self.infoTable.frame;
    CGRect smallRect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height - TableViewShrinkSize);
    [self.infoTable setFrame:smallRect];
    [self.infoTable setScrollEnabled:YES];
    [self.infoTable setNeedsDisplay];
    [UIView commitAnimations];
    
//    NSIndexPath *cellPath = [self.infoTable indexPathForCell:cell];
//    [self.infoTable scrollToRowAtIndexPath:cellPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.1]; 
    CGRect rect = self.infoTable.frame;
    CGRect smallRect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height + TableViewShrinkSize);
    [self.infoTable setFrame:smallRect];
    [self.infoTable setScrollEnabled:NO];
    [self.infoTable setNeedsDisplay];
    [UIView commitAnimations];
    
    switch (textField.tag) {
        case kBillNumber: self.bill.invoiceNumber = textField.text; break;
//        case kBillAmount: self.bill.amount = [[NSDecimalNumber decimalNumberWithString:textField.text] decimalValue];
        default: break;
    }
    
    self.currentField = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
//    currentTextField_ = nil;
    //    NSIndexPath *selectedPath = [tvEdit_ indexPathForSelectedRow];
    //    [tvEdit_ deselectRowAtIndexPath:selectedPath animated:NO];
    return YES;
}

#pragma mark Private methods

- (UIToolbar *)inputAccessoryViewForIndexPath:(NSIndexPath *)indexPath {
    UIToolbar *tlbControls = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, ToolbarHeight)];
    tlbControls.barStyle = UIBarStyleBlackTranslucent;
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(inputAccessoryCancelAction:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:StrDone
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(inputAccessoryDoneAction:)];
    doneButton.tag = indexPath.row;
    tlbControls.items = [NSArray arrayWithObjects:cancelButton, flexibleSpace, doneButton, nil];

    return tlbControls;
}

- (void)inputAccessoryCancelAction:(UIBarButtonItem *)button {
    [self.currentField resignFirstResponder];
    self.currentField = nil;
    NSIndexPath *selectedPath = [self.infoTable indexPathForSelectedRow];
    [self.infoTable deselectRowAtIndexPath:selectedPath animated:NO];
}

- (void)inputAccessoryDoneAction:(UIBarButtonItem *)button {
    switch (button.tag) {
        case kBillDate: {
            self.bill.invoiceDate = self.invoiceDatePicker.date;
            self.currentField.text = [self shortLocalDateStringFromDate:self.invoiceDatePicker.date];
            break;
        }
        case kBillDueDate: {
            self.bill.dueDate = self.dueDatePicker.date;
            self.currentField.text = [self shortLocalDateStringFromDate:self.dueDatePicker.date];
            break;
        }
        case kBillVendor: {
            NSInteger selectedIndex = [self.vendorPicker selectedRowInComponent:0];
//            self.bill.vendorId = 
            self.currentField.text = [VendorArray objectAtIndex:selectedIndex];
            break;
        }
        case kBillPaymentTerms: {
            NSInteger selectedIndex = [self.paymentTermsPicker selectedRowInComponent:0];
//            self.bill.paymentTermId = 
            self.currentField.text = [PaymentTermsArray objectAtIndex:selectedIndex];
            break;
        }
        case kBillAccount: {
            NSInteger selectedIndex = [self.accountPicker selectedRowInComponent:0];
//            self.bill.account = 
            self.currentField.text = [AccountArray objectAtIndex:selectedIndex];
            break;
        }
        default:
            break;
    }
    
    [self.currentField resignFirstResponder];
    self.currentField = nil;
    NSIndexPath *selectedPath = [self.infoTable indexPathForSelectedRow];
    [self.infoTable deselectRowAtIndexPath:selectedPath animated:NO];
}

//TODO: move to Util
- (NSString *)shortLocalDateStringFromDate:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    return [dateFormatter stringFromDate:date];
}

#pragma mark - model delegate
- (void)didCreateBill {
//    [Uploader uploadFile:self.photoName data:self.photoData objectId:self.bill.billId handler:^(NSURLResponse * response, NSData * data, NSError * err) {
//        NSInteger status;
//        [APIHandler getResponse:response data:data error:&err status:&status];
//        
//        if(status == RESPONSE_SUCCESS) {
//            [UIHelper showInfo:@"Attachment saved." withStatus:kSuccess];
//        } else {
//            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
//            Debug(@"Failed to save attachment: %@", [err localizedDescription]);
//        }
//    }];
}


@end
