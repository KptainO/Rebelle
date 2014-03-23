//
// This file is part of Rebelle
//
// Created by JC on 12/6/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import <Kiwi.h>

#import "RBFuture.h"
#import "RBFutureStrategyFactory.h"
#import "RBFutureStrategy.h"

SPEC_BEGIN(RBFutureTests)

describe(@"test", ^{
   __block RBFuture *future;

   beforeEach(^{
      future = [RBFuture new];

      // Always return no strategy
      [RBFutureStrategyFactory stub:@selector(create:) andReturn:nil];
   });

   describe(@"resolve", ^{
      it(@"simple FULFILLED", ^{
         [future resolve:@"OK"];

         [[theValue(future.state) should] equal:theValue(RBFutureStateFulfilled)];
      });

      it(@"simple REJECTED", ^{
         [future resolve:[NSException exceptionWithName:@"" reason:nil userInfo:nil]];

         [[theValue(future.state) should] equal:theValue(RBFutureStateRejected)];
      });

      it(@"simple REJECTED with NSError", ^{
         [future resolve:[NSError nullMock]];

         [[theValue(future.state) should] equal:theValue(RBFutureStateRejected)];
      });

      it(@"only once even if called x times", ^{
         [future resolve:@"OK"];
         [future resolve:[NSException exceptionWithName:@"" reason:nil userInfo:nil]];

         [[theValue(future.state) should] equal:theValue(RBFutureStateFulfilled)];
      });

      it(@"with strategy pending, then re-call resolve:", ^{
         [RBFutureStrategyFactory stub:@selector(create:) andReturn:[KWMock nullMockForProtocol:@protocol(RBFutureStrategy)]];

         [future resolve:@"Hello World"];
         [[theValue(future.state) should] equal:theValue(RBFutureStatePending)];

         // Try to re-resolve future
         [future resolve:@"OK"];
         [[theValue(future.state) should] equal:theValue(RBFutureStatePending)];
         [future.result shouldBeNil];
      });

      it(@"with strategy notifying computation", ^{
         id<RBFutureStrategy> strategy = [KWMock nullMockForProtocol:@protocol(RBFutureStrategy)];

         [RBFutureStrategyFactory stub:@selector(create:) andReturn:strategy];
         [future resolve:@"Hello World"];
         // Need to re-stub selector so that next call to it by RBFuture does not interfer
         [RBFutureStrategyFactory stub:@selector(create:) andReturn:nil];

         [[NSNotificationCenter defaultCenter] postNotificationName:@"RBComputationDoneNotification"
                                                             object:strategy
                                                           userInfo:@{ @"result" : @"World Hello" }];

         [[future.result should] equal:@"World Hello"];
      });

      it(@"with self throw an exception", ^{
         [[theBlock(^{ [future resolve:future]; }) should] raiseWithName:NSInvalidArgumentException];
      });
   });
});

SPEC_END