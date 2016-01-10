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
    requestPickupButton.backgroundColor = [UIColor colorWithRed:(67/255.0) green:(153/255.0) blue:(38/255.0) alpha:1.0];
    requestPickupButton.titleLabel.font = [UIFont systemFontOfSize:20];
    [requestPickupButton setTitle:@"Request Pickup" forState:UIControlStateNormal];
    [requestPickupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [requestPickupButton setTitle:@"Internet Offline" forState:UIControlStateDisabled];
    [requestPickupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
    
    [requestPickupButton addTarget:self action:@selector(requestPickup:) forControlEvents:UIControlEventTouchUpInside];
    
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

- (void)requestPickup:(UIButton *)sender {
    [requestPickupButton setTitle:@"loading" forState:UIControlStateNormal];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        [ShipmateNetwork loadShipmate];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
             [requestPickupButton setTitle:@"done" forState:UIControlStateNormal];
        });
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
