//
// This file is part of Rebelle
//  
// Created by JC on 3/21/14.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "RBFutureStrategyFactory.h"

#import "RBFutureStrategyFuture.h"

// Private API
@interface RBFutureStrategyFactory ()

@end

@implementation RBFutureStrategyFactory

#pragma mark - Ctor/Dtor

#pragma mark - Public methods

+ (id<RBFutureStrategy>)create:(id)value {
   if ([RBFutureStrategyFuture accept:value])
      return [RBFutureStrategyFuture new];

   return nil;
}

#pragma mark - Protected methods

#pragma mark - Private methods

@end
