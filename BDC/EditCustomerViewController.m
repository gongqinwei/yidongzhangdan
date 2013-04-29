//
//  EditCustomerViewController.m
//  BDC
//
//  Created by Qinwei Gong on 2/18/13.
//
//

#import "EditCustomerViewController.h"
#import "Util.h"
#import "UIHelper.h"
#import "Geo.h"
#import <QuartzCore/QuartzCore.h>

enum CustomerInfoType {
    kCustomerName,
    kCustomerAddr1,
    kCustomerAddr2,
    kCustomerAddr3,
    kCustomerAddr4,
    kCustomerCity,
    kCustomerState,
    kCustomerCountry,
    kCustomerZip,
    kCustomerEmail,
    kCustomerPhone
};

#define CustomerInfo    [NSArray arrayWithObjects:@"Name", @"Address1", @"Address2", @"Address3", @"Address4", @"City", @"State", @"Country", @"Zipcode", @"Email", @"Phone", nil]

#define INVALID_OPTION      -1
#define PICKER_TAG_BASE     TAG_BASE * 2

@interface EditCustomerViewController () <CustomerDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, strong) Customer *shaddowCustomer;
@property (nonatomic, assign) BOOL modeChanged;

@property (nonatomic, strong) UIPickerView *customerStatePickerView;
@property (nonatomic, strong) UIPickerView *customerCountryPickerView;
@property (nonatomic, strong) UITextField *customerNameTextField;
@property (nonatomic, strong) UITextField *customerAddr1TextField;
@property (nonatomic, strong) UITextField *customerAddr2TextField;
@property (nonatomic, strong) UITextField *customerAddr3TextField;
@property (nonatomic, strong) UITextField *customerAddr4TextField;
@property (nonatomic, strong) UITextField *customerCityTextField;
@property (nonatomic, strong) UITextField *customerStateTextField;
@property (nonatomic, strong) UITextField *customerCountryTextField;
@property (nonatomic, strong) UITextField *customerZipTextField;
@property (nonatomic, strong) UITextField *customerPhoneTextField;
@property (nonatomic, strong) UITextField *customerEmailTextField;

@end

@implementation EditCustomerViewController

@synthesize customer = _customer;
@synthesize shaddowCustomer;
@synthesize modeChanged;
@synthesize customerStatePickerView;
@synthesize customerCountryPickerView;
@synthesize customerNameTextField;
@synthesize customerAddr1TextField;
@synthesize customerAddr2TextField;
@synthesize customerAddr3TextField;
@synthesize customerAddr4TextField;
@synthesize customerCityTextField;
@synthesize customerStateTextField;
@synthesize customerCountryTextField;
@synthesize customerZipTextField;
@synthesize customerPhoneTextField;
@synthesize customerEmailTextField;


- (void)setCustomer:(Customer *)customer {
    _customer = customer;
    
    self.shaddowCustomer = nil;
    self.shaddowCustomer = [[Customer alloc] init];
    
    [Customer clone:customer to:self.shaddowCustomer];
    self.title = customer.name;
}

- (void)setMode:(ViewMode)mode {
    super.mode = mode;
    self.modeChanged = YES;
    
    if (mode == kViewMode) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(toggleMenu:)];
        self.navigationItem.rightBarButtonItem.tag = 1;
        self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveCustomer:)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEdit:)];
    }
    
    [self.tableView reloadData];
}

#pragma mark - Depricated: this method is no longer needed as the edit bar button will be moved to action menu
- (void)editCustomer:(UIBarButtonItem *)sender {
    if ([self tryTap]) {
        self.mode = kUpdateMode;
    }
}

- (IBAction)saveCustomer:(UIBarButtonItem *)sender {
    if ([self tryTap]) {
        self.navigationItem.rightBarButtonItem.customView = self.activityIndicator;
        [self.activityIndicator startAnimating];
        [self.view findAndResignFirstResponder];
        
        if (self.shaddowCustomer.name == nil || [self.shaddowCustomer.name length] == 0) {
            [UIHelper showInfo:@"Missing name!" withStatus:kError];
            self.navigationItem.rightBarButtonItem.customView = nil;
            return;
        }
        
        if (self.mode == kCreateMode) {
            [self.shaddowCustomer create];
        } else if (self.mode == kUpdateMode){
            [self.shaddowCustomer update];
        }
    }
}

- (void)cancelEdit:(UIBarButtonItem *)sender {
    if ([self tryTap]) {
        if (self.mode == kCreateMode) {
            [self navigateBack];
        } else {
            [self setCustomer:self.customer];
            self.mode = kViewMode;
        }
    }
}

#pragma mark - Life Cycle methods

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    if (!self.customer) {
        self.customer = [[Customer alloc] init];
        self.shaddowCustomer = [[Customer alloc] init];
        self.shaddowCustomer.billState = nil;
        self.shaddowCustomer.billCountry = INVALID_OPTION;
    }
    
    self.busObj = self.customer;
    
    [super viewDidLoad];
    
    if (self.mode == kViewMode) {
        self.modeChanged = NO;
    } else {
        self.crudActions = nil;
        
        if (self.mode == kCreateMode) {
            self.title = @"New Customer";
        }
    }
        
    self.customer.editDelegate = self;
    self.shaddowCustomer.editDelegate = self;
    
    self.customerStatePickerView = [[UIPickerView alloc] initWithFrame:PICKER_RECT];
    self.customerStatePickerView.delegate = self;
    self.customerStatePickerView.dataSource = self;
    self.customerStatePickerView.showsSelectionIndicator = YES;
    self.customerStatePickerView.tag = kCustomerState * PICKER_TAG_BASE;
    if ([self.shaddowCustomer.billState isKindOfClass:[NSNumber class]] && [self.shaddowCustomer.billState intValue] != INVALID_OPTION) {
        [self.customerStatePickerView selectRow:[self.shaddowCustomer.billState intValue] + 1 inComponent:0 animated:YES];
    }
    
    self.customerCountryPickerView = [[UIPickerView alloc] initWithFrame:PICKER_RECT];
    self.customerCountryPickerView.delegate = self;
    self.customerCountryPickerView.dataSource = self;
    self.customerCountryPickerView.showsSelectionIndicator = YES;
    self.customerCountryPickerView.tag = kCustomerCountry * PICKER_TAG_BASE;
    if (self.shaddowCustomer.billCountry != INVALID_OPTION) {
        [self.customerCountryPickerView selectRow:self.shaddowCustomer.billCountry + 1 inComponent:0 animated:YES];
    }
    
    self.customerNameTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:customerNameTextField];
    self.customerNameTextField.tag = kCustomerName * TAG_BASE;
    self.customerNameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.customerNameTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.customerNameTextField.delegate = self;
    
    self.customerAddr1TextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.customerAddr1TextField];
    self.customerAddr1TextField.tag = kCustomerAddr1 * TAG_BASE;
    self.customerAddr1TextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.customerAddr1TextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.customerAddr1TextField.delegate = self;
    
    self.customerAddr2TextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.customerAddr2TextField];
    self.customerAddr2TextField.tag = kCustomerAddr2 * TAG_BASE;
    self.customerAddr2TextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.customerAddr2TextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.customerAddr2TextField.delegate = self;
    
    self.customerAddr3TextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.customerAddr3TextField];
    self.customerAddr3TextField.tag = kCustomerAddr3 * TAG_BASE;
    self.customerAddr3TextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.customerAddr3TextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.customerAddr3TextField.delegate = self;
    
    self.customerAddr4TextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.customerAddr4TextField];
    self.customerAddr4TextField.tag = kCustomerAddr4 * TAG_BASE;
    self.customerAddr4TextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.customerAddr4TextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.customerAddr4TextField.delegate = self;
    
    self.customerCityTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.customerCityTextField];
    self.customerCityTextField.tag = kCustomerCity * TAG_BASE;
    self.customerCityTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.customerCityTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.customerCityTextField.delegate = self;
    
    self.customerStateTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.customerStateTextField];
    self.customerStateTextField.tag = kCustomerState * TAG_BASE;
    
    self.customerCountryTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.customerCountryTextField];
    self.customerCountryTextField.tag = kCustomerCountry * TAG_BASE;
    self.customerCountryTextField.rightViewMode = UITextFieldViewModeAlways;
    self.customerCountryTextField.inputView = self.customerCountryPickerView;
    
    self.customerZipTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.customerZipTextField];
    self.customerZipTextField.tag = kCustomerZip * TAG_BASE;
    self.customerZipTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.customerZipTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.customerZipTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation; //how about zip in foreign countries?
    self.customerZipTextField.delegate = self;
    
    self.customerEmailTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.customerEmailTextField];
    self.customerEmailTextField.tag = kCustomerEmail * TAG_BASE;
    self.customerEmailTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.customerEmailTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.customerEmailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.customerEmailTextField.delegate = self;
    
    self.customerPhoneTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.customerPhoneTextField];
    self.customerPhoneTextField.tag = kCustomerPhone* TAG_BASE;
    self.customerPhoneTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.customerPhoneTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.customerPhoneTextField.keyboardType = UIKeyboardTypePhonePad;
    self.customerPhoneTextField.delegate = self;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activityIndicator.hidesWhenStopped = YES;
}

//- (void)viewWillAppear:(BOOL)animated {
//    [self.view removeGestureRecognizer:self.tapRecognizer];
//}

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
    return [CustomerInfo count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CustomerInfoItem";
    
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
    
    cell.textLabel.text = [CustomerInfo objectAtIndex:indexPath.row];
    cell.textLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:APP_LABEL_FONT_SIZE];
    cell.detailTextLabel.font = [UIFont fontWithName:APP_FONT size:APP_LABEL_FONT_SIZE];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    switch (indexPath.row) {
        case kCustomerName:
        {
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = self.shaddowCustomer.name;
            } else {
                if (self.shaddowCustomer != nil) {
                    self.customerNameTextField.text = self.shaddowCustomer.name;
                }
                self.customerNameTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.customerNameTextField];
            }
        }
            break;
        case kCustomerAddr1:
        {
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = self.shaddowCustomer.billAddr1;
            } else {
                if (self.shaddowCustomer != nil) {
                    self.customerAddr1TextField.text = self.shaddowCustomer.billAddr1;
                }
                self.customerAddr1TextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.customerAddr1TextField];
            }
        }
            break;
        case kCustomerAddr2:
        {
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = self.shaddowCustomer.billAddr2;
            } else {
                if (self.shaddowCustomer != nil) {
                    self.customerAddr2TextField.text = self.shaddowCustomer.billAddr2;
                }
                self.customerAddr2TextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.customerAddr2TextField];
            }
        }
            break;
        case kCustomerAddr3:
        {
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = self.shaddowCustomer.billAddr3;
            } else {
                if (self.shaddowCustomer != nil) {
                    self.customerAddr3TextField.text = self.shaddowCustomer.billAddr3;
                }
                self.customerAddr3TextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.customerAddr3TextField];
            }
        }
            break;
        case kCustomerAddr4:
        {
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = self.shaddowCustomer.billAddr4;
            } else {
                if (self.shaddowCustomer != nil) {
                    self.customerAddr4TextField.text = self.shaddowCustomer.billAddr4;
                }
                self.customerAddr4TextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.customerAddr4TextField];
            }
        }
            break;
        case kCustomerCity:
        {
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = self.shaddowCustomer.billCity;
            } else {
                if (self.shaddowCustomer != nil) {
                    self.customerCityTextField.text = self.shaddowCustomer.billCity;
                }
                self.customerCityTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.customerCityTextField];
            }
        }
            break;
        case kCustomerState:
            if (self.mode == kViewMode) {
                if ([self.shaddowCustomer.billState isKindOfClass:[NSNumber class]]) {
                    if ([self.shaddowCustomer.billState intValue] == INVALID_OPTION) {
                        cell.detailTextLabel.text = @"";
                    } else {
                        cell.detailTextLabel.text = [US_STATES objectAtIndex:[self.shaddowCustomer.billState intValue]];
                    }
                } else {
                    cell.detailTextLabel.text = self.shaddowCustomer.billState;
                }
            } else {
                if ([self.shaddowCustomer.billState isKindOfClass:[NSNumber class]]) {
                    if ([self.shaddowCustomer.billState intValue] == INVALID_OPTION) {
                        self.customerStateTextField.text = @"";
                    } else {
                        self.customerStateTextField.text = [US_STATES objectAtIndex:[self.shaddowCustomer.billState intValue]];
                    }
                    
                    self.customerStateTextField.inputView = self.customerStatePickerView;
                    self.customerStateTextField.rightViewMode = UITextFieldViewModeAlways;
                } else {
                    self.customerStateTextField.text = self.shaddowCustomer.billState;
                    self.customerStateTextField.enabled = YES;
                    self.customerStateTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
                    self.customerStateTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
                }
                
                self.customerStateTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.customerStateTextField];
            }
            break;
        case kCustomerCountry:
            if (self.mode == kViewMode) {
                if (self.shaddowCustomer.billCountry == INVALID_OPTION) {
                    cell.detailTextLabel.text = @"";
                } else {
                    cell.detailTextLabel.text = [COUNTRIES objectAtIndex: self.shaddowCustomer.billCountry];
                }
            } else {
                if (self.shaddowCustomer.billCountry == INVALID_OPTION) {
                    self.customerCountryTextField.text = @"";
                } else {
                    self.customerCountryTextField.text = [COUNTRIES objectAtIndex: self.shaddowCustomer.billCountry];
                }
                self.customerCountryTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.customerCountryTextField];
            }
            break;
        case kCustomerZip:
        {
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = self.shaddowCustomer.billZip;
            } else {
                if (self.shaddowCustomer != nil) {
                    self.customerZipTextField.text = self.shaddowCustomer.billZip;
                }
                self.customerZipTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.customerZipTextField];
            }
        }
            break;
        case kCustomerEmail:
        {
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = self.shaddowCustomer.email;
            } else {
                if (self.shaddowCustomer != nil) {
                    self.customerEmailTextField.text = self.shaddowCustomer.email;
                }
                self.customerEmailTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.customerEmailTextField];
            }
        }
            break;
        case kCustomerPhone:
        {
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = self.shaddowCustomer.phone;
            } else {
                if (self.shaddowCustomer != nil) {
                    self.customerPhoneTextField.text = self.shaddowCustomer.phone;
                }
                self.customerPhoneTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.customerPhoneTextField];
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
    [self.customerStateTextField resignFirstResponder];
    [self.customerCountryTextField resignFirstResponder];
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
                case kCustomerName * TAG_BASE:
                    self.shaddowCustomer.name = txt;
                    break;
                case kCustomerAddr1 * TAG_BASE:
                    self.shaddowCustomer.billAddr1 = txt;
                    break;
                case kCustomerAddr2 * TAG_BASE:
                    self.shaddowCustomer.billAddr2 = txt;
                    break;
                case kCustomerAddr3 * TAG_BASE:
                    self.shaddowCustomer.billAddr3 = txt;
                    break;
                case kCustomerAddr4 * TAG_BASE:
                    self.shaddowCustomer.billAddr4 = txt;
                    break;
                case kCustomerCity * TAG_BASE:
                    self.shaddowCustomer.billCity = txt;
                    break;
                case kCustomerZip * TAG_BASE:
                    self.shaddowCustomer.billZip = txt;
                    break;
                case kCustomerEmail * TAG_BASE:
                    self.shaddowCustomer.email = txt;
                    break;
                case kCustomerPhone * TAG_BASE:
                    self.shaddowCustomer.phone = txt;
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
    if (pickerView.tag == kCustomerState * PICKER_TAG_BASE) {
        return [US_STATES count] + 1;
    } else if (pickerView.tag == kCustomerCountry * PICKER_TAG_BASE) {
        return [COUNTRIES count] + 1;
    } else {
        return 0;
    }
}

- (NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (row == 0) {
        return SELECT_ONE;
    }
    if (pickerView.tag == kCustomerState * PICKER_TAG_BASE) {
        return [US_STATES objectAtIndex: row - 1];
    } else if (pickerView.tag == kCustomerCountry * PICKER_TAG_BASE) {
        return [COUNTRIES objectAtIndex: row - 1];
    } else {
        return nil;
    }
}

#pragma mark - UIPickerView Delegate

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (pickerView.tag == kCustomerState * PICKER_TAG_BASE) {
        if (row == 0) {
            self.customerStateTextField.text = @"";
            self.shaddowCustomer.billState = [NSNumber numberWithInt:INVALID_OPTION];
        } else {
            self.customerStateTextField.text = [US_STATES objectAtIndex: row - 1];
            self.shaddowCustomer.billState = [NSNumber numberWithInt: row - 1];
        }
    } else if (pickerView.tag == kCustomerCountry * PICKER_TAG_BASE) {
        if (row == 0) {
            self.customerCountryTextField.text = @"";
            self.shaddowCustomer.billCountry = INVALID_OPTION;
        } else {
            self.customerCountryTextField.text = [COUNTRIES objectAtIndex: row - 1] ;
            self.shaddowCustomer.billCountry = row - 1;
        }
        
        if (row == 1) {  //USA
            self.customerStateTextField.inputView = self.customerStatePickerView;
            self.customerStateTextField.rightViewMode = UITextFieldViewModeAlways;
            if (![self.shaddowCustomer.billState isKindOfClass:[NSNumber class]]) {
                self.customerStateTextField.text = @"";
                self.shaddowCustomer.billState = [NSNumber numberWithInt:INVALID_OPTION];
            }
        } else {
            self.customerStateTextField.inputView = nil;
            if ([self.shaddowCustomer.billState isKindOfClass:[NSNumber class]]) {
                self.customerStateTextField.text = @"";
                self.shaddowCustomer.billState = nil;
            }
            self.customerStateTextField.text = self.shaddowCustomer.billState;
            self.customerStateTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
            self.customerStateTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
        }
    }
}

#pragma mark - model delegate

- (void)doneSaveObject {
//    [Customer retrieveList];
    
    [Customer clone:self.shaddowCustomer to:self.customer];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.mode = kViewMode;
        self.title = self.shaddowCustomer.name;
    });
    
//    self.navigationItem.rightBarButtonItem.customView = nil;
}

- (void)didCreateCustomer: (NSString *)newCustomerId {
    self.customer.objectId = newCustomerId;
    self.shaddowCustomer.objectId = newCustomerId;
    self.title = self.customerNameTextField.text;
    [self doneSaveObject];
}


@end

