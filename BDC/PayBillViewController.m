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

@interface PayBillViewController ()

@property (nonatomic, strong) UIDatePicker *processDatePicker;

@end

@implementation PayBillViewController

@synthesize bill;
@synthesize billAmountLabel;
@synthesize paidAmountLabel;
@synthesize dueDateLabel;
@synthesize bankAccountLabel;
@synthesize invalidPayAmountLabel;
@synthesize payAmountTextField;
@synthesize processDateTextField;
@synthesize processDatePicker;
@synthesize navBar;
@synthesize payBillDelegate;


- (IBAction)payBill:(id)sender {
    NSDecimalNumber *payAmount = [Util parseCurrency:self.payAmountTextField.text];    
    
    if ([payAmount compare:[NSDecimalNumber zero]] == NSOrderedAscending || [payAmount compare:[NSDecimalNumber zero]] == NSOrderedSame) {
        [UIHelper showInfo:@"Invalid amount to pay!" withStatus:kError];
    } else if ([payAmount compare:[self.bill.amount decimalNumberBySubtracting:self.bill.paidAmount]] == NSOrderedDescending) {
        [UIHelper showInfo:@"You're too generous! Amount too big!" withStatus:kWarning];
    }
    
    NSString *objStr = [NSString stringWithFormat:@"{\"billId\" : \"%@\", \"amount\" : %@, \"processDate\" : \"%@\"}",
                        self.bill.objectId,
                        payAmount,
                        [Util formatDate:self.processDatePicker.date format:@"yyyy-MM-dd"]];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA, objStr, nil];
    
    __weak PayBillViewController *weakSelf = self;
    
    [APIHandler asyncCallWithAction:PAY_BILL_API Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
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
        } else {
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
 
    self.billAmountLabel.text = [Util formatCurrency:self.bill.amount];
    self.paidAmountLabel.text = [Util formatCurrency:self.bill.paidAmount];
    self.payAmountTextField.text = [Util formatCurrency:[self.bill.amount decimalNumberBySubtracting:self.bill.paidAmount]];
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
    
    BankAccount *bankAccount = [((NSArray *)[BankAccount list]) objectAtIndex:0];
    self.bankAccountLabel.text = bankAccount.name;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (void)viewDidUnload {
    [self setBillAmountLabel:nil];
    [self setPaidAmountLabel:nil];
    [self setDueDateLabel:nil];
    [self setBankAccountLabel:nil];
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

@end
