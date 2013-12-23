//
// This file is part of Rebelle
//  
//  Created by JC on 8/10/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import <Foundation/Foundation.h>

#import "RBHandler.h"

@class RBPromise;

@class RBResolver;
@class RBExecuter;

extern NSString *const RBPromisePropertyResolved;

typedef enum {
   RBPromiseStatePending,
   RBPromiseStateFulfilled,
   RBPromiseStateRejected,
   RBPromiseStateAborted,
} RBPromiseState;

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
@interface RBPromise : NSObject<RBHandler>

@property(nonatomic, copy, readonly)RBHandlerThen     then;

/// the promise (result) state
/// - Pending, resolve has not yet happened or nothing started inside it
/// - Fulfilled, promise was fulfilled, but callbacks may not have happened yet
/// - Rejected, promise was fulfilled, but callbacks may not have happened yet
@property(nonatomic, assign, readonly)RBPromiseState  state;

@property(nonatomic, assign, readonly)BOOL isResolved;

@property(nonatomic, copy, readonly)RBHandlerOnSuccess      onSuccess;
@property(nonatomic, copy, readonly)RBHandlerCatched        onCatch;
@property(nonatomic, copy, readonly)RBHandlerReady          ready;

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

- (void)resolve:(id)value;

@end

/// Contain all selectors that are considered as protected
/// **MUST** not be used by others
@interface RBPromise (Protected)

- (RBResolver *)resolver_;
- (RBExecuter *)executer_;

@end
