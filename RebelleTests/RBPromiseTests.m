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

SPEC_BEGIN(RBPromiseTests)

describe(@"test", ^ {
   __block RBPromise *promise;

   beforeEach(^ {
      promise = [RBPromise new];
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
         __block BOOL finished = NO;
         RBPromiseFulfilled block = ^id(id result){
            finished = YES;

            return nil;
         };

         [promise stub:@selector(isStatePending) andReturn:theValue(NO)];
         [promise stub:@selector(isResolved) andReturn:theValue(YES)];

         promise.then(block, nil);
         [[theValue(finished) should] equal:theValue(YES)];
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
     
      it(@"with RBPromise pending, called twice", ^{
         RBPromise *promise2 = [RBPromise new];

         [promise resolve:promise2];
         [[theValue(promise.state) should] equal:theValue(RBPromiseStatePending)];

         // Try to re-resolve promise
         [promise resolve:@"OK"];
         [[theValue(promise.state) should] equal:theValue(RBPromiseStatePending)];
         [[[promise valueForKey:@"result_"] should] equal:promise2];         
      });

      it(@"with RBPromise pending, then resolved", ^{
         __block BOOL verified = NO;
         RBPromise *promise2 = [RBPromise new];
         RBPromiseFulfilled block = ^id(id result) {
            [[theValue(promise.state) should] equal:theValue(RBPromiseStateFulfilled)];

            verified = YES;
            return result;
         };

         promise.then(block, nil);

         [promise resolve:promise2];

         [promise2 resolve:@"resolved"];
         [[theValue(verified) should] equal:theValue(YES)];
      });
      
      it(@"with RBPromise already resolved", ^{
         __block BOOL verified = NO;
         RBPromise *promise2 = [RBPromise new];
         RBPromiseFulfilled block = ^id(NSString *result) {
            [[result should] equal:@"resolved"];

            verified = YES;
            return result;
         };

         promise.then(block, nil);
         
         [promise resolve:promise2];
         [promise2 resolve:@"resolved"];
         [[theValue(verified) should] equal:theValue(YES)];
      });

      it(@"with self throw an exception", ^{
         [promise resolve:promise];
      });

      describe(@"chaining", ^{
         __block RBPromise *promise2;
         __block id expectedResult;
         __block id expectedReturn;

         beforeEach(^{
            expectedResult = nil;
            expectedReturn = nil;
            void(^cmp)(id expected, id value) = ^void(id expected, id value) {
               if (expected)
                  [[value should] beIdenticalTo:expected];
               else
                  [value shouldBeNil];
            };

            promise2 = promise.then(^(id result){ cmp(expectedResult, result); return expectedReturn; },
                                    ^(NSException *exception) { cmp(expectedResult, exception); return expectedReturn; });

            promise2.then(^id(id result) { cmp(expectedReturn, result); return nil; },
                          ^id(NSException *result) { cmp(expectedReturn, result); return nil; });
         });

         it(@"promise1 return a value", ^{
            expectedResult = @"resolved";
            expectedReturn = @"promise2 should receive this text";

            [promise resolve:expectedResult];
         });

         it(@"promise1 'throw' an exception but resolve it", ^{
            expectedResult = [NSException exceptionWithName:@"" reason:nil userInfo:nil];
            expectedReturn = @"exception resolved";

            [promise resolve:expectedResult];
         });

         it(@"promise1 'throw' an exception and let it bubble", ^{
            expectedResult = [NSException exceptionWithName:@"" reason:nil userInfo:nil];
            expectedReturn = expectedResult;

            [promise resolve:expectedResult];
         });

         it(@"promise1 return nil", ^{
            expectedResult = @"resolved";

            [promise resolve:expectedResult];
         });

         it(@"promise1 callback is nil", ^{
            expectedResult = @"skipped value";
            expectedReturn = expectedResult;

            promise = [RBPromise new];

            promise2 = promise.then(nil, nil);
            promise2.then(^id(id result){ [[result should] beIdenticalTo:expectedResult]; return nil; }, nil);

            [promise resolve:expectedResult];
         });
      });
   });
});

SPEC_END