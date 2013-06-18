//
//  InboxViewController.m
//  BDC
//
//  Created by Qinwei Gong on 5/29/13.
//
//

#import "InboxViewController.h"
#import "DocumentCell.h"
#import "Util.h"
#import "BOSelectorViewController.h"
#import <QuartzCore/QuartzCore.h>

#define DOCUMENT_ASSOCIATE_SEGUE        @"DocumentAssociatedWith"


@interface InboxViewController () <DocumentListDelegate, DocumentCellDelegate>

@end


@implementation InboxViewController

// Override
- (void)refreshView {
    [super refreshView];
    
    [Document retrieveListForCategory:FILE_CATEGORY_DOCUMENT];
}

- (void)changeCurrentDocumentTo:(Document *)doc {
    [super changeCurrentDocumentTo:doc];
    
    NSArray *actionMenus = nil;
    if (doc) {
        actionMenus = [NSArray arrayWithObjects:[NSString stringWithFormat:ACTION_ASSOCIATE, self.currentDocument.name], ACTION_DELETE, nil]; //TODO: need delete API
    }
    
    self.actionMenuVC.crudActions = self.crudActions = actionMenus;
    self.actionMenuVC.actionDelegate = self;
    [self.actionMenuVC.tableView reloadData];
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:DOCUMENT_ASSOCIATE_SEGUE]) {
//        [segue.destinationViewController setPhotoName:self.currentDocument.name];
//        [segue.destinationViewController setPhotoData:self.currentDocument.data];
        [segue.destinationViewController setDocument:self.currentDocument];
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
    cell.documentName.text = doc.name;
    cell.documentName.adjustsFontSizeToFitWidth = YES;
    cell.documentName.minimumFontSize = 8;
    cell.documentCreatedDate.text = [Util formatDate:doc.createdDate format:nil];
    cell.selectDelegate = self;
    [cell toggleInfoDisplay:YES];
    
    if (!doc.data) {
        [self downloadDocument:doc];
    }
    
    return cell;
}

/*- (UICollectionReusableView *)collectionView:
 (UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
 return [[UICollectionReusableView alloc] init];
 }*/

#pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self changeCurrentDocumentTo:self.dataArray[indexPath.row]];
    
    self.previewController.currentPreviewItemIndex = indexPath.row;
    [self presentModalViewController:self.previewController animated:YES];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"- %d", indexPath.row);
}

#pragma mark – UICollectionView Delegate FlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize retval = CGSizeMake(95, 95);
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [self changeCurrentDocumentTo:nil];
        [self.collectionView insertItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]];
        [self.previewController reloadData];
    });
}

#pragma mark - Document Cell delegate

- (void)didSelectCell:(DocumentCell *)cell {
    [self changeCurrentDocumentTo:cell.document];
}

#pragma mark - Action Menu delegate

- (void)didSelectCrudAction:(NSString *)action {
    [super didSelectCrudAction:action];
    
    if ([action hasPrefix:@"Associate"]) {
        [self performSegueWithIdentifier:DOCUMENT_ASSOCIATE_SEGUE sender:self];
    }
}


@end
