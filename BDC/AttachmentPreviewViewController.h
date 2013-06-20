//
//  AttachmentPreviewViewController.h
//  BDC
//
//  Created by Qinwei Gong on 9/30/12.
//
//

#import <UIKit/UIKit.h>
#import "Document.h"

@interface AttachmentPreviewViewController : UIViewController

@property (nonatomic, strong) Document *document;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UINavigationBar *previewNavigationBar;

@end
