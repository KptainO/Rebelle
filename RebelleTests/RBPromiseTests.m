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
#import "RBResolver.h"

SPEC_BEGIN(RBPromiseTests)

describe(@"test", ^ {
   __block RBPromise *promise;
   __block RBExecuter *promiseExecuter;
   __block RBResolver *promiseResolver;

   beforeEach(^ {
      promise = [RBPromise new];
      promiseExecuter = [RBExecuter nullMock];
      promiseResolver = [RBResolver nullMock];

      [promise stub:@selector(executer_) andReturn:promiseExecuter];
      [promise stub:@selector(resolver_) andReturn:promiseResolver];
   });

   afterEach(^{
      promiseExecuter = nil;
      promise = nil;
   });

   describe(@"then method", ^{
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

      it(@"call callbacks when promise already resolved", ^{
         RBPromise *x = [RBPromise nullMock];
         RBPromiseFulfilled fulfilled = ^id(id result){ return nil; };

         // Stub current promise for test
         [RBPromise stub:@selector(new) andReturn:x];
         [promise stub:@selector(isResolved) andReturn:theValue(YES)];

         [x stub:@selector(onSuccess) andReturn:^{ return x; }];
         [x stub:@selector(onCatch) andReturn:^{ return x; }];
         [x stub:@selector(ready) andReturn:^{ return x; }];

         // Test expectations
         [[promiseExecuter should] receive:@selector(result) andReturn:@"Hello World"];
         [[x should] receive:@selector(resolve:) withArguments:@"Hello World"];

         promise.then(fulfilled, nil);
      });


   });

   describe(@"resolving", ^{

      it(@"should call resolver", ^{
         [[promiseResolver should] receive:@selector(resolve:) withArguments:@"Hello Promise"];

         [promise resolve:@"Hello Promise"];
      });

      it (@"should call executer when resolver is fulfilled", ^{
         [promiseResolver stub:@selector(state) andReturn:theValue(RBResolverStateFulfilled)];
         [promiseResolver stub:@selector(result) andReturn:@"Hello Promise"];

         [[promiseExecuter should] receive:@selector(execute:withValue:) withArguments:nil,@"Hello Promise"];

         [promise observeValueForKeyPath:RBResolverPropertyState ofObject:promiseResolver change:nil context:(__bridge void *)(RBResolverPropertyState)];
      });

      it(@"with RBPromise", ^{
         RBPromise *x = [RBPromise mock];
         RBResolver *resolver = [RBResolver mock];

         [[x should] receive:@selector(resolver_) andReturn:resolver];
         [[promiseResolver should] receive:@selector(resolve:) withArguments:resolver];

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
   });
});

SPEC_END