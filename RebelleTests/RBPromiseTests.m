//
// This file is part of Rebelle
//
//  Created by JC on 8/10/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//
#import <SenTestingKit/SenTestingKit.h>
#import <Kiwi.h>

#import "RBPromise.h"
#import "RBExecuter.h"
#import "RBFuture.h"

SPEC_BEGIN(RBPromiseTests)

describe(@"test", ^ {
   __block RBPromise *promise;
   __block RBExecuter *promiseExecuter;
   __block RBFuture *promiseFuture;

   beforeEach(^ {
      promise = [RBPromise new];
      promiseExecuter = [RBExecuter nullMock];
      promiseFuture = [RBFuture nullMock];

      [promise stub:@selector(executer_) andReturn:promiseExecuter];
      [promise stub:@selector(future_) andReturn:promiseFuture];
   });

   afterEach(^{
      promiseExecuter = nil;
      promise = nil;
   });

   describe(@"next method", ^{
      it(@"simple call", ^{
         RBPromise *promise2 = promise.then(nil, nil);

         [[promise2 should] beKindOfClass:RBPromise.class];
      });

      it(@"chaining", ^{
         RBPromise *promise2 = promise.then(nil, nil);
         RBPromise *promise3 = promise2.then(nil, nil);

         [[promise3 should] beKindOfClass:RBPromise.class];
         [[[promise valueForKey:@"promises_"] should] contain:promise2];
         [[[promise2 valueForKey:@"promises_"] should] contain:promise3];
         [[[promise3 valueForKey:@"promises_"] should] beEmpty];
      });

      it(@"resolve next when current promise already resolved", ^{
         RBPromise *x = [RBPromise nullMock];

         // Stub current promise for test
         [RBPromise stub:@selector(new) andReturn:x];
         [promise stub:@selector(isResolved) andReturn:theValue(YES)];

         // Test expectations
         [[promiseExecuter should] receive:@selector(result) andReturn:@"Hello World"];
         [[x should] receive:@selector(resolve:) withArguments:@"Hello World"];

         promise.next();
      });

      it(@"next should mark current promise as ready", ^{
         promise.next();

         [[[promise valueForKey:@"isReady_"] should] equal:theValue(YES)];
      });

      it(@"then should define callbacks", ^{
         RBPromiseFulfilled success = ^RBPromise *(id value){ return nil; };
         RBPromiseRejected failure = ^NSException *(NSException *exception) { return nil; };
         RBPromise *x = [RBPromise mock];

         [promise stub:@selector(next) andReturn:^{ return x; }];
         [x stub:@selector(ready) andReturn:^{ return x; }];

         [[x should] receive:@selector(onSuccess) andReturn:^{ return x; } withArguments:success];
         [[x should] receive:@selector(onCatch) andReturn:^{ return x; } withArguments:NSException.class, failure];

         promise.then(success, failure);
      });
   });

   describe(@"ready", ^{
      it(@"auto after delay", ^{
         [[expectFutureValue([promise valueForKey:@"isReady_"]) shouldEventuallyBeforeTimingOutAfter(1)] equal:theValue(YES)];
      });
   });

   describe(@"cancelation", ^{
      it(@"cancel BEFORE resolved", ^{
         // Just create sub promises
         RBPromise *x1 = promise.next();
         RBPromise *x2 = promise.next();

         [[theValue(promise.state) shouldNot] equal:theValue(RBPromiseStateAborted)];
         [[x1 should] receive:@selector(abort)];
         [[x2 should] receive:@selector(abort)];

         promise.ready();
         [promise cancel];
      });

      it(@"abort (immediate stop) BEFORE resolved", ^{
         [[promiseExecuter should] receive:@selector(cancel)];

         promise.ready();
         [promise abort];

         [[theValue(promise.state) should] equal:theValue(RBPromiseStateAborted)];
      });

      it(@"abort AFTER resolved BEFORE executed", ^{
         [promise stub:@selector(state) andReturn:theValue(RBPromiseStateFulfilled)];

         [[promiseExecuter shouldNot] receive:@selector(cancel)];

         promise.ready();
         [promise abort];

         [[theValue(promise.state) shouldNot] equal:theValue(RBPromiseStateAborted)];
      });

      it(@"abort AFTER executed", ^{
         [promise stub:@selector(state) andReturn:theValue(RBPromiseStateFulfilled)];
         [promiseExecuter stub:@selector(executed) andReturn:theValue(YES)];

         [[promiseExecuter shouldNot] receive:@selector(cancel)];

         promise.ready();
         [promise abort];

         [[theValue(promise.state) shouldNot] equal:theValue(RBPromiseStateAborted)];
      });
   });

   describe(@"resolving", ^{

      it(@"should call future", ^{
         [[promiseFuture should] receive:@selector(resolve:) withArguments:@"Hello Promise"];

         [promise resolve:@"Hello Promise"];
      });

      it (@"should call executer when future is fulfilled", ^{
         [promise stub:@selector(state) andReturn:theValue(RBFutureStateFulfilled)];
         [promiseFuture stub:@selector(result) andReturn:@"Hello Promise"];

         [[promiseExecuter should] receive:@selector(execute:) withArguments:promiseFuture];

         promise.ready();
      });

      it(@"should call RBPromise future", ^{
         RBPromise *x = [RBPromise mock];
         RBFuture *future = [RBFuture mock];

         [[x should] receive:@selector(future_) andReturn:future];
         [[promiseFuture should] receive:@selector(resolve:) withArguments:future];

         [promise resolve:x];
      });

      it(@"Chain calls when resolved", ^{
         RBPromise *x = promise.then(nil, nil);

         [promiseExecuter stub:@selector(executed) andReturn:theValue(YES)];

         [[promiseExecuter should] receive:@selector(result) andReturn:@"Hello Executer"];
         [[x should] receive:@selector(resolve:) withArguments:@"Hello Executer"];

         // We're only testing part where executer finish executing
         // We don't care about previous resoving phases (already tested inside other tests)
         [promise observeValueForKeyPath:RBExecuterExecutedProperty ofObject:self change:nil context:(__bridge void *)(RBExecuterExecutedProperty)];
      });

      it(@"with promise not ready()", ^{
         [promiseFuture stub:@selector(state) andReturn:theValue(RBFutureStateFulfilled)];

         [[promiseExecuter shouldNot] receive:@selector(execute:)];

         [promise observeValueForKeyPath:RBFuturePropertyState ofObject:promiseFuture change:Nil context:(__bridge void *)(RBFuturePropertyState)];
      });

      it(@"with promise ready() before", ^{
         [promise stub:@selector(state) andReturn:theValue(RBFutureStateFulfilled)];

         [[promiseExecuter should] receive:@selector(execute:)];

         promise.ready();
      });

      it(@"with promise ready() after", ^{
         promise.ready();

         [[promiseExecuter should] receive:@selector(execute:)];

         [promiseFuture stub:@selector(state) andReturn:theValue(RBFutureStateFulfilled)];
         [promise observeValueForKeyPath:RBFuturePropertyState ofObject:promiseFuture change:Nil context:(__bridge void *)(RBFuturePropertyState)];
      });
   });
});

SPEC_END