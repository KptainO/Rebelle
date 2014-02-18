//
// This file is part of Rebelle
//  
// Created by JC on 12/6/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

extern NSString *const RBFuturePropertyState;

typedef enum RBFutureState : NSUInteger {
   RBFutureStatePending,
   RBFutureStateFulfilled,
   RBFutureStateRejected,
} RBFutureState;

/**
 * A RBFuture represents a future value, that is a value not yet computed but which will be
 * in a (not so far) future
 *
 * Two cases may happen:
 * - Everything go right, in this case state is Fulfilled and result contain the retrieved value
 * - An error occured, in this case state is Rejected and result contain the error object (NSError or NSException)
 */
@interface RBFuture : NSObject

@property(nonatomic, assign, readonly)RBFutureState    state;
@property(nonatomic, strong, readonly)id                 result;

- (void)resolve:(id)value;

@end


// Contain all selectors that are considered as protected
// **MUST** not be used by others
@interface RBFuture (Protected)
@end
