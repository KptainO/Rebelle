//
// This file is part of Rebelle
//
// Created by JC on 11/27/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

@protocol RBActionable;

#import "RBThenable.h"

typedef id<RBActionable>(^RBActionableCatched)(Class exceptionCatchClass, RBPromiseRejected catchAction);
typedef id<RBActionable>(^RBActionableOnSuccess)(RBPromiseFulfilled onFulfilled);

/**
 * Define a chainable API allowing user to define callback actions
 * Unlike RBThenable the idea here is to be able to define each action separately
 */
@protocol RBActionable <NSObject>

@property(nonatomic, copy, readonly)RBActionableOnSuccess   onSuccess;

/**
 * Define a new action to execute when promise has been rejected
 *
 * Its behaviour should be mostly similar to @catch:
 * - You can call multiple times ::onCatch
 * _ If ::onCatch was already called with exceptionCatchClass, any subsequent calls with the same value should be ignored
 * - On rejection matching should be the same as @catch, meaning that only the 1st exceptionCatchClass which match received one is executed
 * (all others are ignored)
 *
 * @param RBActionableCatched the block to call. 1st argument must be an Exception class to condition RBPromiseRejected
 * block execution
 */
@property(nonatomic, copy, readonly)RBActionableCatched  onCatch;

@end
