//
// This file is part of Rebelle
//  
// Created by JC on 12/6/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

extern NSString *const RBResolverPropertyState;

typedef enum RBResolverState : NSUInteger {
   RBResolverStatePending,
   RBResolverStateFulfilled,
   RBResolverStateRejected,
} RBResolverState;

@interface RBResolver : NSObject

@property(nonatomic, assign, readonly)RBResolverState    state;
@property(nonatomic, strong, readonly)id                 result;

- (void)resolve:(id)value;

@end


// Contain all selectors that are considered as protected
// **MUST** not be used by others
@interface RBResolver (Protected)
@end
