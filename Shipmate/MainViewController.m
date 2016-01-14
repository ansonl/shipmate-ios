//
//  MainViewController.m
//  Shipmate
//
//  Created by Anson Liu on 1/6/16.
//  Copyright © 2016 Anson Liu. All rights reserved.
//

#import "MainViewController.h"
@import MapKit;
#import <QuartzCore/QuartzCore.h>
#import "ShipmateNetwork.h"
#import "VanAnnotation.h"

@interface MainViewController ()

@end

@implementation MainViewController {
    MKMapView *mainMapView;
    UIButton *requestPickupButton;
    UIButton *callDirectButton;
    UIButton *menuButton;
    CLLocationManager *locationManager;
    NSMutableArray<id<MKAnnotation>> *vanAnnotations;
}

int phoneNumber = 1234567890;

BOOL centeredOnLocation = NO;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    mainMapView = [[MKMapView alloc] init];
    
    requestPickupButton = [UIButton buttonWithType:UIButtonTypeSystem];
    callDirectButton = [[UIButton alloc] init];
    menuButton = [[UIButton alloc] init];
    
    
    mainMapView.translatesAutoresizingMaskIntoConstraints = NO;
    requestPickupButton.translatesAutoresizingMaskIntoConstraints = NO;
    callDirectButton.translatesAutoresizingMaskIntoConstraints = NO;
    menuButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:mainMapView];
    [self.view addSubview:requestPickupButton];
    
    requestPickupButton.layer.cornerRadius = 8;
    requestPickupButton.clipsToBounds = YES;
    requestPickupButton.titleLabel.font = [UIFont systemFontOfSize:20];
    
    [mainMapView setRotateEnabled:NO];
    [mainMapView setPitchEnabled:NO];
    [mainMapView setScrollEnabled:YES];
    [mainMapView setZoomEnabled:YES];
    [mainMapView setMapType:MKMapTypeStandard];
    [mainMapView setShowsPointsOfInterest:NO];
    [mainMapView setDelegate:self];
    [mainMapView addAnnotations:vanAnnotations];
    
    NSDictionary *dict = NSDictionaryOfVariableBindings(mainMapView, requestPickupButton, callDirectButton, menuButton);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[mainMapView]|"
                                                                      options:(NSLayoutFormatOptions)0
                                                                      metrics:nil views:dict]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[mainMapView]|"
                                                                      options:(NSLayoutFormatOptions)0
                                                                      metrics:nil views:dict]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[requestPickupButton]-10-|"
                                                                      options:(NSLayoutFormatOptions)0
                                                                      metrics:nil views:dict]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=100)-[requestPickupButton(==45)]-10-|"
                                                                      options:(NSLayoutFormatOptions)0
                                                                      metrics:nil views:dict]];
    //move Apple maps legal agreement up
    //http://jdkuzma.tumblr.com/post/79294999487/xcode-mapview-offsetting-the-compass-and-legal
    [mainMapView setLayoutMargins:UIEdgeInsetsMake(0, 0, 50, 0)];
    
    [self monitorVanLocation];
    
    [self pickupInactive];
    
    locationManager = [[CLLocationManager alloc] init];
    [locationManager setDelegate:self];
    [self setupForLocation];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[VanAnnotation class]]) {
        MKAnnotationView *vanAnnotationView = (MKAnnotationView *)[mainMapView dequeueReusableAnnotationViewWithIdentifier:@"annotation"];
        if (!vanAnnotationView)
            vanAnnotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"annotation"];
        else
            vanAnnotationView.annotation = annotation;
        
        [vanAnnotationView setCanShowCallout:YES];
        UIImage *originalImage = [UIImage imageNamed:@"vanFront"];
        
        CGSize size = CGSizeApplyAffineTransform(originalImage.size, CGAffineTransformMakeScale(0.1, 0.1));
        CGFloat scale = 0.0; // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(size, NO, scale);
        [originalImage drawInRect:CGRectMake(CGPointZero.x, CGPointZero.y, size.width, size.height)];
        UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        vanAnnotationView.image = scaledImage;
        return vanAnnotationView;
    } else {
        return nil;
    }
}

- (void)monitorVanLocation {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^(void) {
        
        while (1) {
            NSArray *retrievedVanLocations = [ShipmateNetwork getVanLocations];
            
            if ([retrievedVanLocations count] == 0) {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [self pickupUnavailable];
                });
            } else {
                //alloc new annotation array if van count changes
                BOOL removeAndReaddAnnotations = NO;
                if (!vanAnnotations || [vanAnnotations count] != [retrievedVanLocations count]) {
                    removeAndReaddAnnotations = YES;
                    [mainMapView removeAnnotations:vanAnnotations];
                    vanAnnotations = [[NSMutableArray alloc] initWithCapacity:[retrievedVanLocations count]];
                    for (int i = 0; i < [retrievedVanLocations count]; i++)
                        vanAnnotations[i] = [[VanAnnotation alloc] init];
                }
                
                //update annotation array with retrieved locations
                for (int i = 0; i < [retrievedVanLocations count]; i++) {
                    VanAnnotation __block *targetAnnotation = vanAnnotations[i];
                    //MKMapKit uses KVO key value obs to know when to update annotation location. setCoordinate must be called on main thread for KVO to work.
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [UIView animateWithDuration:0.5 animations:^{
                            [targetAnnotation setTitle:[NSString stringWithFormat:@"Van %d", i+1]];
                            [targetAnnotation setCoordinate:CLLocationCoordinate2DMake([[retrievedVanLocations[i] objectForKey:@"latitude"] doubleValue], [[retrievedVanLocations[i] objectForKey:@"longitude"] doubleValue])];
                        }];
                    });
                }
                
                if (removeAndReaddAnnotations) {
                    [mainMapView addAnnotations:vanAnnotations];
                }
            }
            usleep(1000000);
        }
    });
}

- (void)setupForLocation {
    if (![CLLocationManager locationServicesEnabled]) {
        UIAlertController *locationServiceOffAlert = [UIAlertController alertControllerWithTitle:@"Location services turned off on this phone. " message:@"Call Shipmate at 410-320-5961 directly." preferredStyle:UIAlertControllerStyleAlert];
        [locationServiceOffAlert addAction:[UIAlertAction
                                            actionWithTitle:@"Dismiss"
                                            style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *alertAction) {}]];
        [self presentViewController:locationServiceOffAlert animated:YES completion:^(void) {}];
    } else {
        UIAlertController *locationServiceOffAlert = [UIAlertController alertControllerWithTitle:@"SHIPMATE denied access to location. " message:@"Enable location access for SHIPMATE in Settings app or call Shipmate at 410-320-5961 directly." preferredStyle:UIAlertControllerStyleAlert];
        [locationServiceOffAlert addAction:[UIAlertAction
                                            actionWithTitle:@"Dismiss"
                                            style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *alertAction) {}]];
        
        switch ([CLLocationManager authorizationStatus]) {
            case kCLAuthorizationStatusNotDetermined:
                [locationManager requestAlwaysAuthorization];
                break;
            case kCLAuthorizationStatusDenied:
                [self presentViewController:locationServiceOffAlert animated:YES completion:^(void) {}];
                break;
            case kCLAuthorizationStatusRestricted:
                [self presentViewController:locationServiceOffAlert animated:YES completion:^(void) {}];
                break;
            case kCLAuthorizationStatusAuthorizedAlways:
                [locationManager startUpdatingLocation];
                [mainMapView setShowsUserLocation:YES];
                break;
            case kCLAuthorizationStatusAuthorizedWhenInUse:
                [locationManager startUpdatingLocation];
                [mainMapView setShowsUserLocation:YES];
                break;
                
            default:
                NSLog(@"Unknown location authorization status %d", [CLLocationManager authorizationStatus]);
                break;
        }
    }

}

- (void)monitorStatusAndSwitch:(int)currentStatus {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^(void) {
        
        int newStatus = [ShipmateNetwork getPickupInfo:phoneNumber withLocation:(CGPointMake(0, 0)) withSender:self];
        
        //loop and wait for status change
        while (currentStatus == newStatus) {
            usleep(1000000);
            newStatus = [ShipmateNetwork getPickupInfo:phoneNumber withLocation:(CGPointMake(0, 0)) withSender:self];;
        }
        
        //block that will switch
        void (^switchOnStatus)(int status) = ^void(int status) {
            switch (status) {
                case 0: //inactive
                    [self pickupInactive];
                    break;
                    
                case 1: //pending
                    [self callShipmate];
                    [self pickupPending];
                    break;
                    
                case 2: //confirmed
                    [self pickupEnroute];
                    break;
                    
                case 3: //completed
                    [self pickupComplete];
                    break;
                    
                default:
                    NSLog(@"Unknown status %d", status);
            }
        };
        
        //run switch block on main thread
        dispatch_async(dispatch_get_main_queue(), ^(void){
            switchOnStatus(newStatus);
        });
    });
}

- (void)pickupUnavailable {
    requestPickupButton.backgroundColor = [UIColor colorWithRed:(100/255.0) green:(100/255.0) blue:(100/255.0) alpha:1.0];
    [requestPickupButton setTitle:@"SHIPMATE not running. Tap to call directly." forState:UIControlStateNormal];
    [requestPickupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [requestPickupButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [requestPickupButton addTarget:self action:@selector(callShipmate) forControlEvents:UIControlEventTouchUpInside];
    
    [mainMapView setUserTrackingMode:MKUserTrackingModeNone];
}

- (void)pickupInactive {
    requestPickupButton.backgroundColor = [UIColor colorWithRed:(38/255.0) green:(68/255.0) blue:(153/255.0) alpha:1.0];
    [requestPickupButton setTitle:@"Request Pickup" forState:UIControlStateNormal];
    [requestPickupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [requestPickupButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [requestPickupButton addTarget:self action:@selector(pickupRequested:) forControlEvents:UIControlEventTouchUpInside];
    
    centeredOnLocation = NO;
    
    [mainMapView setUserTrackingMode:MKUserTrackingModeNone];
}

- (void)pickupRequested:(UIButton *)sender {
    [requestPickupButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [requestPickupButton addTarget:self action:@selector(confirmPickupCancel) forControlEvents:UIControlEventTouchUpInside];
    [requestPickupButton setTitle:@"Requesting" forState:UIControlStateNormal];
    
    [mainMapView setUserTrackingMode:MKUserTrackingModeFollow];
    
    /*
    //Check for phone capability
    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]]) {
        UIAlertController *cannotOpenTelAlert = [UIAlertController alertControllerWithTitle:@"Unable to make phone calls right now." message:@"Call Shipmate at 410-320-5961 directly." preferredStyle:UIAlertControllerStyleAlert];
        [cannotOpenTelAlert addAction:[UIAlertAction
                                       actionWithTitle:@"Dismiss"
                                       style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction *alertAction) {}]];
        [self presentViewController:cannotOpenTelAlert animated:YES completion:^(void) {}];
        [self pickupInactive];
        return;
    }
     */

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        BOOL success = [ShipmateNetwork newPickup:phoneNumber withLocation:(CGPointMake(123, 321)) withSender:self];
        
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self monitorStatusAndSwitch:0];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                UIAlertController *cannotOpenTelAlert = [UIAlertController alertControllerWithTitle:@"Shipmate Pickup Unreachable." message:@"Call Shipmate at 410-320-5961 directly?" preferredStyle:UIAlertControllerStyleAlert];
                [cannotOpenTelAlert addAction:[UIAlertAction
                                               actionWithTitle:@"Call"
                                               style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction *alertAction) {
                                                   [self callShipmate];
                                               }]];
                [cannotOpenTelAlert addAction:[UIAlertAction
                                               actionWithTitle:@"Dismiss"
                                               style:UIAlertActionStyleCancel
                                               handler:^(UIAlertAction *alertAction) {}]];
                [self presentViewController:cannotOpenTelAlert animated:YES completion:^(void) {}];

                [self pickupInactive];
            });
        }
    });
}

- (void)callShipmate {
    /*
    NSString *callMessage = [NSString stringWithFormat:@"Calling from xxx-xxx-xxxx"];
    [requestPickupButton setTitle:callMessage forState:UIControlStateDisabled];
     */
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tel://5103868680"]];
    
}

- (void)pickupPending {
    requestPickupButton.backgroundColor = [UIColor colorWithRed:(236/255.0) green:(151/255.0) blue:(31/255.0) alpha:1.0];
    [requestPickupButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [requestPickupButton addTarget:self action:@selector(confirmPickupCancel) forControlEvents:UIControlEventTouchUpInside];
    [requestPickupButton setTitle:@"Pending driver" forState:UIControlStateNormal];
    
    [self monitorStatusAndSwitch:1];
}

- (void)pickupEnroute {
    requestPickupButton.backgroundColor = [UIColor colorWithRed:(49/255.0) green:(176/255.0) blue:(213/255.0) alpha:1.0];
    [requestPickupButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [requestPickupButton addTarget:self action:@selector(confirmPickupCancel) forControlEvents:UIControlEventTouchUpInside];
    [requestPickupButton setTitle:@"Pickup enroute" forState:UIControlStateNormal];
    
    [self monitorStatusAndSwitch:2];
}

- (void)pickupComplete {
    requestPickupButton.backgroundColor = [UIColor colorWithRed:(68/255.0) green:(153/255.0) blue:(38/255.0) alpha:1.0];
    [requestPickupButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [requestPickupButton addTarget:self action:@selector(pickupInactive) forControlEvents:UIControlEventTouchUpInside];
    [requestPickupButton setTitle:@"Pickup complete" forState:UIControlStateNormal];
}

- (void)confirmPickupCancel {
    UIAlertController *confirmCancelAlert = [UIAlertController alertControllerWithTitle:@"Cancel Pickup?" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [confirmCancelAlert addAction:[UIAlertAction
                                   actionWithTitle:@"Yes"
                                   style:UIAlertActionStyleDestructive
                                   handler:^(UIAlertAction *alertAction) {
                                       requestPickupButton.backgroundColor = [UIColor colorWithRed:(201/255.0) green:(48/255.0) blue:(44/255.0) alpha:1.0];
                                       [requestPickupButton setTitle:@"Canceling" forState:UIControlStateNormal];
                                       
                                       dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
                                           while ([ShipmateNetwork cancelPickup:phoneNumber withSender:self] != YES) {
                                               usleep(1000000);
                                           }
                                           dispatch_async(dispatch_get_main_queue(), ^(void){
                                               [self pickupInactive];
                                           });
                                       });
                                   }]];
    [confirmCancelAlert addAction:[UIAlertAction
                                   actionWithTitle:@"No"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *alertAction) {}]];
    [self presentViewController:confirmCancelAlert animated:YES completion:^(void) {}];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self setupForLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (centeredOnLocation == NO) {
        [mainMapView setRegion:MKCoordinateRegionMake([[locationManager location] coordinate], MKCoordinateSpanMake(0.1, 0.1)) animated:YES];
        centeredOnLocation = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
