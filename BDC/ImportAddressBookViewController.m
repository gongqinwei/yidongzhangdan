//
//  ImportAddressBookViewController.m
//  Mobill
//
//  Created by Qinwei Gong on 11/26/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "ImportAddressBookViewController.h"
#import "ImportABPersonViewController.h"
#import "ABPerson.h"
#import "Constants.h"
#import "Geo.h"
#import "UIHelper.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

#define IMPORT_AB_ITEM              @"ImportAddressBookItem"
#define SELECT_AB_IMPORT_SEGUE      @"SelectABImport"


@interface ImportAddressBookViewController ()

@property (nonatomic, strong) NSMutableArray *persons;

@end

@implementation ImportAddressBookViewController

- (void)checkAddressBookAccess {
    // Request authorization to Address Book
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
            if (granted) {
                // First time access has been granted, add the contact
                [self getPersonsFromAddressBook];
            } else {
                // User denied access
                // Display an alert telling user the contact could not be added
            }
        });
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        // The user has previously given access, add the contact
        [self getPersonsFromAddressBook];
    } else {
        // The user has previously denied access
        // Send an alert telling user to change privacy setting in settings app
        [UIHelper showInfo:@"You've denied access to your address book for Mobill" withStatus:kError];
    }
}

- (void)getPersonsFromAddressBook {
    CFErrorRef err = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &err);
    if (addressBook) {
        NSArray *contacts = (__bridge_transfer NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
        
        for (int i = 0; i < contacts.count; i++) {
            ABPerson *person = [[ABPerson alloc] init];
            ABRecordRef contact = (__bridge ABRecordRef)contacts[i];
            
            person.name = [NSMutableString string];
            person.firstName = (__bridge_transfer NSString *)ABRecordCopyValue(contact, kABPersonFirstNameProperty);
            if (person.firstName) {
                [person.name appendString:person.firstName];
            }
            person.lastName = (__bridge_transfer NSString *)ABRecordCopyValue(contact, kABPersonLastNameProperty);
            if (person.lastName) {
                if (person.name.length > 0) {
                    [person.name appendString:@" "];
                }
                [person.name appendString:person.lastName];
            }
            person.company = (__bridge_transfer NSString *)ABRecordCopyValue(contact, kABPersonOrganizationProperty);
            
            if (person.name.length == 0 && person.company) {
                [person.name appendString:person.company];
            }
            
            ABMultiValueRef phones = ABRecordCopyValue(contact, kABPersonPhoneProperty);
            if (ABMultiValueGetCount(phones) > 0) {
                CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, 0);
                person.phone = (__bridge NSString *)phoneNumberRef;
                CFRelease(phoneNumberRef);
            }
            CFRelease(phones);
            
            ABMultiValueRef emails = ABRecordCopyValue(contact, kABPersonEmailProperty);
            person.emails = [NSMutableDictionary dictionary];
            for(CFIndex j = 0; j < ABMultiValueGetCount(emails); j++) {
                CFStringRef emailRef = ABMultiValueCopyValueAtIndex(emails, j);
                CFStringRef locLabel = ABMultiValueCopyLabelAtIndex(emails, j);
                NSString *emailLabel =(__bridge_transfer NSString*) ABAddressBookCopyLocalizedLabel(locLabel);
                NSString *email = (__bridge NSString *)emailRef;
                CFRelease(emailRef);
                CFRelease(locLabel);
                [person.emails setObject:emailLabel forKey:email];
            }
            CFRelease(emails);
            
            ABMultiValueRef addressRef = ABRecordCopyValue(contact, kABPersonAddressProperty);
            if (ABMultiValueGetCount(addressRef) > 0) {
                CFDictionaryRef dict = ABMultiValueCopyValueAtIndex(addressRef, 0);
                person.addr1 = (NSString *)CFDictionaryGetValue(dict, kABPersonAddressStreetKey);
                person.city = (NSString *)CFDictionaryGetValue(dict, kABPersonAddressCityKey);
                person.state = (NSString *)CFDictionaryGetValue(dict, kABPersonAddressStateKey);
                person.zip = (NSString *)CFDictionaryGetValue(dict, kABPersonAddressZIPKey);
                person.country = (NSString *)CFDictionaryGetValue(dict, kABPersonAddressCountryKey);
                person.countryCode = (NSString *)CFDictionaryGetValue(dict, kABPersonAddressCountryCodeKey);
                
//                CFRelease(dict);
            }
//            CFRelease(addressRef);
            
//            CFRelease(contact);
            
            [self.persons addObject:person];
        }
        
        self.persons = [self sortAlphabeticallyForList:self.persons];
        [self.tableView reloadData];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
//    self.title = [NSString stringWithFormat:@"Import %@s", self.importingClass];
    
    self.persons = [NSMutableArray array];
    [self checkAddressBookAccess];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.persons.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.persons[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = IMPORT_AB_ITEM;
    UITableViewCell *cell = nil;
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    ABPerson *person = self.persons[indexPath.section][indexPath.row];
    
    if (person.name && person.name.length > 0) {
        cell.textLabel.text = person.name;
    }
    
    if (person.company) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", person.company];
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.indice[section];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if ([title isEqualToString:@"#"]) {
        title = @"123";
    }
    return [self.indice indexOfObject:title];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.alphabets;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:SELECT_AB_IMPORT_SEGUE sender:self.persons[indexPath.section][indexPath.row]];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(ABPerson *)sender {
    [segue.destinationViewController setImportingClass:self.importingClass];
    [segue.destinationViewController setPerson:sender];
    [segue.destinationViewController setMode:kViewMode];
}


@end
