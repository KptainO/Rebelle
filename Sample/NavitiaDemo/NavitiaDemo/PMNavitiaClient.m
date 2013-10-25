//
//  PMNavitiaClient.m
//  NavitiaDemo
//
//  Created by Pierre de La Morinerie on 24/10/2013.
//  Copyright (c) 2013 Pierre de La Morinerie. All rights reserved.
//

#import "PMNavitiaClient.h"

@implementation PMNavitiaClient
{
    NSURLSession * _session;
}

- (NSURLSession*)session
{
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                 delegate:nil
                                            delegateQueue:[NSOperationQueue currentQueue]];
    }
    return _session;
}

- (void) placesForQuery:(NSString *)query completion:(void (^)(NSArray *, NSError *))completionBlock
{
    NSString * apiURL = [@"http://api.navitia.io/v0/paris/places.json?q=" stringByAppendingString:query];
    
    NSURLSessionTask * task =
    [self.session dataTaskWithURL:[NSURL URLWithString:apiURL]
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
     {
         if (!error) {
             NSError * jsonError;
             NSDictionary * jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
             
             if (jsonResponse) {
                 NSArray * places = jsonResponse[@"places"];
                 
                 if (places) {
                     completionBlock(places, nil);
                 } else {
                     NSError * noPlaces = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:nil];
                     completionBlock(nil, noPlaces);
                 }
             
             } else {
                 completionBlock(nil, jsonError);
             }
         
         } else {
             completionBlock(nil, error);
         }
     }];
    
    [task resume];
}

- (RBPromise*) placesForQuery:(NSString *)query
{
    NSString * apiURL = [@"http://api.navitia.io/v0/paris/places.json?q=" stringByAppendingString:query];
    RBPromise * promise = [RBPromise new];
    
    NSURLSessionTask * task =
    [self.session dataTaskWithURL:[NSURL URLWithString:apiURL]
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
     {
         [promise resolve:(error ?: data)];
     }];
    
    [task resume];
    
    return promise.then( ^(NSData * data) {
        NSError * jsonError;
        NSDictionary * jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        return jsonResponse ?: jsonError;
    }, nil)
    
    .then( ^(NSDictionary * jsonResponse) {
        NSError * noPlacesError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:nil];
        return jsonResponse[@"places"] ?: noPlacesError;
    }, nil);
}

@end
