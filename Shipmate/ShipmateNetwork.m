//
//  ShipmateNetwork.m
//  Shipmate
//
//  Created by Anson Liu on 1/9/16.
//  Copyright © 2016 Anson Liu. All rights reserved.
//

#import "ShipmateNetwork.h"

@implementation ShipmateNetwork 

NSString *const kBaseServer = @"http://127.0.0.1:8080";
NSString *const kNewPickup = @"/newPickup";
NSString *const kGetPickupInfo = @"/getPickupInfo";
NSString *const kCancelPickup = @"/cancelPickup";


+ (BOOL)newPickup:(int)phoneNumber withLocation:(CGPoint)location withSender:(MainViewController *)sender {
    NSURL *aUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kBaseServer, kNewPickup]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:aUrl
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:30.0];
    
    [request setHTTPMethod:@"POST"];
    NSString *postString = [NSString stringWithFormat:@"phoneNumber=%d&latitude=%f&longitude=%f", phoneNumber, location.x, location.y];
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSError * __block sharedError = nil;
    NSData * __block sharedData = nil;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                    sharedError = error;
                                                    sharedData = data;
                                                    dispatch_semaphore_signal(semaphore);
                                                }];
    [dataTask resume];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    if (sharedError != nil) {
        NSLog(@"%@", sharedError);
        return NO;
    }
    
    if (sharedData == nil) {
        NSLog(@"No data returned.");
        return NO;
    }
    
    NSError *parseError = nil;
    NSDictionary *output = [NSJSONSerialization JSONObjectWithData:sharedData options:0 error:&parseError];
    if (![output isKindOfClass:[NSDictionary class]]) {
        NSLog(@"Returned data not a JSON dict at root. %@", output);
        return NO;
    }
    
    if (![[output allKeys] containsObject:@"status"]) {
        NSLog(@"No status key in returned data. %@", output);
        return NO;
    }
    
    if ([[output objectForKey:@"status"] intValue] == 1)
        return YES;
    
    return NO;
}

+ (int)getPickupInfo:(int)phoneNumber withLocation:(CGPoint)location withSender:(MainViewController *)sender{
    /*
    NSURL *aUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",baseServer, newPickup]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:aUrl
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:30.0];
    
    [request setHTTPMethod:@"POST"];
    NSString *postString = [NSString stringWithFormat:@"%@%@?phoneNumber=%d",baseServer, newPickup, phoneNumber];
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLConnection *connection= [[NSURLConnection alloc] initWithRequest:request
                                                                 delegate:self];
    
    return true;
     */
    
    NSURL *aUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kBaseServer, kGetPickupInfo]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:aUrl
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:30.0];
    
    [request setHTTPMethod:@"POST"];
    NSString *postString = [NSString stringWithFormat:@"phoneNumber=%d&latitude=%f&longitude=%f", phoneNumber, location.x, location.y];
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSError * __block sharedError = nil;
    NSData * __block sharedData = nil;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                    sharedError = error;
                                                    sharedData = data;
                                                    dispatch_semaphore_signal(semaphore);
                                                }];
    [dataTask resume];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    if (sharedError != nil) {
        NSLog(@"%@", sharedError);
        return -1;
    }
    
    if (sharedData == nil) {
        NSLog(@"No data returned.");
        return -1;
    }
    
    NSError *parseError = nil;
    NSDictionary *output = [NSJSONSerialization JSONObjectWithData:sharedData options:0 error:&parseError];
    if (![output isKindOfClass:[NSDictionary class]]) {
        NSLog(@"Returned data not a JSON dict at root. %@", output);
        return -1;
    }
    
    if (![[output allKeys] containsObject:@"status"]) {
        NSLog(@"No status key in returned data. %@", output);
        return -1;
    }
    
    return [[output objectForKey:@"status"] intValue];
}

+ (BOOL)cancelPickup:(int)phoneNumber withSender:(MainViewController *)sender {
    NSURL *aUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kBaseServer, kCancelPickup]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:aUrl
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:30.0];
    
    [request setHTTPMethod:@"POST"];
    NSString *postString = [NSString stringWithFormat:@"phoneNumber=%d", phoneNumber];
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSError *sharedError = nil;
    void (^copyError)(NSError *errorRef, NSError *newErrorRef) = ^void(NSError *errorRef, NSError *newErrorRef) {
        errorRef = newErrorRef;
    };
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                    copyError(sharedError, error);
                                                    dispatch_semaphore_signal(semaphore);
                                                }];
    [dataTask resume];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    if (sharedError != nil) {
        NSLog(@"%@", sharedError);
        return NO;
    }
    return YES;

}

@end
