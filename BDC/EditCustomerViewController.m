//
//  EditCustomerViewController.m
//  BDC
//
//  Created by Qinwei Gong on 2/18/13.
//
//

#import "EditCustomerViewController.h"
#import "Customer.h"
#import "Util.h"
#import "UIHelper.h"
#import "Geo.h"
#import <QuartzCore/QuartzCore.h>


enum CustomerSections {
    kCustomerInfo,
    kCustomerAddr,
    kCustomerAttachments
};

enum CustomerInfoType {
    kCustomerName,
    kCustomerEmail,
    kCustomerPhone
};

#define CustomerInfo    [NSArray arrayWithObjects: \
                            [NSArray arrayWithObjects:@"Name", @"Email", @"Phone", nil], \
                            ADDR_DETAILS, \
                            [NSArray arrayWithObjects:nil], \
                        nil]

#define CUSTOMER_ADDR_TAG_OFFSET        3
#define CUSTOMER_SCAN_PHOTO_SEGUE       @"ScanMoreCustomerPhoto"


@interface EditCustomerViewController () <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

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
@property (nonatomic, strong) NSMutableString *address;
@property (nonatomic, assign) int numOfLinesInAddr;

@end


@implementation EditCustomerViewController

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
@synthesize address;
@synthesize numOfLinesInAddr;


- (Class)busObjClass {
    return [Customer class];
}

- (NSIndexPath *)getAttachmentPath {
    return [NSIndexPath indexPathForRow:0 inSection:kCustomerAttachments];
}

- (NSString *)getDocImageAPI {
    return ATTACH_IMAGE_API;
}

- (NSString *)getDocIDParam {
    return ATTACH_ID;
}

#pragma mark - Depricated: this method is no longer needed as the edit bar button will be moved to action menu
- (void)editCustomer:(UIBarButtonItem *)sender {
    if ([self tryTap]) {
        self.mode = kUpdateMode;
    }
}

- (IBAction)saveBusObj:(UIBarButtonItem *)sender {
    if ([self tryTap]) {
        [self.view findAndResignFirstResponder];
        
        Customer *shaddowCustomer = (Customer *)self.shaddowBusObj;
        
        if (self.shaddowBusObj.name == nil || [self.shaddowBusObj.name length] == 0) {
            [UIHelper showInfo:@"Missing name!" withStatus:kError];
            self.navigationItem.rightBarButtonItem.customView = nil;
            return;
        }
        
        [super saveBusObj:sender];
        
        if (self.mode == kCreateMode || self.mode == kAttachMode) {
            [shaddowCustomer create];
        } else if (self.mode == kUpdateMode){
            [shaddowCustomer update];
        }
    }
}

- (void)addMoreAttachment {
    [self.view findAndResignFirstResponder];
    [self performSegueWithIdentifier:CUSTOMER_SCAN_PHOTO_SEGUE sender:self];
}

#pragma mark - Life Cycle methods

- (void)viewDidLoad
{
    if (!self.busObj) {
        self.busObj = [[Customer alloc] init];
        self.shaddowBusObj = [[Customer alloc] init];
        ((Customer *)self.shaddowBusObj).state = nil;
        ((Customer *)self.shaddowBusObj).country = INVALID_OPTION;
    }
        
    [super viewDidLoad];
    
    if (self.mode != kViewMode) {
        self.crudActions = nil;
        
        if (self.mode == kCreateMode || self.mode == kAttachMode) {
            self.title = @"New Customer";
        }
    }
    
    Customer *shaddowCustomer = (Customer *)self.shaddowBusObj;
    
    self.busObj.editDelegate = self;
    self.shaddowBusObj.editDelegate = self;
    
    self.customerStatePickerView = [[UIPickerView alloc] initWithFrame:PICKER_RECT];
    self.customerStatePickerView.delegate = self;
    self.customerStatePickerView.dataSource = self;
    self.customerStatePickerView.showsSelectionIndicator = YES;
    self.customerStatePickerView.tag = (kState + CUSTOMER_ADDR_TAG_OFFSET) * PICKER_TAG_BASE;
    if ([shaddowCustomer.state isKindOfClass:[NSNumber class]] && [shaddowCustomer.state intValue] != INVALID_OPTION) {
        [self.customerStatePickerView selectRow:[shaddowCustomer.state intValue] + 1 inComponent:0 animated:YES];
    }
    
    self.customerCountryPickerView = [[UIPickerView alloc] initWithFrame:PICKER_RECT];
    self.customerCountryPickerView.delegate = self;
    self.customerCountryPickerView.dataSource = self;
    self.customerCountryPickerView.showsSelectionIndicator = YES;
    self.customerCountryPickerView.tag = (kCountry + CUSTOMER_ADDR_TAG_OFFSET) * PICKER_TAG_BASE;
    if (shaddowCustomer.country != INVALID_OPTION) {
        [self.customerCountryPickerView selectRow:shaddowCustomer.country + 1 inComponent:0 animated:YES];
    }
    
    self.customerNameTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:customerNameTextField];
    self.customerNameTextField.tag = kCustomerName * TAG_BASE;
    self.customerNameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.customerNameTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.customerNameTextField.delegate = self;
    
    self.customerAddr1TextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.customerAddr1TextField];
    self.customerAddr1TextField.tag = (kAddr1 + CUSTOMER_ADDR_TAG_OFFSET) * TAG_BASE;
    self.customerAddr1TextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.customerAddr1TextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.customerAddr1TextField.delegate = self;
    
    self.customerAddr2TextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.customerAddr2TextField];
    self.customerAddr2TextField.tag = (kAddr2 + CUSTOMER_ADDR_TAG_OFFSET) * TAG_BASE;
    self.customerAddr2TextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.customerAddr2TextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.customerAddr2TextField.delegate = self;
    
    self.customerAddr3TextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.customerAddr3TextField];
    self.customerAddr3TextField.tag = (kAddr3 + CUSTOMER_ADDR_TAG_OFFSET) * TAG_BASE;
    self.customerAddr3TextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.customerAddr3TextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.customerAddr3TextField.delegate = self;
    
    self.customerAddr4TextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.customerAddr4TextField];
    self.customerAddr4TextField.tag = (kAddr4 + CUSTOMER_ADDR_TAG_OFFSET) * TAG_BASE;
    self.customerAddr4TextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.customerAddr4TextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.customerAddr4TextField.delegate = self;
    
    self.customerCityTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.customerCityTextField];
    self.customerCityTextField.tag = (kCity + CUSTOMER_ADDR_TAG_OFFSET) * TAG_BASE;
    self.customerCityTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.customerCityTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.customerCityTextField.delegate = self;
    
    self.customerStateTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.customerStateTextField];
    self.customerStateTextField.tag = (kState + CUSTOMER_ADDR_TAG_OFFSET) * TAG_BASE;
    
    self.customerCountryTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.customerCountryTextField];
    self.customerCountryTextField.tag = (kCountry + CUSTOMER_ADDR_TAG_OFFSET) * TAG_BASE;
    self.customerCountryTextField.rightViewMode = UITextFieldViewModeAlways;
    self.customerCountryTextField.inputView = self.customerCountryPickerView;
    
    self.customerZipTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.customerZipTextField];
    self.customerZipTextField.tag = (kZip + CUSTOMER_ADDR_TAG_OFFSET) * TAG_BASE;
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
    
    [self formatAddr];
}

- (void)formatAddr {
    self.address = [NSMutableString string];
    self.numOfLinesInAddr = [((BDCBusinessObjectWithAttachmentsAndAddress *)self.shaddowBusObj) formatAddress:self.address];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:CUSTOMER_SCAN_PHOTO_SEGUE]) {
        ((ScannerViewController *)segue.destinationViewController).delegate = self;
        [segue.destinationViewController setMode:kAttachMode];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [CustomerInfo count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kCustomerInfo) {
        return [CustomerInfo[section] count];
    } else if (section == kCustomerAddr) {
        if (self.mode == kViewMode) {
            return 1;
        } else {
            return [CustomerInfo[section] count];
        }
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CUSTOMER_INFO_CELL_ID = @"CustomerInfoItem";
    static NSString *CUSTOMER_ADDRESS_CELL_ID = @"CustomerAddress";
    static NSString *CUSTOMER_ATTACH_CELL_ID = @"CustomerAttachments";
    
    UITableViewCell *cell;
    Customer *shaddowCustomer = (Customer *)self.shaddowBusObj;
    
    switch (indexPath.section) {
        case kCustomerInfo:
        {
            if (self.modeChanged) {
                if (self.mode == kViewMode) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CUSTOMER_INFO_CELL_ID];
                } else {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CUSTOMER_INFO_CELL_ID];
                }
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:CUSTOMER_INFO_CELL_ID];
                if (!cell) {
                    if (self.mode == kViewMode) {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CUSTOMER_INFO_CELL_ID];
                    } else {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CUSTOMER_INFO_CELL_ID];
                    }
                }
            }
            
            cell.textLabel.text = CustomerInfo[indexPath.section][indexPath.row];
            cell.textLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:APP_LABEL_FONT_SIZE];
            cell.detailTextLabel.font = [UIFont fontWithName:APP_FONT size:APP_LABEL_FONT_SIZE];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            switch (indexPath.row) {
                case kCustomerName:
                    if (self.mode == kViewMode) {
                        cell.detailTextLabel.text = self.shaddowBusObj.name;
                    } else {
                        if (self.shaddowBusObj != nil) {
                            self.customerNameTextField.text = self.shaddowBusObj.name;
                        }
                        self.customerNameTextField.backgroundColor = cell.backgroundColor;
                        
                        [cell addSubview:self.customerNameTextField];
                    }
                    break;
                case kCustomerEmail:
                    if (self.mode == kViewMode) {
                        cell.detailTextLabel.text = shaddowCustomer.email;
                    } else {
                        if (self.shaddowBusObj != nil) {
                            self.customerEmailTextField.text = shaddowCustomer.email;
                        }
                        self.customerEmailTextField.backgroundColor = cell.backgroundColor;
                        
                        [cell addSubview:self.customerEmailTextField];
                    }
                    break;
                case kCustomerPhone:
                    if (self.mode == kViewMode) {
                        cell.detailTextLabel.text = shaddowCustomer.phone;
                    } else {
                        if (self.shaddowBusObj != nil) {
                            self.customerPhoneTextField.text = shaddowCustomer.phone;
                        }
                        self.customerPhoneTextField.backgroundColor = cell.backgroundColor;
                        
                        [cell addSubview:self.customerPhoneTextField];
                    }
                    break;
                default:
                    break;
            }
        }
            break;
            
        case kCustomerAddr:
        {
            if (self.modeChanged) {
                if (self.mode == kViewMode) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CUSTOMER_ADDRESS_CELL_ID];
                } else {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CUSTOMER_ADDRESS_CELL_ID];
                }
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:CUSTOMER_ADDRESS_CELL_ID];
                if (!cell) {
                    if (self.mode == kViewMode) {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CUSTOMER_ADDRESS_CELL_ID];
                    } else {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CUSTOMER_ADDRESS_CELL_ID];
                    }
                }
            }
            
            cell.textLabel.text = CustomerInfo[indexPath.section][indexPath.row];
            cell.textLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:APP_LABEL_FONT_SIZE];
            cell.detailTextLabel.font = [UIFont fontWithName:APP_FONT size:APP_LABEL_FONT_SIZE];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            if (self.mode == kViewMode) {
                cell.textLabel.text = @"Address";
                cell.detailTextLabel.text = self.address;
                cell.detailTextLabel.numberOfLines = self.numOfLinesInAddr;
                cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
            } else {
                switch (indexPath.row) {
                    case kAddr1:
                        if (self.mode == kViewMode) {
                            cell.detailTextLabel.text = shaddowCustomer.addr1;
                        } else {
                            if (self.shaddowBusObj != nil) {
                                self.customerAddr1TextField.text = shaddowCustomer.addr1;
                            }
                            self.customerAddr1TextField.backgroundColor = cell.backgroundColor;
                            
                            [cell addSubview:self.customerAddr1TextField];
                        }
                        break;
                    case kAddr2:
                        if (self.mode == kViewMode) {
                            cell.detailTextLabel.text = shaddowCustomer.addr2;
                        } else {
                            if (self.shaddowBusObj != nil) {
                                self.customerAddr2TextField.text = shaddowCustomer.addr2;
                            }
                            self.customerAddr2TextField.backgroundColor = cell.backgroundColor;
                            
                            [cell addSubview:self.customerAddr2TextField];
                        }
                        break;
                    case kAddr3:
                        if (self.mode == kViewMode) {
                            cell.detailTextLabel.text = shaddowCustomer.addr3;
                        } else {
                            if (self.shaddowBusObj != nil) {
                                self.customerAddr3TextField.text = shaddowCustomer.addr3;
                            }
                            self.customerAddr3TextField.backgroundColor = cell.backgroundColor;
                            
                            [cell addSubview:self.customerAddr3TextField];
                        }
                        break;
                    case kAddr4:
                        if (self.mode == kViewMode) {
                            cell.detailTextLabel.text = shaddowCustomer.addr4;
                        } else {
                            if (self.shaddowBusObj != nil) {
                                self.customerAddr4TextField.text = shaddowCustomer.addr4;
                            }
                            self.customerAddr4TextField.backgroundColor = cell.backgroundColor;
                            
                            [cell addSubview:self.customerAddr4TextField];
                        }
                        break;
                    case kCity:
                        if (self.mode == kViewMode) {
                            cell.detailTextLabel.text = shaddowCustomer.city;
                        } else {
                            if (self.shaddowBusObj != nil) {
                                self.customerCityTextField.text = shaddowCustomer.city;
                            }
                            self.customerCityTextField.backgroundColor = cell.backgroundColor;
                            
                            [cell addSubview:self.customerCityTextField];
                        }
                        break;
                    case kState:
                        if (self.mode == kViewMode) {
                            if ([shaddowCustomer.state isKindOfClass:[NSNumber class]]) {
                                if ([shaddowCustomer.state intValue] == INVALID_OPTION) {
                                    cell.detailTextLabel.text = @"";
                                } else {
                                    cell.detailTextLabel.text = [US_STATES objectAtIndex:[shaddowCustomer.state intValue]];
                                }
                            } else {
                                cell.detailTextLabel.text = shaddowCustomer.state;
                            }
                        } else {
                            if ([shaddowCustomer.state isKindOfClass:[NSNumber class]]) {
                                if ([shaddowCustomer.state intValue] == INVALID_OPTION) {
                                    self.customerStateTextField.text = @"";
                                } else {
                                    self.customerStateTextField.text = [US_STATES objectAtIndex:[shaddowCustomer.state intValue]];
                                }
                                
                                self.customerStateTextField.inputView = self.customerStatePickerView;
                                self.customerStateTextField.rightViewMode = UITextFieldViewModeAlways;
                            } else {
                                self.customerStateTextField.text = shaddowCustomer.state;
                                self.customerStateTextField.enabled = YES;
                                self.customerStateTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
                                self.customerStateTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
                            }
                            
                            self.customerStateTextField.backgroundColor = cell.backgroundColor;
                            
                            [cell addSubview:self.customerStateTextField];
                        }
                        break;
                    case kCountry:
                        if (self.mode == kViewMode) {
                            if (shaddowCustomer.country == INVALID_OPTION) {
                                cell.detailTextLabel.text = @"";
                            } else {
                                cell.detailTextLabel.text = [COUNTRIES objectAtIndex: shaddowCustomer.country];
                            }
                        } else {
                            if (shaddowCustomer.country == INVALID_OPTION) {
                                self.customerCountryTextField.text = @"";
                            } else {
                                self.customerCountryTextField.text = [COUNTRIES objectAtIndex: shaddowCustomer.country];
                            }
                            self.customerCountryTextField.backgroundColor = cell.backgroundColor;
                            
                            [cell addSubview:self.customerCountryTextField];
                        }
                        break;
                    case kZip:
                        if (self.mode == kViewMode) {
                            cell.detailTextLabel.text = shaddowCustomer.zip;
                        } else {
                            if (self.shaddowBusObj != nil) {
                                self.customerZipTextField.text = shaddowCustomer.zip;
                            }
                            self.customerZipTextField.backgroundColor = cell.backgroundColor;
                            
                            [cell addSubview:self.customerZipTextField];
                        }
                        break;
                    default:
                        break;
                }
            }
        }
            break;
            
        case kCustomerAttachments:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:CUSTOMER_ATTACH_CELL_ID];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CUSTOMER_ATTACH_CELL_ID];
            }
            
            [cell.contentView addSubview:self.attachmentScrollView];
            [cell.contentView addSubview:self.attachmentPageControl];
            cell.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        }
            break;
            
        default:
            break;
    }
    
        
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kCustomerInfo) {
        return CELL_HEIGHT;
    } else if (indexPath.section == kCustomerAddr) {
        if (self.mode == kViewMode) {
            return CELL_HEIGHT * (self.numOfLinesInAddr + 1) * 0.4;
        } else {
            return CELL_HEIGHT;
        }
    } else {
        return IMG_HEIGHT + IMG_PADDING + ATTACHMENT_PV_HEIGHT;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == kCustomerInfo || section == kCustomerAddr) {
        return 0;
    } else {
        return 30;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == kCustomerInfo || section == kCustomerAddr) {
        return nil;
    } else {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 360, 30)];
        headerView.backgroundColor = [UIColor clearColor];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 200, 20)];
        label.text = @"Documents";
        label.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = APP_SYSTEM_BLUE_COLOR;
        label.shadowColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0, 1);
        
        [headerView addSubview:label];
        
        if (self.mode != kViewMode) {
            UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
            CGRect frame = CGRectMake(265, -10, 40, 40);
            cameraButton.frame = frame;
            cameraButton.backgroundColor = [UIColor clearColor];
            [cameraButton addTarget:self action:@selector(addMoreAttachment) forControlEvents:UIControlEventTouchUpInside];
            
            [headerView addSubview:cameraButton];
        }
        
        return headerView;
    }
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
        Customer *shaddowCustomer = (Customer *)self.shaddowBusObj;
        NSString *txt = [Util trim:textField.text];
        
        switch (textField.tag) {
            case kCustomerName * TAG_BASE:
                self.shaddowBusObj.name = txt;
                break;
            case kCustomerEmail * TAG_BASE:
                shaddowCustomer.email = txt;
                break;
            case kCustomerPhone * TAG_BASE:
                shaddowCustomer.phone = txt;
                break;
            case (kAddr1 + CUSTOMER_ADDR_TAG_OFFSET) * TAG_BASE:
                shaddowCustomer.addr1 = txt;
                break;
            case (kAddr2 + CUSTOMER_ADDR_TAG_OFFSET) * TAG_BASE:
                shaddowCustomer.addr2 = txt;
                break;
            case (kAddr3 + CUSTOMER_ADDR_TAG_OFFSET) * TAG_BASE:
                shaddowCustomer.addr3 = txt;
                break;
            case (kAddr4 + CUSTOMER_ADDR_TAG_OFFSET) * TAG_BASE:
                shaddowCustomer.addr4 = txt;
                break;
            case (kCity + CUSTOMER_ADDR_TAG_OFFSET) * TAG_BASE:
                shaddowCustomer.city = txt;
                break;
            case (kZip + CUSTOMER_ADDR_TAG_OFFSET) * TAG_BASE:
                shaddowCustomer.zip = txt;
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

#pragma mark - UIPickerView Datascource

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (pickerView.tag == (kState + CUSTOMER_ADDR_TAG_OFFSET) * PICKER_TAG_BASE) {
        return [US_STATES count] + 1;
    } else if (pickerView.tag == (kCountry + CUSTOMER_ADDR_TAG_OFFSET) * PICKER_TAG_BASE) {
        return [COUNTRIES count] + 1;
    } else {
        return 0;
    }
}

- (NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (row == 0) {
        return SELECT_ONE;
    }
    if (pickerView.tag == (kState + CUSTOMER_ADDR_TAG_OFFSET) * PICKER_TAG_BASE) {
        return [US_STATES objectAtIndex: row - 1];
    } else if (pickerView.tag == (kCountry + CUSTOMER_ADDR_TAG_OFFSET) * PICKER_TAG_BASE) {
        return [COUNTRIES objectAtIndex: row - 1];
    } else {
        return nil;
    }
}

#pragma mark - UIPickerView Delegate

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    Customer *shaddowCustomer = (Customer *)self.shaddowBusObj;
    
    if (pickerView.tag == (kState + CUSTOMER_ADDR_TAG_OFFSET) * PICKER_TAG_BASE) {
        if (row == 0) {
            self.customerStateTextField.text = @"";
            shaddowCustomer.state = [NSNumber numberWithInt:INVALID_OPTION];
        } else {
            self.customerStateTextField.text = [US_STATES objectAtIndex: row - 1];
            shaddowCustomer.state = [NSNumber numberWithInt: row - 1];
        }
    } else if (pickerView.tag == (kCountry + CUSTOMER_ADDR_TAG_OFFSET) * PICKER_TAG_BASE) {
        if (row == 0) {
            self.customerCountryTextField.text = @"";
            shaddowCustomer.country = INVALID_OPTION;
        } else {
            self.customerCountryTextField.text = [COUNTRIES objectAtIndex: row - 1] ;
            shaddowCustomer.country = row - 1;
        }
        
        if (row == 1 || row == US_FULL_INDEX + 1) {  //USA
            self.customerStateTextField.inputView = self.customerStatePickerView;
            self.customerStateTextField.rightViewMode = UITextFieldViewModeAlways;
            if (![shaddowCustomer.state isKindOfClass:[NSNumber class]]) {
                self.customerStateTextField.text = @"";
                shaddowCustomer.state = [NSNumber numberWithInt:INVALID_OPTION];
            }
        } else {
            self.customerStateTextField.inputView = nil;
            if ([shaddowCustomer.state isKindOfClass:[NSNumber class]]) {
                self.customerStateTextField.text = @"";
                shaddowCustomer.state = nil;
            }
            self.customerStateTextField.text = shaddowCustomer.state;
            self.customerStateTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
            self.customerStateTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
        }
    }
}

#pragma mark - Model delegate

- (void)didReadObject {
    [self formatAddr];
    [super didReadObject];
}

- (void)doneSaveObject {
    [super doneSaveObject];
    self.address = [NSMutableString string];
    self.numOfLinesInAddr = [((BDCBusinessObjectWithAttachmentsAndAddress *)self.shaddowBusObj) formatAddress:self.address];
}


@end

