//
//  PayBillViewController.m
//  BDC
//
//  Created by Qinwei Gong on 5/1/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "PayBillViewController.h"
#import "BankAccount.h"
#import "Util.h"
#import "APIHandler.h"
#import "UIHelper.h"

#define PAY_BILL_PARAMS @"{\"vendorId\" : \"%@\", \"bankAccountId\" : \"%@\", \"processDate\" : \"%@\", \"billPays\" : [{\"billId\" : \"%@\", \"amount\" : %@}], \"billCredits\" : []}"


@interface PayBillViewController () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, strong) UIDatePicker *processDatePicker;
@property (nonatomic, strong) UIPickerView *bankAccountPickerView;
@property (nonatomic, strong) NSArray *bankAccounts;

@end

@implementation PayBillViewController

@synthesize bill;
@synthesize billAmountLabel;
@synthesize paidAmountLabel;
@synthesize dueDateLabel;
@synthesize bankAccountTextField;
@synthesize invalidPayAmountLabel;
@synthesize payAmountTextField;
@synthesize processDateTextField;
@synthesize processDatePicker;
@synthesize navBar;
@synthesize payBillDelegate;
@synthesize bankAccountPickerView;
@synthesize bankAccounts;


- (IBAction)payBill:(UIBarButtonItem *)sender {
    NSDecimalNumber *payAmount = [Util parseCurrency:self.payAmountTextField.text];
    if ([payAmount compare:[NSDecimalNumber zero]] == NSOrderedAscending || [payAmount compare:[NSDecimalNumber zero]] == NSOrderedSame) {
        [UIHelper showInfo:@"Invalid amount to pay!" withStatus:kError];
    } else if ([payAmount compare:[self.bill.amount decimalNumberBySubtracting:self.bill.paidAmount]] == NSOrderedDescending) {
        [UIHelper showInfo:@"You're too generous! Amount too big!" withStatus:kWarning];
    }

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.hidesWhenStopped = YES;
    [activityIndicator startAnimating];
    self.navBar.rightBarButtonItem =  [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    
    BankAccount *bankAccount;
    if ([self.bankAccounts count] > 1) {
        bankAccount = self.bankAccounts[[self.bankAccountPickerView selectedRowInComponent:0]];
    } else {
        bankAccount = self.bankAccounts[0];
    }
    
    NSString *objStr = [NSString stringWithFormat:PAY_BILL_PARAMS,
                        self.bill.vendorId,
                        bankAccount.objectId,
                        [Util formatDate:self.processDatePicker.date format:@"yyyy-MM-dd"],
                        self.bill.objectId,
                        payAmount];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA_, objStr, nil];
    
    __weak PayBillViewController *weakSelf = self;
    
    [APIHandler asyncCallWithAction:PAY_BILL_API Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        self.navBar.rightBarButtonItem = sender;
        
        NSInteger response_status;
        [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {                        
            [UIHelper showInfo:[NSString stringWithFormat:@"Successfully paid %@ for bill %@", [Util formatCurrency:payAmount], bill.name] withStatus:kSuccess];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
            });
            
            // refresh details page for the change in payment status
            [self.bill read];
            
//            self.bill.paymentStatus = PAYMENT_SCHEDULED;
//            [self.payBillDelegate billPaid];
            
            [Util track:@"paid_bill"];
        } else {
            [Organization getSelectedOrg].canPay = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [activityIndicator stopAnimating];
            });
            [UIHelper showInfo:[NSString stringWithFormat:@"Failed to pay bill %@: %@", self.bill.name, [err localizedDescription]] withStatus:kFailure];
            Error(@"Failed to pay bill %@: %@", self.bill.name, [err localizedDescription]);
        }
    }];
}

- (IBAction)cancelPay:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

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
    [super viewDidLoad];
    
    self.navBar.title = [@"Pay " stringByAppendingString:self.bill.name];
    
    self.processDatePicker = [[UIDatePicker alloc] initWithFrame:PICKER_RECT];
    self.processDatePicker.datePickerMode = UIDatePickerModeDate;
    [self.processDatePicker addTarget:self action:@selector(selectProcessDateFromPicker:) forControlEvents:UIControlEventValueChanged];
 
    NSDecimalNumber *previousPayments = [self.bill.paidAmount decimalNumberByAdding:self.bill.scheduledAmount];
    self.billAmountLabel.text = [Util formatCurrency:self.bill.amount];
    self.paidAmountLabel.text = [Util formatCurrency:previousPayments];
    self.payAmountTextField.text = [Util formatCurrency:[self.bill.amount decimalNumberBySubtracting:previousPayments]];
    self.payAmountTextField.keyboardType = UIKeyboardTypeDecimalPad;
    self.payAmountTextField.textColor = APP_LABEL_BLUE_COLOR;
    self.dueDateLabel.text = [Util formatDate:self.bill.dueDate format:nil];
    
    NSDate *processDate;
    
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSHourCalendarUnit fromDate:now];
    NSInteger hour = [components hour];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [gregorian setFirstWeekday:2]; // Sunday == 1, Saturday == 7
    NSUInteger weekday = [gregorian ordinalityOfUnit:NSWeekdayCalendarUnit inUnit:NSWeekCalendarUnit forDate:now];

    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    
    int dayDiff = hour < 18 ? 2 : 3;
    
    if (weekday >= 5) {
        [offsetComponents setDay:(7 - weekday + dayDiff)];
    } else {
        [offsetComponents setDay:dayDiff];
    }

    processDate = [gregorian dateByAddingComponents:offsetComponents toDate:now options:0];
    self.processDateTextField.text = [Util formatDate:processDate format:nil];
    self.processDateTextField.textColor = APP_LABEL_BLUE_COLOR;
    self.processDatePicker.minimumDate = processDate;
    self.processDateTextField.inputView = self.processDatePicker;
    
    self.bankAccounts = (NSArray *)[BankAccount list];
    if ([self.bankAccounts count] > 1) {
        int primaryAPAccount = [BankAccount primaryAPAccountIndex];
        if (primaryAPAccount >= 0) {
            self.bankAccountPickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, 320, 70)];
            self.bankAccountPickerView.delegate = self;
            self.bankAccountPickerView.dataSource = self;
            self.bankAccountPickerView.showsSelectionIndicator = YES;
            
            BankAccount *bankAccount = self.bankAccounts[primaryAPAccount];
            self.bankAccountTextField.text = bankAccount.name;
            self.bankAccountTextField.inputView = self.bankAccountPickerView;
        }
    } else {
        self.bankAccountTextField.text = ((BankAccount *)self.bankAccounts[0]).name;
        self.bankAccountTextField.enabled = NO;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self.bankAccounts count] > 1) {
        int primaryAPAccount = [BankAccount primaryAPAccountIndex];
        if (primaryAPAccount >= 0) {
            [self.bankAccountPickerView selectRow:primaryAPAccount inComponent:0 animated:NO];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setBillAmountLabel:nil];
    [self setPaidAmountLabel:nil];
    [self setDueDateLabel:nil];
    [self setBankAccountTextField:nil];
    [self setPayAmountTextField:nil];
    [self setProcessDateTextField:nil];
    [self setInvalidPayAmountLabel:nil];
    [self setNavBar:nil];
    [super viewDidUnload];
}

#pragma mark - Date Picker target action

- (void)selectProcessDateFromPicker:(UIDatePicker *)sender {
    self.processDateTextField.text = [Util formatDate:sender.date format:nil];
}

#pragma mark - UIPickerView Datascource

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.bankAccounts count];
}

- (NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    BankAccount *bankAccount = self.bankAccounts[row];
    return bankAccount.name;
}

#pragma mark - UIPickerView Delegate

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    BankAccount *bankAccount = self.bankAccounts[row];
    self.bankAccountTextField.text = bankAccount.name;
}

@end
