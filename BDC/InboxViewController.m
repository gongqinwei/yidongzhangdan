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

static LRU *InMemCache = nil;

@interface InboxViewController () <DocumentListDelegate, DocumentCellDelegate>

@end


@implementation InboxViewController

+ (void)freeMem {
    [InMemCache spit];
}

// Override
- (void)refreshView {
    [super refreshView];
    
    [Document retrieveListForCategory:FILE_CATEGORY_DOCUMENT];
}

- (BOOL)changeCurrentDocumentTo:(Document *)doc {
    BOOL docChanged = [super changeCurrentDocumentTo:doc];
    
    if (docChanged) {
        NSArray *actionMenus = nil;
        if (doc && doc.objectId && doc.data) {
            actionMenus = [NSArray arrayWithObjects:[NSString stringWithFormat:ACTION_ASSOCIATE, self.currentDocument.name], nil];
            //        actionMenus = [NSArray arrayWithObjects:[NSString stringWithFormat:ACTION_ASSOCIATE, self.currentDocument.name], ACTION_DELETE, nil]; //TODO: need delete API
        } else {
            actionMenus = [NSArray array];
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
    
    InMemCache = self.dataInMemCache;
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
    cell.parentVC = self;
    cell.docCellDelegate = self;
    
//    if (!doc.data) {
//        [self downloadDocument:doc];
//    }
    
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
    if (!doc.data) {
        DocumentCell *cell = (DocumentCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell.downloadingIndicator startAnimating];
        cell.downloadingIndicator.hidden = NO;
        [self downloadDocument:doc];
    } else {
//        self.previewController.currentPreviewItemIndex = indexPath.row;
        
        [self presentModalViewController:self.previewController animated:YES];
        if (docChanged) {
            [self.previewController reloadData];
        }
        
        [self.dataInMemCache cache:doc];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
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
    @synchronized(self) {
        self.dataArray = [Document listForCategory:FILE_CATEGORY_DOCUMENT];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self changeCurrentDocumentTo:nil];
            [self.collectionView insertItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]];
            [self.previewController reloadData];
        });
    }
}

- (void)failedToGetDocuments {
    dispatch_async(dispatch_get_main_queue(), ^{
        [super endRefreshView];
    });
}

#pragma mark - Document Cell delegate

- (void)didSelectCell:(DocumentCell *)cell {
    [self changeCurrentDocumentTo:cell.document];
}

- (void)didLoadData:(DocumentCell *)cell {
    if (cell.document == self.currentDocument) {
        [self presentModalViewController:self.previewController animated:YES];
        [self.previewController reloadData];
        
        self.actionMenuVC.crudActions = self.crudActions = [NSArray arrayWithObjects:[NSString stringWithFormat:ACTION_ASSOCIATE, self.currentDocument.name], nil];
        self.actionMenuVC.actionDelegate = self;
    }
}

#pragma mark - Action Menu delegate

- (void)didSelectCrudAction:(NSString *)action {
    [super didSelectCrudAction:action];
    
    if ([action hasPrefix:@"Associate"]) {
        [self performSegueWithIdentifier:DOCUMENT_ASSOCIATE_SEGUE sender:self];
    }
}


@end
