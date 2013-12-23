//
// This file is part of Rebelle
//
// Created by JC on 11/27/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

@protocol RBHandler;

#import "RBThenable.h"

// This just re-declare RBThenable with a covariant return type
typedef id<RBHandler>(^RBHandlerThen)(RBPromiseFulfilled onFulfilled, RBPromiseRejected onRejected);

typedef id<RBHandler>(^RBHandlerCatched)(Class exceptionCatchClass, RBPromiseRejected catchAction);
typedef id<RBHandler>(^RBHandlerOnSuccess)(RBPromiseFulfilled onFulfilled);
typedef id<RBHandler>(^RBHandlerReady)(void);
typedef id<RBHandler>(^RBHandlerNext)(void);

/**
 * Define an API providing callback entry points
 * 
 * Each callback can be defined separately from each other. But no one should be called as long as
 * the RBHandler object is not marked as ready to do so
 *
 * Protocol also provide easy way to chain objets responding to it
 */
@protocol RBHandler <RBThenable>

@property(nonatomic, copy, readonly)RBThenableThen          then;

/// Should mark the RBHandler object as ready to call callbacks if required
/// Until this method is called no callbacks should be callable
@property(nonatomic, copy, readonly)RBHandlerReady          ready;

/// Should return a new RBHandler compatible object
/// This method should also automatically mark current object as ready
@property(nonatomic, copy, readonly)RBHandlerNext           next;

/// Should represent a success block callback
@property(nonatomic, copy, readonly)RBHandlerOnSuccess      onSuccess;

/**
 * Define a new action to execute when promise has been rejected
 *
 * Its behaviour should be mostly similar to @catch:
 * - You can call multiple times ::onCatch
 * _ If ::onCatch was already called with exceptionCatchClass, any subsequent calls with the same value should be ignored
 * - On rejection matching should be the same as @catch, meaning that only the 1st exceptionCatchClass which match received one is executed
 * (all others are ignored)
 *
 * @param RBHandlerCatched the block to call. 1st argument must be an Exception class to condition RBPromiseRejected
 * block execution
 */
@property(nonatomic, copy, readonly)RBHandlerCatched        onCatch;

@end
