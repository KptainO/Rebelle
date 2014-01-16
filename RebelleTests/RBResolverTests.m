//
// This file is part of Rebelle
//
// Created by JC on 12/6/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import <Kiwi.h>

#import "RBResolver.h"

SPEC_BEGIN(RBResolverTests)

describe(@"test", ^{
   __block RBResolver *resolver;

   beforeEach(^{
      resolver = [RBResolver new];
   });

   describe(@"resolve", ^{
      it(@"simple FULFILLED", ^{
         [resolver resolve:@"OK"];

         [[theValue(resolver.state) should] equal:theValue(RBResolverStateFulfilled)];
      });

      it(@"simple REJECTED", ^{
         [resolver resolve:[NSException exceptionWithName:@"" reason:nil userInfo:nil]];

         [[theValue(resolver.state) should] equal:theValue(RBResolverStateRejected)];
      });

      it(@"simple REJECTED with NSError", ^{
         [resolver resolve:[NSError nullMock]];

         [[theValue(resolver.state) should] equal:theValue(RBResolverStateRejected)];
      });

      it(@"only once even if called x times", ^{
         [resolver resolve:@"OK"];
         [resolver resolve:[NSException exceptionWithName:@"" reason:nil userInfo:nil]];

         [[theValue(resolver.state) should] equal:theValue(RBResolverStateFulfilled)];
      });

      it(@"with RBResolver pending, then re-call resolve:", ^{
         RBResolver *resolver2 = [RBResolver new];

         [resolver resolve:resolver2];
         [[theValue(resolver.state) should] equal:theValue(RBResolverStatePending)];

         // Try to re-resolve resolver
         [resolver resolve:@"OK"];
         [[theValue(resolver.state) should] equal:theValue(RBResolverStatePending)];
         [[resolver.result should] equal:resolver2];
      });

      it(@"with RBResolver pending, then fulfilled", ^{
         RBResolver *resolver2 = [RBResolver mock];

         [resolver2 stub:@selector(state) andReturn:theValue(RBResolverStatePending)];
         [resolver resolve:resolver2];

         [[resolver2 should] receive:@selector(state) andReturn:theValue(RBResolverStateFulfilled)];
         [[resolver2 should] receive:@selector(result) andReturn:@"Hello Resolved"];

         // Manually trigger notification about resolver2 being fulfilled
         [resolver observeValueForKeyPath:RBResolverPropertyState
                                ofObject:resolver2
                                  change:nil
                                 context:(__bridge void *)(RBResolverPropertyState)];
      });

      it(@"with RBResolver already fulfilled", ^{
         RBResolver *resolver2 = [RBResolver new];

         [[resolver2 should] receive:@selector(state) andReturn:theValue(RBResolverStateFulfilled)];
         [[resolver2 should] receive:@selector(result) andReturn:@"Hello World"];

         [resolver resolve:resolver2];
      });

      it(@"with self throw an exception", ^{
         [[theBlock(^{ [resolver resolve:resolver]; }) should] raiseWithName:NSInvalidArgumentException];
      });
   });
});

SPEC_END