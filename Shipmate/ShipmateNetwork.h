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

+ (BOOL)newPickup:(int)phoneNumber withLocation:(CGPoint)location withSender:(MainViewController *)sender;
+ (int)getPickupInfo:(int)phoneNumber withLocation:(CGPoint)location withSender:(MainViewController *)sender;
+ (BOOL)cancelPickup:(int)phoneNumber withSender:(MainViewController *)sender;

@end
