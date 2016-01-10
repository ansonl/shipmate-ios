//
//  MapLayoutGuide.h
//  Shipmate
//
//  Created by Anson Liu on 1/9/16.
//  Copyright © 2016 Anson Liu. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

@interface MapLayoutGuide : NSObject <UILayoutSupport>
@property (nonatomic) CGFloat insetLength;
-(id)initWithLength:(CGFloat)length;
@end
