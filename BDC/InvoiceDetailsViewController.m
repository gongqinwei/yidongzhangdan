//
//  InvoiceDetailsViewController.m
//  BDC
//
//  Created by Qinwei Gong on 9/9/12.
//
//

#import "InvoiceDetailsViewController.h"
#import "Constants.h"


@interface InvoiceDetailsViewController () <UIGestureRecognizerDelegate>

@end

@implementation InvoiceDetailsViewController

@synthesize InvoicePDFView;
@synthesize invoice = _invoice;
//@synthesize invoicePDFData;
@synthesize navigationBar;

- (IBAction)donePreview:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private methods

- (void)updateView {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@?%@=%@&%@=%@", DOMAIN_URL, INV_2_PDF_API, Id, self.invoice.objectId, PRESENT_TYPE, HTML_TYPE]];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    [self.InvoicePDFView loadRequest:req];
}

- (void)viewTapped:(UITapGestureRecognizer *)gestureRecognizer {
    if (self.navigationBar.hidden == YES) {
        self.navigationBar.hidden = NO;
    } else {
        self.navigationBar.hidden = YES;
    }
}

#pragma mark - View Controller Life Cycle

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
    
    [self.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
    self.navigationBar.topItem.title = [@"Invoice " stringByAppendingString:self.invoice.invoiceNumber];
    
    self.InvoicePDFView.scalesPageToFit = YES;
//    self.invoice.detailsDelegate = self;
    [self updateView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    tap.delegate = self;
    [self.InvoicePDFView addGestureRecognizer:tap];
}

- (void)viewDidUnload
{
    [self setInvoicePDFView:nil];
    [self setNavigationBar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - model delegate

- (void)didUpdateInvoice {
    [self updateView];
}

@end
