//
//  InboxViewController.m
//  BDC
//
//  Created by Qinwei Gong on 5/29/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "InboxViewController.h"
#import "DocumentCell.h"
#import "Util.h"
#import "BOSelectorViewController.h"
#import "EditBillViewController.h"
#import <QuartzCore/QuartzCore.h>

#define DOCUMENT_ASSOCIATE_SEGUE        @"DocumentAssociatedWith"
#define DOCUMENT_ACCEPT_EBILL           @"AcceptEBill"

//static LRU *InMemCache = nil;
//static NSLock *accessLock = nil;

@interface InboxViewController () <DocumentListDelegate, DocumentCellDelegate>

@end


@implementation InboxViewController

//+ (void)freeMem {
//    [InMemCache spit];
//}

// Override
- (void)refreshView {
    [super refreshView];
    [Document retrieveListForCategory:FILE_CATEGORY_DOCUMENT];
}

- (BOOL)changeCurrentDocumentTo:(Document *)doc {
    BOOL docChanged = [super changeCurrentDocumentTo:doc];
    
    if (docChanged) {
        NSArray *actionMenus = nil;
        
        if (doc && doc.objectId && (doc.thumbnail || ![doc isImage])) {
            if (doc.eBill) {
                actionMenus = [NSArray arrayWithObjects:ACTION_ACCEPT_EBILL, nil];
            } else {
                actionMenus = [NSArray arrayWithObjects:[NSString stringWithFormat:ACTION_ASSOCIATE, self.currentDocument.name], nil];
//          actionMenus = [NSArray arrayWithObjects:[NSString stringWithFormat:ACTION_ASSOCIATE, self.currentDocument.name], ACTION_DELETE, nil]; //TODO: need delete API
            }
        } else {
            actionMenus = [NSArray arrayWithObjects:ACTION_BDC_PROCESSING, ACTION_BDC_PROCESSING2, nil];
        }
        
        self.actionMenuVC.crudActions = self.crudActions = actionMenus;
        self.actionMenuVC.actionDelegate = self;
        [self.actionMenuVC.tableView reloadData];
    }
    
    return docChanged;
}

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
    
    [Document setDocumentListDelegate:self];
    
    self.dataArray = [Document listForCategory:FILE_CATEGORY_DOCUMENT];
    
//    InMemCache = self.dataInMemCache;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:DOCUMENT_ASSOCIATE_SEGUE]) {
        [segue.destinationViewController setDocument:self.currentDocument];
        [segue.destinationViewController setMode:kAttachMode];
    } else if ([segue.identifier isEqualToString:DOCUMENT_ACCEPT_EBILL]) {
        [segue.destinationViewController setBusObj:(BDCBusinessObjectWithAttachments *)self.currentDocument.eBill];
        [segue.destinationViewController addDocument:self.currentDocument];
        [segue.destinationViewController setMode:kAttachMode];
        [segue.destinationViewController setTitle:@"New eBill"];
    }
}

#pragma mark - UICollectionView Datasource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"InboxCell";
    DocumentCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Document *doc = self.dataArray[indexPath.row];
    cell.document = doc;
    if (doc.eBill) {
        cell.documentName.text = doc.eBillVendorOrgName;
    } else {
        cell.documentName.text = [doc.name stringByDeletingPathExtension];
    }
    cell.documentName.adjustsFontSizeToFitWidth = YES;
    cell.documentName.minimumScaleFactor = 8;
    if (doc.createdDate) {
        cell.documentCreatedDate.text = [Util formatDate:doc.createdDate format:nil];
        cell.documentCreatedDate.font = [UIFont systemFontOfSize:11];
    } else {
        cell.documentCreatedDate.text = @"Processing...";
        cell.documentCreatedDate.font = [UIFont fontWithName:@"Arial-BoldMT" size:13];
    }
    if (cell.document.eBill) {
        cell.ebillLabel.hidden = NO;
    } else {
        cell.ebillLabel.hidden = YES;
    }
    
    cell.parentVC = self;
    cell.docCellDelegate = self;
    
    doc.documentDelegate = cell;
    
    if (doc.thumbnail) {
        cell.documentImageView.image = [UIImage imageWithData:doc.thumbnail];
    } else {
        if (doc.objectId && [doc isImageOrPDF]) {
                
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@/is/%@?%@=%@&%@=%d&%@=%d&%@=%d", DOMAIN_URL, DOC_IMAGE_API, _ID, doc.objectId, PAGE_NUMBER, 1, IMAGE_WIDTH, DOCUMENT_CELL_DIMENTION * 2, IMAGE_HEIGHT, DOCUMENT_CELL_DIMENTION * 2]]];

                if (data != nil) {
                    doc.thumbnail = data;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIImage *icon = [UIImage imageWithData: data];
                        
                        if (icon) {
                            cell.documentImageView.image = icon;
                        }
                    });
                }
            });
        }
    }
    
    if (doc == self.currentDocument) {
        [cell didGetSelected];
    } else {
        [cell didGetDeselected];
    }
    
    [cell toggleInfoDisplay:!cell.document.showInfo];
    
    return cell;
}

/*- (UICollectionReusableView *)collectionView:
 (UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
 return [[UICollectionReusableView alloc] init];
 }*/

#pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {    
    BOOL docChanged = [self changeCurrentDocumentTo:self.dataArray[indexPath.row]];
    
    Document *doc = self.currentDocument;
    
    if ([doc docFileExists] || doc.data) {
        [self presentViewController:self.previewController animated:YES completion:nil];
        if (docChanged) {
            [self.previewController reloadData];
        }
    } else {
        DocumentCell *cell = (DocumentCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell.downloadingIndicator startAnimating];
        cell.downloadingIndicator.hidden = NO;
        [self downloadDocument:doc];
    }
    
    [Util track:[NSString stringWithFormat:@"View Inbox doc"]];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark – UICollectionView Delegate FlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize retval = CGSizeMake(DOCUMENT_CELL_DIMENTION, DOCUMENT_CELL_DIMENTION);
    return retval;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(7, 7, 7, 7);
}

#pragma mark - Document List delegate

- (void)didGetDocuments {
    self.dataArray = [Document listForCategory:FILE_CATEGORY_DOCUMENT];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self changeCurrentDocumentTo:nil];
        [super endRefreshView];
        [self.previewController reloadData];
    });
}

- (void)didAddDocument:(Document *)doc {
    self.dataArray = [Document listForCategory:FILE_CATEGORY_DOCUMENT];
    @synchronized(self) {
        [self changeCurrentDocumentTo:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView insertItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]];
            [self.previewController reloadData];
        });
    }
}

- (void)failedToGetDocuments {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
    });
}

- (void)deniedPermissionForInbox {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
    });
}

#pragma mark - Document Cell delegate

- (void)didSelectCell:(DocumentCell *)cell {
    [self changeCurrentDocumentTo:cell.document];
}

- (void)didLoadData:(DocumentCell *)cell {
    [cell.document writeToFile];
    
    if (cell.document == self.currentDocument) {
        if (self.presentedViewController != self.previewController) {
            [self presentViewController:self.previewController animated:YES completion:nil];
        }
        [self.previewController reloadData];
        
//        self.actionMenuVC.crudActions = self.crudActions = [NSArray arrayWithObjects:[NSString stringWithFormat:ACTION_ASSOCIATE, self.currentDocument.name], nil];
//        self.actionMenuVC.actionDelegate = self;
    }
    
//    [self.dataInMemCache cache:cell.document];
}

#pragma mark - Action Menu delegate

- (void)didSelectCrudAction:(NSString *)action {
    [super didSelectCrudAction:action];
    
    if ([action hasPrefix:@"Associate"]) {
        [self performSegueWithIdentifier:DOCUMENT_ASSOCIATE_SEGUE sender:self];
    } else if ([action isEqualToString:ACTION_ACCEPT_EBILL]) {
        [self performSegueWithIdentifier:DOCUMENT_ACCEPT_EBILL sender:self];
    }
}


@end
