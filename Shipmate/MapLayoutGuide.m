//
//  MapLayoutGuide.m
//  Shipmate
//
//  Created by Anson Liu on 1/9/16.
//  Copyright © 2016 Anson Liu. All rights reserved.
//

#import "MapLayoutGuide.h"

@implementation MapLayoutGuide
@synthesize insetLength = _length;

- (id)initWithLength:(CGFloat)insetlength
{
    self = [super init];
    if (self) {
        _length = insetlength;
    }
    return self;
}

@end
