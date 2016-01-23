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
    UIButton *changePhoneNumberButton;
    CLLocationManager *locationManager;
    NSMutableArray<id<MKAnnotation>> *vanAnnotations;
    NSUserDefaults *sharedDefaults;
    NSString *phoneNumber;
    UIActivityIndicatorView *buttonActivityIndicator;
}

BOOL centeredOnLocation = NO;
BOOL rideCancelled = NO;

UIAlertAction *phoneNumberSaveAction;

NSString *const kPhoneNumberSettingsKey = @"phoneNumber";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    mainMapView = [[MKMapView alloc] init];
    
    requestPickupButton = [UIButton buttonWithType:UIButtonTypeSystem];
    callDirectButton = [UIButton buttonWithType:UIButtonTypeSystem];
    changePhoneNumberButton = [[UIButton alloc] init];
    buttonActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    
    
    mainMapView.translatesAutoresizingMaskIntoConstraints = NO;
    requestPickupButton.translatesAutoresizingMaskIntoConstraints = NO;
    callDirectButton.translatesAutoresizingMaskIntoConstraints = NO;
    changePhoneNumberButton.translatesAutoresizingMaskIntoConstraints = NO;
    buttonActivityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:mainMapView];
    [self.view addSubview:requestPickupButton];
    [self.view addSubview:callDirectButton];
    [self.view addSubview:changePhoneNumberButton];
    [requestPickupButton addSubview:buttonActivityIndicator];
    
    requestPickupButton.layer.cornerRadius = 8;
    requestPickupButton.clipsToBounds = YES;
    requestPickupButton.titleLabel.font = [UIFont systemFontOfSize:20];
    
    callDirectButton.layer.cornerRadius = 25;
    callDirectButton.clipsToBounds = YES;
    callDirectButton.titleLabel.font = [UIFont systemFontOfSize:30];
    [callDirectButton setTitle:@"\u260E\U0000FE0E" forState:UIControlStateNormal];
    [callDirectButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    callDirectButton.backgroundColor = [UIColor colorWithRed:(0/255.0) green:(193/255.0) blue:(94/255.0) alpha:1.0];
    [callDirectButton addTarget:self action:@selector(callShipmate) forControlEvents:UIControlEventTouchUpInside];
    
    changePhoneNumberButton.layer.cornerRadius = 8;
    changePhoneNumberButton.clipsToBounds = YES;
    changePhoneNumberButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [changePhoneNumberButton setTitle:@"\u2699\U0000FE0E Change Number" forState:UIControlStateNormal];
    [changePhoneNumberButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    changePhoneNumberButton.backgroundColor = [UIColor colorWithRed:(0/255.0) green:(0/255.0) blue:(0/255.0) alpha:0.8];
    [changePhoneNumberButton addTarget:self action:@selector(changePhoneNumber) forControlEvents:UIControlEventTouchUpInside];
    
    [mainMapView setRotateEnabled:NO];
    [mainMapView setPitchEnabled:NO];
    [mainMapView setScrollEnabled:YES];
    [mainMapView setZoomEnabled:YES];
    [mainMapView setMapType:MKMapTypeStandard];
    [mainMapView setShowsPointsOfInterest:NO];
    [mainMapView setDelegate:self];
    [mainMapView addAnnotations:vanAnnotations];
    
    id topGuide = [self topLayoutGuide];
    NSDictionary *dict = NSDictionaryOfVariableBindings(mainMapView, requestPickupButton, callDirectButton, changePhoneNumberButton, buttonActivityIndicator, topGuide);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[mainMapView]|"
                                                                      options:(NSLayoutFormatOptions)0
                                                                      metrics:nil views:dict]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[mainMapView]|"
                                                                      options:(NSLayoutFormatOptions)0
                                                                      metrics:nil views:dict]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[requestPickupButton]-10-|"
                                                                      options:(NSLayoutFormatOptions)0
                                                                      metrics:nil views:dict]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[changePhoneNumberButton(==150)]-(>=10)-[callDirectButton(==50)]-10-|"
                                                                      options:(NSLayoutFormatOptions)0
                                                                      metrics:nil views:dict]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=100)-[requestPickupButton(==45)]-10-|"
                                                                      options:(NSLayoutFormatOptions)0
                                                                      metrics:nil views:dict]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[callDirectButton(==50)]-10-[requestPickupButton]"
                                                                      options:(NSLayoutFormatOptions)0
                                                                      metrics:nil views:dict]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[topGuide]-10-[changePhoneNumberButton(==25)]-(>=10)-|"
                                                                      options:(NSLayoutFormatOptions)0
                                                                      metrics:nil views:dict]];
    
    [requestPickupButton addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[buttonActivityIndicator]-(>=10)-|"
                                                                      options:(NSLayoutFormatOptions)0
                                                                      metrics:nil views:dict]];
    
    [requestPickupButton addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[buttonActivityIndicator]-(>=10)-|"
                                                                                options:(NSLayoutFormatOptions)0
                                                                                metrics:nil views:dict]];
    //move Apple maps legal agreement up
    //http://jdkuzma.tumblr.com/post/79294999487/xcode-mapview-offsetting-the-compass-and-legal
    [mainMapView setLayoutMargins:UIEdgeInsetsMake(0, 0, 50, 0)];
    mainMapView.userLocation.title = @"You";
}

- (void)viewDidAppear:(BOOL)animated {
    [self pickupConnecting];
    
    [self monitorVanLocation];
    
    phoneNumber = [self getPhoneNumber];
    if (!phoneNumber) {
        [self changePhoneNumber];
    }
    
    locationManager = [[CLLocationManager alloc] init];
    [locationManager setDelegate:self];
    [self setupForLocation];
}

- (NSString *)getPhoneNumber {
    if (!sharedDefaults)
        sharedDefaults = [NSUserDefaults standardUserDefaults];
    return [sharedDefaults stringForKey:kPhoneNumberSettingsKey];
}

- (void)changePhoneNumber {
    if (!sharedDefaults)
        sharedDefaults = [NSUserDefaults standardUserDefaults];
    
    UIAlertController *inputPhoneNumberAlert = [UIAlertController alertControllerWithTitle:@"Set your phone number. " message:@"SHIPMATE drivers will match location using the phone number that you call from.\nPlease provide last 10 digits. We won't know where you are if you provide the wrong number :(" preferredStyle:UIAlertControllerStyleAlert];
    phoneNumberSaveAction = [UIAlertAction actionWithTitle:@"Save"
                                            style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *alertAction) {
                                                [sharedDefaults setObject:inputPhoneNumberAlert.textFields.firstObject.text forKey:kPhoneNumberSettingsKey];
                                                [sharedDefaults synchronize];
                                                phoneNumber = [sharedDefaults objectForKey:kPhoneNumberSettingsKey]; //re-set global phoneNumber string
                                            }];
    [inputPhoneNumberAlert addAction:phoneNumberSaveAction];
    [inputPhoneNumberAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        NSString *savedPhoneNumber = [self getPhoneNumber];
        [textField setPlaceholder:@"4012935001"];
        if (savedPhoneNumber) {
            [textField setText:savedPhoneNumber];
        }
        
        [UIApplication sharedApplication].applicationSupportsShakeToEdit = NO;
        [textField setKeyboardType:UIKeyboardTypeNumberPad];
        [textField setDelegate:self];
        
        if (savedPhoneNumber && [savedPhoneNumber length] == 10) {
            [phoneNumberSaveAction setEnabled:YES];
        } else {
            [phoneNumberSaveAction setEnabled:NO];
        }
    }];
    [self presentViewController:inputPhoneNumberAlert animated:YES completion:^(void) {}];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *validRegEx =@"^[0-9]*$"; //change this regular expression as your requirement
    NSPredicate *regExPredicate =[NSPredicate predicateWithFormat:@"SELF MATCHES %@", validRegEx];
    BOOL myStringMatchesRegEx = [regExPredicate evaluateWithObject:string];
    if (myStringMatchesRegEx) {
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        
        if (newLength >= 10) {
            [phoneNumberSaveAction setEnabled:YES];
        } else {
            [phoneNumberSaveAction setEnabled:NO];
        }
        
        return newLength <= 10;
    }
    else
        return NO;
    
    
    
    
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
        BOOL __block hasConnection = NO;
        BOOL __block hasNoVans = NO;
        
        while (1) {
            NSArray *retrievedVanLocations = [ShipmateNetwork getVanLocations];
            
            if (!retrievedVanLocations) {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [mainMapView removeAnnotations:vanAnnotations];
                    vanAnnotations = nil;
                    
                    [self pickupStatusError];
                    hasConnection = NO;
                    
                });
                //sleep 10 seconds in between
                usleep(10000000);
                
                continue;
            } else {
                if (!hasConnection && [retrievedVanLocations count] > 0) { //if UI updated for no connection, set UI for current status by passing -1 to monitorStatusAndSwitch
                    hasConnection = YES; //set first so that future while loops do not rerun this
                    [self monitorStatusAndSwitch:-1];
                }
            }
            
            if ([retrievedVanLocations count] == 0) {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [mainMapView removeAnnotations:vanAnnotations];
                    vanAnnotations = nil;
                    [self pickupUnavailable];
                    hasConnection = YES;
                    hasNoVans = YES;
                });
            } else {
                //alloc new annotation array if van count changes
                BOOL removeAndReaddAnnotations = NO;
                
                if (hasNoVans) { //if UI updated for no vans, set UI for current status by passing -1 to monitorStatusAndSwitch
                    hasNoVans = NO; //set first so that future while loops do not rerun this because this call may tkae a
                    [self monitorStatusAndSwitch:-1];
                }
                
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                
                //if counts of vans do not match up
                if (!vanAnnotations || [vanAnnotations count] != [retrievedVanLocations count]) {
                    removeAndReaddAnnotations = YES;
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [mainMapView removeAnnotations:vanAnnotations];
                        vanAnnotations = [[NSMutableArray alloc] initWithCapacity:[retrievedVanLocations count]];
                        for (int i = 0; i < [retrievedVanLocations count]; i++)
                            vanAnnotations[i] = [[VanAnnotation alloc] init];
                        dispatch_semaphore_signal(semaphore);
                    });
                } else {
                    dispatch_semaphore_signal(semaphore);
                }
                
                //wait for mainMapView update on main thread
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                
                //update annotation array with retrieved locations
                for (int i = 0; i < [retrievedVanLocations count]; i++) {
                    VanAnnotation __block *targetAnnotation = vanAnnotations[i];
                    //MKMapKit uses KVO key value obs to know when to update annotation location. setCoordinate must be called on main thread for KVO to work.
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [UIView animateWithDuration:1.0 animations:^{
                            [targetAnnotation setTitle:[NSString stringWithFormat:@"Van %d", i+1]];
                            [targetAnnotation setCoordinate:CLLocationCoordinate2DMake([[retrievedVanLocations[i] objectForKey:@"latitude"] doubleValue], [[retrievedVanLocations[i] objectForKey:@"longitude"] doubleValue])];
                        }];
                    });
                }
                
                if (removeAndReaddAnnotations) {
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [mainMapView addAnnotations:vanAnnotations];
                    });
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

//pass -1 for currentStatus to switch on any returned status
- (void)monitorStatusAndSwitch:(int)currentStatus {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^(void) {
        CLLocationCoordinate2D currentLocation = [[locationManager location] coordinate];
        CGPoint currentPoint = CGPointMake(currentLocation.latitude, currentLocation.longitude);
        
        int newStatus = [ShipmateNetwork getPickupInfo:phoneNumber withLocation:currentPoint withSender:self];
        
        //loop and wait for status change
        while (currentStatus == newStatus) {
            usleep(5000000); //check every 5 seconds
            newStatus = [ShipmateNetwork getPickupInfo:phoneNumber withLocation:currentPoint withSender:self];
            
            if (newStatus == -1) {
                newStatus = currentStatus;
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [self pickupStatusError];
                });
            }
        }
        
        //block that will switch
        void (^switchOnStatus)(int status) = ^void(int status) {
            switch (status) {
                case 0: //inactive
                    [self pickupInactive];
                    break;
                    
                case 1: //pending
                    [self pickupPending];
                    break;
                    
                case 2: //confirmed
                    [self pickupEnroute];
                    break;
                    
                case 3: //completed
                    [self pickupComplete];
                    break;
                    
                case -2: //wrong password
                    [self pickupWrongPassword];
                    break;
                    
                default:
                    NSLog(@"Unknown status %d", status);
                    if (!rideCancelled)
                        [self pickupStatusError];
            }
        };
        
        //run switch block on main thread
        dispatch_async(dispatch_get_main_queue(), ^(void){
            switchOnStatus(newStatus);
        });
    });
}

- (void)pickupConnecting {
    requestPickupButton.backgroundColor = [UIColor colorWithRed:(201/255.0) green:(48/255.0) blue:(44/255.0) alpha:1.0];
    requestPickupButton.titleLabel.font = [UIFont systemFontOfSize:20];
    [requestPickupButton setTitle:@"Connecting" forState:UIControlStateNormal];
    [requestPickupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [requestPickupButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    
    [buttonActivityIndicator startAnimating];
    
    [mainMapView setUserTrackingMode:MKUserTrackingModeNone];
}

- (void)pickupUnavailable {
    requestPickupButton.backgroundColor = [UIColor colorWithRed:(100/255.0) green:(100/255.0) blue:(100/255.0) alpha:1.0];
    requestPickupButton.titleLabel.font = [UIFont systemFontOfSize:20];
    [requestPickupButton setTitle:@"SHIPMATE not running" forState:UIControlStateNormal];
    [requestPickupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [requestPickupButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    
    [buttonActivityIndicator startAnimating];
    
    [mainMapView setUserTrackingMode:MKUserTrackingModeNone];
}

- (void)pickupInactive {
    requestPickupButton.backgroundColor = [UIColor colorWithRed:(38/255.0) green:(68/255.0) blue:(153/255.0) alpha:1.0];
    requestPickupButton.titleLabel.font = [UIFont systemFontOfSize:20];
    [requestPickupButton setTitle:@"Request Pickup" forState:UIControlStateNormal];
    [requestPickupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [requestPickupButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [requestPickupButton addTarget:self action:@selector(pickupRequested:) forControlEvents:UIControlEventTouchUpInside];
    
    [buttonActivityIndicator stopAnimating];
    
    centeredOnLocation = NO;
    
    [mainMapView setUserTrackingMode:MKUserTrackingModeNone];
}

- (void)pickupRequested:(UIButton *)sender {
    [requestPickupButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [requestPickupButton addTarget:self action:@selector(confirmPickupCancel) forControlEvents:UIControlEventTouchUpInside];
    requestPickupButton.titleLabel.font = [UIFont systemFontOfSize:20];
    [requestPickupButton setTitle:@"Requesting" forState:UIControlStateNormal];
    [requestPickupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [buttonActivityIndicator startAnimating];
    
    [mainMapView setUserTrackingMode:MKUserTrackingModeFollow];
    
    
    //Check for phone capability
    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel:5103868680"]] || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIAlertController *cannotOpenTelAlert = [UIAlertController alertControllerWithTitle:@"Unable to make phone calls right now." message:@"Call Shipmate at 410-320-5961 directly." preferredStyle:UIAlertControllerStyleAlert];
        [cannotOpenTelAlert addAction:[UIAlertAction
                                       actionWithTitle:@"Dismiss"
                                       style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction *alertAction) {}]];
        [self presentViewController:cannotOpenTelAlert animated:YES completion:^(void) {}];
        [self pickupInactive];
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        CLLocationCoordinate2D currentLocation = [[locationManager location] coordinate];
        BOOL success = [ShipmateNetwork newPickup:phoneNumber withLocation:CGPointMake(currentLocation.latitude, currentLocation.longitude) withSender:self];
        
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self monitorStatusAndSwitch:0];
                [self callShipmate];
                rideCancelled = NO;
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
    
    //Check for phone capability
    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel:5103868680"]] || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIAlertController *cannotOpenTelAlert = [UIAlertController alertControllerWithTitle:@"Unable to make phone calls right now." message:@"Call Shipmate at 410-320-5961 directly." preferredStyle:UIAlertControllerStyleAlert];
        [cannotOpenTelAlert addAction:[UIAlertAction
                                       actionWithTitle:@"Dismiss"
                                       style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction *alertAction) {}]];
        [self presentViewController:cannotOpenTelAlert animated:YES completion:^(void) {}];
        return;
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tel:5103868680"]];
    
}

- (void)pickupPending {
    requestPickupButton.backgroundColor = [UIColor colorWithRed:(236/255.0) green:(151/255.0) blue:(31/255.0) alpha:1.0];
    [requestPickupButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [requestPickupButton addTarget:self action:@selector(confirmPickupCancel) forControlEvents:UIControlEventTouchUpInside];
    requestPickupButton.titleLabel.font = [UIFont systemFontOfSize:20];
    [requestPickupButton setTitle:@"Pending driver" forState:UIControlStateNormal];
    
    [buttonActivityIndicator startAnimating];
    
    [self monitorStatusAndSwitch:1];
}

- (void)pickupEnroute {
    requestPickupButton.backgroundColor = [UIColor colorWithRed:(49/255.0) green:(176/255.0) blue:(213/255.0) alpha:1.0];
    [requestPickupButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [requestPickupButton addTarget:self action:@selector(confirmPickupCancel) forControlEvents:UIControlEventTouchUpInside];
    requestPickupButton.titleLabel.font = [UIFont systemFontOfSize:20];
    [requestPickupButton setTitle:@"Pickup enroute" forState:UIControlStateNormal];
    
    [buttonActivityIndicator stopAnimating];
    
    [self monitorStatusAndSwitch:2];
}

- (void)pickupComplete {
    requestPickupButton.backgroundColor = [UIColor colorWithRed:(68/255.0) green:(153/255.0) blue:(38/255.0) alpha:1.0];
    [requestPickupButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [requestPickupButton addTarget:self action:@selector(pickupInactive) forControlEvents:UIControlEventTouchUpInside];
    requestPickupButton.titleLabel.font = [UIFont systemFontOfSize:20];
    [requestPickupButton setTitle:@"Pickup complete" forState:UIControlStateNormal];
    
    [buttonActivityIndicator stopAnimating];
}

- (void)pickupStatusError {
    requestPickupButton.backgroundColor = [UIColor colorWithRed:(201/255.0) green:(48/255.0) blue:(44/255.0) alpha:1.0];
    requestPickupButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [requestPickupButton setTitle:@"⚡\U0000FE0E Connection error. Retrying..." forState:UIControlStateNormal];
    [requestPickupButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [mainMapView setUserTrackingMode:MKUserTrackingModeNone];
    
    [buttonActivityIndicator startAnimating];
}

- (void)pickupWrongPassword {
    requestPickupButton.backgroundColor = [UIColor colorWithRed:(201/255.0) green:(48/255.0) blue:(44/255.0) alpha:1.0];
    requestPickupButton.titleLabel.font = [UIFont systemFontOfSize:12];
    [requestPickupButton setTitle:@"\u1f6ab\U0000FE0E Phone number in use by someone else, use another phone number. " forState:UIControlStateNormal];
    [requestPickupButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [mainMapView setUserTrackingMode:MKUserTrackingModeNone];
    
    [self monitorStatusAndSwitch:-2];
    
    [buttonActivityIndicator stopAnimating];
}

- (void)confirmPickupCancel {
    UIAlertController *confirmCancelAlert = [UIAlertController alertControllerWithTitle:@"Cancel Pickup?" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [confirmCancelAlert addAction:[UIAlertAction
                                   actionWithTitle:@"Yes"
                                   style:UIAlertActionStyleDestructive
                                   handler:^(UIAlertAction *alertAction) {
                                       requestPickupButton.backgroundColor = [UIColor colorWithRed:(201/255.0) green:(48/255.0) blue:(44/255.0) alpha:1.0];
                                       [requestPickupButton setTitle:@"Canceling" forState:UIControlStateNormal];
                                       
                                       [buttonActivityIndicator startAnimating];
                                       
                                       dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
                                           while ([ShipmateNetwork cancelPickup:phoneNumber withSender:self] != YES) {
                                               usleep(1000000);
                                           }
                                           dispatch_async(dispatch_get_main_queue(), ^(void){
                                               [self pickupInactive];
                                               rideCancelled = YES;
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
        
        if (vanAnnotations && [vanAnnotations count] > 0) {
            CLLocationCoordinate2D currentLocation = [[locationManager location] coordinate];
            [mainMapView setRegion:MKCoordinateRegionMake(currentLocation, MKCoordinateSpanMake(fabs(currentLocation.latitude - ((VanAnnotation *)vanAnnotations[0]).coordinate.latitude) * 2, fabs(currentLocation.longitude - ((VanAnnotation *)vanAnnotations[0]).coordinate.longitude) * 2)) animated:YES];
        }
        
        centeredOnLocation = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
