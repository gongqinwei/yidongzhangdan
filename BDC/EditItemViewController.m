//
//  EditItemViewController.m
//  BDC
//
//  Created by Qinwei Gong on 10/20/12.
//
//

#import "EditItemViewController.h"
#import "Util.h"
#import "UIHelper.h"
#import <QuartzCore/QuartzCore.h>

enum ItemInfoType {
    kItemType,
    kItemName,
    kItemPrice,
    kItemQuantity,
};

#define INVALID_ITEM_TYPE   -1
#define ItemInfo            [NSArray arrayWithObjects:@"Type", @"Name", @"Price", @"Qty", nil]
#define DOLLAR_RECT         CGRectMake(CELL_WIDTH - 185, 5, 10, CELL_HEIGHT - 10)

@interface EditItemViewController () <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, strong) UIPickerView *itemTypePickerView;
@property (nonatomic, strong) UITextField *itemTypeTextField;
@property (nonatomic, strong) UITextField *itemNameTextField;
@property (nonatomic, strong) UITextField *itemPriceTextField;
@property (nonatomic, strong) UITextField *itemQtyTextField;

@end

@implementation EditItemViewController

@synthesize lineItemIndex;
@synthesize itemTypePickerView;
@synthesize itemTypeTextField;
@synthesize itemNameTextField;
@synthesize itemPriceTextField;
@synthesize itemQtyTextField;
@synthesize lineItemDelegate;

- (Class)busObjClass {
    return [Item class];
}

- (NSString *)getDocImageAPI {
    return ATTACH_IMAGE_API;
}

- (NSString *)getDocIDParam {
    return ATTACH_ID;
}

#pragma mark - Depricated: this method is no longer needed as the edit bar button will be moved to action menu
- (void)editItem:(UIBarButtonItem *)sender {
    if ([self tryTap]) {
        self.mode = kUpdateMode;
    }
}

- (IBAction)saveBusObj:(UIBarButtonItem *)sender {
    if ([self tryTap]) {
        [self.view findAndResignFirstResponder];
        
        Item *shaddowItem = (Item *)self.shaddowBusObj;
        
        if (shaddowItem.type == INVALID_ITEM_TYPE) {
            [UIHelper showInfo:@"Missing type!" withStatus:kError];
            //        self.navigationItem.rightBarButtonItem.customView = nil;
            return;
        }
        
        if (self.shaddowBusObj.name == nil || [self.shaddowBusObj.name length] == 0) {
            [UIHelper showInfo:@"Missing name!" withStatus:kError];
            //        self.navigationItem.rightBarButtonItem.customView = nil;
            return;
        }
        
        if (shaddowItem.price == nil) {
            [UIHelper showInfo:@"Missing price!" withStatus:kError];
            //        self.navigationItem.rightBarButtonItem.customView = nil;
            return;
        }
        
        [super saveBusObj:sender];
        
        if (self.mode == kCreateMode || self.mode == kAttachMode) {
            [shaddowItem create];
        } else if (self.mode == kUpdateMode){
            [shaddowItem update];
        } else if (self.mode == kModifyMode) {
            [self.lineItemDelegate didModifyItem:shaddowItem forIndex:self.lineItemIndex];
            [self navigateBack];
        }
    }
}

#pragma mark - Life Cycle methods

- (void)viewDidLoad
{
    Item *shaddowItem = (Item *)self.shaddowBusObj;
    
    if (!self.busObj) {
        self.busObj = [[Item alloc] init];
        self.shaddowBusObj = [[Item alloc] init];
        shaddowItem.type = INVALID_ITEM_TYPE;
    }
        
    [super viewDidLoad];
    
    if (self.mode == kCreateMode || self.mode == kAttachMode) {
        self.title = @"New Item";
    }
    
//    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.busObj.editDelegate = self;
    self.shaddowBusObj.editDelegate = self;
    
    self.itemTypePickerView = [[UIPickerView alloc] initWithFrame:PICKER_RECT];
    self.itemTypePickerView.delegate = self;
    self.itemTypePickerView.dataSource = self;
    self.itemTypePickerView.showsSelectionIndicator = YES;
    
    self.itemTypeTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:itemTypeTextField];
    self.itemTypeTextField.tag = kItemType * TAG_BASE;
    self.itemTypeTextField.inputView = self.itemTypePickerView;
    self.itemTypeTextField.rightViewMode = UITextFieldViewModeAlways;
    self.itemTypeTextField.delegate = self;
    
    self.itemNameTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.itemNameTextField];
    self.itemNameTextField.tag = kItemName * TAG_BASE;
    self.itemNameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.itemNameTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.itemNameTextField.delegate = self;
    
    self.itemPriceTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.itemPriceTextField];
    self.itemPriceTextField.tag = kItemPrice * TAG_BASE;
    self.itemPriceTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.itemPriceTextField.keyboardType = UIKeyboardTypeDecimalPad;
    self.itemPriceTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.itemPriceTextField.delegate = self;
    
    self.itemQtyTextField = [[UITextField alloc] initWithFrame:INFO_INPUT_RECT];
    [self initializeTextField:self.itemQtyTextField];
    self.itemQtyTextField.tag = kItemQuantity * TAG_BASE;
    self.itemQtyTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.itemQtyTextField.keyboardType = UIKeyboardTypeNumberPad;
    self.itemQtyTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.itemQtyTextField.delegate = self;
    
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
    if (self.mode == kModifyMode) {
        return [ItemInfo count];
    } else {
        return [ItemInfo count] - 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ItemInfoItem";
    
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

    cell.textLabel.text = [ItemInfo objectAtIndex:indexPath.row]; //[ItemInfo objectForKey:[NSNumber numberWithInt:indexPath.row]];
    cell.textLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:APP_LABEL_FONT_SIZE];
    cell.detailTextLabel.font = [UIFont fontWithName:APP_FONT size:APP_LABEL_FONT_SIZE];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    Item *shaddowItem = (Item *)self.shaddowBusObj;
    
    switch (indexPath.row) {
        case kItemType:
            if (self.mode == kCreateMode) {
                self.itemTypeTextField.text = @"";
                self.itemTypeTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.itemTypeTextField];
            } else {
                cell.detailTextLabel.text = [ItemTypeNames objectAtIndex: shaddowItem.type];
            }
            break;
        case kItemName:
        {
            if (self.mode == kViewMode || self.mode == kModifyMode) {
                cell.detailTextLabel.text = self.shaddowBusObj.name;
            } else {
                if (self.shaddowBusObj != nil) {
                    self.itemNameTextField.text = self.shaddowBusObj.name;
                }
                self.itemNameTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.itemNameTextField];
            }
        }
            break;
        case kItemPrice:
        {
            if (self.mode == kViewMode) {
                cell.detailTextLabel.text = [Util formatCurrency:shaddowItem.price];
            } else {
                UILabel *dollarLabel = [[UILabel alloc] initWithFrame:DOLLAR_RECT];
                dollarLabel.text = @"$";
                dollarLabel.backgroundColor = [UIColor clearColor];
                [cell addSubview:dollarLabel];
                
                if (self.shaddowBusObj != nil) {
                    self.itemPriceTextField.text = [shaddowItem.price stringValue];
                }
                self.itemPriceTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.itemPriceTextField];
            }
        }
            break;
        case kItemQuantity:
        {
            if (self.mode == kModifyMode) {
                if (self.shaddowBusObj != nil) {
                    self.itemQtyTextField.text = [NSString stringWithFormat:@"%d", shaddowItem.qty];
                }
                self.itemQtyTextField.backgroundColor = cell.backgroundColor;
                
                [cell addSubview:self.itemQtyTextField];
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
//    [self textFieldDoneEditing:self.editingField];
    [super tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    [self.itemTypeTextField resignFirstResponder];
}

#pragma mark - Text Field delegate

// private
- (void)textFieldDoneEditing:(UITextField *)textField {
    Item *shaddowItem = (Item *)self.shaddowBusObj;
    
    NSString *txt = [Util trim:textField.text];
        if (textField.tag == kItemName * TAG_BASE) {
            self.shaddowBusObj.name = txt;
        } else if (textField.tag == kItemPrice * TAG_BASE) {
            if ([txt length] == 0) {
                shaddowItem.price = 0;
                self.itemPriceTextField.text = @"0.00";
            } else {
                shaddowItem.price = [NSDecimalNumber decimalNumberWithString: txt];
            }
        } else if (textField.tag == kItemQuantity * TAG_BASE) {
            if ([txt length] == 0) {
                shaddowItem.qty = 0;
                self.itemQtyTextField.text = @"0";
            } else {
                shaddowItem.qty = [txt intValue];
            }
        }
//    }
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
    return [ItemTypes count] + 1;
}

- (NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (row == 0) {
        return SELECT_ONE;
    } else {
        return [ItemTypeNames objectAtIndex: row - 1];
    }
}

#pragma mark - UIPickerView Delegate

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    Item *shaddowItem = (Item *)self.shaddowBusObj;
    
    if (row == 0) {
        self.itemTypeTextField.text = @"";
        shaddowItem.type = INVALID_ITEM_TYPE;
    } else {
        self.itemTypeTextField.text = [ItemTypeNames objectAtIndex: row - 1];
        shaddowItem.type = row - 1;
    }
}


@end
