//
//  MapViewController.m
//  Mobill
//
//  Created by Qinwei Gong on 9/7/13.
//  Copyright (c) 2013 Mobill Inc. All rights reserved.
//

#import "MapViewController.h"
#import "BDCBusinessObjectWithAttachmentsAndAddress.h"
#import "SlidingDetailsTableViewController.h"
#import "Constants.h"

#define INIT_MAP_POINTS             10000


@interface MapViewController () <MKMapViewDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@end


@implementation MapViewController

@synthesize mapView = _mapView;
@synthesize mapTypeSwitch;
@synthesize locationManager;
@synthesize annotations = _annotations;

- (IBAction)switchMapType:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        self.mapView.mapType = MKMapTypeStandard;
    } else {
        self.mapView.mapType = MKMapTypeSatellite;
    }
}

- (void) updateMapView
{
    if(self.mapView.annotations) {
        [self.mapView removeAnnotations:self.mapView.annotations];
    }
    
    if(self.annotations) {
        [self.mapView addAnnotations:self.annotations];   
    }
}

- (void) setAnnotations:(NSArray *)annotations {
    _annotations = annotations;
    
//    for (BDCBusinessObjectWithAttachmentsAndAddress *obj in self.annotations) {
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//            [obj geoCodeUsingAddress:obj.formattedAddress];
//        });
//    }
}

- (void) setMapView:(MKMapView *)mapView
{
    _mapView = mapView;
    [self updateMapView];
}

#pragma mark - MKMapView

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        //Don't trample the user location annotation (pulsing blue dot).
        return nil;
    } else {
        MKPinAnnotationView * aView = (MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"MapVCAnnotation"];
        if(!aView) {
            aView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MapVCAnnotation"];
            aView.canShowCallout = YES;
            
            UIImage *directionsImg = [UIImage imageNamed:@"directionsIcon.png"];
            UIButton *directionsBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
            [directionsBtn setImage:directionsImg forState:UIControlStateNormal];
            aView.leftCalloutAccessoryView = directionsBtn;
            aView.leftCalloutAccessoryView.tag = 0;
            
            aView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            aView.rightCalloutAccessoryView.tag = 1;
        }
        aView.annotation = annotation;
        aView.pinColor = MKPinAnnotationColorRed;
                
        return aView;
    }
}

//- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
//    MKCoordinateRegion region;
//    MKCoordinateSpan span;
//    span.latitudeDelta = 0.005;
//    span.longitudeDelta = 0.005;
//    CLLocationCoordinate2D location;
//    location.latitude = userLocation.coordinate.latitude;
//    location.longitude = userLocation.coordinate.longitude;
//    region.span = span;
//    region.center = location;
//    [mapView setRegion:region animated:YES];
//}

- (void) mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
//    [(UIImageView *)view.leftCalloutAccessoryView setImage:[UIImage imageNamed:@"Mobill40.png"]];
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    BDCBusinessObjectWithAttachmentsAndAddress *obj = view.annotation;
    
    if (control.tag == 0) {
        Class mapItemClass = [MKMapItem class];
        CLLocationCoordinate2D coordinate = [obj coordinate];
        
        if (mapItemClass && [mapItemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)]) {
            // Create an MKMapItem to pass to the Maps app
            MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate
                                                           addressDictionary:nil];
            MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
//            [mapItem setName:@"My Place"];
            
            NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
            MKMapItem *currentLocationMapItem = [MKMapItem mapItemForCurrentLocation];
            [MKMapItem openMapsWithItems:@[currentLocationMapItem, mapItem] launchOptions:launchOptions];
        } else {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://maps.google.com/?saddr=Current+Location&daddr=%f,%f", obj.latitude, obj.longitude]];
            [[UIApplication sharedApplication] openURL:url];
        }
    } else {
        [self.navigationController popViewControllerAnimated:YES]; //TODO: if pop to list vc, need to segue to a detail vc.
    }
}

#pragma mark - CLLocationManager delegate

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    Debug(@"%@", error);
}

- (void) locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    MKMapRect zoomRect = MKMapRectNull;
//    MKMapPoint annotationPoint = MKMapPointForCoordinate(newLocation.coordinate);
//    MKMapRect zoomRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
    for (id <MKAnnotation> annotation in self.mapView.annotations)
    {
        if (!(annotation.coordinate.latitude == 0.0 && annotation.coordinate.longitude == 0.0)) {
            MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
            MKMapRect pointRect = MKMapRectMake(annotationPoint.x - INIT_MAP_POINTS / 2, annotationPoint.y - INIT_MAP_POINTS / 2, INIT_MAP_POINTS, INIT_MAP_POINTS);
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }
    }
    [self.mapView setVisibleMapRect:zoomRect animated:YES];
    
    
//    MKCoordinateRegion region; // = MKCoordinateRegionForMapRect(zoomRect);
//    CLLocationCoordinate2D currLoc = newLocation.coordinate;
//    region.center = currLoc;
//
//    MKCoordinateSpan span;
//    span.latitudeDelta = 0.0003;
//    span.longitudeDelta = 0.0003;
//    region.span = span;
//
//    [self.mapView setRegion:region animated:YES];
//    [self.mapView regionThatFits:region];
    
    
//    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 30000, 30000);
//    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
//    [self.mapView setRegion:adjustedRegion animated:YES];
    
    self.locationManager.delegate = nil;
    [self.locationManager stopUpdatingHeading];
}

//- (NSArray *) mapAnnotations
//{
//    NSMutableArray * annotations = [NSMutableArray array];
//    
//    for(NSArray * busObj in self.busObjs) {
//        for(NSDictionary * contact in alphaGroup) {
//            [annotations addObject:[ContactAnnotation annotationForContact:contact]];
//        }
//    }
//    return annotations;
//}

- (void)viewDidLoad
{
    [super viewDidLoad];

//    self.mapView.showsUserLocation = YES;
    self.mapView.delegate = self;
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    [self.locationManager startUpdatingLocation];
    
    [self.mapTypeSwitch addTarget:self action:@selector(switchMapType:) forControlEvents:UIControlEventValueChanged];
}

- (void)viewDidUnload
{
    self.mapView = nil;
    self.locationManager = nil;
    self.annotations = nil;
    [super viewDidUnload];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
