//
//  EditVendorViewController.m
//  BDC
//
//  Created by Qinwei Gong on 4/27/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "EditVendorViewController.h"
#import "Vendor.h"
#import "MapViewController.h"
#import "RootMenuViewController.h"
#import "BillsTableViewController.h"
#import "Bill.h"
#import "Util.h"
#import "UIHelper.h"
#import "Geo.h"
#import "BDCAppDelegate.h"
#import <QuartzCore/QuartzCore.h>

enum VendorSections {
    kVendorInfo,
    kVendorAddr,
    kVendorAttachments
};

enum VendorInfoType {
    kVendorName,
    kVendorPayBy,
    kVendorEmail,
    kVendorPhone
};

#define VendorInfo      [NSArray arrayWithObjects: \
                            [NSArray arrayWithObjects:@"Name", @"Pay By", @"Email", @"Phone", nil], \
                            ADDR_DETAILS, \
                            [NSArray arrayWithObjects:nil], \
                        nil]

#define VENDOR_ADDR_TAG_OFFSET          4
#define VENDOR_SCAN_PHOTO_SEGUE         @"ScanMoreVendorPhoto"
#define VENDOR_VIEW_MAP                 @"ViewVendorMap"


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
//@property (nonatomic, strong) NSMutableString *address;
@property (nonatomic, assign) int numOfLinesInAddr;

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
//@synthesize address;
@synthesize numOfLinesInAddr;


- (Class)busObjClass {
    return [Vendor class];
}


- (BOOL)isAP {
    return YES;
}

- (NSIndexPath *)getAttachmentPath {
    return [NSIndexPath indexPathForRow:0 inSection:kVendorAttachments];
}

- (NSIndexSet *)getNonAttachmentSections {
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(kVendorInfo, kVendorAddr)];
}

- (NSString *)getDocImageAPI {
    return ATTACH_IMAGE_API;
}

- (NSString *)getDocIDParam {
    return ATTACH_ID;
}

#pragma mark - Depricated: this method is no longer needed as the edit bar button will be moved to action menu
- (void)editVendor:(UIBarButtonItem *)sender {
    if ([self tryTap]) {
        self.mode = kUpdateMode;
    }
}

- (IBAction)saveBusObj:(UIBarButtonItem *)sender {
    if ([self tryTap]) {
        [self.view findAndResignFirstResponder];
        
        Vendor *shaddowVendor = (Vendor *)self.shaddowBusObj;
        
        if (shaddowVendor.name == nil || [shaddowVendor.name length] == 0) {
            [UIHelper showInfo:@"Missing name!" withStatus:kError];
            self.navigationItem.rightBarButtonItem.customView = nil;
            return;
        }
        
        [super saveBusObj:sender];
        
        if (self.mode == kCreateMode || self.mode == kAttachMode) {
            [shaddowVendor create];
        } else if (self.mode == kUpdateMode){
            [shaddowVendor update];
        }
    }
}

- (void)addMoreAttachment {
    if ([self tryTap]) {
#ifdef LITE_VERSION
        [UIAppDelegate presentUpgrade];
#else
        [self.view findAndResignFirstResponder];
        [self performSegueWithIdentifier:VENDOR_SCAN_PHOTO_SEGUE sender:self];
#endif
    }
}

#pragma mark - Life Cycle methods

- (void)setupActionMenu {
    Vendor *vendor = (Vendor *)self.shaddowBusObj;
    if (vendor.email && [vendor.payBy isEqualToString:[NSString stringWithFormat:@"%d", kCheck]]) {
        self.crudActions = [self.crudActions arrayByAddingObjectsFromArray:@[ACTION_LIST_VENDOR_BILLS, ACTION_VENDOR_INVITE]];
    } else {
        self.crudActions = [self.crudActions arrayByAddingObject:ACTION_LIST_VENDOR_BILLS];
    }
}

- (void)viewDidLoad
{
    if (!self.busObj) {
        self.busObj = [[Vendor alloc] init];
        self.shaddowBusObj = [[Vendor alloc] init];
    }
        
    [super viewDidLoad];
    
    if (self.mode != kViewMode) {
        self.crudActions = nil;
        
        if (self.mode == kCreateMode || self.mode == kAttachMode) {
            self.title = @"New Vendor";
        }
    } else {
        if ([[RootMenuViewController sharedInstance].currVC.navigationId isEqualToString:MENU_VENDORS]) {
            [self setupActionMenu];
        }
    }
    
    Vendor *shaddowVendor = (Vendor *)self.shaddowBusObj;
    
    self.busObj.editDelegate = self;
    self.shaddowBusObj.editDelegate = self;
        
    self.vendorStatePickerView = [[UIPickerView alloc] initWithFrame:PICKER_RECT];
    self.vendorStatePickerView.delegate = self;
    self.vendorStatePickerView.dataSource = self;
    self.vendorStatePickerView.showsSelectionIndicator = YES;
    self.vendorStatePickerView.tag = (kState + VENDOR_ADDR_TAG_OFFSET) * PICKER_TAG_BASE;
    if ([shaddowVendor.state isKindOfClass:[NSNumber class]] && [shaddowVendor.state intValue] != INVALID_OPTION) {
        [self.vendorStatePickerView selectRow:[shaddowVendor.state intValue] + 1 inComponent:0 animated:NO];
    }
    
    self.vendorCountryPickerView = [[UIPickerView alloc] initWithFrame:PICKER_RECT];
    self.vendorCountryPickerView.delegate = self;
    self.vendorCountryPickerView.dataSource = self;
    self.vendorCountryPickerView.showsSelectionIndicator = YES;
    self.vendorCountryPickerView.tag = (kCountry + VENDOR_ADDR_TAG_OFFSET) * PICKER_TAG_BASE;
    if (shaddowVendor.country != INVALID_OPTION) {
        [self.vendorCountryPickerView selectRow:shaddowVendor.country + 1 inComponent:0 animated:NO];
    }
    
    self.vendorNameTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:vendorNameTextField];
    self.vendorNameTextField.tag = kVendorName * TAG_BASE;
    self.vendorNameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.vendorNameTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.vendorNameTextField.delegate = self;
    
    self.vendorAddr1TextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.vendorAddr1TextField];
    self.vendorAddr1TextField.tag = (kAddr1 + VENDOR_ADDR_TAG_OFFSET) * TAG_BASE;
    self.vendorAddr1TextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.vendorAddr1TextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.vendorAddr1TextField.delegate = self;
    
    self.vendorAddr2TextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.vendorAddr2TextField];
    self.vendorAddr2TextField.tag = (kAddr2 + VENDOR_ADDR_TAG_OFFSET) * TAG_BASE;
    self.vendorAddr2TextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.vendorAddr2TextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.vendorAddr2TextField.delegate = self;
    
    self.vendorAddr3TextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.vendorAddr3TextField];
    self.vendorAddr3TextField.tag = (kAddr3 + VENDOR_ADDR_TAG_OFFSET) * TAG_BASE;
    self.vendorAddr3TextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.vendorAddr3TextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.vendorAddr3TextField.delegate = self;
    
    self.vendorAddr4TextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.vendorAddr4TextField];
    self.vendorAddr4TextField.tag = (kAddr4 + VENDOR_ADDR_TAG_OFFSET) * TAG_BASE;
    self.vendorAddr4TextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.vendorAddr4TextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.vendorAddr4TextField.delegate = self;
    
    self.vendorCityTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.vendorCityTextField];
    self.vendorCityTextField.tag = (kCity + VENDOR_ADDR_TAG_OFFSET) * TAG_BASE;
    self.vendorCityTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.vendorCityTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.vendorCityTextField.delegate = self;
    
    self.vendorStateTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.vendorStateTextField];
    self.vendorStateTextField.tag = (kState + VENDOR_ADDR_TAG_OFFSET) * TAG_BASE;
    self.vendorStateTextField.delegate = self;
    
    self.vendorCountryTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.vendorCountryTextField];
    self.vendorCountryTextField.tag = (kCountry + VENDOR_ADDR_TAG_OFFSET) * TAG_BASE;
    self.vendorCountryTextField.rightViewMode = UITextFieldViewModeAlways;
    self.vendorCountryTextField.inputView = self.vendorCountryPickerView;
    self.vendorCountryTextField.delegate = self;
    
    self.vendorZipTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.vendorZipTextField];
    self.vendorZipTextField.tag = (kZip + VENDOR_ADDR_TAG_OFFSET) * TAG_BASE;
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
    
//    [self formatAddr];
    self.numOfLinesInAddr = shaddowVendor.numOfLinesInAddr;
}

- (void)formatAddr {
    self.numOfLinesInAddr = [((BDCBusinessObjectWithAttachmentsAndAddress *)self.shaddowBusObj) formatAddress:((Vendor *)self.shaddowBusObj).formattedAddress];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:VENDOR_SCAN_PHOTO_SEGUE]) {
        ((ScannerViewController *)segue.destinationViewController).delegate = self;
        [segue.destinationViewController setMode:kAttachMode];
    } else if ([segue.identifier isEqualToString:VENDOR_VIEW_MAP]) {
        [segue.destinationViewController setAnnotations:[NSMutableArray arrayWithArray:@[self.shaddowBusObj]]];
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
    return [VendorInfo count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kVendorInfo) {
        return [VendorInfo[section] count];
    } else if (section == kVendorAddr) {
        if (self.mode == kViewMode) {
            return 1;
        } else {
            return [VendorInfo[section] count];
        }
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *VENDOR_INFO_CELL_ID = @"VendorInfoItem";
    static NSString *VENDOR_ADDRESS_CELL_ID = @"VendorAddress";
    static NSString *VENDOR_ATTACH_CELL_ID = @"VendorAttachments";
    
    Vendor *shaddowVendor = (Vendor *)self.shaddowBusObj;
    UITableViewCell *cell;
    
    switch (indexPath.section) {
        case kVendorInfo:
        {
//            if (self.modeChanged) {
//                if (self.mode == kViewMode) {
//                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:VENDOR_INFO_CELL_ID];
//                } else {
//                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:VENDOR_INFO_CELL_ID];
//                }
//            } else {
//                cell = [tableView dequeueReusableCellWithIdentifier:VENDOR_INFO_CELL_ID];
                if (!cell) {
                    if (self.mode == kViewMode) {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:VENDOR_INFO_CELL_ID];
                    } else {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:VENDOR_INFO_CELL_ID];
                    }
                }
//            }
            
            cell.textLabel.text = VendorInfo[indexPath.section][indexPath.row];            
            cell.textLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:APP_LABEL_FONT_SIZE];
            cell.detailTextLabel.font = [UIFont fontWithName:APP_FONT size:APP_LABEL_FONT_SIZE];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            switch (indexPath.row) {
                case kVendorName:
                    if (self.mode == kViewMode) {
                        cell.detailTextLabel.text = self.shaddowBusObj.name;
                    } else {
                        if (self.shaddowBusObj != nil) {
                            self.vendorNameTextField.text = self.shaddowBusObj.name;
                        }
                        self.vendorNameTextField.backgroundColor = cell.backgroundColor;
                        
                        [cell addSubview:self.vendorNameTextField];
                    }
                    break;
                case kVendorPayBy:
                    cell.detailTextLabel.text = [VENDOR_PAYMENT_TYPES objectForKey:shaddowVendor.payBy];
                    break;
                case kVendorEmail:
                    if (self.mode == kViewMode) {
                        UIImageView *emailImg = [[UIImageView alloc] initWithFrame:CGRectMake(22, 14, 18, 18)];
                        emailImg.image = [UIImage imageNamed:@"emailIcon1.png"];
                        [cell addSubview:emailImg];
                        
//                        cell.detailTextLabel.text = shaddowVendor.email;
                        
                        UITextView *emailView = [[UITextView alloc] initWithFrame:SYSTEM_VERSION_LESS_THAN(@"7.0") ? TABLE_CELL_DETAIL_TEXT_RECT : TABLE_CELL_DETAIL_TEXT_RECT_7];
                        emailView.font = [UIFont systemFontOfSize:TABLE_CELL_DETAIL_TEXT_FONT];
                        emailView.text = shaddowVendor.email;
                        emailView.backgroundColor = [UIColor clearColor];
                        emailView.editable = NO;
                        emailView.dataDetectorTypes = UIDataDetectorTypeLink;
                        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
                            emailView.selectable = YES;
                            emailView.scrollEnabled = NO;
                            emailView.editable = NO;
                        }
                        
                        [cell addSubview:emailView];

                    } else {
                        if (self.shaddowBusObj != nil) {
                            self.vendorEmailTextField.text = shaddowVendor.email;
                        }
                        self.vendorEmailTextField.backgroundColor = cell.backgroundColor;
                        
                        [cell addSubview:self.vendorEmailTextField];
                    }
                    break;
                case kVendorPhone:
                    if (self.mode == kViewMode) {
                        UIImageView *phoneImg = [[UIImageView alloc] initWithFrame:CGRectMake(22, 14, 16, 16)];
                        phoneImg.image = [UIImage imageNamed:@"phoneIcon.png"];
                        [cell addSubview:phoneImg];
                        
//                        cell.detailTextLabel.text = shaddowVendor.phone;

                        UITextView *phoneView = [[UITextView alloc] initWithFrame:SYSTEM_VERSION_LESS_THAN(@"7.0") ? TABLE_CELL_DETAIL_TEXT_RECT : TABLE_CELL_DETAIL_TEXT_RECT_7];
                        phoneView.font = [UIFont systemFontOfSize:TABLE_CELL_DETAIL_TEXT_FONT];
                        phoneView.text = shaddowVendor.phone;
                        phoneView.backgroundColor = [UIColor clearColor];
                        phoneView.editable = NO;
                        
                        phoneView.dataDetectorTypes = UIDataDetectorTypePhoneNumber;
                        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
                            phoneView.selectable = YES;
                            phoneView.scrollEnabled = NO;
                            phoneView.editable = NO;
                        }
                        
                        [cell addSubview:phoneView];

                    } else {
                        if (self.shaddowBusObj != nil) {
                            self.vendorPhoneTextField.text = shaddowVendor.phone;
                        }
                        self.vendorPhoneTextField.backgroundColor = cell.backgroundColor;
                        
                        [cell addSubview:self.vendorPhoneTextField];
                    }
                    break;
                default:
                    break;
            }
        }
            break;
            
        case kVendorAddr:
        {
            if (self.modeChanged) {
                if (self.mode == kViewMode) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:VENDOR_ADDRESS_CELL_ID];
                } else {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:VENDOR_ADDRESS_CELL_ID];
                }
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:VENDOR_ADDRESS_CELL_ID];
                if (!cell) {
                    if (self.mode == kViewMode) {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:VENDOR_ADDRESS_CELL_ID];
                    } else {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:VENDOR_ADDRESS_CELL_ID];
                    }
                }
            }
            
            cell.textLabel.text = VendorInfo[indexPath.section][indexPath.row];            
            cell.textLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:APP_LABEL_FONT_SIZE];
            cell.detailTextLabel.font = [UIFont fontWithName:APP_FONT size:APP_LABEL_FONT_SIZE];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if (self.mode == kViewMode) {
                cell.textLabel.text = @"Address";
                cell.detailTextLabel.text = shaddowVendor.formattedAddress;
                cell.detailTextLabel.numberOfLines = self.numOfLinesInAddr;
                cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
                
                if ([[shaddowVendor.formattedAddress stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0) {
                    if (shaddowVendor.latitude == 0.0 && shaddowVendor.longitude == 0.0) {
                        [shaddowVendor geoCodeUsingAddress:shaddowVendor.formattedAddress];
                    }
                    
                    if (!(shaddowVendor.latitude == 0.0 && shaddowVendor.longitude == 0.0)) {
                        ((Vendor *)self.busObj).latitude = shaddowVendor.latitude;
                        ((Vendor *)self.busObj).longitude = shaddowVendor.longitude;
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    }
                }
            } else {
                switch (indexPath.row) {
                    case kAddr1:
                        if (self.mode == kViewMode) {
                            cell.detailTextLabel.text = shaddowVendor.addr1;
                        } else {
                            if (self.shaddowBusObj != nil) {
                                self.vendorAddr1TextField.text = shaddowVendor.addr1;
                            }
                            self.vendorAddr1TextField.backgroundColor = cell.backgroundColor;
                            
                            [cell addSubview:self.vendorAddr1TextField];
                        }
                        break;
                    case kAddr2:
                        if (self.mode == kViewMode) {
                            cell.detailTextLabel.text = shaddowVendor.addr2;
                        } else {
                            if (self.shaddowBusObj != nil) {
                                self.vendorAddr2TextField.text = shaddowVendor.addr2;
                            }
                            self.vendorAddr2TextField.backgroundColor = cell.backgroundColor;
                            
                            [cell addSubview:self.vendorAddr2TextField];
                        }
                        break;
                    case kAddr3:
                        if (self.mode == kViewMode) {
                            cell.detailTextLabel.text = shaddowVendor.addr3;
                        } else {
                            if (self.shaddowBusObj != nil) {
                                self.vendorAddr3TextField.text = shaddowVendor.addr3;
                            }
                            self.vendorAddr3TextField.backgroundColor = cell.backgroundColor;
                            
                            [cell addSubview:self.vendorAddr3TextField];
                        }
                        break;
                    case kAddr4:
                        if (self.mode == kViewMode) {
                            cell.detailTextLabel.text = shaddowVendor.addr4;
                        } else {
                            if (self.shaddowBusObj != nil) {
                                self.vendorAddr4TextField.text = shaddowVendor.addr4;
                            }
                            self.vendorAddr4TextField.backgroundColor = cell.backgroundColor;
                            
                            [cell addSubview:self.vendorAddr4TextField];
                        }
                        break;
                    case kCity:
                        if (self.mode == kViewMode) {
                            cell.detailTextLabel.text = shaddowVendor.city;
                        } else {
                            if (self.shaddowBusObj != nil) {
                                self.vendorCityTextField.text = shaddowVendor.city;
                            }
                            self.vendorCityTextField.backgroundColor = cell.backgroundColor;
                            
                            [cell addSubview:self.vendorCityTextField];
                        }
                        break;
                    case kState:
                        if (self.mode == kViewMode) {
                            if ([shaddowVendor.state isKindOfClass:[NSNumber class]]) {
                                if ([shaddowVendor.state intValue] == INVALID_OPTION) {
                                    cell.detailTextLabel.text = @"";
                                } else {
                                    cell.detailTextLabel.text = [US_STATES objectAtIndex:[shaddowVendor.state intValue]];
                                }
                            } else {
                                cell.detailTextLabel.text = shaddowVendor.state;
                            }
                        } else {
                            if ([shaddowVendor.state isKindOfClass:[NSNumber class]]) {
                                if ([shaddowVendor.state intValue] == INVALID_OPTION) {
                                    self.vendorStateTextField.text = @"";
                                } else {
                                    self.vendorStateTextField.text = [US_STATES objectAtIndex:[shaddowVendor.state intValue]];
                                }
                                
                                self.vendorStateTextField.inputView = self.vendorStatePickerView;
                                self.vendorStateTextField.rightViewMode = UITextFieldViewModeAlways;
                            } else {
                                self.vendorStateTextField.text = shaddowVendor.state;
                                self.vendorStateTextField.enabled = YES;
                                self.vendorStateTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
                                self.vendorStateTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
                            }
                            
                            self.vendorStateTextField.backgroundColor = cell.backgroundColor;
                            
                            [cell addSubview:self.vendorStateTextField];
                        }
                        break;
                    case kCountry:
                        if (self.mode == kViewMode) {
                            if (shaddowVendor.country == INVALID_OPTION) {
                                cell.detailTextLabel.text = @"";
                            } else {
                                cell.detailTextLabel.text = [COUNTRIES objectAtIndex: shaddowVendor.country];
                            }
                        } else {
                            if (shaddowVendor.country == INVALID_OPTION) {
                                self.vendorCountryTextField.text = @"";
                            } else {
                                self.vendorCountryTextField.text = [COUNTRIES objectAtIndex: shaddowVendor.country];
                            }
                            self.vendorCountryTextField.backgroundColor = cell.backgroundColor;
                            
                            [cell addSubview:self.vendorCountryTextField];
                        }
                        break;
                    case kZip:
                        if (self.mode == kViewMode) {
                            cell.detailTextLabel.text = shaddowVendor.zip;
                        } else {
                            if (self.shaddowBusObj != nil) {
                                self.vendorZipTextField.text = shaddowVendor.zip;
                            }
                            self.vendorZipTextField.backgroundColor = cell.backgroundColor;
                            
                            [cell addSubview:self.vendorZipTextField];
                        }
                        break;
                    default:
                        break;
                }
            }
        }
            break;
        
        case kVendorAttachments:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:VENDOR_ATTACH_CELL_ID];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:VENDOR_ATTACH_CELL_ID];
            }
            
            [cell.contentView addSubview:self.attachmentScrollView];
            [cell.contentView addSubview:self.attachmentPageControl];
            cell.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
            cell.backgroundColor = [UIColor clearColor];
        }
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kVendorInfo) {
        return CELL_HEIGHT;
    } else if (indexPath.section == kVendorAddr) {
        if (self.mode == kViewMode) {
            return CELL_HEIGHT * (self.numOfLinesInAddr + 1) * 0.4;
        } else {
            return CELL_HEIGHT;
        }
    } else {
        return IMG_HEIGHT + IMG_PADDING + ATTACHMENT_PV_HEIGHT + (SYSTEM_VERSION_LESS_THAN(@"7.0") ? 0 : 10);
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == kVendorInfo || section == kVendorAddr) {
        return 0;
    } else {
        return 30;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == kVendorInfo || section == kVendorAddr) {
        return nil;
    } else {
        return [self initializeSectionHeaderViewWithLabel:@"Documents" needAddButton:(self.mode != kViewMode) addAction:@selector(addMoreAttachment)];
        
//        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 360, 30)];
//        headerView.backgroundColor = [UIColor clearColor];
//        
//        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 200, 20)];
//        label.text = @"Documents";
//        label.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
//        label.backgroundColor = [UIColor clearColor];
//        label.textColor = APP_SYSTEM_BLUE_COLOR;
//        label.shadowColor = [UIColor whiteColor];
//        label.shadowOffset = CGSizeMake(0, 1);
//        
//        [headerView addSubview:label];
//        
//        if (self.mode != kViewMode) {
//            UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
//            CGRect frame = CGRectMake(265, -10, 40, 40);
//            cameraButton.frame = frame;
//            cameraButton.backgroundColor = [UIColor clearColor];
//            [cameraButton addTarget:self action:@selector(addMoreAttachment) forControlEvents:UIControlEventTouchUpInside];
//            
//            [headerView addSubview:cameraButton];
//        }
//        
//        return headerView;
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
    [self.vendorStateTextField resignFirstResponder];
    [self.vendorCountryTextField resignFirstResponder];
    
    if (self.mode == kViewMode && indexPath.section == kVendorAddr) {
        CLLocationCoordinate2D coordinate = [((Vendor*)self.shaddowBusObj) coordinate];
        if (!(coordinate.latitude == 0.0 && coordinate.longitude == 0.0)) {
            [self performSegueWithIdentifier:VENDOR_VIEW_MAP sender:self];
        }
    }
}

#pragma mark - Text Field delegate

// private
- (void)textFieldDoneEditing:(UITextField *)textField {
    if (textField != nil) {
        Vendor *shaddowVendor = (Vendor *)self.shaddowBusObj;
        NSString *txt = [Util trim:textField.text];
                
        switch (textField.tag) {
            case kVendorName * TAG_BASE:
                self.shaddowBusObj.name = txt;
                break;
            case kVendorEmail * TAG_BASE:
                shaddowVendor.email = txt;
                break;
            case kVendorPhone * TAG_BASE:
                shaddowVendor.phone = txt;
                break;
            case (kAddr1 + VENDOR_ADDR_TAG_OFFSET) * TAG_BASE:
                shaddowVendor.addr1 = txt;
                break;
            case (kAddr2 + VENDOR_ADDR_TAG_OFFSET) * TAG_BASE:
                shaddowVendor.addr2 = txt;
                break;
            case (kAddr3 + VENDOR_ADDR_TAG_OFFSET) * TAG_BASE:
                shaddowVendor.addr3 = txt;
                break;
            case (kAddr4 + VENDOR_ADDR_TAG_OFFSET) * TAG_BASE:
                shaddowVendor.addr4 = txt;
                break;
            case (kCity + VENDOR_ADDR_TAG_OFFSET) * TAG_BASE:
                shaddowVendor.city = txt;
                break;
            case (kZip + VENDOR_ADDR_TAG_OFFSET) * TAG_BASE:
                shaddowVendor.zip = txt;
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
    if (pickerView.tag == (kState + VENDOR_ADDR_TAG_OFFSET) * PICKER_TAG_BASE) {
        return [US_STATES count] + 1;
    } else if (pickerView.tag == (kCountry + VENDOR_ADDR_TAG_OFFSET) * PICKER_TAG_BASE) {
        return [COUNTRIES count] + 1;
    } else {
        return 0;
    }
}

- (NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (row == 0) {
        return SELECT_ONE;
    }
    if (pickerView.tag == (kState + VENDOR_ADDR_TAG_OFFSET) * PICKER_TAG_BASE) {
        return [US_STATES objectAtIndex: row - 1];
    } else if (pickerView.tag == (kCountry + VENDOR_ADDR_TAG_OFFSET) * PICKER_TAG_BASE) {
        return [COUNTRIES objectAtIndex: row - 1];
    } else {
        return nil;
    }
}

#pragma mark - UIPickerView Delegate

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    Vendor *shaddowVendor = (Vendor *)self.shaddowBusObj;
    
    if (pickerView.tag == (kState + VENDOR_ADDR_TAG_OFFSET) * PICKER_TAG_BASE) {
        if (row == 0) {
            self.vendorStateTextField.text = @"";
            shaddowVendor.state = [NSNumber numberWithInt:INVALID_OPTION];
        } else {
            self.vendorStateTextField.text = [US_STATES objectAtIndex: row - 1];
            shaddowVendor.state = [NSNumber numberWithInt: row - 1];
        }
    } else if (pickerView.tag == (kCountry + VENDOR_ADDR_TAG_OFFSET) * PICKER_TAG_BASE) {
        if (row == 0) {
            self.vendorCountryTextField.text = @"";
            shaddowVendor.country = INVALID_OPTION;
        } else {
            self.vendorCountryTextField.text = [COUNTRIES objectAtIndex: row - 1] ;
            shaddowVendor.country = row - 1;
        }
        
        if (row == 1 || row == US_FULL_INDEX + 1) {  //USA
            self.vendorStateTextField.inputView = self.vendorStatePickerView;
            self.vendorStateTextField.rightViewMode = UITextFieldViewModeAlways;
            if (![shaddowVendor.state isKindOfClass:[NSNumber class]]) {
                self.vendorStateTextField.text = @"";
                shaddowVendor.state = [NSNumber numberWithInt:INVALID_OPTION];
            }
        } else {
            self.vendorStateTextField.inputView = nil;
            if ([shaddowVendor.state isKindOfClass:[NSNumber class]]) {
                self.vendorStateTextField.text = @"";
                shaddowVendor.state = nil;
            }
            self.vendorStateTextField.text = shaddowVendor.state;
            self.vendorStateTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
            self.vendorStateTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
        }
    }
}

#pragma mark - Model delegate

- (void)didReadObject {
    [super didReadObject];
    [self.shaddowBusObj cloneTo:self.busObj];
}

- (void)doneSaveObject {
    [super doneSaveObject];
    [self formatAddr];
    [((BDCBusinessObjectWithAttachmentsAndAddress *)self.shaddowBusObj) geoCodeUsingAddress:((BDCBusinessObjectWithAttachmentsAndAddress *)self.shaddowBusObj).formattedAddress];
    
    [self setupActionMenu];
    [self.actionMenuVC.tableView reloadData];
}

#pragma mark - Action Menu delegate

- (void)didSelectCrudAction:(NSString *)action {
    if ([action isEqualToString:ACTION_LIST_VENDOR_BILLS]) {
        BillsTableViewController *billsVC = [[RootMenuViewController sharedInstance] showView:MENU_BILLS].childViewControllers[0];
        [billsVC.navigationController popToRootViewControllerAnimated:NO];
        [billsVC didSelectSortAttribute:BILL_VENDOR_NAME ascending:YES active:YES];
        [billsVC.tableView reloadData];
        
        [[RootMenuViewController sharedInstance].menuTableView selectRowAtIndexPath:[NSIndexPath indexPathForItem:kAPBill inSection:kRootAP] animated:NO scrollPosition:UITableViewScrollPositionNone];
        billsVC.actionMenuVC.isActive = YES;
        billsVC.actionMenuVC.ascSwitch.on = YES;
        billsVC.actionMenuVC.activenessSwitch.selectedSegmentIndex = 0;
        billsVC.actionMenuVC.lastSortAttribute = [NSIndexPath indexPathForItem:[billsVC.sortAttributes indexOfObject:BILL_VENDOR_NAME] inSection:1];
        [billsVC.actionMenuVC.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 1)] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        if ([billsVC.vendorSectionLabels containsObject:self.busObj.name]) {
            int section = [billsVC.vendorSectionLabels indexOfObject:self.busObj.name];
            [billsVC.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        } else {
            [UIHelper showInfo:[NSString stringWithFormat:@"There's no unpaid bills for %@", self.busObj.name] withStatus:kInfo];
        }
    } else if ([action isEqualToString:ACTION_VENDOR_INVITE]) {
        [((Vendor *)self.busObj) sendVendorInvite];
    } else {
        [super didSelectCrudAction:action];
    }
}


@end


