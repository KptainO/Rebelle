//
// This file is part of Rebelle
//
// Created by JC on 11/27/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "RBHandler.h"

/**
 * Store a set of related actions
 * It *NEVER* return a nil block but always a wrapper one if no one was defined by user
 */
@interface RBActionSet : NSObject

/**
 * Define success action
 * When calling getter, if no block is defined it return one returning passed argument
 */
@property(nonatomic, copy)RBPromiseFulfilled                succeeded;

/**
 * When called if no block is defined OR none is found for passed exception, then the exception
 * is returned into a wrapped block
 * Use ::setCatched:do: to set one or more catch/exception blocks
 */
@property(nonatomic, copy, readonly)RBPromiseRejected       catched;

- (void)setCatched:(Class)exceptionCatchClass do:(RBPromiseRejected)action;

@end

// Contain all selectors that are considered as protected
// **MUST** not be used by others
@interface RBActionSet (Protected)
- (RBPromiseRejected)_actionForException:(NSException *)exception;
@end