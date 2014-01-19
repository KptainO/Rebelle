//
// This file is part of Rebelle
//
// Created by JC on 11/27/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

@protocol RBThenablePlus;

#import "RBThenable.h"

// This just re-declare RBThenable with a covariant return type
typedef id<RBThenablePlus>(^RBThenablePlusThen)(RBPromiseFulfilled onFulfilled, RBPromiseRejected onRejected);

typedef id<RBThenablePlus>(^RBThenablePlusCatched)(Class exceptionCatchClass, RBPromiseRejected catchAction);
typedef id<RBThenablePlus>(^RBThenablePlusOnSuccess)(RBPromiseFulfilled onFulfilled);
typedef id<RBThenablePlus>(^RBThenablePlusReady)(void);
typedef id<RBThenablePlus>(^RBThenablePlusNext)(void);

/**
 * API providing separated callbacks for promise resolution cases
 * 
 * Each callback can be defined separately from each other. But no one should be called as long as
 * the RBThenablePlus object is not marked as ready to do so
 *
 * Protocol also provide easy way to chain objets
 */
@protocol RBThenablePlus <RBThenable>

@property(nonatomic, copy, readonly)RBThenablePlusThen            then;

/// Should mark the RBThenablePlus object as ready to call callbacks if required
/// Until this method is called no callbacks should be callable
@property(nonatomic, copy, readonly)RBThenablePlusReady          ready;

/// Should return a new RBThenablePlus compatible object
/// This method should also automatically mark current object as ready
@property(nonatomic, copy, readonly)RBThenablePlusNext           next;

/// Should represent a success block callback
@property(nonatomic, copy, readonly)RBThenablePlusOnSuccess      onSuccess;

/**
 * Define a new action to execute when promise has been rejected
 *
 * Its behaviour should be mostly similar to @catch:
 * - You can call multiple times ::onCatch
 * _ If ::onCatch was already called with exceptionCatchClass, any subsequent calls with the same value should be ignored
 * - On rejection matching should be the same as @catch, meaning that only the 1st exceptionCatchClass which match received one is executed
 * (all others are ignored)
 *
 * @param RBThenablePlusCatched the block to call. 1st argument must be an Exception class to condition RBPromiseRejected
 * block execution
 */
@property(nonatomic, copy, readonly)RBThenablePlusCatched        onCatch;

@end
