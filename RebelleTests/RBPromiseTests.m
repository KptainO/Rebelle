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
#import "RBAction.h"

SPEC_BEGIN(RBPromiseTests)

describe(@"test", ^ {
   __block RBPromise *promise;
   __block RBExecuter *promiseExecuter;

   beforeEach(^ {
      promise = [RBPromise new];
      promiseExecuter = [RBExecuter nullMock];

      [promise setValue:promiseExecuter forKey:@"executer_"];
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
         [promise stub:@selector(resolveState) andReturn:theValue(RBPromiseResolveStateResolved)];
         [[promiseExecuter should] receive:@selector(result) andReturn:@"Hello World"];
         // Mock RBPromise object that will be created by then() call method
         [[RBPromise should] receive:@selector(new) andReturn:x];

         [[x should] receive:@selector(onSuccess) andReturn:^() { return x; }];
         [[x should] receive:@selector(onCatch) andReturn:^() { return x; }];
         [[x should] receive:@selector(ready) andReturn:^() { return x; }];

         // Test expectations
         [[x should] receive:@selector(resolve:) withArguments:@"Hello World"];

         promise.then(fulfilled, nil);
      });


   });

   describe(@"resolving", ^{
      it(@"simple FULFILLED", ^{
         [promise resolve:@"OK"];

         [[theValue(promise.state) should] equal:theValue(RBPromiseStateFulfilled)];
      });

      it(@"simple REJECTED", ^{
         [promise resolve:[NSException exceptionWithName:@"" reason:nil userInfo:nil]];

         [[theValue(promise.state) should] equal:theValue(RBPromiseStateRejected)];
      });

      it(@"only once even if called x times", ^{
         [promise resolve:@"OK"];
         [promise resolve:[NSException exceptionWithName:@"" reason:nil userInfo:nil]];

         [[theValue(promise.state) should] equal:theValue(RBPromiseStateFulfilled)];
      });
     
      it(@"with RBPromise pending, then re-call resolve:", ^{
         RBPromise *promise2 = [RBPromise new];

         [promise resolve:promise2];
         [[theValue(promise.state) should] equal:theValue(RBPromiseStatePending)];

         // Try to re-resolve promise
         [promise resolve:@"OK"];
         [[theValue(promise.state) should] equal:theValue(RBPromiseStatePending)];
         [[[promise valueForKey:@"result_"] should] equal:promise2];         
      });

      it(@"with RBPromise pending, then resolved", ^{
         RBPromise *promise2 = [RBPromise mock];

         [promise stub:@selector(resolveState) andReturn:theValue(RBPromiseResolveStateReady)];

         [[promise2 stubAndReturn:theValue(NO)] isResolved];
         [promise resolve:promise2];

         [[promise2 should] receive:@selector(isResolved) andReturn:theValue(YES)];
         [[promise2 should] receive:NSSelectorFromString(@"result_") andReturn:@"Hello Resolved"];
         [[promiseExecuter should] receive:@selector(execute:withValue:) withArguments:nil, @"Hello Resolved"];

         // Manually trigger notification about promise2 being "resolved"
         [promise observeValueForKeyPath:RBPromisePropertyResolved
                                ofObject:promise2
                                  change:nil
                                 context:(__bridge void *)(RBPromisePropertyResolved)];
      });
      
      it(@"with RBPromise already resolved", ^{
         RBPromise *promise2 = [RBPromise new];

         [promise stub:@selector(resolveState) andReturn:theValue(RBPromiseResolveStateReady)];

         [[promise2 should] receive:@selector(resolveState) andReturn:theValue(RBPromiseResolveStateResolved)];
         [[promise2 should] receive:NSSelectorFromString(@"result_") andReturn:@"Hello World"];

         [[promiseExecuter should] receive:@selector(execute:withValue:) withArguments:nil, @"Hello World"];

         [promise resolve:promise2];
      });

      it(@"with self throw an exception", ^{
         [[theBlock(^{ [promise resolve:promise]; }) should] raiseWithName:NSInvalidArgumentException];
      });

      it(@"Chain calls when resolved", ^{
         RBPromise *x = promise.then(nil, nil);
         RBExecuter *xExecuter = [RBExecuter mock];

         [x setValue:xExecuter forKey:@"executer_"];
         [promiseExecuter stub:@selector(executed) andReturn:theValue(YES)];
         // Manually notify about executer.executed value
         // Required so that promise loop on sub promises
         [promiseExecuter stub:@selector(execute:withValue:) withBlock:^id(NSArray *arguments) {
            [promise observeValueForKeyPath:NSStringFromSelector(@selector(executed))
                                   ofObject:promiseExecuter
                                     change:nil
                                    context:(__bridge void *)(RBExecuterExecutedProperty)];

            return nil;
         }];


         [[promiseExecuter should] receive:@selector(execute:withValue:)];
         [[promiseExecuter should] receive:@selector(result) andReturn:@"Hello Executer"];
         [[xExecuter should] receive:@selector(execute:withValue:) andReturn:nil withArguments:nil, @"Hello Executer"];

         [promise resolve:@"Hello World"];
      });
   });
});

SPEC_END