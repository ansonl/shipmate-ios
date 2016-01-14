//
//  VanAnnotation.h
//  Shipmate
//
//  Created by Anson Liu on 1/13/16.
//  Copyright © 2016 Anson Liu. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MapKit;

@interface VanAnnotation : NSObject <MKAnnotation>

@property(nonatomic, assign) CLLocationCoordinate2D coordinate;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *subtitle;

@end
