//
//  PMNavitiaClient.h
//  NavitiaDemo
//
//  Created by Pierre de La Morinerie on 24/10/2013.
//  Copyright (c) 2013 Pierre de La Morinerie. All rights reserved.
//

#import <Rebelle/RBPromise.h>
#import <Rebelle/RBErrorException.h>

@interface PMNavitiaClient : NSObject

- (void) placesForQuery:(NSString*)query
             completion:(void (^)(NSArray * places, NSError * error))completionBlock;

- (RBPromise*) placesForQuery:(NSString*)query;

@end
