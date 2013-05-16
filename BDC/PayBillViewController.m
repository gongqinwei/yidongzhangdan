//
//  PayBillViewController.m
//  BDC
//
//  Created by Qinwei Gong on 5/1/13.
//
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


- (IBAction)payBill:(id)sender {
    //TODO: if pay amount from textfield is bigger than what's supposed to be, show "invalid" red label, and return right away
    
    NSString *objStr = [NSString stringWithFormat:@"{\"billId\" : \"%@\", \"amount\" : %f, \"processDate\" : \"%@\"}",
                        self.bill.objectId,
                        [self.payAmountTextField.text doubleValue],
                        [Util formatDate:self.processDatePicker.date format:@"yyyy-MM-dd"]];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: DATA, objStr, nil];
        
    [APIHandler asyncCallWithAction:PAY_BILL_API Info:params AndHandler:^(NSURLResponse * response, NSData * data, NSError * err) {
        NSInteger response_status;
        [APIHandler getResponse:response data:data error:&err status:&response_status];
        
        if(response_status == RESPONSE_SUCCESS) {                        
            //TODO:
            // 1. show success info box
            // 2. if fully paid, after info box disappear, remove this bill also from both edit and list
        } else {
            [UIHelper showInfo:[err localizedDescription] withStatus:kFailure];
            NSLog(@"Failed to pay bill %@: %@", self.bill.name, [err localizedDescription]);
        }
    }];
}

- (IBAction)cancelPay:(UIBarButtonItem *)sender {
    [self dismissModalViewControllerAnimated:YES];
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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
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
    
    int dayDiff = hour < 18 ? 1 : 2;
    
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
