//
//  ShipmateNetwork.m
//  Shipmate
//
//  Created by Anson Liu on 1/9/16.
//  Copyright © 2016 Anson Liu. All rights reserved.
//

#import "ShipmateNetwork.h"

@implementation ShipmateNetwork 

NSString *const kBaseServer = @"https://navy-shipmate.herokuapp.com";
NSString *const kNewPickup = @"/newPickup";
NSString *const kGetPickupInfo = @"/getPickupInfo";
NSString *const kCancelPickup = @"/cancelPickup";
NSString *const kGetVanLocations = @"/getVanLocations";


+ (BOOL)newPickup:(NSString *)phoneNumber withLocation:(CGPoint)location withSender:(MainViewController *)sender {
    NSURL *aUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kBaseServer, kNewPickup]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:aUrl
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:15.0];
    
    [request setHTTPMethod:@"POST"];
    NSString *postString = [NSString stringWithFormat:@"phoneNumber=%@&latitude=%f&longitude=%f&phrase=%@", phoneNumber, location.x, location.y, [[[UIDevice currentDevice] identifierForVendor] UUIDString]];
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

+ (int)getPickupInfo:(NSString *)phoneNumber withLocation:(CGPoint)location withSender:(MainViewController *)sender{
    NSURL *aUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kBaseServer, kGetPickupInfo]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:aUrl
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:15.0];
    
    [request setHTTPMethod:@"POST"];
    NSString *postString = [NSString stringWithFormat:@"phoneNumber=%@&latitude=%f&longitude=%f&phrase=%@", phoneNumber, location.x, location.y, [[[UIDevice currentDevice] identifierForVendor] UUIDString]];
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

+ (BOOL)cancelPickup:(NSString *)phoneNumber withSender:(MainViewController *)sender {
    NSURL *aUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kBaseServer, kCancelPickup]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:aUrl
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:15.0];
    
    [request setHTTPMethod:@"POST"];
    NSString *postString = [NSString stringWithFormat:@"phoneNumber=%@&phrase=%@", phoneNumber, [[[UIDevice currentDevice] identifierForVendor] UUIDString]];
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
    
    if ([[output objectForKey:@"status"] intValue] != 0) {
        return NO;
    }
    
    return YES;
}

+ (NSArray *)getVanLocations {
    NSURL *aUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kBaseServer, kGetVanLocations]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:aUrl
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:5.0];
    
    [request setHTTPMethod:@"GET"];
    
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
        return nil;
    }
    
    if (sharedData == nil) {
        NSLog(@"No data returned.");
        return nil;
    }
    
    NSError *parseError = nil;
    NSArray *output = [NSJSONSerialization JSONObjectWithData:sharedData options:0 error:&parseError];
    if (![output isKindOfClass:[NSArray class]]) {
        NSLog(@"Returned data not a JSON array at root. %@", output);
        return nil;
    }
    
    NSMutableArray *mutableOutput = [[NSMutableArray alloc] initWithArray:output];
    
    for (int i = 0; i < [mutableOutput count]; i++) {
        if (![mutableOutput[i] isKindOfClass:[NSDictionary class]])
            return nil;
        if (![[mutableOutput[i] allKeys] containsObject:@"latitude"] || ![[mutableOutput[i] allKeys] containsObject:@"longitude"])
            return nil;
        if ([[mutableOutput[i] objectForKey:@"latitude"] doubleValue] == 0 && [[mutableOutput[i] objectForKey:@"longitude"] doubleValue] == 0) {
            [mutableOutput removeObjectAtIndex:i];
            i--;
        }
    }
    return output;
}

@end
