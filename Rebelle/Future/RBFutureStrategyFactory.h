//
// This file is part of Rebelle
//  
// Created by JC on 3/21/14.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

@protocol RBFutureStrategy;

@interface RBFutureStrategyFactory : NSObject

- (id)init UNAVAILABLE_ATTRIBUTE;
+ (id)new UNAVAILABLE_ATTRIBUTE;

+ (id<RBFutureStrategy>)create:(id)value;

@end


// Contain all selectors that are considered as protected
// **MUST** not be used by others
@interface RBFutureStrategyFactory (Protected)
@end
