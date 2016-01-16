//
//  ShipmateNetwork.h
//  Shipmate
//
//  Created by Anson Liu on 1/9/16.
//  Copyright © 2016 Anson Liu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MainViewController.h"

@interface ShipmateNetwork : NSObject

+ (BOOL)newPickup:(NSString *)phoneNumber withLocation:(CGPoint)location withSender:(MainViewController *)sender;
+ (int)getPickupInfo:(NSString *)phoneNumber withLocation:(CGPoint)location withSender:(MainViewController *)sender;
+ (BOOL)cancelPickup:(NSString *)phoneNumber withSender:(MainViewController *)sender;
+ (NSArray *)getVanLocations;

@end
