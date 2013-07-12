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
        
        NSString *ext = [[doc.name pathExtension] lowercaseString];
            
        if (doc && doc.objectId && (doc.thumbnail || ![IMAGE_TYPE_SET containsObject:ext])) {
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
    cell.documentName.text = [doc.name stringByDeletingPathExtension];
    cell.documentName.adjustsFontSizeToFitWidth = YES;
    cell.documentName.minimumFontSize = 8;
    cell.documentCreatedDate.text = doc.createdDate ? [Util formatDate:doc.createdDate format:nil] : @"Processing...";
    cell.parentVC = self;
    cell.docCellDelegate = self;
    
    doc.documentDelegate = cell;
    
    if (doc.thumbnail) {
        cell.documentImageView.image = [UIImage imageWithData:doc.thumbnail];
    } else {
        NSString *ext = [[doc.name pathExtension] lowercaseString];
        if (doc.objectId && ([IMAGE_TYPE_SET containsObject:ext] || [ext isEqualToString:@"pdf"])) {
                
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@/%@?%@=%@&%@=%d&%@=%d&%@=%d", DOMAIN_URL, DOC_IMAGE_API, ID, doc.objectId, PAGE_NUMBER, (doc.page <= 0 ? 1: doc.page), IMAGE_WIDTH, DOCUMENT_CELL_DIMENTION * 2, IMAGE_HEIGHT, DOCUMENT_CELL_DIMENTION * 2]]];

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
    
//    if (!doc.data) {
//        [self downloadDocument:doc];
//        [cell.downloadingIndicator startAnimating];
//        cell.downloadingIndicator.hidden = NO;
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
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *filePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:doc.name]];
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    
    if (exists) {
        [self presentModalViewController:self.previewController animated:YES];
        if (docChanged) {
            [self.previewController reloadData];
        }
    } else {
        if (!doc.data) {
            DocumentCell *cell = (DocumentCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            [cell.downloadingIndicator startAnimating];
            cell.downloadingIndicator.hidden = NO;
            [self downloadDocument:doc];
        }
    }
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
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *filePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:cell.document.name]];
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    if (exists) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    
    [cell.document.data writeToFile:filePath atomically:YES];
    
    if (cell.document == self.currentDocument) {
        if (self.presentedViewController != self.previewController) {
            [self presentModalViewController:self.previewController animated:YES];
        }
        [self.previewController reloadData];
        
//        self.actionMenuVC.crudActions = self.crudActions = [NSArray arrayWithObjects:[NSString stringWithFormat:ACTION_ASSOCIATE, self.currentDocument.name], nil];
//        self.actionMenuVC.actionDelegate = self;
    }
    
    [self.dataInMemCache cache:cell.document];
}

#pragma mark - Action Menu delegate

- (void)didSelectCrudAction:(NSString *)action {
    [super didSelectCrudAction:action];
    
    if ([action hasPrefix:@"Associate"]) {
        [self performSegueWithIdentifier:DOCUMENT_ASSOCIATE_SEGUE sender:self];
    }
}


@end
