//
// This file is part of Rebelle
//  
// Created by JC on 3/23/14.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import <Kiwi.h>

#import "RBFutureStrategyFuture.h"
#import "RBFuture.h"

SPEC_BEGIN(RBFutureStrategyFutureTests)

describe(@"test", ^{
   __block RBFutureStrategyFuture *strategy;
   __block RBFuture *future;
   NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

   beforeEach(^{
      strategy = [RBFutureStrategyFuture new];
      future = [RBFuture mock];
   });

   describe(@"compute", ^{
      it(@"with RBFuture pending, then fulfilled", ^{
         [future stub:@selector(state) andReturn:theValue(RBFutureStatePending)];
         [future stub:@selector(result) andReturn:@"Hello World"];

         [[notificationCenter should] receive:@selector(postNotificationName:object:userInfo:)
                                withArguments:@"RBComputationDoneNotification", strategy, @{ @"result": @"Hello World" }];

         [strategy compute:future];

         [[future should] receive:@selector(state) andReturn:theValue(RBFutureStateFulfilled) withCountAtLeast:1];

         [strategy observeValueForKeyPath:RBFuturePropertyState
                                 ofObject:future
                                   change:nil
                                  context:(__bridge void *)(RBFuturePropertyState)];
      });

      it(@"with RBFuture already fulfilled", ^{
         [[future should] receive:@selector(state) andReturn:theValue(RBFutureStateFulfilled) withCountAtLeast:1];
         [[future should] receive:@selector(result) andReturn:@"Hello World"];

         [[notificationCenter should] receive:@selector(postNotificationName:object:userInfo:)
                            withArguments:@"RBComputationDoneNotification", strategy, @{ @"result": @"Hello World" }];

         [strategy compute:future];
      });

      it(@"with result NIL", ^{
         [[future should] receive:@selector(state) andReturn:theValue(RBFutureStateFulfilled) withCountAtLeast:1];
         [[future should] receive:@selector(result) andReturn:nil];

         [[notificationCenter should] receive:@selector(postNotificationName:object:userInfo:)
                            withArguments:@"RBComputationDoneNotification", strategy, @{ @"result": [NSNull null] }];

         [strategy compute:future];
      });
   });
});

SPEC_END

