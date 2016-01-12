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

@interface MainViewController ()

@end

@implementation MainViewController {
    MKMapView *mainMapView;
    UIButton *requestPickupButton;
    UIButton *callDirectButton;
    UIButton *menuButton;
}

int phoneNumber = 1234567890;

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
    
    [self pickupInactive];
    
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


- (void)pickupInactive {
    requestPickupButton.layer.cornerRadius = 8;
    requestPickupButton.clipsToBounds = YES;
    requestPickupButton.backgroundColor = [UIColor colorWithRed:(38/255.0) green:(68/255.0) blue:(153/255.0) alpha:1.0];
    requestPickupButton.titleLabel.font = [UIFont systemFontOfSize:20];
    [requestPickupButton setTitle:@"Request Pickup" forState:UIControlStateNormal];
    [requestPickupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [requestPickupButton addTarget:self action:@selector(pickupRequested:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)pickupRequested:(UIButton *)sender {
    [requestPickupButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [requestPickupButton setTitle:@"Requesting" forState:UIControlStateNormal];
    
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
                UIAlertController *cannotOpenTelAlert = [UIAlertController alertControllerWithTitle:@"Shipmate Pickup Unreachable." message:@"Call Shipmate at 410-320-5961 directly." preferredStyle:UIAlertControllerStyleAlert];
                [cannotOpenTelAlert addAction:[UIAlertAction
                                               actionWithTitle:@"Call"
                                               style:UIAlertViewStyleDefault
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
    //requestPickupButton.backgroundColor = [UIColor colorWithRed:(255/255.0) green:(238/255.0) blue:(00/255.0) alpha:1.0];
    //[requestPickupButton setTitleColor:[UIColor blackColor] forState:UIControlStateDisabled];
    [requestPickupButton setTitle:@"Pending driver" forState:UIControlStateNormal];
    
    [self monitorStatusAndSwitch:1];
}

- (void)pickupEnroute {
    [requestPickupButton setTitle:@"Pickup enroute" forState:UIControlStateNormal];
    
    [self monitorStatusAndSwitch:2];
}

- (void)pickupComplete {
    [requestPickupButton setTitle:@"Pickup complete" forState:UIControlStateNormal];
}

- (void)confirmPickupCancelWithCurrentStatus:(int)currentStatus {
    UIAlertController *confirmCancelAlert = [UIAlertController alertControllerWithTitle:@"Cancel Pickup?" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [confirmCancelAlert addAction:[UIAlertAction
                                   actionWithTitle:@"Yes"
                                   style:UIAlertActionStyleDestructive
                                   handler:^(UIAlertAction *alertAction) {
                                       [requestPickupButton setTitle:@"Canceling" forState:UIControlStateNormal];
                                       
                                       dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
                                           while (![ShipmateNetwork cancelPickup:phoneNumber withSender:self]) {
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
