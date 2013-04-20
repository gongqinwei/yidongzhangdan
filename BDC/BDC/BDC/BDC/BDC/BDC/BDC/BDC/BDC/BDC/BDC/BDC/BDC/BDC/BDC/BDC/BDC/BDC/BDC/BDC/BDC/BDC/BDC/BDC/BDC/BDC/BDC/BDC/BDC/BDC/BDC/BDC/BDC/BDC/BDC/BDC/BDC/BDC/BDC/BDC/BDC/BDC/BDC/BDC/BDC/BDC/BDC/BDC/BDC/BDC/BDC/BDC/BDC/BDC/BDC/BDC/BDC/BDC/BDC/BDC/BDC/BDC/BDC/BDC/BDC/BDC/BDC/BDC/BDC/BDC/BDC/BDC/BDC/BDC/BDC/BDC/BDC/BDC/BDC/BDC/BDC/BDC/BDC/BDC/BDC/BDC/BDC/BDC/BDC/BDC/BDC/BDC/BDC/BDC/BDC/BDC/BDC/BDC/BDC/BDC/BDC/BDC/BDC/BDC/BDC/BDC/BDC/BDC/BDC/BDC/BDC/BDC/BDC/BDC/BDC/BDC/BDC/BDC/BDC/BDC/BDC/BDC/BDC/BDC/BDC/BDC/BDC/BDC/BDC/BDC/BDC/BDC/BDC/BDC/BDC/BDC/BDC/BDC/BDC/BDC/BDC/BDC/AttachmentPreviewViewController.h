//
//  AttachmentPreviewViewController.h
//  BDC
//
//  Created by Qinwei Gong on 9/30/12.
//
//

#import <UIKit/UIKit.h>

@interface AttachmentPreviewViewController : UIViewController

@property (nonatomic, strong) NSData *photoData;
@property (nonatomic, strong) NSString *photoName;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UINavigationBar *previewNavigationBar;

@end
