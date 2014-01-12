//
// This file is part of Rebelle
//
// Created by JC on 12/23/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import <SenTestingKit/SenTestingKit.h>
#import <Kiwi.h>

#import "RBActionSet.h"
#import "RBErrorException.h"

#import <objc/runtime.h>

SPEC_BEGIN(RBHandlerTests)

describe(@"test", ^{
   __block RBActionSet *actionSet = nil;

   beforeEach(^{
      actionSet = [RBActionSet new];
   });

   describe(@"success", ^{
      it(@"should return argument when NIL", ^{
         NSString *result = @"Hello World";

         [[actionSet.succeeded(result) should] equal:result];
      });
   });

   describe(@"catch", ^{
      it(@"should return exception x when no catch defined", ^{
         NSException *x = [NSException exceptionWithName:@"ExceptionX"
                                                  reason:@""
                                                userInfo:nil];

         [[actionSet.catched(x) should] equal:x];
      });

      it(@"should catch all when class is nil", ^{
         __block BOOL invoked = NO;
         RBPromiseRejected action = ^(NSException *exception) {
            invoked = YES;

            return actionSet;
         };

         [actionSet setCatched:nil do:action];

         actionSet.catched([NSException exceptionWithName:@"" reason:@"" userInfo:nil]);

         [[theValue(invoked) should] beTrue];
      });

      it(@"should catch when exception x", ^{
         __block BOOL invoked = NO;
         RBPromiseRejected action = ^(NSException *exception) {
            invoked = YES;

            return actionSet;
         };

         [actionSet setCatched:RBErrorException.class do:action];

         actionSet.catched([RBErrorException exceptionWithError:nil message:nil]);

         [[theValue(invoked) should] beTrue];
      });

      it(@"should execute only y when exception x", ^{
         __block BOOL goodInvoke = NO;
         __block BOOL badInvoke = NO;

         RBPromiseRejected goodAction = ^(NSException *e) {
            goodInvoke = YES;

            return actionSet;
         };

         RBPromiseRejected badAction = ^(NSException *e) {
            badInvoke = YES;

            return actionSet;
         };

         [actionSet setCatched:RBErrorException.class do:badAction];
         [actionSet setCatched:nil do:goodAction];

         actionSet.catched([NSException exceptionWithName:@"" reason:@"" userInfo:nil]);

         [[theValue(goodInvoke) should] beTrue];
         [[theValue(badInvoke) should] beFalse];
      });

      it(@"should not catch when exception x", ^{
         __block BOOL invoked = NO;
         RBPromiseRejected action = ^(NSException *exception) {
            invoked = YES;

            return actionSet;
         };

         [actionSet setCatched:RBErrorException.class do:action];

         actionSet.catched([NSException exceptionWithName:@"" reason:@"" userInfo:nil]);

         [[theValue(invoked) should] beFalse];
      });
   });
});

SPEC_END