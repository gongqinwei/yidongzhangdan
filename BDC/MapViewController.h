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

@interface MapViewController : UIViewController <CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *mapTypeSwitch;

@property (nonatomic, strong) NSArray * annotations; //of id<MKAnnotation>

@end
