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
#import "RBFutureArray.h"

SPEC_BEGIN(RBFutureStrategyFutureTests)

describe(@"test", ^{
   __block RBFutureStrategyFuture *strategy;
   NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

   beforeEach(^{
      strategy = [RBFutureStrategyFuture new];
   });

   describe(@"compute single RBFuture", ^{
      __block RBFuture *future;

      beforeEach(^{
         future = [RBFuture mock];
      });

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

   describe(@"compute array of futures", ^{
      __block RBFuture *f1;
      __block RBFuture *f2;
      __block KWCaptureSpy *userInfo;

      beforeEach(^{
         f1 = [RBFuture mock];
         f2 = [RBFuture mock];
         userInfo = [notificationCenter captureArgument:@selector(postNotificationName:object:userInfo:) atIndex:2];
      });

      it(@"fulfilled", ^{
         [f1 stub:@selector(state) andReturn:theValue(RBFutureStateFulfilled)];
         [f1 stub:@selector(result) andReturn:@"Hello"];
         [f2 stub:@selector(state) andReturn:theValue(RBFutureStateFulfilled)];
         [f2 stub:@selector(result) andReturn:@"World"];

         [strategy compute:[RBFutureArray arrayWithFutures:f1,f2,nil]];

         [[userInfo.argument should] equal:@{ @"result": @[@"Hello", @"World"] }];
      });

      it(@"with one rejected", ^{
         [f1 stub:@selector(state) andReturn:theValue(RBFutureStateFulfilled)];
         [f1 stub:@selector(result) andReturn:@"Hello"];
         [f2 stub:@selector(state) andReturn:theValue(RBFutureStateRejected)];
         [f2 stub:@selector(result) andReturn:@"NSException"];

         [strategy compute:[RBFutureArray arrayWithFutures:f1,f2,nil]];

         [[userInfo.argument should] equal:@{ @"result": @"NSException" }];
      });

      it(@"with one pending", ^{
         [f1 stub:@selector(state) andReturn:theValue(RBFutureStateFulfilled)];
         [f1 stub:@selector(result) andReturn:@"Hello"];
         [f2 stub:@selector(state) andReturn:theValue(RBFutureStatePending)];
         [f2 stub:@selector(result) andReturn:@"World"];

         [strategy compute:[RBFutureArray arrayWithFutures:f1,f2,nil]];

         [f2 stub:@selector(state) andReturn:theValue(RBFutureStateFulfilled)];
         [strategy observeValueForKeyPath:RBFuturePropertyState
                                 ofObject:f2
                                   change:nil
                                  context:(__bridge void *)(RBFuturePropertyState)];

         [[userInfo.argument should] equal:@{ @"result": @[@"Hello", @"World"] }];
      });
   });
});

SPEC_END

