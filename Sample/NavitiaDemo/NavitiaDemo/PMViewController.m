//
//  PMViewController.m
//  NavitiaDemo
//
//  Created by Pierre de La Morinerie on 24/10/2013.
//  Copyright (c) 2013 Pierre de La Morinerie. All rights reserved.
//

#import "PMViewController.h"
#import "PMNavitiaClient.h"

@interface PMViewController () <UITextFieldDelegate>
@end

@implementation PMViewController
{
    IBOutlet UITextField             * _queryTextField;
    IBOutlet UISwitch                * _usePromisesSwitch;
    IBOutlet UITextView              * _resultsTextView;
    IBOutlet PMNavitiaClient         * _navitiaClient;
    IBOutlet UIActivityIndicatorView * _activityIndicator;
}

- (IBAction) textFieldValueDidChange:(id)sender
{
    SEL searchSelector = ([_usePromisesSwitch isOn] ? @selector(searchPlacesPromise) : @selector(searchPlacesCallback));
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:searchSelector object:nil];
    [self performSelector:searchSelector withObject:nil afterDelay:0.2];
}

- (void) searchPlacesCallback
{
    if ([self isSearching])
        return;
    
    [self setSearching:YES];
    
    [_navitiaClient placesForQuery:_queryTextField.text completion:^(NSArray *places, NSError *error) {
        
        if (places) {
            NSArray * placesNames = [places valueForKey:@"name"];
            _resultsTextView.text = [placesNames componentsJoinedByString:@"\n"];
        } else {
            [self presentError:error];
        }
        
        [self setSearching:NO];
    }];
}

- (void) searchPlacesPromise
{
    if ([self isSearching])
        return;
    
    [self setSearching:YES];
    
    [_navitiaClient placesForQuery:_queryTextField.text]
    .then( ^id(NSArray * places) {
        NSArray * placesNames = [places valueForKey:@"name"];
        _resultsTextView.text = [placesNames componentsJoinedByString:@"\n"];
        [self setSearching:NO];
        return nil;
        
    }, ^id(RBErrorException * e) {
        [self presentError:e.error];
        [self setSearching:NO];
        return nil;
    });
}

#pragma mark Helpers

- (BOOL) isSearching
{
    return [_activityIndicator isAnimating];
}

- (void) setSearching:(BOOL)searching
{
    if (searching)
        [_activityIndicator startAnimating];
    else
        [_activityIndicator stopAnimating];
}

- (void) presentError:(NSError*)error
{
    [[[UIAlertView alloc] initWithTitle:error.localizedDescription
                                message:error.localizedFailureReason
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil]
     show];
}

@end
