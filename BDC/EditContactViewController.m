//
//  EditContactViewController.m
//  Mobill
//
//  Created by Qinwei Gong on 9/15/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "EditContactViewController.h"
#import "UIHelper.h"

enum ContactInfoType {
    kContactFName,
    kContactLName,
    kContactEmail,
    kContactPhone
};

#define ContactInfo        [NSArray arrayWithObjects:@"First Name", @"Last Name", @"Email", @"Phone", nil]


@interface EditContactViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *contactFNameTextField;
@property (nonatomic, strong) UITextField *contactLNameTextField;
@property (nonatomic, strong) UITextField *contactPhoneTextField;
@property (nonatomic, strong) UITextField *contactEmailTextField;

@end

@implementation EditContactViewController

@synthesize customer;
@synthesize contactFNameTextField;
@synthesize contactLNameTextField;
@synthesize contactEmailTextField;
@synthesize contactPhoneTextField;


- (Class)busObjClass {
    return [CustomerContact class];
}

- (BOOL)isAR {
    return YES;
}

- (NSIndexSet *)getNonAttachmentSections {
    return [NSIndexSet indexSetWithIndex:0];
}

- (IBAction)saveBusObj:(UIBarButtonItem *)sender {
    if ([self tryTap]) {
        [self.view findAndResignFirstResponder];
        
        CustomerContact *shaddowContact = (CustomerContact *)self.shaddowBusObj;
        
        if (shaddowContact.fname == nil || shaddowContact.fname.length == 0) {
            [UIHelper showInfo:@"Missing first name!" withStatus:kError];
            self.navigationItem.rightBarButtonItem.customView = nil;
            return;
        }
        
        if (shaddowContact.email == nil || shaddowContact.email.length == 0) {
            [UIHelper showInfo:@"Missing email!" withStatus:kError];
            self.navigationItem.rightBarButtonItem.customView = nil;
            return;
        }
        
        shaddowContact.name = shaddowContact.fname;
        if (shaddowContact.lname && shaddowContact.lname.length > 0) {
            shaddowContact.name = [shaddowContact.name stringByAppendingFormat:@" %@", shaddowContact.lname];
        }
        
        [super saveBusObj:sender];
        
        if (self.mode == kCreateMode) {
            [shaddowContact create];
        } else if (self.mode == kUpdateMode){
            [shaddowContact update];
        }
    }
}

#pragma mark - Life Cycle methods

- (void)viewDidLoad
{
    if (!self.busObj) {
        self.busObj = [[CustomerContact alloc] initWithCustomer:self.customer];
        self.shaddowBusObj = [[CustomerContact alloc] initWithCustomer:self.customer];
    }

    [super viewDidLoad];
    
    if (self.mode != kViewMode) {
        self.crudActions = nil;
        
        if (self.mode == kCreateMode) {
            self.title = @"New Contact";
        }
    }
    
//    CustomerContact *shaddowContact = (CustomerContact *)self.shaddowBusObj;
    
    self.busObj.editDelegate = self;
    self.shaddowBusObj.editDelegate = self;
        
    self.contactFNameTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:contactFNameTextField];
    self.contactFNameTextField.tag = kContactFName * TAG_BASE;
    self.contactFNameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.contactFNameTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.contactFNameTextField.delegate = self;
        
    self.contactLNameTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.contactLNameTextField];
    self.contactLNameTextField.tag = kContactLName * TAG_BASE;
    self.contactLNameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.contactLNameTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.contactLNameTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.contactLNameTextField.delegate = self;
    
    self.contactEmailTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.contactEmailTextField];
    self.contactEmailTextField.tag = kContactEmail * TAG_BASE;
    self.contactEmailTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.contactEmailTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.contactEmailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.contactEmailTextField.delegate = self;
    
    self.contactPhoneTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.contactPhoneTextField];
    self.contactPhoneTextField.tag = kContactPhone * TAG_BASE;
    self.contactPhoneTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.contactPhoneTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.contactPhoneTextField.keyboardType = UIKeyboardTypePhonePad;
    self.contactPhoneTextField.delegate = self;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activityIndicator.hidesWhenStopped = YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [ContactInfo count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CUSTOMER_INFO_CELL_ID = @"ContactInfoItem";
    
    UITableViewCell *cell;
    CustomerContact *shaddowContact = (CustomerContact *)self.shaddowBusObj;
    
    if (!cell) {
        if (self.mode == kViewMode) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CUSTOMER_INFO_CELL_ID];
        } else {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CUSTOMER_INFO_CELL_ID];
        }
    }
    
    cell.textLabel.text = ContactInfo[indexPath.row];
    cell.textLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:APP_LABEL_FONT_SIZE];
    cell.detailTextLabel.font = [UIFont fontWithName:APP_FONT size:APP_LABEL_FONT_SIZE];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    switch (indexPath.row) {
        case kContactFName:
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = shaddowContact.fname;
            } else {
                if (shaddowContact != nil) {
                    self.contactFNameTextField.text = shaddowContact.fname;
                }
                self.contactFNameTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.contactFNameTextField];
            }
            break;
        case kContactLName:
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = shaddowContact.lname;
            } else {
                if (shaddowContact != nil) {
                    self.contactLNameTextField.text = shaddowContact.lname;
                }
                self.contactLNameTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.contactLNameTextField];
            }
            break;
        case kContactEmail:
            if (self.mode == kViewMode) {
                UIImageView *emailImg = [[UIImageView alloc] initWithFrame:CGRectMake(30, 14, 18, 18)];
                emailImg.image = [UIImage imageNamed:@"emailIcon1.png"];
                [cell addSubview:emailImg];
                
                UITextView *emailView = [[UITextView alloc] initWithFrame:CGRectMake(100, 5, CELL_WIDTH - 100, CELL_HEIGHT - 10)];
                emailView.font = [UIFont systemFontOfSize:TABLE_CELL_DETAIL_TEXT_FONT];
                emailView.text = shaddowContact.email;
                emailView.backgroundColor = [UIColor clearColor];
                emailView.editable = NO;
                emailView.dataDetectorTypes = UIDataDetectorTypeLink;
                
                [cell addSubview:emailView];
            } else {
                if (shaddowContact != nil) {
                    self.contactEmailTextField.text = shaddowContact.email;
                }
                self.contactEmailTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.contactEmailTextField];
            }
            break;
        case kContactPhone:
            if (self.mode == kViewMode) {
                UIImageView *phoneImg = [[UIImageView alloc] initWithFrame:CGRectMake(30, 14, 16, 16)];
                phoneImg.image = [UIImage imageNamed:@"phoneIcon.png"];
                [cell addSubview:phoneImg];
                                
                UITextView *phoneView = [[UITextView alloc] initWithFrame:CGRectMake(100, 5, CELL_WIDTH - 100, CELL_HEIGHT - 10)];
                phoneView.font = [UIFont systemFontOfSize:TABLE_CELL_DETAIL_TEXT_FONT];
                phoneView.text = shaddowContact.phone;
                phoneView.backgroundColor = [UIColor clearColor];
                phoneView.editable = NO;
                phoneView.dataDetectorTypes = UIDataDetectorTypePhoneNumber;
                
                [cell addSubview:phoneView];
            } else {
                if (shaddowContact != nil) {
                    self.contactPhoneTextField.text = shaddowContact.phone;
                }
                self.contactPhoneTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.contactPhoneTextField];
            }
            break;
        default:
            break;
    }
    
    return cell;
}

//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return NO;
//}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    
//    //    [self textFieldDoneEditing:self.editingField];
//    [self.customerStateTextField resignFirstResponder];
//    [self.customerCountryTextField resignFirstResponder];
}

#pragma mark - Text Field delegate

// private
- (void)textFieldDoneEditing:(UITextField *)textField {
    if (textField != nil) {
        CustomerContact *shaddowContact = (CustomerContact *)self.shaddowBusObj;
        NSString *txt = [Util trim:textField.text];
        
        switch (textField.tag) {
            case kContactFName * TAG_BASE:
                shaddowContact.fname = txt;
                break;
            case kContactLName * TAG_BASE:
                shaddowContact.lname = txt;
                break;
            case kContactEmail * TAG_BASE:
                shaddowContact.email = txt;
                break;
            case kContactPhone * TAG_BASE:
                shaddowContact.phone = txt;
                break;
            default:
                break;
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    [self textFieldDoneEditing:textField];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self textFieldDoneEditing:textField];
    
    [super textFieldDidEndEditing:textField];
}

#pragma mark - Model delegate

- (void)didReadObject {
    [super didReadObject];
    [self.shaddowBusObj cloneTo:self.busObj];
}

- (void)doneSaveObject {
    [super doneSaveObject];
}

@end
