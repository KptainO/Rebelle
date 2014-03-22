//
// This file is part of Rebelle
//  
// Created by JC on 3/21/14.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "RBFutureStrategy.h"

@interface RBFutureStrategyFuture : NSObject<RBFutureStrategy>

+ (BOOL)accept:(id)value;
- (void)compute:(id)value;

@end


// Contain all selectors that are considered as protected
// **MUST** not be used by others
@interface RBFutureStrategyFuture (Protected)
@end
