//
//  ImportABPersonViewController.m
//  Mobill
//
//  Created by Qinwei Gong on 11/27/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "ImportABPersonViewController.h"
#import "Vendor.h"
#import "UIHelper.h"
#import "Geo.h"
#import <QuartzCore/QuartzCore.h>
#import <MessageUI/MessageUI.h>


#define AB_INFO_INPUT_RECT                  CGRectMake(CELL_WIDTH - 190, 5, 170, CELL_HEIGHT - 10)
#define AB_BUTTON_RECT                      CGRectMake(10, 0, CELL_WIDTH, CELL_HEIGHT)
#define AB_IMPORT                           @"Import"
#define AB_IMPORT_AND_INVITE                @"Import & Invite to receive ePayment"
#define AB_REFER_MOBILL                     @"Recommend Mobill"


enum ABPersonDetailsType {
    kPersonName,
    kPersonEmail,
    kPersonImport,
    kPersonImportAndInvite
};

@interface ImportABPersonViewController () <UIAlertViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) NSArray *personEmailsArr;
@property (nonatomic, strong) UITextField *companyField;
@property (nonatomic, strong) MFMailComposeViewController *mailer;
@property (nonatomic, assign) int emailRow;

@end

@implementation ImportABPersonViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.personEmailsArr = self.person.emails.allKeys;

    self.companyField = [[UITextField alloc] initWithFrame:AB_INFO_INPUT_RECT];
    [self initializeTextField:self.companyField];
    self.companyField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.companyField.rightViewMode = UITextFieldViewModeUnlessEditing;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.person.emails.count) {
        if (self.importingClass == [Vendor class]) {
            return 4;
        }
        
        return 3;
    } else {
        return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.person.emails.count) {
        if (section == kPersonName) {
            return 2;
        } else if (section == kPersonEmail) {
            return self.person.emails.count;
        } else {
            return 1;
        }
    } else {
        if (section == kPersonName) {
            return 2;
        } else {
            return 1;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ABPERSON_CELL_ID = @"ImportABPersonItem";
    UITableViewCell *cell;
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:ABPERSON_CELL_ID];
    }
    
    cell.selectionStyle = UITableViewCellAccessoryNone;
    cell.textLabel.font = [UIFont fontWithName:APP_BOLD_FONT size:APP_LABEL_FONT_SIZE + 2];
    cell.detailTextLabel.font = [UIFont fontWithName:APP_FONT size:APP_LABEL_FONT_SIZE + 2];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    switch (indexPath.section) {
        case kPersonName:
            if (indexPath.row == 0) {
                cell.textLabel.text = @"Name";
                cell.detailTextLabel.text = self.person.name;
            } else {
                cell.textLabel.text = @"Company";
                if (self.person.company) {
                    cell.detailTextLabel.text = self.person.company;
                } else {
                    [cell addSubview:self.companyField];
                }
            }
            break;
        
        case 1:
        {
            if (self.person.emails.count) {
                NSString *email = self.personEmailsArr[indexPath.row];
                NSString *emailLabel = self.person.emails[email];
                cell.textLabel.text = emailLabel;
                cell.detailTextLabel.text = email;
            } else {
                [self addImportButtonForCell:cell];
            }
        }
            break;
            
        case 2:
            cell.backgroundColor = [UIColor clearColor];
            [self addImportButtonForCell:cell];
            
            break;
            
        case 3:
        {
            cell.backgroundColor = [UIColor clearColor];
            [self addImportAndInviteButtonForCell:cell];
        }
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (void) addImportButtonForCell:(UITableViewCell *)cell {
    UIButton *importButton = [self initializeABButton];
    importButton.tag = 0;
    [importButton setTitle:AB_IMPORT forState:UIControlStateNormal];
    [importButton addTarget:self action:@selector(importAB:) forControlEvents:UIControlEventTouchUpInside];
    
    [cell addSubview:importButton];
}

- (void)addImportAndInviteButtonForCell:(UITableViewCell *)cell {
    UIButton *importAndInviteButton = [self initializeABButton];
    importAndInviteButton.tag = 1;
    [importAndInviteButton setTitle:AB_IMPORT_AND_INVITE forState:UIControlStateNormal];
    [importAndInviteButton addTarget:self action:@selector(importAB:) forControlEvents:UIControlEventTouchUpInside];
    
    [cell addSubview:importAndInviteButton];
}

- (UIButton *)initializeABButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = AB_BUTTON_RECT;
    button.backgroundColor = APP_LABEL_BLUE_COLOR;
    button.layer.cornerRadius = 7;
    button.clipsToBounds = YES;
    
    return button;
}

- (void)importAB:(UIButton *)sender {
    if ([self tryTap]) {
        BDCBusinessObjectWithAttachmentsAndAddress *obj = [[self.importingClass alloc] init];
        int nameRow = -1;
        self.emailRow = self.person.emails.count == 1 ? 0 : -1;
        
        NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
        for (NSIndexPath *path in selectedIndexPaths) {
            if (path.section == kPersonName) {
                nameRow = path.row;
            } else if (path.section == kPersonEmail) {
                self.emailRow = path.row;
            }
        }
        
        if (nameRow < 0) {
            [UIHelper showInfo:[NSString stringWithFormat:@"Please choose %@ name", self.importingClass] withStatus:kWarning];
            return;
        } else if(nameRow == 0) {
            obj.name = self.person.name;
        } else {
            if (!self.person.company) {
                if (self.companyField.text.length == 0) {
                    [UIHelper showInfo:[NSString stringWithFormat:@"Please enter %@ name", self.importingClass] withStatus:kWarning];
                    return;
                } else {
                    obj.name = self.companyField.text;
                }
            } else {
                obj.name = self.person.company;
            }
        }
        
        if (self.person.emails.count) {
            if (self.emailRow < 0) {
                [UIHelper showInfo:[NSString stringWithFormat:@"Please choose %@ email", self.importingClass] withStatus:kWarning];
                return;
            } else {
                obj.email = self.personEmailsArr[self.emailRow];
            }
        }
        
        obj.phone = self.person.phone;
        obj.addr1 = self.person.addr1;
        obj.city = self.person.city;
        obj.zip = self.person.zip;
        
        NSUInteger countryIndex = [COUNTRIES indexOfObject:self.person.country];
        obj.country = countryIndex == NSNotFound ? INVALID_OPTION : countryIndex;
        
        NSUInteger stateIndex;
        if (countryIndex == 0 || countryIndex == US_FULL_INDEX) {
            stateIndex = [US_STATE_CODES indexOfObject:self.person.state.uppercaseString];
            if (stateIndex == NSNotFound) {
                stateIndex = [US_STATE_NAMES indexOfObject:self.person.state.lowercaseString];
            }
            if (stateIndex == NSNotFound) {
                obj.state = nil;
            } else {
                obj.state = [NSNumber numberWithInteger:stateIndex];
            }
        } else {
            obj.state = self.person.state;
        }
        
        if (sender.tag == 0) {
            [obj create];
        } else if(sender.tag == 1) {
            [obj createAndInvite];
        }
        
        if (self.person.emails.count && self.emailRow >= 0) {
            [self promptForRecommendation];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (void)promptForRecommendation {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: nil //@"Recommend Mobill"
                          message: [NSString stringWithFormat:@"Do you want to recommend Mobill to %@?", self.person.name]
                          delegate: self
                          cancelButtonTitle:@"No"
                          otherButtonTitles:@"Yes", nil];
    [alert show];
}

- (void)presentMailer {
    if ([MFMailComposeViewController canSendMail]) {
        self.mailer = [[MFMailComposeViewController alloc] init];
        self.mailer.mailComposeDelegate = self;
        
        Organization *org = [Organization getSelectedOrg];
        [self.mailer setSubject:[NSString stringWithFormat:@"Recommendation for Mobill from %@ ", org.name]];
        
        NSArray *toRecipients = [NSArray arrayWithObjects:self.personEmailsArr[self.emailRow], nil];
        [self.mailer setToRecipients:toRecipients];
        
        NSString *emailBody = [NSString stringWithFormat:RECOMMEND_MOBILL_EMAIL, self.person.name, MOBILL_APP_STORE_LINK, MOBILL_LITE_APP_STORE_LINK, org.name, nil];
        [self.mailer setMessageBody:emailBody isHTML:YES];
        
        [self presentViewController:self.mailer animated:YES completion:nil];
    } else {
        [UIHelper showInfo:@"Your device doesn't support the composer sheet" withStatus:kError];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == kPersonName || section == kPersonEmail) {
        return 30;
    } else {
        return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == kPersonName) {
        return [self initializeSectionHeaderViewWithLabel:[NSString stringWithFormat:@"Choose %@ Name", self.importingClass] needAddButton:NO addAction:nil];
    } else if (section == 1 && self.person.emails.count) {
        NSString *label;
        if (self.person.emails.count == 1) {
            label = [NSString stringWithFormat:@"%@ Email", self.importingClass];
        } else {
            label = [NSString stringWithFormat:@"Choose %@ Email", self.importingClass];
        }
        return [self initializeSectionHeaderViewWithLabel:label needAddButton:NO addAction:nil];
    } else {
        return nil;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *row = [self.tableView cellForRowAtIndexPath:indexPath];
    row.accessoryType = UITableViewCellAccessoryCheckmark;
    
    NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
    for (NSIndexPath *path in selectedIndexPaths) {
        if (path.section == indexPath.section && path.row != indexPath.row) {
            [self.tableView deselectRowAtIndexPath:path animated:NO];
            UITableViewCell *row1 = [self.tableView cellForRowAtIndexPath:path];
            row1.accessoryType = UITableViewCellAccessoryNone;
        }
    }
}

#pragma mark - Alert delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self presentMailer];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - MailComposer delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    switch (result){
        case MFMailComposeResultSent:
            [UIHelper showInfo: EMAIL_SENT withStatus:kSuccess];
            break;
        case MFMailComposeResultCancelled:
            break;
        case MFMailComposeResultSaved:
            break;
        case MFMailComposeResultFailed:
            [UIHelper showInfo: EMAIL_FAILED withStatus:kFailure];
            break;
        default:
            [UIHelper showInfo: EMAIL_FAILED withStatus:kError];
            break;
    }
    
    // Remove the mail view
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [self.navigationController popViewControllerAnimated:YES];
}


@end
