//
// This file is part of Rebelle
//  
// Created by JC on 3/24/14.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

@protocol RBFuture;

/**
 * Provide a typed NSArray of RBFuture
 * Allow RBFuture to differentiate a classical NSArray from a NSArray of RBFuture
 */
@interface RBFutureArray : NSObject<NSFastEnumeration>

+ (instancetype)arayWithFuture:(id<RBFuture>)future;
+ (instancetype)arrayWithFutures:(id<RBFuture>)firstObj,... NS_REQUIRES_NIL_TERMINATION;

- (instancetype)initWithArray:(NSArray *)anArray;
- (instancetype)initWithFutures:(id<RBFuture>)firstObj,... NS_REQUIRES_NIL_TERMINATION;

- (NSUInteger)count;

- (id<RBFuture>)firstObject;
- (id<RBFuture>)lastObject;
- (NSUInteger)indexOfObject:(id<RBFuture>)future;
- (id<RBFuture>)objectAtIndex:(NSUInteger)index;
- (id<RBFuture>)objectAtIndexedSubscript:(NSUInteger)idx;

@end


// Contain all selectors that are considered as protected
// **MUST** not be used by others
@interface RBFutureArray (Protected)
@end
