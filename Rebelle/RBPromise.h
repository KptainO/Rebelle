//
// This file is part of Rebelle
//  
//  Created by JC on 8/10/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import <Foundation/Foundation.h>

#import "RBThenable.h"
#import "RBActionable.h"

@class RBPromise;

// This just re-declare RBThenable with a covariant return type
typedef RBPromise *(^RBPromiseThenableThen)(RBPromiseFulfilled onFulfilled, RBPromiseRejected onRejected);

@class RBResolver;
@class RBExecuter;

extern NSString *const RBPromisePropertyResolved;

typedef enum {
   RBPromiseStatePending,
   RBPromiseStateFulfilled,
   RBPromiseStateRejected,
   RBPromiseStateAborted,
} RBPromiseState;

typedef enum RBPromiseResolveState : NSUInteger {
   /// Promise is in configuration mode so any resolve call will not perform the resolve chaining
   RBPromiseResolveStateNotReady,
   /// Promise is ready to do the resolve chaining
   RBPromiseResolveStateReady,
   /// Promise has been resolved. Which also mean it has a valid result value (and thus a valid state)
   RBPromiseResolveStateResolved
} RBPromiseResolveState;

/**
 * Thenable promise
 * - Call "then" if you want to define actions to occur once promise has been resolved
 * - Call ::resolve: to start promise resolving procedure.
 *
 * You can chain calls to then to define multiple promises which must occur after the previous
 * one was realized.
 * \code promise.then(loadUserBlock, nil).then(loadUserLastTweetsBlock, nil) etc. \endcode
 *
 * Promise resolving depend on value type argument:
 * - Any NSExceptions/NSError whill be treated as a promise rejection. Note that NSError objects will be wrapped
 * into a RBErrorException when passed to callback blocks
 * - Any RBPromise will be 1st resolved, then its result will be used as the value argument
 * - Any other value will be considered as a promise fulfillment
 * Once value is determined, it is passed to the fulfill/reject block whose result value is then
 * passed to all promises created by calling "then". If fulfill/reject do not return any value then
 * the one used when calling ::resolve: will be used instead
 *
 * For more information about how a promise work/what it does, check Promises/A+ documentation
 * https://github.com/promises-aplus/promises-spec
 */
@interface RBPromise : NSObject<RBThenable, RBActionable>

@property(nonatomic, copy, readonly)RBPromiseThenableThen then;

/// the promise (result) state
/// - Pending, resolve has not yet happened or nothing started inside it
/// - Fulfilled, promise was fulfilled, internal resolve process (resolveState) may still need to happen
/// - Rejected, promise was fulfilled, internal resolve process (resolveState) may still need to happen
@property(nonatomic, assign, readonly)RBPromiseState  state;

/// The overall promise resolution state which encompass the result state
/// Exposed as an attribute so that KVO can be done on it
/// @see RBPromiseResolveState to have more information about each enum value
@property(nonatomic, assign, readonly)RBPromiseResolveState resolveState;

@property(nonatomic, copy, readonly)RBActionableOnSuccess   onSuccess;
@property(nonatomic, copy, readonly)RBActionableCatched     onCatch;
@property(nonatomic, copy, readonly)RBActionableReady          ready;

/**
 * @brief Abort all chained promises to current one
 *
 * Leave current promise intact but abort all chained ones
 */
- (void)cancel;

/**
 * @brief Completely stop resolve process of this promise and its chained ones 
 *
 * It merely work like ::cancel expect that the current promise is also canceled and set its state
 * to RBPromiseStateAborted
 * Note though that if promise was already fulfilled/rejected prior to ::abort call state won't
 * be changed and only chained promises will be aborted
 *
 */
- (void)abort;

@end

/// Contain all selectors that are considered as protected
/// **MUST** not be used by others
@interface RBPromise (Protected)

- (RBResolver *)resolver_;
- (RBExecuter *)executer_;

@end
