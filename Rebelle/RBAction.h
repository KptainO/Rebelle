//
// This file is part of Rebelle
//
// Created by JC on 11/27/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "RBActionable.h"

@interface RBAction : NSObject

@property(nonatomic, copy)RBPromiseFulfilled      succeeded;
@property(nonatomic, copy)RBPromiseRejected       catched;

- (void)setOnCatch:(Class)exceptionCatchClass do:(RBPromiseRejected)action;

@end

// Contain all selectors that are considered as protected
// **MUST** not be used by others
@interface RBAction (Protected)
- (RBPromiseRejected)_actionForException:(NSException *)exception;
@end