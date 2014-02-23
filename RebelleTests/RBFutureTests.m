//
// This file is part of Rebelle
//
// Created by JC on 12/6/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import <Kiwi.h>

#import "RBFuture.h"

SPEC_BEGIN(RBFutureTests)

describe(@"test", ^{
   __block RBFuture *future;

   beforeEach(^{
      future = [RBFuture new];
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

      it(@"with RBFuture pending, then re-call resolve:", ^{
         RBFuture *resolver2 = [RBFuture new];

         [future resolve:resolver2];
         [[theValue(future.state) should] equal:theValue(RBFutureStatePending)];

         // Try to re-resolve future
         [future resolve:@"OK"];
         [[theValue(future.state) should] equal:theValue(RBFutureStatePending)];
         [future.result shouldBeNil];
      });

      it(@"with RBFuture pending, then fulfilled", ^{
         RBFuture *resolver2 = [RBFuture mock];

         [resolver2 stub:@selector(state) andReturn:theValue(RBFutureStatePending)];
         [future resolve:resolver2];

         [[resolver2 should] receive:@selector(state) andReturn:theValue(RBFutureStateFulfilled)];
         [[resolver2 should] receive:@selector(result) andReturn:@"Hello Resolved"];

         // Manually trigger notification about resolver2 being fulfilled
         [future observeValueForKeyPath:RBFuturePropertyState
                                ofObject:resolver2
                                  change:nil
                                 context:(__bridge void *)(RBFuturePropertyState)];
      });

      it(@"with RBFuture already fulfilled", ^{
         RBFuture *resolver2 = [RBFuture new];

         [[resolver2 should] receive:@selector(state) andReturn:theValue(RBFutureStateFulfilled)];
         [[resolver2 should] receive:@selector(result) andReturn:@"Hello World"];

         [future resolve:resolver2];
      });

      it(@"with self throw an exception", ^{
         [[theBlock(^{ [future resolve:future]; }) should] raiseWithName:NSInvalidArgumentException];
      });
   });
});

SPEC_END