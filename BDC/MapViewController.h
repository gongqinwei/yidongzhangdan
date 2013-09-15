//
//  MapViewController.h
//  Mobill
//
//  Created by Qinwei Gong on 9/7/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "BDCBusinessObjectWithAttachmentsAndAddress.h"

@protocol SelectObjectProtocol <NSObject>

- (void)selectObject:(BDCBusinessObjectWithAttachmentsAndAddress *)obj;

@end

@interface MapViewController : UIViewController <CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *mapTypeSwitch;

@property (nonatomic, strong) NSMutableArray * annotations; //of id<MKAnnotation>
@property (nonatomic, strong) id<SelectObjectProtocol> selectObjDelegate;

@end
