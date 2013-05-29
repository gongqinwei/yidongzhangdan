//
//  EditVendorViewController.m
//  BDC
//
//  Created by Qinwei Gong on 4/27/13.
//
//

#import "EditVendorViewController.h"
#import "Vendor.h"
#import "Util.h"
#import "UIHelper.h"
#import "Geo.h"
#import <QuartzCore/QuartzCore.h>

enum VendorInfoType {
    kVendorName,
    kVendorPayBy,
    kVendorAddr1,
    kVendorAddr2,
    kVendorAddr3,
    kVendorAddr4,
    kVendorCity,
    kVendorState,
    kVendorCountry,
    kVendorZip,
    kVendorEmail,
    kVendorPhone
};

#define VendorInfo    [NSArray arrayWithObjects:@"Name", @"Pay By", @"Address1", @"Address2", @"Address3", @"Address4", @"City", @"State", @"Country", @"Zipcode", @"Email", @"Phone", nil]

#define INVALID_OPTION      -1
#define PICKER_TAG_BASE     TAG_BASE * 2

@interface EditVendorViewController () <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, strong) UIPickerView *vendorStatePickerView;
@property (nonatomic, strong) UIPickerView *vendorCountryPickerView;
@property (nonatomic, strong) UITextField *vendorNameTextField;
@property (nonatomic, strong) UITextField *vendorAddr1TextField;
@property (nonatomic, strong) UITextField *vendorAddr2TextField;
@property (nonatomic, strong) UITextField *vendorAddr3TextField;
@property (nonatomic, strong) UITextField *vendorAddr4TextField;
@property (nonatomic, strong) UITextField *vendorCityTextField;
@property (nonatomic, strong) UITextField *vendorStateTextField;
@property (nonatomic, strong) UITextField *vendorCountryTextField;
@property (nonatomic, strong) UITextField *vendorZipTextField;
@property (nonatomic, strong) UITextField *vendorPhoneTextField;
@property (nonatomic, strong) UITextField *vendorEmailTextField;
@property (nonatomic, strong) UILabel *vendorPayByLabel;

@end


@implementation EditVendorViewController

@synthesize vendorStatePickerView;
@synthesize vendorCountryPickerView;
@synthesize vendorNameTextField;
@synthesize vendorAddr1TextField;
@synthesize vendorAddr2TextField;
@synthesize vendorAddr3TextField;
@synthesize vendorAddr4TextField;
@synthesize vendorCityTextField;
@synthesize vendorStateTextField;
@synthesize vendorCountryTextField;
@synthesize vendorZipTextField;
@synthesize vendorPhoneTextField;
@synthesize vendorEmailTextField;
@synthesize vendorPayByLabel;


- (Class)busObjClass {
    return [Vendor class];
}

#pragma mark - Depricated: this method is no longer needed as the edit bar button will be moved to action menu
- (void)editVendor:(UIBarButtonItem *)sender {
    if ([self tryTap]) {
        self.mode = kUpdateMode;
    }
}

- (IBAction)saveBusObj:(UIBarButtonItem *)sender {
    if ([self tryTap]) {
        Vendor *shaddowVendor = (Vendor *)self.shaddowBusObj;
        
        if (shaddowVendor.name == nil || [shaddowVendor.name length] == 0) {
            [UIHelper showInfo:@"Missing name!" withStatus:kError];
            self.navigationItem.rightBarButtonItem.customView = nil;
            return;
        }
        
        [super saveBusObj:sender];
        
        if (self.mode == kCreateMode) {
            [shaddowVendor create];
        } else if (self.mode == kUpdateMode){
            [shaddowVendor update];
        }
    }
}

#pragma mark - Life Cycle methods

- (void)viewDidLoad
{
    if (!self.busObj) {
        self.busObj = [[Vendor alloc] init];
        self.shaddowBusObj = [[Vendor alloc] init];
        ((Vendor *)self.shaddowBusObj).state = nil;
        ((Vendor *)self.shaddowBusObj).country = INVALID_OPTION;
    }
        
    [super viewDidLoad];
    
    if (self.mode == kViewMode) {
        self.modeChanged = NO;
    } else {
        self.crudActions = nil;
        
        if (self.mode == kCreateMode) {
            self.title = @"New Vendor";
        }
    }
    
    self.busObj.editDelegate = self;
    self.shaddowBusObj.editDelegate = self;
    
    self.vendorStatePickerView = [[UIPickerView alloc] initWithFrame:PICKER_RECT];
    self.vendorStatePickerView.delegate = self;
    self.vendorStatePickerView.dataSource = self;
    self.vendorStatePickerView.showsSelectionIndicator = YES;
    self.vendorStatePickerView.tag = kVendorState * PICKER_TAG_BASE;
    if ([((Vendor *)self.shaddowBusObj).state isKindOfClass:[NSNumber class]] && [((Vendor *)self.shaddowBusObj).state intValue] != INVALID_OPTION) {
        [self.vendorStatePickerView selectRow:[((Vendor *)self.shaddowBusObj).state intValue] + 1 inComponent:0 animated:YES];
    }
    
    self.vendorCountryPickerView = [[UIPickerView alloc] initWithFrame:PICKER_RECT];
    self.vendorCountryPickerView.delegate = self;
    self.vendorCountryPickerView.dataSource = self;
    self.vendorCountryPickerView.showsSelectionIndicator = YES;
    self.vendorCountryPickerView.tag = kVendorCountry * PICKER_TAG_BASE;
    if (((Vendor *)self.shaddowBusObj).country != INVALID_OPTION) {
        [self.vendorCountryPickerView selectRow:((Vendor *)self.shaddowBusObj).country + 1 inComponent:0 animated:YES];
    }
    
    self.vendorNameTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:vendorNameTextField];
    self.vendorNameTextField.tag = kVendorName * TAG_BASE;
    self.vendorNameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.vendorNameTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.vendorNameTextField.delegate = self;
    
    self.vendorAddr1TextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.vendorAddr1TextField];
    self.vendorAddr1TextField.tag = kVendorAddr1 * TAG_BASE;
    self.vendorAddr1TextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.vendorAddr1TextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.vendorAddr1TextField.delegate = self;
    
    self.vendorAddr2TextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.vendorAddr2TextField];
    self.vendorAddr2TextField.tag = kVendorAddr2 * TAG_BASE;
    self.vendorAddr2TextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.vendorAddr2TextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.vendorAddr2TextField.delegate = self;
    
    self.vendorAddr3TextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.vendorAddr3TextField];
    self.vendorAddr3TextField.tag = kVendorAddr3 * TAG_BASE;
    self.vendorAddr3TextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.vendorAddr3TextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.vendorAddr3TextField.delegate = self;
    
    self.vendorAddr4TextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.vendorAddr4TextField];
    self.vendorAddr4TextField.tag = kVendorAddr4 * TAG_BASE;
    self.vendorAddr4TextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.vendorAddr4TextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.vendorAddr4TextField.delegate = self;
    
    self.vendorCityTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.vendorCityTextField];
    self.vendorCityTextField.tag = kVendorCity * TAG_BASE;
    self.vendorCityTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.vendorCityTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.vendorCityTextField.delegate = self;
    
    self.vendorStateTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.vendorStateTextField];
    self.vendorStateTextField.tag = kVendorState * TAG_BASE;
    
    self.vendorCountryTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.vendorCountryTextField];
    self.vendorCountryTextField.tag = kVendorCountry * TAG_BASE;
    self.vendorCountryTextField.rightViewMode = UITextFieldViewModeAlways;
    self.vendorCountryTextField.inputView = self.vendorCountryPickerView;
    
    self.vendorZipTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.vendorZipTextField];
    self.vendorZipTextField.tag = kVendorZip * TAG_BASE;
    self.vendorZipTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.vendorZipTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.vendorZipTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation; //how about zip in foreign countries?
    self.vendorZipTextField.delegate = self;
    
    self.vendorEmailTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.vendorEmailTextField];
    self.vendorEmailTextField.tag = kVendorEmail * TAG_BASE;
    self.vendorEmailTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.vendorEmailTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.vendorEmailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.vendorEmailTextField.delegate = self;
    
    self.vendorPhoneTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.vendorPhoneTextField];
    self.vendorPhoneTextField.tag = kVendorPhone* TAG_BASE;
    self.vendorPhoneTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.vendorPhoneTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.vendorPhoneTextField.keyboardType = UIKeyboardTypePhonePad;
    self.vendorPhoneTextField.delegate = self;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activityIndicator.hidesWhenStopped = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [VendorInfo count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"VendorInfoItem";
    
    UITableViewCell *cell;
    if (self.modeChanged) {
        if (self.mode == kViewMode) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
        } else {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            if (self.mode == kViewMode) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
            } else {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
            }
        }
    }
    
    cell.textLabel.text = [VendorInfo objectAtIndex:indexPath.row];
    cell.textLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:APP_LABEL_FONT_SIZE];
    cell.detailTextLabel.font = [UIFont fontWithName:APP_FONT size:APP_LABEL_FONT_SIZE];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    switch (indexPath.row) {
        case kVendorName:
        {
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = self.shaddowBusObj.name;
            } else {
                if (self.shaddowBusObj != nil) {
                    self.vendorNameTextField.text = self.shaddowBusObj.name;
                }
                self.vendorNameTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.vendorNameTextField];
            }
        }
            break;
        case kVendorPayBy:
            cell.detailTextLabel.text = [VENDOR_PAYMENT_TYPES objectForKey:((Vendor *)self.shaddowBusObj).payBy];
            break;
        case kVendorAddr1:
        {
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = ((Vendor *)self.shaddowBusObj).addr1;
            } else {
                if (self.shaddowBusObj != nil) {
                    self.vendorAddr1TextField.text = ((Vendor *)self.shaddowBusObj).addr1;
                }
                self.vendorAddr1TextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.vendorAddr1TextField];
            }
        }
            break;
        case kVendorAddr2:
        {
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = ((Vendor *)self.shaddowBusObj).addr2;
            } else {
                if (self.shaddowBusObj != nil) {
                    self.vendorAddr2TextField.text = ((Vendor *)self.shaddowBusObj).addr2;
                }
                self.vendorAddr2TextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.vendorAddr2TextField];
            }
        }
            break;
        case kVendorAddr3:
        {
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = ((Vendor *)self.shaddowBusObj).addr3;
            } else {
                if (self.shaddowBusObj != nil) {
                    self.vendorAddr3TextField.text = ((Vendor *)self.shaddowBusObj).addr3;
                }
                self.vendorAddr3TextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.vendorAddr3TextField];
            }
        }
            break;
        case kVendorAddr4:
        {
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = ((Vendor *)self.shaddowBusObj).addr4;
            } else {
                if (self.shaddowBusObj != nil) {
                    self.vendorAddr4TextField.text = ((Vendor *)self.shaddowBusObj).addr4;
                }
                self.vendorAddr4TextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.vendorAddr4TextField];
            }
        }
            break;
        case kVendorCity:
        {
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = ((Vendor *)self.shaddowBusObj).city;
            } else {
                if (self.shaddowBusObj != nil) {
                    self.vendorCityTextField.text = ((Vendor *)self.shaddowBusObj).city;
                }
                self.vendorCityTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.vendorCityTextField];
            }
        }
            break;
        case kVendorState:
            if (self.mode == kViewMode) {
                if ([((Vendor *)self.shaddowBusObj).state isKindOfClass:[NSNumber class]]) {
                    if ([((Vendor *)self.shaddowBusObj).state intValue] == INVALID_OPTION) {
                        cell.detailTextLabel.text = @"";
                    } else {
                        cell.detailTextLabel.text = [US_STATES objectAtIndex:[((Vendor *)self.shaddowBusObj).state intValue]];
                    }
                } else {
                    cell.detailTextLabel.text = ((Vendor *)self.shaddowBusObj).state;
                }
            } else {
                if ([((Vendor *)self.shaddowBusObj).state isKindOfClass:[NSNumber class]]) {
                    if ([((Vendor *)self.shaddowBusObj).state intValue] == INVALID_OPTION) {
                        self.vendorStateTextField.text = @"";
                    } else {
                        self.vendorStateTextField.text = [US_STATES objectAtIndex:[((Vendor *)self.shaddowBusObj).state intValue]];
                    }
                    
                    self.vendorStateTextField.inputView = self.vendorStatePickerView;
                    self.vendorStateTextField.rightViewMode = UITextFieldViewModeAlways;
                } else {
                    self.vendorStateTextField.text = ((Vendor *)self.shaddowBusObj).state;
                    self.vendorStateTextField.enabled = YES;
                    self.vendorStateTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
                    self.vendorStateTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
                }
                
                self.vendorStateTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.vendorStateTextField];
            }
            break;
        case kVendorCountry:
            if (self.mode == kViewMode) {
                if (((Vendor *)self.shaddowBusObj).country == INVALID_OPTION) {
                    cell.detailTextLabel.text = @"";
                } else {
                    cell.detailTextLabel.text = [COUNTRIES objectAtIndex: ((Vendor *)self.shaddowBusObj).country];
                }
            } else {
                if (((Vendor *)self.shaddowBusObj).country == INVALID_OPTION) {
                    self.vendorCountryTextField.text = @"";
                } else {
                    self.vendorCountryTextField.text = [COUNTRIES objectAtIndex: ((Vendor *)self.shaddowBusObj).country];
                }
                self.vendorCountryTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.vendorCountryTextField];
            }
            break;
        case kVendorZip:
        {
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = ((Vendor *)self.shaddowBusObj).zip;
            } else {
                if (self.shaddowBusObj != nil) {
                    self.vendorZipTextField.text = ((Vendor *)self.shaddowBusObj).zip;
                }
                self.vendorZipTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.vendorZipTextField];
            }
        }
            break;
        case kVendorEmail:
        {
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = ((Vendor *)self.shaddowBusObj).email;
            } else {
                if (self.shaddowBusObj != nil) {
                    self.vendorEmailTextField.text = ((Vendor *)self.shaddowBusObj).email;
                }
                self.vendorEmailTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.vendorEmailTextField];
            }
        }
            break;
        case kVendorPhone:
        {
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = ((Vendor *)self.shaddowBusObj).phone;
            } else {
                if (self.shaddowBusObj != nil) {
                    self.vendorPhoneTextField.text = ((Vendor *)self.shaddowBusObj).phone;
                }
                self.vendorPhoneTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.vendorPhoneTextField];
            }
        }
            break;
        default:
            break;
    }
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

//// Override to support editing the table view.
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//    // Delete the row from the data source
//        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//    }
//    else if (editingStyle == UITableViewCellEditingStyleInsert) {
//    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//    }
//}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    
    //    [self textFieldDoneEditing:self.editingField];
    [self.vendorStateTextField resignFirstResponder];
    [self.vendorCountryTextField resignFirstResponder];
}

#pragma mark - Text Field delegate

// private
- (void)textFieldDoneEditing:(UITextField *)textField {
    if (textField != nil) {
        //        [self.editingField resignFirstResponder];
        //        self.editingField = nil;
        
        NSString *txt = [Util trim:textField.text];
        //        if ([txt length] > 0) {
        switch (textField.tag) {
            case kVendorName * TAG_BASE:
                self.shaddowBusObj.name = txt;
                break;
            case kVendorAddr1 * TAG_BASE:
                ((Vendor *)self.shaddowBusObj).addr1 = txt;
                break;
            case kVendorAddr2 * TAG_BASE:
                ((Vendor *)self.shaddowBusObj).addr2 = txt;
                break;
            case kVendorAddr3 * TAG_BASE:
                ((Vendor *)self.shaddowBusObj).addr3 = txt;
                break;
            case kVendorAddr4 * TAG_BASE:
                ((Vendor *)self.shaddowBusObj).addr4 = txt;
                break;
            case kVendorCity * TAG_BASE:
                ((Vendor *)self.shaddowBusObj).city = txt;
                break;
            case kVendorZip * TAG_BASE:
                ((Vendor *)self.shaddowBusObj).zip = txt;
                break;
            case kVendorEmail * TAG_BASE:
                ((Vendor *)self.shaddowBusObj).email = txt;
                break;
            case kVendorPhone * TAG_BASE:
                ((Vendor *)self.shaddowBusObj).phone = txt;
                break;
            default:
                break;
        }
        //        }
        
    }
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    [self textFieldDoneEditing:textField];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    //    self.editingField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self textFieldDoneEditing:textField];
}

#pragma mark - UIPickerView Datascource

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (pickerView.tag == kVendorState * PICKER_TAG_BASE) {
        return [US_STATES count] + 1;
    } else if (pickerView.tag == kVendorCountry * PICKER_TAG_BASE) {
        return [COUNTRIES count] + 1;
    } else {
        return 0;
    }
}

- (NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (row == 0) {
        return SELECT_ONE;
    }
    if (pickerView.tag == kVendorState * PICKER_TAG_BASE) {
        return [US_STATES objectAtIndex: row - 1];
    } else if (pickerView.tag == kVendorCountry * PICKER_TAG_BASE) {
        return [COUNTRIES objectAtIndex: row - 1];
    } else {
        return nil;
    }
}

#pragma mark - UIPickerView Delegate

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (pickerView.tag == kVendorState * PICKER_TAG_BASE) {
        if (row == 0) {
            self.vendorStateTextField.text = @"";
            ((Vendor *)self.shaddowBusObj).state = [NSNumber numberWithInt:INVALID_OPTION];
        } else {
            self.vendorStateTextField.text = [US_STATES objectAtIndex: row - 1];
            ((Vendor *)self.shaddowBusObj).state = [NSNumber numberWithInt: row - 1];
        }
    } else if (pickerView.tag == kVendorCountry * PICKER_TAG_BASE) {
        if (row == 0) {
            self.vendorCountryTextField.text = @"";
            ((Vendor *)self.shaddowBusObj).country = INVALID_OPTION;
        } else {
            self.vendorCountryTextField.text = [COUNTRIES objectAtIndex: row - 1] ;
            ((Vendor *)self.shaddowBusObj).country = row - 1;
        }
        
        if (row == 1) {  //USA
            self.vendorStateTextField.inputView = self.vendorStatePickerView;
            self.vendorStateTextField.rightViewMode = UITextFieldViewModeAlways;
            if (![((Vendor *)self.shaddowBusObj).state isKindOfClass:[NSNumber class]]) {
                self.vendorStateTextField.text = @"";
                ((Vendor *)self.shaddowBusObj).state = [NSNumber numberWithInt:INVALID_OPTION];
            }
        } else {
            self.vendorStateTextField.inputView = nil;
            if ([((Vendor *)self.shaddowBusObj).state isKindOfClass:[NSNumber class]]) {
                self.vendorStateTextField.text = @"";
                ((Vendor *)self.shaddowBusObj).state = nil;
            }
            self.vendorStateTextField.text = ((Vendor *)self.shaddowBusObj).state;
            self.vendorStateTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
            self.vendorStateTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
        }
    }
}


@end


